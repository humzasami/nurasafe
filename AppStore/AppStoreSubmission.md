# NuraSafe — App Store Submission Reference

> Use this document when filling in App Store Connect fields.
> Replace `[YOUR NAME]` and `[YOUR EMAIL]` with your actual details before submitting.

---

## App Information

| Field | Value |
|---|---|
| **App Name** | NuraSafe |
| **Subtitle** | Offline AI Emergency Assistant |
| **Bundle ID** | com.[yourname].nurasafe *(set in Xcode)* |
| **SKU** | NURASAFE-001 |
| **Primary Category** | Utilities |
| **Secondary Category** | Health & Fitness |
| **Content Rating** | 4+ |
| **Price** | Free *(or set your price)* |

---

## App Description (up to 4000 characters)

```
NuraSafe is your always-ready, fully offline AI assistant for emergencies, safety guidance, and everyday questions.

Powered by a local AI model that runs entirely on your device — no internet, no cloud, no data collection — NuraSafe gives you instant, intelligent guidance whenever you need it most.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WHAT NURASAFE DOES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 General AI Chat
Ask anything — general knowledge, advice, calculations, creative ideas, or everyday questions. Nura is a warm, helpful AI assistant available 24/7, even without a signal.

🚨 Emergency Guidance
Get step-by-step guidance for real-world emergencies:
• First aid (CPR, bleeding, burns, choking, fractures, seizures, stroke, heart attack)
• Natural disasters (earthquake, flood, tsunami, wildfire, blizzard)
• Fire safety and evacuation
• Chemical and nuclear hazards
• Power outages and extreme heat
• Road emergencies and water safety
• Mental health crisis support

📚 Emergency Knowledge Base
Backed by guidance from the WHO, Red Cross/Red Crescent, and international emergency management standards. 80+ practical, research-informed articles covering the scenarios that matter most.

🔒 Emergency Modes
Lock the AI to a specific scenario (Fire, Flood, Earthquake, etc.) for focused, context-aware responses during an active emergency.

📌 Save & Reference
Pin important messages for quick access. Copy any response to share with others.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FULLY OFFLINE & PRIVATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Works without any internet connection
• All AI inference runs on your device
• No accounts, no sign-up, no cloud sync
• Zero data collection — your conversations never leave your device
• No ads, no tracking, no analytics

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPORTANT NOTICE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NuraSafe provides general educational information only. It is not a substitute for professional medical advice or emergency services. In any life-threatening situation, always call your local emergency number (112, 999, or your regional equivalent) first.
```

---

## Keywords (100 characters max)

```
emergency,first aid,offline AI,safety,disaster,CPR,earthquake,flood,fire,survival,assistant
```

---

## Promotional Text (170 characters — can be updated without new build)

```
Your offline AI companion for emergencies and everyday questions. No internet needed. No data collected. Always ready.
```

---

## What's New (Version 1.0)

```
Initial release of NuraSafe — your fully offline AI emergency assistant.

• General AI chat powered by on-device language model
• 80+ emergency guidance articles (first aid, disasters, safety)
• Emergency Modes for focused scenario guidance
• Pin and copy messages for quick reference
• Fully private — no data collection, no internet required
```

---

## App Review Information

### Review Notes (paste into App Store Connect "Notes for Reviewer")

