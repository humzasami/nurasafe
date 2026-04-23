// Core/IntentRouter.swift
// Pre-LLM intent detection — decides which "tools" to invoke before generation.
//
// This is a lightweight rule-based router that runs BEFORE the LLM.
// It classifies the user's message and decides:
//   1. Should RAG be invoked? (is this an emergency/knowledge query?)
//   2. Which scenario does this query relate to?
//   3. How urgent is this? (affects inference parameters)
//
// WHY THIS EXISTS (tool calling without LLM overhead):
//   True LLM tool calling requires the model to output structured JSON,
//   which is unreliable at 3B parameter scale and adds latency.
//   This rule-based router achieves the same result deterministically
//   in <1ms with zero model calls.
//
// TOOL CATALOGUE:
//   • .searchKnowledge  — invoke RAG, inject top-K chunks into prompt
//   • .directResponse   — skip RAG, answer from model knowledge + system prompt
//   • .emergencyAlert   — invoke RAG with urgency flag, use emergency parameters

import Foundation

// MARK: - Tool Decision

enum ToolDecision {
    /// RAG should be invoked. Chunks will be injected into the prompt.
    case searchKnowledge(scenario: EmergencyScenario?, urgency: Urgency)
    /// Skip RAG. The query is conversational or off-topic.
    case directResponse
    /// Critical emergency. RAG + emergency inference parameters.
    case emergencyAlert(scenario: EmergencyScenario?)
}

enum Urgency {
    case low        // Informational query
    case medium     // Preparedness / planning
    case high       // Active emergency situation
    case critical   // Life-threatening, immediate action needed
}

// MARK: - Intent Router

final class IntentRouter {

    nonisolated(unsafe) static let shared = IntentRouter()
    private init() {}

    // MARK: - Route

    /// Analyses the user message and returns the appropriate tool decision.
    func route(query: String, activeMode: EmergencyScenario?) -> ToolDecision {
        let lower = query.lowercased()
        let tokens = tokenize(lower)

        let decision: ToolDecision

        // If an emergency mode is active, always search knowledge
        if let mode = activeMode {
            let urgency = detectUrgency(tokens: tokens, text: lower)
            if urgency == .critical {
                decision = .emergencyAlert(scenario: mode)
            } else {
                decision = .searchKnowledge(scenario: mode, urgency: urgency)
            }
        } else if isCriticalEmergency(tokens: tokens, text: lower) {
            let scenario = detectScenario(tokens: tokens, text: lower)
            decision = .emergencyAlert(scenario: scenario)
        } else if isKnowledgeQuery(tokens: tokens, text: lower) {
            let scenario = detectScenario(tokens: tokens, text: lower)
            let urgency = detectUrgency(tokens: tokens, text: lower)
            decision = .searchKnowledge(scenario: scenario, urgency: urgency)
        } else {
            decision = .directResponse
        }

        logIntentDecision(decision, query: query)
        return decision
    }

    private func logIntentDecision(_ decision: ToolDecision, query: String) {
        let preview = query.count > 120 ? String(query.prefix(120)) + "…" : query
        switch decision {
        case .directResponse:
            AppLog.intent.notice("directResponse — conversational routing (emergency-style prompt off); RAG still runs in ChatEngine | query: \(preview, privacy: .public)")
        case .searchKnowledge(let scenario, let urgency):
            let scen = scenario?.rawValue ?? "nil(infer from KB)"
            AppLog.intent.notice("searchKnowledge — RAG ON | scenario=\(scen, privacy: .public) urgency=\(String(describing: urgency), privacy: .public) | query: \(preview, privacy: .public)")
        case .emergencyAlert(let scenario):
            let scen = scenario?.rawValue ?? "nil"
            AppLog.intent.notice("emergencyAlert — RAG ON (emergency params) | scenario=\(scen, privacy: .public) | query: \(preview, privacy: .public)")
        }
    }

