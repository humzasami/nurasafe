# NuraSafe — Private Offline AI Safety Companion

<p align="center">
  <img src="docs/images/banner.png" alt="NuraSafe banner" width="100%" />
</p>

[![App Store](https://img.shields.io/badge/App%20Store-Free%20Download-blue?logo=apple)](https://apps.apple.com/app/id6761926910)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018.5+-lightgrey?logo=apple)](https://apps.apple.com/app/id6761926910)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Medium](https://img.shields.io/badge/Medium-Technical%20Article-black?logo=medium)](https://medium.com/@thegotoguyx/how-i-built-a-smarter-rag-system-for-a-mobile-ai-app-80f7aeecdcf5)

> **Your private, offline AI — ready when it matters most.**

NuraSafe is a fully offline AI safety companion for iPhone. It runs a 3-billion parameter LLM and a semantic embedding model entirely on-device using Apple's Neural Engine. No internet connection required. No cloud. No data leaves your device.

---

## 📱 Download

**[Download free on the App Store →](https://apps.apple.com/app/id6761926910)**

**[Project website → nurasafe.io](https://nurasafe.io)**

---

## 📸 Screenshots

<p align="center">
  <img src="docs/images/chat.png" width="220" alt="Chat screen — offline AI assistant" />
  <img src="docs/images/emergency-modes.png" width="220" alt="Emergency mode selector" />
  <img src="docs/images/nuclear-mode.png" width="220" alt="Nuclear / Radiation mode active" />
</p>

---

## ✨ Features

- **Works fully offline** — all AI inference runs on-device via Core ML and llama.cpp
- **Emergency mode system** — dedicated AI modes for fire, flood, earthquake, nuclear, chemical, medical, and more
- **Adaptive Hybrid RAG** — proprietary retrieval pipeline combining semantic + lexical search (see below)
- **Conversation memory** — retains last 3 exchanges for context-aware follow-up
- **Multilingual support** — responds in the user's preferred language
- **Pin important responses** — save critical guidance for quick access
- **Complete privacy** — zero data collection, no tracking, no account required

---

## 🚨 Emergency Modes

Tapping the emergency panel activates a dedicated mode that re-focuses the LLM's system prompt, filters the knowledge base to the relevant scenario, and surfaces contextual quick-prompt chips. Each mode has its own conversation history and can be deactivated at any time to return to general chat.

| Mode | Scenario | What it focuses on |
|------|----------|--------------------|
| 🩺 **First Aid** | Medical emergencies, injuries | CPR, bleeding, burns, fractures, unconsciousness |
| 🔥 **Fire** | Structure fires, wildfires | Evacuation, smoke, burn treatment, rescue signals |
| 🌊 **Flood** | Flash flood, rising water | High ground, floodwater safety, vehicle escape |
| ⚡ **Power Outage** | Grid failure | Food safety, heating, generator use, device charging |
| 🏠 **Shelter** | Displacement, no shelter | Shelter-in-place, emergency shelters, securing a room |
| 🌍 **Earthquake** | Seismic events | Drop/cover/hold, gas leaks, aftershocks, structural damage |
| ☢️ **Nuclear / Radiation** | Radiation alert, dirty bomb | Shelter-in-place, potassium iodide, decontamination |
| 🛡️ **War / Conflict** | Active conflict zone | Evacuation routes, airstrikes, civilian signalling |
| ☣️ **Chemical Hazard** | Gas leak, chemical release | Exposure response, decontamination, evacuate vs. shelter |
| 🌊 **Tsunami** | Coastal wave warning | Evacuation distance, high ground, return timing |
| 🌲 **Wildfire** | Fast-moving fire | Evacuation timing, ember defence, smoke inhalation |
| ❄️ **Blizzard / Extreme Cold** | Severe winter storm | Hypothermia, car survival, carbon monoxide |

### How modes work technically

When a mode is activated:

1. A new dedicated conversation is created and tagged with the scenario.
2. The system prompt switches to a mode-specific template (see `Core/SystemPrompts.swift`).
3. The RAG pipeline pre-filters the knowledge base to chunks matching the active scenario before hybrid search runs.
4. Five contextual quick-prompt chips appear in the chat UI so users can get help with one tap.
5. Deactivating the mode resumes the previous general-chat conversation.

### Adding a new emergency mode

1. **Add a case** to `EmergencyScenario` in `NuraSafe/Models/EmergencyScenario.swift`:
   ```swift
   case volcano = "Volcanic Eruption"
   ```

2. **Fill in the required computed properties** in the same file — `icon` (SF Symbol name), `color`, `shortLabel`, `modeDescription`, and `suggestedPrompts` (5 example questions).

3. **Add a system prompt** in `NuraSafe/Core/SystemPrompts.swift` — add a `case` to the switch in `systemPrompt(for:)` with survival-focused instructions for the LLM.

4. **Add knowledge base chunks** in `NuraSafe/Resources/KnowledgeBase.json` — add JSON objects with `"id"`, `"scenario"` (matching the raw value, e.g. `"Volcanic Eruption"`), `"title"`, and `"content"` fields. The RAG engine picks them up automatically on next launch.

---

## 🏗️ Architecture

### Tech Stack

| Component | Technology |
|-----------|-----------|
| Chat LLM | Qwen 2.5 3B Instruct (Q4_K_M, ~2GB) via llama.cpp |
| Embedding model | multilingual-e5-small (384-dim, Core ML, Neural Engine) |
| Tokenizer | Unigram SentencePiece (250,002 vocab, bit-identical to HuggingFace) |
| Knowledge base | 120 chunks across 26 emergency/safety scenarios |
| Vector store | In-memory cosine similarity search (<0.1ms) |
| Persistence | ObjectBox + KnowledgeIndexStore (JSON embedding cache) |
| UI | SwiftUI |
| Language | Swift |

---

### Adaptive Hybrid RAG Pipeline

The core innovation in NuraSafe is a five-component retrieval pipeline designed specifically for small on-device LLMs. Standard RAG architectures break on small models in three ways — query drift, retrieval noise, and semantic blindness — this pipeline addresses each.

```
User message
     │
     ▼
[1] Retrieval Gate ─── SKIP ──► LLM answers from memory
     │ (needs KB)
     ▼
[2] Query Generator
     │  LLM compresses message + mode context → search phrase
     ▼
[3] Drift Guard (Jaccard check) ── drift detected ──► use raw message
     │ no drift
     ▼
[4] Hybrid Search
     │  BM25 (40%) + E5 Semantic (60%) on scenario-filtered candidates
     ▼
[5] Degenerate Embedding Detection ── degenerate ──► BM25-only fallback
     │ healthy
     ▼
Top 3 chunks injected into LLM prompt
     │
     ▼
Answer LLM — grounded in KB content
```

#### Component Details

**[1] Retrieval Gate**
Decides whether the message requires knowledge base grounding or is general conversation. Outputs `<retrieval_query>` or `<retrieval_skip/>`. Prevents irrelevant KB passages from polluting conversational turns.

**[2] Query Generator**
First lightweight LLM pass that compresses the user message + active emergency mode context into a focused retrieval phrase. Adds medical/safety terminology the user didn't type. Mode-aware: "what should I do" in Fire mode becomes "fire immediate steps what should I do".

**[3] Drift Guard**
Computes Jaccard similarity between the generated query and the original user message. If overlap falls below threshold (J < 0.15, coverage < 0.4), the system falls back to the verbatim user message. Prevents the small LLM from drifting to the wrong topic.

**[4] Hybrid Search**
- **BM25** (Okapi BM25, k1=1.5, b=0.75) with title match bonus (2×) and scenario/ID bonus (0.8×)
- **E5 Semantic** using multilingual-e5-small, cosine similarity, threshold 0.25, min-max normalised per query
- Combined: `score = 0.60 × normalised_semantic + 0.40 × normalised_BM25`

**[5] Degenerate Detection**
Monitors the spread of top-20 E5 similarity scores. If min > 0.88 and spread < 0.06, embeddings are considered degenerate and weight shifts to BM25-only (100%) until resolved.

---

### Evaluation Results

Tested on 23 real-device queries (Apple A19 Pro, Neural Engine). All metrics from production Xcode logs.

| Query Type | N | Hit@1 | Hit@3 | MRR |
|------------|---|-------|-------|-----|
| Exact keyword | 2 | 100% | 100% | 1.000 |
| Paraphrase | 8 | 12% | 75% | 0.375 |
| Implicit/symptom | 8 | 38% | 38% | 0.375 |
| Emergency mode | 5 | 40% | 100% | 0.700 |
| **Overall** | **23** | **35%** | **70%** | **0.500** |

**vs no retrieval: 0% Hit@3.**  
The pipeline provides a +70 percentage point improvement over a 3B model answering from training data alone.

Key findings:
- Drift guard fired 9/23 times — prevented 3 documented catastrophic retrieval failures
- E5 semantic search retrieved correct chunks with zero keyword overlap in 4 cases
- Emergency mode: 0% skip rate, 100% Hit@3, <0.1ms vector search

Full technical write-up: [Medium article](https://medium.com/@thegotoguyx/how-i-built-a-smarter-rag-system-for-a-mobile-ai-app-80f7aeecdcf5)

---

## 📁 Project Structure

```
NuraSafe/
├── Core/
│   ├── E5Tokenizer.swift          # Unigram SentencePiece tokenizer (250k vocab)
│   ├── EmbeddingService.swift     # Core ML E5 inference + mean pooling
│   ├── RAGEngine.swift            # Hybrid BM25+E5 retrieval pipeline
│   ├── RAGQueryGeneration.swift   # Query parsing + drift guard
│   ├── VectorStore.swift          # In-memory cosine similarity search
│   ├── MemoryManager.swift        # ConversationBufferWindowMemory (3 pairs)
│   ├── IntentRouter.swift         # Rule-based intent + urgency detection
│   ├── SystemPrompts.swift        # Prompt templates for all modes
│   └── LLMEngine.swift            # llama.cpp inference protocol
│
├── Services/
│   ├── ChatEngine.swift           # Pipeline orchestration
│   └── PromptService.swift        # ChatML prompt builder
│
├── Storage/
│   ├── ObjectBoxKnowledgeStore.swift  # KB text persistence
│   ├── KnowledgeIndexStore.swift      # Embedding cache (JSON)
│   └── StorageService.swift           # SwiftData conversations
│
├── Resources/
│   ├── KnowledgeBase.json         # 120 safety/emergency chunks
│   ├── tokenizer.json             # E5 Unigram vocabulary (250k entries)
│   └── sentencepiece.bpe.model    # SentencePiece binary model
│
├── UI/
│   ├── Screens/                   # ChatView, SettingsView, ModeSelectionView, etc.
│   └── Components/                # MessageBubble, ChatSideMenu, EmergencyPanel, etc.
│
└── multilingual-e5-small.mlpackage   # Core ML embedding model
```

---

## 🚀 Getting Started

### Prerequisites

- Xcode 16+ (non-beta)
- iOS 18.5+ device or simulator
- Apple Developer account (for device deployment)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/NuraSafe.git
   cd NuraSafe
   ```

2. **Download the Qwen 2.5 GGUF model** (~2 GB, chat LLM)

   Run the download script — it fetches the GGUF and places it directly in `NuraSafe/`:
   ```bash
   bash Scripts/download-models.sh
   ```
   This downloads `qwen2.5-3b-instruct-q4_k_m.gguf` from [Hugging Face](https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF). The download supports resume if interrupted.

3. **Convert the E5 embedding model** (~90 MB, semantic search)

   The `multilingual-e5-small.mlpackage` is not redistributable as a pre-built binary, so you generate it once on your Mac from the original HuggingFace weights.

   **a. Install dependencies** (Python 3.9+ required):
   ```bash
   pip install transformers coremltools torch sentencepiece
   ```

   **b. Run the conversion** (save this as a `.py` file and run it, or paste into a Python shell):
   ```python
   from transformers import AutoTokenizer, AutoModel
   import coremltools as ct
   import torch

   model_name = "intfloat/multilingual-e5-small"
   tokenizer = AutoTokenizer.from_pretrained(model_name)
   model = AutoModel.from_pretrained(model_name).eval()

   sample = tokenizer("passage: test", return_tensors="pt",
                      max_length=128, padding="max_length", truncation=True)
   traced = torch.jit.trace(model,
                            (sample["input_ids"], sample["attention_mask"]),
                            strict=False)
   mlmodel = ct.convert(traced,
       inputs=[ct.TensorType(name="input_ids",
                             shape=sample["input_ids"].shape,
                             dtype=int),
               ct.TensorType(name="attention_mask",
                             shape=sample["attention_mask"].shape,
                             dtype=int)])
   mlmodel.save("multilingual-e5-small.mlpackage")
   ```

   **c. Move the output into the project:**
   ```bash
   mv multilingual-e5-small.mlpackage NuraSafe/
   ```

   > **Optional step:** The app works without the embedding model — it falls back to BM25-only keyword retrieval. Skip this step if you just want to build and run quickly.

4. **Open in Xcode**
   ```bash
   open NuraSafe.xcodeproj
   ```

5. **Set your Team** in Signing & Capabilities for the NuraSafe target.

6. **Build and run** on a physical device for best performance (Neural Engine).

> **Note:** Both `qwen2.5-3b-instruct-q4_k_m.gguf` and `multilingual-e5-small.mlpackage` are excluded from this repository via `.gitignore`. The GGUF is downloaded by `Scripts/download-models.sh`; the mlpackage is generated locally using the conversion steps above.

---

## 📖 Knowledge Base

The knowledge base (`Resources/KnowledgeBase.json`) contains 120 chunks across 26 scenarios:

- First Aid (22 chunks) — CPR, burns, bleeding, stroke, anaphylaxis, and more
- Fire, Flood, Earthquake, Nuclear, Chemical, Tsunami, Wildfire, Blizzard
- General emergency preparedness, family safety, mental health crisis
- Urban survival, road emergencies, power outage, water safety

Each chunk has an `id`, `scenario`, `title`, and `content` field. The knowledge base is embedded at first launch and cached on disk — subsequent launches load from cache in milliseconds.

---

## 🔬 Research

A formal evaluation of the Adaptive Hybrid RAG pipeline has been conducted and documented:

- **Medium article:** [How I Built a Smarter RAG System for a Mobile AI App](https://medium.com/@thegotoguyx/how-i-built-a-smarter-rag-system-for-a-mobile-ai-app-80f7aeecdcf5)
- **Pipeline architecture:** [nurasafe.io/how-it-works/architecture](https://nurasafe.io/how-it-works/architecture)

---

## 🔒 Privacy

- **Data not collected** — verified by Apple App Store privacy review
- All inference runs on-device
- No network requests for core functionality
- No analytics, no tracking, no third-party SDKs

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

The LLM model (Qwen 2.5) is subject to its own [Qwen License](https://huggingface.co/Qwen/Qwen2.5-3B-Instruct/blob/main/LICENSE).  
The embedding model (multilingual-e5-small) is subject to the [MIT License](https://huggingface.co/intfloat/multilingual-e5-small).

---

## 👤 Author

**Humza Sami Chughtai**

- App Store: [NuraSafe](https://apps.apple.com/app/id6761926910)
- Website: [nurasafe.io](https://nurasafe.io)
- Medium: [@thegotoguyx](https://medium.com/@thegotoguyx)

---

## ⭐ If this project helped you

Consider starring the repo and sharing the [Medium article](https://medium.com/@thegotoguyx/how-i-built-a-smarter-rag-system-for-a-mobile-ai-app-80f7aeecdcf5) — it helps others find the RAG research.
