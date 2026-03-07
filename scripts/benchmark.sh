#!/usr/bin/env bash
set -euo pipefail

# OpenClaw Pixel 10a Benchmark Script
# Captures gateway performance metrics for before/after comparison
#
# Usage:
#   ./scripts/benchmark.sh              # Run full benchmark
#   ./scripts/benchmark.sh --baseline   # Save as baseline (before optimization)
#   ./scripts/benchmark.sh --compare    # Compare current vs saved baseline
#
# Requires: SSH access to Pixel via 'termux' host in ~/.ssh/config

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RESULTS_DIR="${SCRIPT_DIR}/../benchmarks"
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)

SSH_HOST="${SSH_HOST:-termux}"

log() {
  echo "[bench] $*"
}

err() {
  echo "[bench] ERROR: $*" >&2
}

check_ssh() {
  if ! ssh -o ConnectTimeout=5 "$SSH_HOST" 'echo ok' > /dev/null 2>&1; then
    err "Cannot SSH to $SSH_HOST — check connection"
    exit 1
  fi
}

collect_metrics() {
  local output_file="$1"
  log "Collecting metrics from $SSH_HOST..."

  cat > "$output_file" << HEADER
# OpenClaw Pixel 10a Benchmark
# Collected: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
# Host: $SSH_HOST
HEADER

  # --- Device Info ---
  echo "" >> "$output_file"
  echo "## Device" >> "$output_file"
  ssh "$SSH_HOST" '
    echo "kernel: $(uname -r)"
    echo "arch: $(uname -m)"
    echo "node: $(node --version 2>/dev/null || echo N/A)"
    echo "openclaw: $(openclaw --version 2>/dev/null || echo N/A)"
  ' >> "$output_file" 2>/dev/null

  # --- Memory ---
  echo "" >> "$output_file"
  echo "## Memory" >> "$output_file"
  ssh "$SSH_HOST" '
    free -b | awk "/Mem:/ {
      printf \"total_bytes: %s\n\", \$2
      printf \"used_bytes: %s\n\", \$3
      printf \"free_bytes: %s\n\", \$4
      printf \"available_bytes: %s\n\", \$7
      printf \"used_pct: %.1f\n\", (\$3/\$2)*100
    }"
    free -b | awk "/Swap:/ {
      printf \"swap_total_bytes: %s\n\", \$2
      printf \"swap_used_bytes: %s\n\", \$3
    }"
  ' >> "$output_file" 2>/dev/null

  # --- Gateway Process ---
  echo "" >> "$output_file"
  echo "## Gateway Process" >> "$output_file"
  ssh "$SSH_HOST" '
    # Find the actual gateway process (not the launcher bash or openclaw parent)
    GWPID=""
    for pid in $(pgrep -f "openclaw"); do
      PNAME=$(cat /proc/$pid/status 2>/dev/null | awk "/^Name:/ {print \$2}")
      if [ "$PNAME" = "openclaw-gatewa" ] || [ "$PNAME" = "openclaw-gateway" ]; then
        GWPID=$pid
        break
      fi
    done
    if [ -n "$GWPID" ]; then
      echo "pid: $GWPID"
      echo "status: running"
      # RSS in KB from /proc
      RSS_KB=$(awk "/VmRSS/ {print \$2}" /proc/$GWPID/status 2>/dev/null || echo "0")
      echo "rss_kb: $RSS_KB"
      echo "rss_mb: $((RSS_KB / 1024))"
      # VSZ
      VSZ_KB=$(awk "/VmSize/ {print \$2}" /proc/$GWPID/status 2>/dev/null || echo "0")
      echo "vsz_kb: $VSZ_KB"
      echo "vsz_mb: $((VSZ_KB / 1024))"
      # Threads
      THREADS=$(awk "/Threads/ {print \$2}" /proc/$GWPID/status 2>/dev/null || echo "0")
      echo "threads: $THREADS"
      # Open FDs
      FDS=$(ls /proc/$GWPID/fd 2>/dev/null | wc -l)
      echo "open_fds: $FDS"
      # Uptime
      START=$(stat -c %Y /proc/$GWPID 2>/dev/null || echo "0")
      NOW=$(date +%s)
      UPTIME=$((NOW - START))
      echo "uptime_seconds: $UPTIME"
    else
      echo "status: not_running"
    fi
  ' >> "$output_file" 2>/dev/null

  # --- Storage ---
  echo "" >> "$output_file"
  echo "## Storage" >> "$output_file"
  ssh "$SSH_HOST" '
    OPENCLAW_SIZE=$(du -sk ~/.openclaw/ 2>/dev/null | awk "{print \$1}")
    NODE_MODULES_SIZE=$(du -sk /data/data/com.termux/files/usr/lib/node_modules/openclaw/ 2>/dev/null | awk "{print \$1}")
    echo "openclaw_config_kb: ${OPENCLAW_SIZE:-0}"
    echo "openclaw_install_kb: ${NODE_MODULES_SIZE:-0}"
    df /data 2>/dev/null | awk "NR==2 {
      printf \"disk_total_kb: %s\n\", \$2
      printf \"disk_used_kb: %s\n\", \$3
      printf \"disk_avail_kb: %s\n\", \$4
      printf \"disk_used_pct: %s\n\", \$5
    }"
  ' >> "$output_file" 2>/dev/null

  # --- Gateway Responsiveness ---
  echo "" >> "$output_file"
  echo "## Gateway Latency" >> "$output_file"
  # Test WebSocket upgrade latency via HTTP
  local tunnel_active=false
  if lsof -i:18789 > /dev/null 2>&1; then
    tunnel_active=true
  else
    # Start temporary tunnel
    ssh -f -N -L 18789:127.0.0.1:18789 "$SSH_HOST" 2>/dev/null && tunnel_active=true
    sleep 1
  fi

  if $tunnel_active; then
    for i in 1 2 3 4 5; do
      LATENCY=$(curl -s -o /dev/null -w "%{time_total}" http://127.0.0.1:18789/__openclaw__/canvas/ 2>/dev/null || echo "0")
      echo "http_latency_${i}_sec: $LATENCY" >> "$output_file"
    done
    # Average
    AVG=$(awk '/http_latency_.*_sec/ {sum+=$2; n++} END {if(n>0) printf "%.4f", sum/n; else print "0"}' "$output_file")
    echo "http_latency_avg_sec: $AVG" >> "$output_file"
  else
    echo "http_latency_avg_sec: N/A (no tunnel)" >> "$output_file"
  fi

  # --- Log Health ---
  echo "" >> "$output_file"
  echo "## Log Health" >> "$output_file"
  ssh "$SSH_HOST" '
    LOG=~/openclaw-gateway.log
    if [ -f "$LOG" ]; then
      LINES=$(wc -l < "$LOG")
      SIZE_KB=$(($(wc -c < "$LOG") / 1024))
      ERRORS=$(grep -c "error\|Error\|ERROR\|failed\|ENOENT\|EACCES" "$LOG" 2>/dev/null || echo "0")
      WARNINGS=$(grep -c "Warning\|warning\|warn" "$LOG" 2>/dev/null || echo "0")
      CONNECTIONS=$(grep -c "webchat connected" "$LOG" 2>/dev/null || echo "0")
      DISCONNECTIONS=$(grep -c "webchat disconnected" "$LOG" 2>/dev/null || echo "0")
      BONJOUR=$(grep -c "bonjour" "$LOG" 2>/dev/null || echo "0")
      echo "log_lines: $LINES"
      echo "log_size_kb: $SIZE_KB"
      echo "error_count: $ERRORS"
      echo "warning_count: $WARNINGS"
      echo "connection_count: $CONNECTIONS"
      echo "disconnection_count: $DISCONNECTIONS"
      echo "bonjour_spam_count: $BONJOUR"
    else
      echo "log_file: not_found"
    fi
  ' >> "$output_file" 2>/dev/null

  # --- CPU Snapshot ---
  echo "" >> "$output_file"
  echo "## CPU (5-second sample)" >> "$output_file"
  ssh "$SSH_HOST" '
    # Find actual gateway process for CPU measurement
    GWPID=""
    for pid in $(pgrep -f "openclaw"); do
      PNAME=$(cat /proc/$pid/status 2>/dev/null | awk "/^Name:/ {print \$2}")
      if [ "$PNAME" = "openclaw-gatewa" ] || [ "$PNAME" = "openclaw-gateway" ]; then
        GWPID=$pid
        break
      fi
    done
    if [ -n "$GWPID" ]; then
      # Read CPU jiffies at two points
      read _ UTIME1 STIME1 _ < /proc/$GWPID/stat 2>/dev/null
      read CPU_TOTAL1 < <(awk "/^cpu / {print \$2+\$3+\$4+\$5+\$6+\$7+\$8}" /proc/stat 2>/dev/null)
      sleep 5
      read _ UTIME2 STIME2 _ < /proc/$GWPID/stat 2>/dev/null
      read CPU_TOTAL2 < <(awk "/^cpu / {print \$2+\$3+\$4+\$5+\$6+\$7+\$8}" /proc/stat 2>/dev/null)

      PROC_DIFF=$(( (UTIME2 + STIME2) - (UTIME1 + STIME1) ))
      TOTAL_DIFF=$(( CPU_TOTAL2 - CPU_TOTAL1 ))
      if [ "$TOTAL_DIFF" -gt 0 ]; then
        CPU_PCT=$(awk "BEGIN {printf \"%.2f\", ($PROC_DIFF / $TOTAL_DIFF) * 100 * $(nproc)}")
        echo "cpu_pct_5s: $CPU_PCT"
      else
        echo "cpu_pct_5s: 0.00"
      fi
    else
      echo "cpu_pct_5s: N/A"
    fi
  ' >> "$output_file" 2>/dev/null

  log "Metrics saved to $output_file"
}