    // MARK: - Critical Emergency Detection

    private func isCriticalEmergency(tokens: Set<String>, text: String) -> Bool {
        let criticalPhrases = [
            "help me", "i am dying", "dying", "can't breathe", "cannot breathe",
            "not breathing", "heart attack", "choking", "unconscious", "passed out",
            "severe bleeding", "heavy bleeding", "bleeding out", "on fire",
            "trapped", "drowning", "overdose", "anaphylaxis", "stroke",
            "chest pain", "collapsed", "seizure", "not responding"
        ]
        for phrase in criticalPhrases {
            if text.contains(phrase) { return true }
        }
        let criticalTokens: Set<String> = [
            "dying", "choking", "drowning", "unconscious", "seizing", "overdosed"
        ]
        return !tokens.isDisjoint(with: criticalTokens)
    }

    // MARK: - Knowledge Query Detection

    private func isKnowledgeQuery(tokens: Set<String>, text: String) -> Bool {
        // Emergency action keywords
        let emergencyTokens: Set<String> = [
            // First Aid
            "bleeding", "blood", "wound", "injury", "injured", "hurt", "pain",
            "cpr", "resuscitation", "pulse", "breathing", "breath", "airway",
            "burn", "scald", "fracture", "broken", "bone", "sprain", "strain",
            "shock", "faint", "dizzy", "unconscious", "concussion", "head",
            "allergic", "allergy", "anaphylaxis", "epipen", "swelling",
            "diabetes", "insulin", "glucose", "sugar", "diabetic",
            "poison", "poisoning", "overdose", "toxic", "swallowed",
            "nosebleed", "seizure", "epilepsy", "stroke", "heart",
            // Fire
            "fire", "flame", "smoke", "burning", "evacuation", "evacuate",
            "extinguisher", "grease", "electrical", "arson",
            // Flood
            "flood", "flooding", "water", "drowning", "swept", "current",
            // Earthquake
            "earthquake", "tremor", "aftershock", "rubble", "collapse",
            // Nuclear / Radiation
            "nuclear", "radiation", "radioactive", "iodine", "potassium",
            "fallout", "contamination", "decontamination", "geiger",
            // War / Conflict
            "war", "attack", "explosion", "bomb", "shooting", "shooter",
            "conflict", "military", "landmine", "ordnance",
            // Chemical
            "chemical", "gas", "toxic", "fumes", "chlorine", "nerve",
            "carbon monoxide", "monoxide",
            // Tsunami
            "tsunami", "tidal", "wave", "coastal",
            // Wildfire
            "wildfire", "forest fire", "bushfire", "ember", "evacuation",
            // Blizzard
            "blizzard", "hypothermia", "frostbite", "frozen", "snowstorm",
            "stranded", "cold", "freezing",
            // Power / Shelter
            "power", "outage", "blackout", "generator", "shelter", "refuge",
            // General emergency
            "emergency", "danger", "safe", "safety", "survive", "survival",
            "rescue", "trapped", "escape", "evacuate", "first aid"
        ]

        if !tokens.isDisjoint(with: emergencyTokens) { return true }

        // Question patterns about emergency procedures
        let questionPhrases = [
            "what should i do", "how do i", "how to", "what to do",
            "steps for", "guide for", "help with", "treat", "handle",
            "deal with", "respond to", "prepare for", "protect from"
        ]
        for phrase in questionPhrases {
            if text.contains(phrase) { return true }
        }

        return false
    }

    // MARK: - Scenario Detection

