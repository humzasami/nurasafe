// Models/EmergencyScenario.swift

import Foundation
import SwiftUI

enum EmergencyScenario: String, CaseIterable, Identifiable {
    case injured    = "First Aid"
    case fire       = "Fire"
    case flood      = "Flood"
    case noPower    = "Power Outage"
    case shelter    = "Shelter"
    case earthquake = "Earthquake"
    case nuclear    = "Nuclear / Radiation"
    case war        = "War / Conflict"
    case chemical   = "Chemical Hazard"
    case tsunami    = "Tsunami"
    case wildfire   = "Wildfire"
    case blizzard   = "Blizzard / Extreme Cold"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .injured:    return "cross.case.fill"
        case .fire:       return "flame.fill"
        case .flood:      return "water.waves"
        case .noPower:    return "bolt.slash.fill"
        case .shelter:    return "house.fill"
        case .earthquake: return "waveform.path.ecg"
        case .nuclear:    return "atom"
        case .war:        return "shield.slash.fill"
        case .chemical:   return "aqi.medium"
        case .tsunami:    return "water.waves"
        case .wildfire:   return "smoke.fill"
        case .blizzard:   return "snowflake"
        }
    }

    var color: Color {
        switch self {
        case .injured:    return Color(red: 0.85, green: 0.2,  blue: 0.2)
        case .fire:       return Color(red: 0.95, green: 0.45, blue: 0.1)
        case .flood:      return Color(red: 0.15, green: 0.5,  blue: 0.9)
        case .noPower:    return Color(red: 0.6,  green: 0.4,  blue: 0.9)
        case .shelter:    return Color(red: 0.2,  green: 0.65, blue: 0.4)
        case .earthquake: return Color(red: 0.75, green: 0.55, blue: 0.2)
        case .nuclear:    return Color(red: 0.9,  green: 0.8,  blue: 0.1)
        case .war:        return Color(red: 0.55, green: 0.15, blue: 0.15)
        case .chemical:   return Color(red: 0.3,  green: 0.75, blue: 0.4)
        case .tsunami:    return Color(red: 0.1,  green: 0.6,  blue: 0.85)
        case .wildfire:   return Color(red: 0.9,  green: 0.35, blue: 0.05)
        case .blizzard:   return Color(red: 0.55, green: 0.8,  blue: 0.95)
        }
    }

    var shortLabel: String {
        switch self {
        case .injured:    return "First Aid"
        case .fire:       return "Fire"
        case .flood:      return "Flood"
        case .noPower:    return "No Power"
        case .shelter:    return "Shelter"
        case .earthquake: return "Quake"
        case .nuclear:    return "Nuclear"
        case .war:        return "War"
        case .chemical:   return "Chemical"
        case .tsunami:    return "Tsunami"
        case .wildfire:   return "Wildfire"
        case .blizzard:   return "Blizzard"
        }
    }

    var modeDescription: String {
        switch self {
        case .injured:    return "Responses focused on first aid, injuries, and medical emergencies."
        case .fire:       return "Responses focused on fire safety, evacuation, and burn treatment."
        case .flood:      return "Responses focused on flood survival, evacuation, and water safety."
        case .noPower:    return "Responses focused on power outage safety, food, and heating."
        case .shelter:    return "Responses focused on finding and securing emergency shelter."
        case .earthquake: return "Responses focused on earthquake survival and aftershock safety."
        case .nuclear:    return "Responses focused on nuclear/radiation exposure and shelter-in-place."
        case .war:        return "Responses focused on conflict zone survival, shelter, and evacuation."
        case .chemical:   return "Responses focused on chemical hazard exposure and decontamination."
        case .tsunami:    return "Responses focused on tsunami evacuation and coastal safety."
        case .wildfire:   return "Responses focused on wildfire evacuation and smoke safety."
        case .blizzard:   return "Responses focused on blizzard survival, hypothermia, and shelter."
        }
    }

    /// Contextual quick prompts shown as chips when this mode is active.
    var suggestedPrompts: [String] {
        switch self {
        case .injured:
            return [
                "How do I stop severe bleeding?",
                "Someone is unconscious — what do I do?",
                "How do I perform CPR?",
                "How do I treat a burn?",
                "Signs of a broken bone?"
            ]
        case .fire:
            return [
                "Fire is blocking the exit — what do I do?",
                "How do I evacuate a burning building?",
                "How do I treat a burn injury?",
                "Is it safe to use the elevator?",
                "How do I signal for rescue?"
            ]
        case .flood:
            return [
                "Water is rising fast — where do I go?",
                "Is it safe to walk through floodwater?",
                "My car is stuck in floodwater",
                "How do I find high ground quickly?",
                "What supplies do I need right now?"
            ]
        case .noPower:
            return [
                "How do I keep food safe without power?",
                "How do I stay warm without heating?",
                "Is it safe to use a generator indoors?",
                "How do I charge my phone without power?",
                "How long will the food in my fridge last?"
            ]
        case .shelter:
            return [
                "How do I find emergency shelter nearby?",
                "How do I shelter-in-place safely?",
                "What should I bring to a shelter?",
                "How do I secure a room from the outside?",
                "How do I signal my location for rescue?"
            ]
        case .earthquake:
            return [
                "Earthquake is happening right now — what do I do?",
                "How do I check for gas leaks after a quake?",
                "Is it safe to go outside after an earthquake?",
                "What are signs of structural damage?",
                "How do I prepare for aftershocks?"
            ]
        case .nuclear:
            return [
                "There is a radiation alert — what do I do immediately?",
                "How do I shelter-in-place from radiation?",
                "Should I take potassium iodide?",
                "How do I decontaminate myself?",
                "How long should I stay indoors?"
            ]
        case .war:
            return [
                "I hear explosions nearby — what do I do?",
                "How do I find a safe evacuation route?",
                "How do I shelter from an airstrike?",
                "What should I pack to evacuate quickly?",
                "How do I signal that I am a civilian?"
            ]
        case .chemical:
            return [
                "I smell a strange gas — what do I do?",
                "How do I protect myself from chemical exposure?",
                "How do I decontaminate my skin and eyes?",
                "Should I evacuate or shelter-in-place?",
                "Signs of chemical poisoning?"
            ]
        case .tsunami:
            return [
                "Tsunami warning just issued — what do I do?",
                "How far inland do I need to go?",
                "I am on the beach and the water is receding",
                "How do I find the nearest high ground?",
                "Is it safe to return after the first wave?"
            ]
        case .wildfire:
            return [
                "Wildfire is approaching — when should I evacuate?",
                "How do I protect my home from embers?",
                "I am trapped by fire — what do I do?",
                "How do I drive through smoke safely?",
                "How do I protect myself from smoke inhalation?"
            ]
        case .blizzard:
            return [
                "I am stranded in my car in a blizzard",
                "Signs of hypothermia and how to treat it?",
                "How do I stay warm without heating?",
                "Is it safe to go outside in a blizzard?",
                "How do I prevent carbon monoxide poisoning indoors?"
            ]
        }
    }
}