format_report() {
  local file="$1"
  echo ""
  echo "============================================"
  echo "  OpenClaw Pixel 10a Benchmark Report"
  echo "  $(grep 'Collected:' "$file" | sed 's/# //')"
  echo "============================================"
  echo ""

  # Parse and display
  awk '
    /^## / { section=$0; next }
    /^#/ { next }
    /^$/ { next }
    /: / {
      split($0, a, ": ")
      key=a[1]; val=a[2]
      if (section == "## Memory") {
        if (key == "used_pct") printf "  RAM Used:           %s%%\n", val
        if (key == "available_bytes") printf "  RAM Available:      %d MB\n", val/1048576
      }
      if (section == "## Gateway Process") {
        if (key == "status") printf "  Gateway Status:     %s\n", val
        if (key == "rss_mb") printf "  Gateway RSS:        %s MB\n", val
        if (key == "threads") printf "  Threads:            %s\n", val
        if (key == "open_fds") printf "  Open FDs:           %s\n", val
        if (key == "uptime_seconds") {
          h=int(val/3600); m=int((val%3600)/60); s=val%60
          printf "  Uptime:             %dh %dm %ds\n", h, m, s
        }
      }
      if (section == "## Gateway Latency") {
        if (key == "http_latency_avg_sec") printf "  Avg HTTP Latency:   %s sec\n", val
      }
      if (section == "## Storage") {
        if (key == "openclaw_install_kb") printf "  Install Size:       %d MB\n", val/1024
        if (key == "disk_used_pct") printf "  Disk Used:          %s\n", val
      }
      if (section == "## Log Health") {
        if (key == "error_count") printf "  Errors in Log:      %s\n", val
        if (key == "bonjour_spam_count") printf "  Bonjour Spam:       %s entries\n", val
        if (key == "connection_count") printf "  Total Connections:  %s\n", val
      }
      if (section == "## CPU (5-second sample)") {
        if (key == "cpu_pct_5s") printf "  CPU (5s idle):      %s%%\n", val
      }
    }
  ' "$file"
  echo ""
  echo "  Full data: $file"
  echo "============================================"
}

