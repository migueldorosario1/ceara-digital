#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RIOCARTA_ASTRO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$RIOCARTA_ASTRO_DIR"

source "/home/migueldorosario/Downloads/Antigravity Google/Cicero Agentes/root/cicero_cron_env.sh"

if [[ -f tools/cicero_publish_paused.txt ]]; then
  pause_reason="$(head -c 240 tools/cicero_publish_paused.txt | tr '\n' ' ')"
  printf '[%s] Ceará Digital hourly publish skipped: publicacao automatica pausada (%s)\n' "$(date -Is)" "$pause_reason" >> logs/cicero_hourly_cron.log
  exit 0
fi

if [[ -f tools/loop_24h_until.txt ]]; then
  until_ts="$(cat tools/loop_24h_until.txt)"
  now_epoch="$(date +%s)"
  until_epoch="$(date -d "$until_ts" +%s 2>/dev/null || echo 0)"
  if [[ "$until_epoch" -gt 0 && "$now_epoch" -gt "$until_epoch" ]]; then
    printf '[%s] Ceará Digital hourly publish skipped: janela 24h encerrada em %s\n' "$(date -Is)" "$until_ts" >> logs/cicero_hourly_cron.log
    exit 0
  fi
fi

{
  printf '\n[%s] Ceará Digital hourly publish start\n' "$(date -Is)"
  "$RIOCARTA_PYTHON" scripts/cicero_zelador_destaques.py
  "$RIOCARTA_PYTHON" "/home/migueldorosario/Downloads/Antigravity Google/Cicero Agentes/root/cicero_smoke_markdown.py" 15 --queue
  "$RIOCARTA_NPM" run cicero:publish-hourly
  printf '[%s] Ceará Digital hourly publish done\n' "$(date -Is)"
} >> logs/cicero_hourly_cron.log 2>&1