    private func detectScenario(tokens: Set<String>, text: String) -> EmergencyScenario? {
        // Score each scenario by keyword overlap
        let scenarioKeywords: [(EmergencyScenario, Set<String>)] = [
            (.injured, ["bleeding", "blood", "wound", "injury", "injured", "hurt",
                        "cpr", "burn", "fracture", "broken", "shock", "unconscious",
                        "allergy", "anaphylaxis", "seizure", "stroke", "heart",
                        "diabetes", "poison", "choking", "nosebleed"]),
            (.fire,    ["fire", "flame", "smoke", "burning", "extinguisher", "grease"]),
            (.flood,   ["flood", "flooding", "drowning", "swept", "floodwater"]),
            (.earthquake, ["earthquake", "tremor", "aftershock", "rubble", "seismic"]),
            (.nuclear, ["nuclear", "radiation", "radioactive", "iodine", "fallout",
                        "contamination", "decontamination", "potassium"]),
            (.war,     ["war", "attack", "explosion", "bomb", "shooting", "shooter",
                        "conflict", "military", "landmine", "ordnance"]),
            (.chemical, ["chemical", "gas", "toxic", "fumes", "chlorine", "nerve",
                         "monoxide", "propane", "leak"]),
            (.tsunami, ["tsunami", "tidal", "wave", "coastal"]),
            (.wildfire, ["wildfire", "bushfire", "forest fire", "ember"]),
            (.blizzard, ["blizzard", "hypothermia", "frostbite", "snowstorm", "freezing"]),
            (.noPower, ["power", "outage", "blackout", "generator", "electricity"]),
            (.shelter, ["shelter", "refuge", "displaced", "homeless", "stranded"])
        ]

        var bestScenario: EmergencyScenario? = nil
        var bestScore = 0

        for (scenario, keywords) in scenarioKeywords {
            let overlap = tokens.intersection(keywords).count
            if overlap > bestScore {
                bestScore = overlap
                bestScenario = scenario
            }
        }

        return bestScenario
    }

    // MARK: - Urgency Detection

    /// "What are official sources during an emergency?" contains `emergency` but is informational — must not use `.critical`
    /// or the app switches to the terse survival system prompt and the model ignores detailed RAG passages (e.g. NCEMA/MOD).
    private func isInformationalOfficialSourcesQuery(lower: String) -> Bool {
        let asksFacts = lower.contains("what are") || lower.contains("what is") || lower.contains("which ")
            || lower.contains("where can") || lower.contains("where to") || lower.contains("where do")
            || lower.contains("who should") || lower.contains("list ") || lower.contains("tell me about")
        let aboutTrust = lower.contains("source") || lower.contains("official") || lower.contains("government")
            || lower.contains("authority") || lower.contains("agency") || lower.contains("agencies")
            || lower.contains("ncema") || lower.contains("website") || lower.contains("portal")
            || lower.contains("reliable") || lower.contains("verify") || lower.contains("information")
        let topicContext = lower.contains("emergency") || lower.contains("crisis") || lower.contains("disaster")
            || lower.contains("abu dhabi") || lower.contains("uae") || lower.contains("dubai")
        return asksFacts && aboutTrust && topicContext
    }

    private func detectUrgency(tokens: Set<String>, text: String) -> Urgency {
        let lower = text.lowercased()

        if isInformationalOfficialSourcesQuery(lower: lower) {
            return .low
        }

        let criticalTokens: Set<String> = [
            "dying", "dead", "kill", "critical", "severe", "emergency",
            "immediately", "now", "urgent", "help", "sos", "mayday"
        ]
        let highTokens: Set<String> = [
            "bleeding", "burning", "choking", "unconscious", "trapped",
            "drowning", "attack", "explosion", "collapsed", "seizing"
        ]
        let mediumTokens: Set<String> = [
            "injured", "hurt", "pain", "fire", "flood", "earthquake",
            "radiation", "chemical", "tsunami", "wildfire"
        ]

        if !tokens.isDisjoint(with: criticalTokens) { return .critical }
        if !tokens.isDisjoint(with: highTokens)     { return .high }
        if !tokens.isDisjoint(with: mediumTokens)   { return .medium }
        return .low
    }

    // MARK: - Tokenizer

    private func tokenize(_ text: String) -> Set<String> {
        Set(text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 })
    }
}