compare_reports() {
  local baseline="$1"
  local current="$2"

  echo ""
  echo "============================================"
  echo "  Before vs After Optimization"
  echo "============================================"
  echo ""
  printf "  %-25s %12s %12s %10s\n" "Metric" "Before" "After" "Change"
  printf "  %-25s %12s %12s %10s\n" "-------------------------" "------------" "------------" "----------"

  # Extract values from both files
  local metrics=("rss_mb" "threads" "open_fds" "cpu_pct_5s" "http_latency_avg_sec" "error_count" "bonjour_spam_count" "log_lines")
  local labels=("Gateway RSS (MB)" "Threads" "Open File Descriptors" "CPU % (5s idle)" "HTTP Latency (sec)" "Log Errors" "Bonjour Spam Lines" "Total Log Lines")

  for i in "${!metrics[@]}"; do
    local key="${metrics[$i]}"
    local label="${labels[$i]}"
    local val_before=$(grep "^${key}:" "$baseline" 2>/dev/null | awk '{print $2}' || echo "N/A")
    local val_after=$(grep "^${key}:" "$current" 2>/dev/null | awk '{print $2}' || echo "N/A")

    local change="--"
    if [[ "$val_before" =~ ^[0-9.]+$ ]] && [[ "$val_after" =~ ^[0-9.]+$ ]]; then
      if [[ "$val_before" != "0" ]]; then
        change=$(awk "BEGIN {pct=(($val_after - $val_before) / $val_before) * 100; printf \"%+.0f%%\", pct}")
      fi
    fi

    printf "  %-25s %12s %12s %10s\n" "$label" "$val_before" "$val_after" "$change"
  done

  echo ""
  echo "============================================"
}

# --- Main ---

mkdir -p "$RESULTS_DIR"

case "${1:-}" in
  --baseline)
    log "Capturing BASELINE metrics (before optimization)..."
    check_ssh
    OUTFILE="${RESULTS_DIR}/baseline.txt"
    collect_metrics "$OUTFILE"
    format_report "$OUTFILE"
    log "Baseline saved. Run optimizations, then: $0 --compare"
    ;;
  --compare)
    log "Capturing CURRENT metrics and comparing to baseline..."
    check_ssh
    BASELINE="${RESULTS_DIR}/baseline.txt"
    if [[ ! -f "$BASELINE" ]]; then
      err "No baseline found at $BASELINE"
      err "Run '$0 --baseline' first, before applying optimizations."
      exit 1
    fi
    OUTFILE="${RESULTS_DIR}/optimized-${TIMESTAMP}.txt"
    collect_metrics "$OUTFILE"
    format_report "$OUTFILE"
    compare_reports "$BASELINE" "$OUTFILE"
    ;;
  *)
    log "Capturing current metrics..."
    check_ssh
    OUTFILE="${RESULTS_DIR}/snapshot-${TIMESTAMP}.txt"
    collect_metrics "$OUTFILE"
    format_report "$OUTFILE"
    ;;
esac
