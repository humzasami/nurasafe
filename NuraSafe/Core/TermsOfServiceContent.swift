// Core/TermsOfServiceContent.swift
// Legal documents shown at first launch and accessible from the side menu.
// Bump `version` when text changes so existing users must acknowledge the update.

import Foundation

enum TermsOfServiceContent {

    /// Increment when the agreement text changes; existing users will see the gate again.
    static let version = "1.1"

    /// Full Terms of Service + Privacy Policy presented for acceptance.
    static let fullText = """
    NURASAFE — TERMS OF SERVICE AND PRIVACY POLICY
    Last updated: April 2026 | Version 1.1

    Please read this document carefully before using NuraSafe. By tapping "I Agree" you confirm that you have read, understood, and agree to be bound by these Terms of Service and Privacy Policy.

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PART A — TERMS OF SERVICE
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    1. WHAT NURASAFE IS
    NuraSafe is a general-purpose AI chat assistant with a focus on emergency preparedness and safety guidance. It runs entirely on your device using a local language model — no internet connection is required or used for AI inference. The app also provides a curated knowledge base of emergency and first-aid guidance.

    2. WHAT NURASAFE IS NOT
    NuraSafe is NOT:
    • A substitute for professional medical, legal, or safety advice.
    • A replacement for emergency services.
    • A certified medical device or clinical decision-support tool.
    • A real-time information service — it has no access to live data, news, or current events.

    AI-generated responses can be incorrect, incomplete, outdated, or inappropriate for your specific situation. Always apply your own judgment.

    3. EMERGENCY SITUATIONS
    In any life-threatening or urgent situation, contact your local emergency number immediately (e.g. 112, 999, or your regional equivalent). Do not delay calling emergency services in order to consult this app. NuraSafe cannot call for help on your behalf, cannot contact emergency services, and cannot verify your location or condition.

    4. AI LIMITATIONS AND ACCURACY
    The AI model in NuraSafe is a general-purpose language model. It:
    • May produce factually incorrect information ("hallucinations").
    • Does not have knowledge of events after its training cutoff date.
    • Cannot assess your specific medical, physical, or environmental situation.
    • May give advice that is inappropriate for your age, health condition, or location.

    All guidance provided by the AI should be treated as general educational information only, not as personalised professional advice.

    5. ACCEPTABLE USE
    You agree to use NuraSafe only for lawful purposes. You must not use the app to:
    • Seek advice for illegal activities.
    • Attempt to circumvent safety guidelines built into the AI.
    • Misrepresent AI-generated content as professional advice to others.

    6. INTELLECTUAL PROPERTY
    The NuraSafe app, its design, branding, and curated knowledge base content are the intellectual property of the developer. The underlying AI model is provided under its respective open-source licence. You are granted a limited, non-exclusive, non-transferable licence to use the app for personal, non-commercial purposes.

    7. DISCLAIMER OF WARRANTIES
    THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, AND NON-INFRINGEMENT.

    8. LIMITATION OF LIABILITY
    TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, THE DEVELOPER OF NURASAFE SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES ARISING FROM YOUR USE OF OR INABILITY TO USE THE APP, INCLUDING ANY RELIANCE ON AI-GENERATED CONTENT, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

    IF ANY LIMITATION OF LIABILITY IS NOT ENFORCEABLE IN YOUR JURISDICTION, LIABILITY SHALL BE LIMITED TO THE MAXIMUM EXTENT PERMITTED BY LAW.

    9. CHANGES TO TERMS
    These terms may be updated from time to time. When they change, you will be asked to review and accept the updated terms before continuing to use the app. The version you accepted is stored locally on your device and accessible from the menu.

    10. GOVERNING LAW
    These terms are governed by applicable law. If any provision is found unenforceable, the remaining provisions continue in full force.

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PART B — PRIVACY POLICY
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    11. OUR COMMITMENT TO YOUR PRIVACY
    NuraSafe is designed with privacy as a core principle. The app is built to work entirely offline. We do not collect, transmit, or sell your personal data.

    12. DATA WE DO NOT COLLECT
    We do NOT collect:
    • Your name, email address, phone number, or any account credentials.
    • Your location or GPS data.
    • Your chat conversations or messages.
    • Your device identifiers or advertising IDs.
    • Crash reports or analytics (no third-party analytics SDKs are included).
    • Biometric data of any kind.

    13. DATA STORED ON YOUR DEVICE
    The following data is stored locally on your device only, using iOS system storage (SwiftData and UserDefaults). It never leaves your device:

    • Chat conversations and message history.
    • App settings (text size, language preference, haptic feedback toggle, AI parameters).
    • Your profile information (display name, country/region, emergency contacts) — entered voluntarily and used only to personalise AI responses on-device.
    • Pinned messages you choose to save.
    • Your acceptance record for these Terms (version accepted and date).
    • The AI knowledge base index (pre-computed embeddings for faster search).

    You can delete all stored data at any time using "Clear Chat History" in Settings, or by deleting the app entirely.

    14. PASTEBOARD (CLIPBOARD)
    NuraSafe writes to your device clipboard only when you explicitly tap the "Copy" button on a message. The app never reads from your clipboard.

    15. EMERGENCY CONTACTS
    If you choose to enter emergency contacts in your profile, this information is stored locally on your device only. It is used solely to allow you to quickly reference contact details within the app. It is never transmitted or shared.

    16. THIRD-PARTY SERVICES
    NuraSafe does not integrate any third-party analytics, advertising, crash reporting, or tracking services. The app contains no SDKs that collect or transmit data.

    The AI model included in the app is an open-source language model distributed under its respective licence. It runs entirely on your device.

    17. CHILDREN'S PRIVACY
    NuraSafe is rated 4+ and does not knowingly collect any personal information from children. Since no data is collected from any user, no special measures for children's data are required beyond this statement.

    18. DATA SECURITY
    All data stored by NuraSafe is protected by iOS system-level security, including device encryption when your device is locked. We have no access to your device or its data.

    19. YOUR RIGHTS
    Since we do not collect or process your personal data on any server, there is no data held by us to access, correct, or delete. All your data is on your device and under your control. You can delete it at any time by clearing chat history in Settings or deleting the app.

    20. CHANGES TO THIS PRIVACY POLICY
    If we make material changes to this Privacy Policy, we will update the version number and ask you to review and accept the updated document. The version you accepted is stored in the app.

    21. CONTACT
    For questions, concerns, or feedback about NuraSafe, please use the support channel listed on the app's page in the App Store.

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    IMPORTANT SAFETY NOTICE
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    NuraSafe provides general educational information about emergencies and safety. It is not a certified medical device, does not provide professional medical advice, and cannot replace trained emergency responders or healthcare professionals.

    In any emergency, always:
    1. Call your local emergency number first (112, 999, or your regional equivalent).
    2. Follow instructions from trained emergency responders.
    3. Use NuraSafe as a supplementary reference only.

    By tapping "I Agree," you confirm that you have read and understood this Terms of Service and Privacy Policy, and you agree to be bound by them.
    """

    /// Short privacy policy summary for display in Settings (links to full text).
    static let privacyPolicySummary = """
    NuraSafe is fully offline and collects no personal data. All conversations, settings, and profile information are stored only on your device and are never transmitted anywhere. No analytics, advertising, or tracking SDKs are included. You can delete all data at any time from Settings.
    """
}
