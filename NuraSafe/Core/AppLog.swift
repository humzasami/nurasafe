// Core/AppLog.swift
// Unified logging for RAG retrieval and related flows.
//
// How to view logs
// ----------------
// • Xcode: Run the app and open the **Debug area** (⌘⇧Y). Logs use `Logger` (os_log).
// • Filter the console: type `RAG`, `Intent`, `ChatEngine`, `VectorStore`, or `Embedding`.
// • Console.app (device): select the process, search **subsystem** = your bundle id,
//   or **category** = RAG / IntentRouter / ChatEngine.
// • **Debug**-level lines only appear if you enable “Include Debug Messages” in the
//   scheme’s Environment or Console.app; **notice** / **info** / **warning** show by default.
//
// RAG pipeline (high level): IntentRouter → (optional) RAGEngine.retrieve → PromptService → LLM

import Foundation
import os

enum AppLog {
    private static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "io.axon86.NuraSafe"
    }

    static var rag: Logger { Logger(subsystem: subsystem, category: "RAG") }
    static var intent: Logger { Logger(subsystem: subsystem, category: "IntentRouter") }
    static var chatEngine: Logger { Logger(subsystem: subsystem, category: "ChatEngine") }
    static var vector: Logger { Logger(subsystem: subsystem, category: "VectorStore") }
    static var embedding: Logger { Logger(subsystem: subsystem, category: "Embedding") }
}
