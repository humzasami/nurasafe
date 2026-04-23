// Core/EmbeddingService.swift
// Sentence embedding service using multilingual-e5-small via Core ML.
//
// HOW TO ADD THE EMBEDDING MODEL:
//   1. On your Mac, run the conversion script (Python):
//
//      pip install transformers coremltools torch sentencepiece
//
//      from transformers import AutoTokenizer, AutoModel
//      import coremltools as ct
//      import torch, numpy as np
//
//      model_name = "intfloat/multilingual-e5-small"
//      tokenizer = AutoTokenizer.from_pretrained(model_name)
//      model = AutoModel.from_pretrained(model_name).eval()
//
//      sample = tokenizer("passage: test", return_tensors="pt",
//                         max_length=128, padding="max_length", truncation=True)
//      traced = torch.jit.trace(model,
//                               (sample["input_ids"], sample["attention_mask"]),
//                               strict=False)
//      mlmodel = ct.convert(traced,
//          inputs=[ct.TensorType(name="input_ids",
//                                shape=sample["input_ids"].shape,
//                                dtype=int),
//                  ct.TensorType(name="attention_mask",
//                                shape=sample["attention_mask"].shape,
//                                dtype=int)])
//      mlmodel.save("multilingual-e5-small.mlpackage")
//
//   2. Drag "multilingual-e5-small.mlpackage" into Xcode → NuraSafe target.
//      Make sure "Add to targets: NuraSafe" is checked.
//
//   3. The service auto-detects the model on startup. No code changes needed.
//
// EMBEDDING PREFIXES (required by E5 model):
//   • Documents/chunks: "passage: <title>: <content>"
//   • Queries:          "query: <user message>"
//
// OUTPUT: 384-dimensional float vector, L2-normalised.

import Foundation
import CoreML
import Accelerate

// MARK: - Embedding Service

final class EmbeddingService {

    nonisolated(unsafe) static let shared = EmbeddingService()

    // Maximum token sequence length (must match model input shape)
    static let maxLength = 128
    // Output embedding dimension for multilingual-e5-small
    static let embeddingDim = 384

    private var model: MLModel?
    private(set) var isAvailable = false

    private init() {
        loadModel()
    }

    /// Retries loading if the singleton’s first attempt failed (bundle timing). Called from `RAGEngine.buildIndex`.
    func reloadFromBundleIfNeeded() {
        guard !isAvailable else { return }
        print("[Embedding] Retrying multilingual-e5-small load from bundle…")
        loadModel()
    }

    // MARK: - Model Loading

