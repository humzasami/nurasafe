// Core/LLMSwiftEngine.swift
// Real LLM engine powered by LLM.swift + llama.cpp running Qwen on-device.

import Foundation
import Combine

#if os(iOS)
import LLM

final class LLMSwiftEngine: LLMEngineProtocol {

    let state = CurrentValueSubject<InferenceState, Never>(.idle)

    private var bot: LLM?
    private var cancelled = false

    /// Exposed for RAGEngine to use the loaded model for embeddings.
    var exposedBot: AnyObject? { bot }

    // MARK: - Load model

    /// Base names (no `.gguf`) tried in order. Put the file in `NuraSafe/` so the synchronized group copies it into the app bundle.
    ///
    /// - Qwen 2.5 3B: https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF
    /// - Qwen 2.5 4B: https://huggingface.co/bartowski/Qwen_Qwen2.5-4B-Instruct-GGUF
    private static let bundledGGUFCandidateBaseNames: [String] = [
        "qwen2.5-3b-instruct-q4_k_m",
        "qwen2.5-3b-instruct-q4_k_s",
        "Qwen_Qwen2.5-4B-Instruct-Q4_K_M",
        "Qwen_Qwen2.5-4B-Instruct-Q4_K_S",
    ]

    /// Lower context uses less RAM during `LLMCore` init; does not fix unsupported model architectures.
    private static let maxContextTokens: Int32 = 4096

    func loadModel() async throws {
        if bot != nil { state.send(.idle); return }
        state.send(.loading)

        guard let url = Self.bundledGGUFURL() else {
            let listed = Self.bundledGGUFCandidateBaseNames.map { "\($0).gguf" }.joined(separator: ", ")
            let msg = """
            Model file not found in app bundle. Add one of: \(listed)
            under the NuraSafe folder in Xcode (same folder as your sources) and rebuild. The name must match exactly.
            """
            print("[LLM] ERROR: \(msg)")
            state.send(.failed(msg))
            throw NSError(domain: "NuraSafe.LLM", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }

        Self.logBundleDiagnostics(for: url)

        let loadedBot = await Task.detached(priority: .userInitiated) {
            return LLM(from: url, template: .chatML(nil), maxTokenCount: Self.maxContextTokens)
        }.value

        guard let loadedBot else {
            let msg = """
            Could not load the GGUF file. Common causes:
            (1) GGUF not compatible with bundled llama.cpp — run LocalPackages/LLM/update.sh to refresh llama.xcframework, or use a GGUF built for current llama.cpp.
            (2) Corrupt or incomplete download — re-download the .gguf.
            (3) Out of memory on device — try a smaller quant (e.g. Q4_K_S) or lower max context in LLMSwiftEngine.
            Check Xcode console for [LLM] lines above.
            """
            print("[LLM] ERROR: llama_model_load_from_file returned nil for path: \(url.path)")
            state.send(.failed(msg))
            throw NSError(domain: "NuraSafe.LLM", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }

        print("[LLM] Model loaded OK: \(url.lastPathComponent)")
        self.bot = loadedBot
        state.send(.idle)
    }

    private static func bundledGGUFURL() -> URL? {
        for name in bundledGGUFCandidateBaseNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "gguf") {
                return url
            }
        }
        return nil
    }

    private static func logBundleDiagnostics(for url: URL) {
        let path = url.path
        let fm = FileManager.default
        var sizeMB = "?"
        if let attrs = try? fm.attributesOfItem(atPath: path),
           let bytes = attrs[.size] as? NSNumber {
            sizeMB = String(format: "%.2f", bytes.doubleValue / 1_048_576.0)
        }
        let exists = fm.fileExists(atPath: path)
        print("[LLM] Bundle path: \(path)")
        print("[LLM] File exists: \(exists)  size: ~\(sizeMB) MB")
    }

    // MARK: - Generate (streaming)

    func generate(
        prompt: String,
        parameters: InferenceParameters
    ) -> AsyncThrowingStream<String, Error> {
        cancelled = false
        state.send(.generating)

        return AsyncThrowingStream { continuation in
            Task {
                // Ensure model is loaded
                if self.bot == nil {
                    do { try await self.loadModel() }
                    catch { continuation.finish(throwing: error); return }
                }

                guard let bot = self.bot else {
                    continuation.finish(throwing: NSError(
                        domain: "NuraSafe.LLM", code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Model failed to load."]))
                    return
                }

                // Inject the correct system prompt into the full ChatML prompt
                let fullPrompt = Self.injectSystemPrompt(
                    into: prompt,
                    systemPrompt: parameters.systemPrompt
                )

                // Reset the KV cache before every generation.
                // LLMCore.prepareContext does NOT clear the cache between calls —
                // without this reset, llama_decode fails silently on the 2nd+ message
                // and the stream produces zero tokens (blank bubble).
                await bot.core.resetContext()

                // Sampling + length: without a generation cap, the model can repeat until
                // the context window fills (~4k tokens) if it never emits the stop token.
                await bot.core.setParameters(
                    topP: parameters.topP,
                    temp: parameters.temperature
                )
                await bot.core.setRepeatPenalty(parameters.repeatPenalty)
                await bot.core.setMaxNewTokens(Int32(max(32, min(parameters.maxTokens, 2048))))

                await bot.core.setStopSequence("<|im_end|>")

                // Stream tokens directly from the core, bypassing LLM.respond()
                // which has an isAvailable guard that can block concurrent/rapid calls
                let stream = await bot.core.generateResponseStream(from: fullPrompt)

                var yieldedPieces = 0
                for await token in stream {
                    if self.cancelled { break }
                    let clean = token.replacingOccurrences(of: "<|im_end|>", with: "")
                    if !clean.isEmpty {
                        continuation.yield(clean)
                        yieldedPieces += 1
                        if yieldedPieces >= parameters.maxTokens { break }
                    }
                }

                self.state.send(.idle)
                continuation.finish()
            }
        }
    }

    // MARK: - Cancel

    func cancelGeneration() {
        cancelled = true
        Task { await bot?.core.stopGeneration() }
        state.send(.idle)
    }

    // MARK: - Unload

    func unloadModel() {
        bot = nil
        state.send(.idle)
    }

    // MARK: - Helpers

    /// Replaces (or prepends) the system block in a ChatML-formatted prompt.
    private static func injectSystemPrompt(into prompt: String, systemPrompt: String) -> String {
        let sysStart = "<|im_start|>system\n"
        let sysEnd   = "<|im_end|>"

        if let startRange = prompt.range(of: sysStart),
           let endRange   = prompt.range(of: sysEnd, range: startRange.upperBound..<prompt.endIndex) {
            let before = String(prompt[..<startRange.lowerBound])
            let after  = String(prompt[endRange.upperBound...])
            return before + sysStart + systemPrompt + sysEnd + after
        }

        return sysStart + systemPrompt + sysEnd + "\n" + prompt
    }
}

#endif
