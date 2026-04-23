// Core/LLMEngine.swift
// Abstraction layer for local LLM inference.
// Swap the underlying runtime (llama.cpp / Core ML) without touching the rest of the app.

import Foundation
import Combine

// MARK: - Inference state

enum InferenceState: Equatable {
    case idle
    case loading
    case generating
    case failed(String)
}

// MARK: - LLM Engine Protocol

protocol LLMEngineProtocol: AnyObject {
    var state: CurrentValueSubject<InferenceState, Never> { get }
    func loadModel() async throws
    func generate(prompt: String, parameters: InferenceParameters) -> AsyncThrowingStream<String, Error>
    func cancelGeneration()
    func unloadModel()
}

// MARK: - Inference Parameters

struct InferenceParameters {
    var maxTokens: Int
    var temperature: Float
    var topP: Float
    var repeatPenalty: Float
    var systemPrompt: String

    static let `default` = InferenceParameters(
        maxTokens: 512,
        temperature: 0.7,
        topP: 0.9,
        repeatPenalty: 1.1,
        systemPrompt: SystemPrompts.base
    )

    static let emergency = InferenceParameters(
        maxTokens: 768,
        temperature: 0.3,
        topP: 0.85,
        repeatPenalty: 1.15,
        systemPrompt: SystemPrompts.emergency
    )
}

// MARK: - Mock / Stub Engine (used until real model is integrated)

/// Drop-in stub that simulates streaming token output.
/// Replace with `LlamaCppEngine` once the GGUF model is bundled.
final class MockLLMEngine: LLMEngineProtocol {

    let state = CurrentValueSubject<InferenceState, Never>(.idle)
    private var cancelled = false

    func loadModel() async throws {
        state.send(.loading)
        try await Task.sleep(nanoseconds: 500_000_000)
        state.send(.idle)
    }

    func generate(prompt: String, parameters: InferenceParameters) -> AsyncThrowingStream<String, Error> {
        cancelled = false
        state.send(.generating)

        let response = Self.buildMockResponse(for: prompt)
        let tokens = response.split(separator: " ", omittingEmptySubsequences: false).map(String.init)

        return AsyncThrowingStream { continuation in
            Task {
                for token in tokens {
                    if self.cancelled {
                        continuation.finish()
                        return
                    }
                    try await Task.sleep(nanoseconds: 35_000_000)
                    continuation.yield(token + " ")
                }
                self.state.send(.idle)
                continuation.finish()
            }
        }
    }

    func cancelGeneration() {
        cancelled = true
        state.send(.idle)
    }

    func unloadModel() {
        state.send(.idle)
    }

    // MARK: - Mock response builder