    private func loadModel() {
        guard let modelURL = Self.resolveBundledE5ModelURL() else {
            Self.logBundleDiagnostics()
            print("[Embedding] multilingual-e5-small not found in bundle. Semantic RAG disabled until model is added.")
            AppLog.embedding.warning("E5 model not in bundle — semantic RAG unavailable.")
            return
        }

        let configs: [(MLComputeUnits, String)] = [
            (.cpuAndNeuralEngine, "cpu+NE"),
            (.cpuAndGPU, "cpu+GPU"),
            (.cpuOnly, "cpuOnly")
        ]
        for (units, label) in configs {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = units
                let loaded = try MLModel(contentsOf: modelURL, configuration: config)
                model = loaded
                isAvailable = true
                Self.logOutputDescriptions(loaded)
                print("[Embedding] multilingual-e5-small loaded (\(label)) from \(modelURL.path). Vector search enabled.")
                AppLog.embedding.notice("multilingual-e5-small loaded — semantic RAG available when index is built.")
                return
            } catch {
                print("[Embedding] Load attempt (\(label)) failed: \(error.localizedDescription)")
            }
        }
        model = nil
        isAvailable = false
        print("[Embedding] Failed to load model after all compute unit strategies. Semantic RAG disabled.")
        AppLog.embedding.error("Failed to load E5 model after retries.")
    }

    private static func logOutputDescriptions(_ model: MLModel) {
        let outs = model.modelDescription.outputDescriptionsByName
        let names = outs.keys.sorted().joined(separator: ", ")
        print("[Embedding] Model outputs: \(names)")
    }

    private static func logBundleDiagnostics() {
        let b = Bundle.main
        let res = b.resourcePath ?? "(nil)"
        print("[Embedding] Bundle resource path: \(res)")
        if let urls = b.urls(forResourcesWithExtension: "mlpackage", subdirectory: nil) {
            print("[Embedding] .mlpackage in bundle: \(urls.map(\.lastPathComponent).joined(separator: ", "))")
        }
        if let urls = b.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil) {
            print("[Embedding] .mlmodelc in bundle: \(urls.map(\.lastPathComponent).joined(separator: ", "))")
        }
    }

    /// Prefer compiled `.mlmodelc` from the build; if only `.mlpackage` is present, compile at first launch.
    private static func resolveBundledE5ModelURL() -> URL? {
        let bundle = Bundle.main
        if let compiled = bundle.url(forResource: "multilingual-e5-small", withExtension: "mlmodelc") {
            return compiled
        }
        if let packageURL = bundle.url(forResource: "multilingual-e5-small", withExtension: "mlpackage") {
            return compilePackageIfNeeded(packageURL)
        }
        // Broader search (folder sync / nested copy)
        if let urls = bundle.urls(forResourcesWithExtension: "mlpackage", subdirectory: nil) {
            if let match = urls.first(where: { $0.lastPathComponent == "multilingual-e5-small.mlpackage" }) {
                return compilePackageIfNeeded(match)
            }
        }
        return nil
    }

    private static func compilePackageIfNeeded(_ packageURL: URL) -> URL? {
        if packageURL.pathExtension == "mlmodelc" { return packageURL }
        do {
            let url = try MLModel.compileModel(at: packageURL)
            print("[Embedding] Runtime-compiled mlpackage → \(url.path)")
            return url
        } catch {
            print("[Embedding] MLModel.compileModel failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Embed

    /// Embeds a passage (knowledge base chunk) for indexing.
    /// Uses "passage: " prefix as required by E5.
    func embedPassage(title: String, content: String) -> [Float]? {
        return embed("passage: \(title): \(content)")
    }

    /// Embeds a user query for retrieval.
    /// Uses "query: " prefix as required by E5.
    func embedQuery(_ query: String) -> [Float]? {
        return embed("query: \(query)")
    }

    // MARK: - Internal Embedding

    private func embed(_ text: String) -> [Float]? {
        guard isAvailable, let model = model else { return nil }

        let tokenizer = E5Tokenizer.shared
        guard tokenizer.isLoaded else {
            AppLog.embedding.error("E5Tokenizer not loaded — tokenizer.json missing from bundle.")
            return nil
        }

        let tokenized = tokenizer.tokenize(text, maxLength: Self.maxLength)
        let L = Self.maxLength

        // Diagnostic: warn if unk rate is unexpectedly high
        let unkRate = tokenizer.unkRate(for: tokenized)
        if unkRate > 0.05 {
            print("[Embedding] ⚠️ High unk rate \(String(format: "%.1f%%", unkRate * 100)) for: \(text.prefix(60))")
        }

        guard tokenized.inputIds.count == L, tokenized.attentionMask.count == L else {
            AppLog.embedding.error("Tokenizer must emit length-\(L) padded ids/mask for E5 Core ML inputs.")
            return nil
        }

        do {
            // E5 Core ML export uses fixed [batch, sequence] e.g. [1, 128] — variable seqLen breaks inference.
            let inputIds = try MLMultiArray(shape: [1, NSNumber(value: L)], dataType: .int32)
            let attentionMask = try MLMultiArray(shape: [1, NSNumber(value: L)], dataType: .int32)

            for i in 0..<L {
                inputIds[[0, i] as [NSNumber]] = NSNumber(value: tokenized.inputIds[i])
                attentionMask[[0, i] as [NSNumber]] = NSNumber(value: tokenized.attentionMask[i])
            }

            // Run inference
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "input_ids": MLFeatureValue(multiArray: inputIds),
                "attention_mask": MLFeatureValue(multiArray: attentionMask)
            ])

            let output = try model.prediction(from: input)

            guard let hiddenState = Self.extractHiddenState(from: output) else {
                AppLog.embedding.error("No usable hidden-state output — check model output names.")
                return nil
            }

            return meanPool(hiddenState: hiddenState, attentionMask: tokenized.attentionMask)

        } catch {
            print("[Embedding] Inference error: \(error.localizedDescription)")
            AppLog.embedding.error("Inference failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Core ML Program / traced exports may rename outputs; try common keys.
    private static func extractHiddenState(from output: MLFeatureProvider) -> MLMultiArray? {
        let candidates = [
            "last_hidden_state",
            "var_0",
            "output",
            "hidden_states",
            "embeddings",
            "logits"
        ]
        for name in candidates {
            if let m = output.featureValue(for: name)?.multiArrayValue { return m }
        }
        let names = output.featureNames.sorted().joined(separator: ", ")
        print("[Embedding] Unknown output layout; feature names: \(names)")
        return nil
    }

    // MARK: - Mean Pooling

    /// Averages token embeddings weighted by attention mask, then L2-normalises.
    /// Supports `[seq, dim]` or `[1, seq, dim]` (batch-major).
    private func meanPool(hiddenState: MLMultiArray, attentionMask: [Int32]) -> [Float] {
        let shape = hiddenState.shape.map { $0.intValue }
        let seq: Int
        let dim: Int
        let batchOffset: Int
        if shape.count == 3 {
            seq = shape[1]
            dim = shape[2]
            let plane = seq * dim
            batchOffset = 0 * plane
        } else if shape.count == 2 {
            seq = shape[0]
            dim = shape[1]
            batchOffset = 0
        } else {
            return [Float](repeating: 0, count: Self.embeddingDim)
        }

        var pooled = [Float](repeating: 0, count: dim)
        var maskSum: Float = 0
        let T = min(seq, attentionMask.count, Self.maxLength)

        for t in 0..<T {
            let mask = Float(attentionMask[t])
            maskSum += mask
            let rowBase = batchOffset + t * dim
            for d in 0..<dim {
                pooled[d] += hiddenState[rowBase + d].floatValue * mask
            }
        }

        if maskSum > 0 {
            for d in 0..<dim { pooled[d] /= maskSum }
        }

        var norm: Float = 0
        vDSP_svesq(pooled, 1, &norm, vDSP_Length(dim))
        norm = sqrt(norm)
        if norm > 0 {
            vDSP_vsdiv(pooled, 1, &norm, &pooled, 1, vDSP_Length(dim))
        }

        if dim != Self.embeddingDim {
            print("[Embedding] Warning: model hidden dim \(dim) ≠ expected \(Self.embeddingDim); downstream assumes E5-small.")
        }

        return pooled
    }
}

