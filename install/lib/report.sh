#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# report.sh - Generate post-installation report

# Generate HTML report
generate_html_report() {
  local output_file="${1:-${HOME}/anthonyware-install-report.html}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local metrics_dir=${METRICS_DIR:-${LOG_DIR:-/var/log/anthonyware-install}/metrics}
  local timeline_file="${metrics_dir}/timeline.jsonl"
  
  cat > "$output_file" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Anthonyware OS Installation Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; border-left: 4px solid #3498db; padding-left: 10px; }
        .success { color: #27ae60; font-weight: bold; }
        .error { color: #e74c3c; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        .info-box { background: #ecf0f1; padding: 15px; border-radius: 5px; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #ddd; }
        th { background: #3498db; color: white; }
        tr:hover { background: #f5f5f5; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 3px; font-size: 0.9em; }
        .badge-success { background: #27ae60; color: white; }
        .badge-error { background: #e74c3c; color: white; }
        .badge-warning { background: #f39c12; color: white; }
        .cmd { background: #2c3e50; color: #ecf0f1; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Anthonyware OS Installation Report</h1>
        <div class="info-box">
            <strong>Installation Date:</strong> TIMESTAMP_PLACEHOLDER<br>
            <strong>Profile:</strong> PROFILE_PLACEHOLDER<br>
            <strong>Status:</strong> <span class="STATUS_CLASS_PLACEHOLDER">STATUS_PLACEHOLDER</span>
        </div>

        <h2>📊 Installation Statistics</h2>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Scripts Completed</td><td>COMPLETED_PLACEHOLDER</td></tr>
            <tr><td>Scripts Failed</td><td>FAILED_PLACEHOLDER</td></tr>
            <tr><td>Scripts Skipped</td><td>SKIPPED_PLACEHOLDER</td></tr>
            <tr><td>Total Duration</td><td>DURATION_PLACEHOLDER</td></tr>
            <tr><td>Packages Installed</td><td>PACKAGES_PLACEHOLDER</td></tr>
        </table>

        <h2>💻 Hardware Configuration</h2>
        <div class="info-box">
            <pre>HARDWARE_PLACEHOLDER</pre>
        </div>

        <h2>📦 Installed Components</h2>
        <table>
            <tr><th>Component</th><th>Status</th><th>Time</th></tr>
            COMPONENTS_PLACEHOLDER
        </table>

        <h2>⚙️ System Services</h2>
        <table>
            <tr><th>Service</th><th>Status</th></tr>
            SERVICES_PLACEHOLDER
        </table>

        <h2>⏱ Timeline</h2>
        TIMELINE_PLACEHOLDER

        <h2>🔧 Next Steps</h2>
        <ol>
            <li>Reboot your system: <span class="cmd">sudo reboot</span></li>
            <li>Login at SDDM with your username</li>
            <li>Select Hyprland session</li>
            <li>Enjoy your new system!</li>
        </ol>

        <h2>📝 Logs</h2>
        <p>Installation logs available at: <span class="cmd">LOGS_PLACEHOLDER</span></p>

        <h2>🆘 Troubleshooting</h2>
        <ul>
            <li>View errors: <span class="cmd">cat ~/.anthonyware-logs/errors.log</span></li>
            <li>Check services: <span class="cmd">systemctl --failed</span></li>
            <li>GPU issues: <span class="cmd">lspci -k | grep -A3 VGA</span></li>
            <li>Network issues: <span class="cmd">nmcli device status</span></li>
        </ul>

        <div class="info-box" style="margin-top: 30px;">
            <strong>Documentation:</strong> See <span class="cmd">/root/anthonyware-setup/anthonyware/docs/</span> for detailed guides<br>
            <strong>Support:</strong> Check logs and troubleshooting guides in INSTALL_INSTRUCTIONS.md
        </div>
    </div>
</body>
</html>
EOF

  # Now fill in placeholders with actual data
  sed -i "s/TIMESTAMP_PLACEHOLDER/$(date '+%Y-%m-%d %H:%M:%S')/" "$output_file"
  
  # Get installation stats
  local completed=$(checkpoint_list_completed 2>/dev/null | wc -l)
  local failed=$(checkpoint_list_failed 2>/dev/null | wc -l)
  local skipped=0
  if command -v checkpoint_list_skipped >/dev/null 2>&1; then
    skipped=$(checkpoint_list_skipped 2>/dev/null | wc -l)
  fi
  local duration_minutes=0
  if [[ -n "${INSTALL_START_TIME:-}" ]]; then
    local now_ts
    now_ts=$(date +%s)
    duration_minutes=$(( (now_ts - INSTALL_START_TIME) / 60 ))
  fi
  
  sed -i "s/COMPLETED_PLACEHOLDER/$completed/" "$output_file"
  sed -i "s/FAILED_PLACEHOLDER/$failed/" "$output_file"
  sed -i "s/SKIPPED_PLACEHOLDER/$skipped/" "$output_file"
  sed -i "s/DURATION_PLACEHOLDER/${duration_minutes} min/" "$output_file"
  sed -i "s/PROFILE_PLACEHOLDER/${PROFILE:-unknown}/" "$output_file"
  sed -i "s/PACKAGES_PLACEHOLDER/See package logs/" "$output_file"
  
  # Hardware info
  local hardware=$(hardware_report 2>/dev/null || echo "Hardware detection not available")
  # Escape for HTML
  hardware=$(echo "$hardware" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
  sed -i "s|HARDWARE_PLACEHOLDER|$hardware|" "$output_file"
  
  # Status
  if [[ $failed -eq 0 ]]; then
    sed -i "s/STATUS_PLACEHOLDER/Installation Successful/" "$output_file"
    sed -i "s/STATUS_CLASS_PLACEHOLDER/success/" "$output_file"
  else
    sed -i "s/STATUS_PLACEHOLDER/Installation Completed with Errors/" "$output_file"
    sed -i "s/STATUS_CLASS_PLACEHOLDER/warning/" "$output_file"
  fi

  # Timeline rendering
  if [[ -f "$timeline_file" ]]; then
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$output_file" "$timeline_file" <<'PY'
import json, html, sys
out, tl = sys.argv[1], sys.argv[2]
rows = []
with open(tl, 'r', encoding='utf-8', errors='ignore') as f:
    for line in f:
        try:
            j = json.loads(line)
        except Exception:
            continue
        rows.append(
            f"<tr><td>{html.escape(str(j.get('ts','')))}</td>"
            f"<td>{html.escape(str(j.get('script','')))}</td>"
            f"<td>{html.escape(str(j.get('type','')))}</td>"
            f"<td>{html.escape(str(j.get('msg','')))}</td></tr>"
        )
table = "<table><tr><th>Time</th><th>Script</th><th>Event</th><th>Message</th></tr>" + "".join(rows) + "</table>"
with open(out, 'r', encoding='utf-8') as fh:
    data = fh.read()
data = data.replace('TIMELINE_PLACEHOLDER', table)
with open(out, 'w', encoding='utf-8') as fh:
    fh.write(data)
PY
    else
      local tl_html
      tl_html="<pre>$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$timeline_file" | tr '\n' ' ' )</pre>"
      sed -i "s|TIMELINE_PLACEHOLDER|$tl_html|" "$output_file"
    fi
  else
    sed -i "s|TIMELINE_PLACEHOLDER|<p>No timeline captured.</p>|" "$output_file"
  fi
  
  echo "✓ Report generated: $output_file"
  
  # Try to open in browser if available
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$output_file" 2>/dev/null &
  fi
}

# Generate text report
generate_text_report() {
  local output_file="${1:-${HOME}/anthonyware-install-report.txt}"
  
  cat > "$output_file" <<EOF
╔══════════════════════════════════════════════════════════╗
║ ANTHONYWARE OS INSTALLATION REPORT                       ║
╚══════════════════════════════════════════════════════════╝

Installation Date: $(date '+%Y-%m-%d %H:%M:%S')

$(checkpoint_stats 2>/dev/null || echo "Stats not available")

$(hardware_report 2>/dev/null || echo "Hardware detection not available")

INSTALLED COMPONENTS:
$(checkpoint_list_completed 2>/dev/null || echo "No completion log found")

FAILED COMPONENTS:
$(checkpoint_list_failed 2>/dev/null || echo "No failures")

LOGS LOCATION:
  Main log: ${LOG_DIR}/install-*.log
  Error log: ${LOG_DIR}/errors.log

NEXT STEPS:
  1. Reboot: sudo reboot
  2. Login at SDDM
  3. Select Hyprland session

For troubleshooting, see INSTALL_INSTRUCTIONS.md

╚══════════════════════════════════════════════════════════╝
EOF

  echo "✓ Text report generated: $output_file"
  cat "$output_file"
}

# Export functions
export -f generate_html_report
export -f generate_text_report