    private static func buildMockResponse(for prompt: String) -> String {
        if prompt.contains(RAGQueryGeneration.promptMarker) {
            return "<retrieval_query>emergency safety procedures</retrieval_query>"
        }
        let lower = prompt.lowercased()
        if lower.contains("fire") {
            return """
            🔥 FIRE EMERGENCY — Act immediately:

            1. Alert everyone nearby — shout "FIRE!" clearly.
            2. Activate the nearest fire alarm pull station.
            3. Call emergency services (911 / 999 / 112) if possible.
            4. Evacuate using stairs — never use elevators.
            5. Feel doors before opening — if hot, find another exit.
            6. Stay low under smoke; crawl if needed.
            7. Once outside, move to the assembly point and do NOT re-enter.

            ⚠️ This is general guidance. Follow official instructions from emergency services.
            """
        } else if lower.contains("flood") {
            return """
            🌊 FLOOD EMERGENCY — Stay safe:

            1. Move immediately to higher ground — do not wait.
            2. Avoid walking or driving through floodwater (6 inches can knock you down).
            3. Turn off utilities at the main switch if safe to do so.
            4. Disconnect electrical appliances.
            5. Do not touch electrical equipment if wet.
            6. If trapped indoors, go to the highest floor and signal for help.
            7. Listen to emergency broadcasts for evacuation orders.

            ⚠️ This is general guidance. Seek official emergency services assistance.
            """
        } else if lower.contains("injur") || lower.contains("bleed") {
            return """
            🩹 INJURY / FIRST AID — Immediate steps:

            1. Ensure the scene is safe before approaching.
            2. Call emergency services immediately.
            3. For severe bleeding: apply firm direct pressure with a clean cloth.
            4. Do not remove embedded objects — stabilise them.
            5. Keep the person warm and still.
            6. Monitor breathing — if absent, begin CPR if trained.
            7. Stay with the person until help arrives.

            ⚠️ This is general guidance. Professional medical care is essential.
            """
        } else if lower.contains("shelter") || lower.contains("war") || lower.contains("attack") {
            return """
            🏠 EMERGENCY SHELTER — Immediate steps:

            1. Move to the most interior room of a sturdy building.
            2. Stay away from windows and exterior walls.
            3. If outdoors, find a ditch or low-lying area and lie flat.
            4. Do not use elevators.
            5. Keep emergency supplies: water, food, first aid kit, torch.
            6. Monitor battery-powered radio for official instructions.
            7. Do not leave shelter until authorities declare it safe.

            ⚠️ Follow official civil defence instructions at all times.
            """
        } else if lower.contains("nuclear") || lower.contains("radiation") {
            return """
            ☢️ NUCLEAR / RADIATION ALERT — Critical steps:

            1. GET INSIDE — any building is better than outside.
            2. STAY INSIDE — close all windows, doors, and fireplace dampers.
            3. TURN OFF fans, AC, and heating systems that draw outside air.
            4. Go to the basement or the centre of a middle floor.
            5. Remove outer clothing and shower with soap and water.
            6. Do NOT use conditioner (it binds radioactive particles to hair).
            7. STAY TUNED to emergency broadcasts for further instructions.

            ⚠️ This is general guidance. Follow official civil defence orders immediately.
            """
        } else if lower.contains("earthquake") {
            return """
            🌍 EARTHQUAKE — Drop, Cover, Hold On:

            1. DROP to hands and knees immediately.
            2. Take COVER under a sturdy desk/table, or against an interior wall.
            3. HOLD ON until shaking stops.
            4. Stay away from windows, heavy furniture, and exterior walls.
            5. If outdoors, move away from buildings, trees, and power lines.
            6. After shaking stops, check for injuries and hazards.
            7. Expect aftershocks — be prepared to drop again.

            ⚠️ This is general guidance. Seek official emergency services assistance.
            """
        } else if lower.contains("power") || lower.contains("blackout") {
            return """
            🔋 POWER OUTAGE — Stay prepared:

            1. Use torches — avoid candles if possible (fire risk).
            2. Keep refrigerator and freezer doors closed to preserve food.
            3. Disconnect sensitive electronics to protect from surges.
            4. Use battery-powered or hand-crank radio for news.
            5. Never use generators, grills, or camp stoves indoors.
            6. Check on elderly and vulnerable neighbours.
            7. If using a generator, keep it outside and away from windows.

            ⚠️ This is general guidance. Follow utility company instructions.
            """
        } else if lower.contains("war") || lower.contains("conflict") || lower.contains("attack") || lower.contains("bomb") {
            return """
            🛡️ WAR / CONFLICT ZONE — Immediate steps:

            1. GET INSIDE a sturdy building immediately — away from windows.
            2. Move to the lowest floor or basement if possible.
            3. Stay away from glass, exterior walls, and doors.
            4. Do NOT go outside during active shelling or gunfire.
            5. Keep emergency bag ready: water, food, documents, first aid, torch.
            6. Listen to official civil defence broadcasts for evacuation orders.
            7. If you must evacuate, use designated safe corridors — avoid open roads.
            8. Raise a white flag or signal if you need rescue.

            ⚠️ War / Conflict Mode active. Follow official civil defence instructions immediately.
            """
        } else if lower.contains("chemical") || lower.contains("gas") || lower.contains("toxic") {
            return """
            ☣️ CHEMICAL HAZARD — Act immediately:

            1. Move UPWIND and UPHILL from the source immediately.
            2. If indoors, seal doors and windows with tape or wet cloth.
            3. Turn off all ventilation, AC, and fans.
            4. Do NOT eat, drink, or touch anything potentially contaminated.
            5. If exposed: remove all clothing, shower with soap and water for 15+ minutes.
            6. Do NOT induce vomiting if chemical was swallowed — call poison control.
            7. Cover nose and mouth with a damp cloth if you must move through contaminated air.

            ⚠️ Chemical Hazard Mode active. This is general guidance — seek medical help immediately.
            """
        } else if lower.contains("tsunami") || lower.contains("tidal wave") {
            return """
            🌊 TSUNAMI WARNING — Evacuate immediately:

            1. Move INLAND and to HIGH GROUND immediately — do not wait for visual confirmation.
            2. A tsunami warning means you have minutes — leave NOW.
            3. Do NOT go to the beach to watch — this is fatal.
            4. If you feel a strong earthquake near the coast, treat it as a tsunami warning.
            5. Follow designated tsunami evacuation routes (blue signs).
            6. If caught in water: grab a floating object and protect your head.
            7. Do NOT return to coastal areas until authorities declare it safe.

            ⚠️ Tsunami Mode active. This is general guidance — follow official evacuation orders.
            """
        } else if lower.contains("wildfire") || lower.contains("bush fire") || lower.contains("forest fire") {
            return """
            🔥 WILDFIRE — Evacuate or shelter immediately:

            1. If evacuation is ordered — LEAVE IMMEDIATELY. Do not delay.
            2. Take your emergency bag: water, documents, medications, phone charger.
            3. Close all windows, doors, and vents to slow fire entry.
            4. Turn off gas at the meter. Leave lights on so firefighters can see your home.
            5. If trapped in a vehicle: park away from trees, windows down, lie on floor.
            6. If caught outside: find a ditch or low area, cover yourself with soil/blanket.
            7. Breathe through a wet cloth to filter smoke.

            ⚠️ Wildfire Mode active. Follow official evacuation orders immediately.
            """
        } else if lower.contains("blizzard") || lower.contains("snowstorm") || lower.contains("hypothermia") || lower.contains("cold") {
            return """
            ❄️ BLIZZARD / EXTREME COLD — Stay safe:

            1. STAY INDOORS — do not travel unless absolutely necessary.
            2. Layer clothing: base layer (wool/synthetic), insulating layer, waterproof outer layer.
            3. Eat high-calorie foods and drink warm fluids to maintain body heat.
            4. Never use gas stoves, BBQs, or generators indoors for heat (carbon monoxide risk).
            5. If stranded in a vehicle: run engine 10 min/hour, keep exhaust pipe clear of snow.
            6. Hypothermia signs: uncontrollable shivering, confusion, slurred speech — warm slowly.
            7. Check on elderly and vulnerable neighbours.

            ⚠️ Blizzard Mode active. This is general guidance — follow official weather service instructions.
            """
        } else {
            return """
            I'm NuraSafe — your offline emergency assistant. I'm here to help you stay safe.

            You can ask me about:
            • 🔥 Fire & Wildfire safety
            • 🌊 Flood & Tsunami survival
            • 🩹 First aid and injuries
            • 🏠 Emergency shelter
            • ☢️ Nuclear/radiation alerts
            • 🌍 Earthquake response
            • 🔋 Power outages
            • 🛡️ War / Conflict zones
            • ☣️ Chemical hazards
            • ❄️ Blizzard / Extreme cold

            Tap an emergency button above, select a Mode, or type your situation below.

            ⚠️ Always follow official emergency services instructions when available.
            """
        }
    }
}
