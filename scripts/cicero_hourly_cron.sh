#!/usr/bin/env bash
set -euo pipefail

source "/home/migueldorosario/Downloads/Antigravity Google/Cícero Agentes/root/cicero_cron_env.sh"
cd "/home/migueldorosario/Downloads/Antigravity Google/Cícero Agentes/cicero"

if [[ -f tools/cicero_publish_paused.txt ]]; then
  pause_reason="$(head -c 240 tools/cicero_publish_paused.txt | tr '\n' ' ')"
  printf '[%s] Cícero hourly publish skipped: publicacao automatica pausada (%s)\n' "$(date -Is)" "$pause_reason" >> logs/cicero_hourly_cron.log
  exit 0
fi

if [[ -f tools/loop_24h_until.txt ]]; then
  until_ts="$(cat tools/loop_24h_until.txt)"
  now_epoch="$(date +%s)"
  until_epoch="$(date -d "$until_ts" +%s 2>/dev/null || echo 0)"
  if [[ "$until_epoch" -gt 0 && "$now_epoch" -gt "$until_epoch" ]]; then
    printf '[%s] Cícero hourly publish skipped: janela 24h encerrada em %s\n' "$(date -Is)" "$until_ts" >> logs/cicero_hourly_cron.log
    exit 0
  fi
fi

{
  printf '\n[%s] Cícero hourly publish start\n' "$(date -Is)"
  "$RIOCARTA_PYTHON" scripts/cicero_zelador_destaques.py
  "$RIOCARTA_PYTHON" "../root/cicero_smoke_markdown.py" 15 --queue
  "$RIOCARTA_NPM" run cicero:publish-hourly
  printf '[%s] Cícero hourly publish done\n' "$(date -Is)"
} >> logs/cicero_hourly_cron.log 2>&1
