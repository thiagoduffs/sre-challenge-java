#!/bin/bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${SCRIPTS_DIR}/output"

mkdir -p "$OUTPUT_DIR"

echo "=================================================="
echo " Inventario AWS - Regiao: $REGION"
echo " Data: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "=================================================="

for script in "$SCRIPTS_DIR"/*.sh; do
  name=$(basename "$script" .sh)
  [ "$name" = "run_all" ] && continue

  echo ""
  echo "--- Inventariando: $name ---"
  bash "$script" "$REGION" 2>/dev/null | tee "$OUTPUT_DIR/${name}.txt" || echo "  WARN: Falha parcial em $name"
done

echo ""
echo "=================================================="
echo " Inventario completo. Resultados em: $OUTPUT_DIR/"
echo "=================================================="
