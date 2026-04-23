#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/Tools/ObjectBoxModel"
swift package resolve
swift package plugin --allow-writing-to-package-directory --allow-network-connections all objectbox-generator --target ObjectBoxModel --no-statistics
echo "Generated: Tools/ObjectBoxModel/generated/EntityInfo-ObjectBoxModel.generated.swift and model-ObjectBoxModel.json"
echo "To use HNSW: merge the embedding property into NuraSafe/Storage/KnowledgeVectorEntity+ObjectBox.swift and replace EntityInfo-NuraSafe.generated.swift + model-NuraSafe.json with generator output (adjust entity name/Uids)."