```
NuraSafe is a general-purpose AI chat assistant with a focus on emergency preparedness and safety education.

KEY POINTS FOR REVIEW:

1. FULLY OFFLINE: The app uses an on-device language model (Qwen 2.5 3B Instruct, GGUF format). All AI inference runs locally. No network requests are made for AI functionality.

2. NO DATA COLLECTION: The app collects no personal data. All conversations, settings, and profile information are stored only on the user's device (SwiftData + UserDefaults). No analytics, advertising, or tracking SDKs are included.

3. MEDICAL/SAFETY CONTENT: The emergency guidance content is educational and informational only, based on WHO, Red Cross, and international emergency management guidelines. The app prominently displays a disclaimer that it is not a substitute for professional emergency services. Users are directed to call local emergency services (112/999) in all life-threatening situations.

4. TERMS ACCEPTANCE: Users must accept the Terms of Service and Privacy Policy on first launch before accessing the app. The terms clearly state the app's limitations and that it is not professional medical advice.

5. FIRST LAUNCH: On first launch, the app displays a Terms & Conditions screen that must be accepted. After acceptance, the app loads the AI model (this may take 15-30 seconds on first run as the model is compiled for the device).

6. TEST CREDENTIALS: No login or account is required. The app is fully functional without any credentials.

DEMO SUGGESTIONS:
- Tap "Select Emergency Mode" to see scenario-specific guidance
- Ask "What should I do in a fire?" for emergency guidance
- Ask "What is 2+2?" to see general chat capability
- Long-press any AI message to see copy/pin options
```

---

## Privacy Policy URL

You need a live URL for your Privacy Policy. Options:

### Option A — GitHub Pages (Free, Recommended)
1. Create a GitHub repository (e.g. `nurasafe-privacy`)
2. Create a file `index.html` or `privacy.html` with the privacy policy text
3. Enable GitHub Pages in repository settings
4. URL will be: `https://[yourusername].github.io/nurasafe-privacy/`

### Option B — Simple Web Host
Host a plain HTML page at any domain you control.

### Privacy Policy Text for Web Hosting

Copy the text below into your hosted privacy policy page:

---

**NuraSafe Privacy Policy**
*Last updated: April 2026*

NuraSafe is a fully offline AI assistant app. We are committed to protecting your privacy.

**No Data Collection**
NuraSafe does not collect, transmit, or store any personal data on external servers. The app has no internet connectivity for AI functions and includes no analytics, advertising, or tracking SDKs.

**Data Stored On Your Device**
The following information is stored locally on your device only and is never transmitted:
- Chat conversations and message history
- App settings and preferences
- Optional profile information (name, country, emergency contacts) entered by you
- Pinned messages
- Terms acceptance record

**Pasteboard**
The app writes to your clipboard only when you explicitly tap the Copy button. It never reads from your clipboard.

**Third-Party Services**
NuraSafe does not use any third-party services, SDKs, or APIs that collect data.

**Children**
NuraSafe does not knowingly collect information from children. Since no data is collected from any user, no special measures are required.

**Your Rights**
All your data is on your device and under your control. You can delete it at any time by clearing chat history in Settings or deleting the app.

**Contact**
For privacy questions, contact: [YOUR EMAIL]

---

## Support URL

You need a support URL. Options:
- A GitHub repository page with a README
- An email link: `mailto:[YOUR EMAIL]`
- A simple webpage

---

## Screenshots Required

### iPhone 6.7" (iPhone 16 Pro Max) — Required
Minimum 3 screenshots, up to 10. Suggested:
1. Welcome screen with NuraSafe logo
2. Active chat conversation showing AI response
3. Emergency Mode selection screen
4. Pinned Messages view
5. Settings screen

### iPhone 5.5" (iPhone 8 Plus) — Required for older device support
Same content as above, different device frame.

---

## Checklist Before Submitting

- [ ] Bundle ID set in Xcode (unique, e.g. `com.yourname.nurasafe`)
- [ ] Version: `1.0` | Build: `1`
- [ ] Deployment Target: iOS 17.0 or lower (currently 18.5 — consider lowering)
- [ ] `PrivacyInfo.xcprivacy` added to NuraSafe target in Xcode
- [ ] App icon 1024×1024 present ✅
- [ ] Privacy Policy URL live and accessible
- [ ] Support URL live and accessible
- [ ] All screenshots uploaded (6.7" and 5.5")
- [ ] App description, keywords, and promotional text filled in
- [ ] Review notes added
- [ ] Content rating questionnaire completed (select 4+)
- [ ] Export Compliance: select "No" for encryption (standard HTTPS is exempt; this app uses no networking)
- [ ] Signed with Distribution certificate and correct provisioning profile
