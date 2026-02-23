#!/usr/bin/env bash
#
# Veeam Agent (Management + Backup) installation and diagnostic script
#
# --- Client one-liner (from UI) ---
# The client runs a single command: curl the script, then run with Management Agent URL.
# This installs the Management Agent, installs the global command 'ovhbackupagent',
# creates the README on disk, and opens the menu.
#
#   curl -sSL "https://YOUR-DOMAIN/install-veeam-agent.sh" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh --setup "https://.../LinuxAgentPackages.xxx.sh"
#
# Replace YOUR-DOMAIN with the script URL and the last URL with the Management Agent download link from VSPC.
#
# --- Other usage ---
#   Menu                :  sudo bash install-veeam-agent.sh
#   Install with URL    :  sudo bash install-veeam-agent.sh "https://.../LinuxAgentPackages.xxx.sh"
#   Full setup + menu   :  sudo bash install-veeam-agent.sh --setup "https://.../LinuxAgentPackages.xxx.sh"
#   Diagnostic          :  sudo bash install-veeam-agent.sh --diagnostic
#   Global command      :  sudo bash install-veeam-agent.sh --install-global  (then: ovhbackupagent)
#

set -e

# --- Configuration (adapt to your environment) ---
VSPC_GATEWAY="${VSPC_GATEWAY:-vspc-cgw1.prod01.eu-west-rbx.backup.ovhcloud.com}"
VSPC_PORT="${VSPC_PORT:-6180}"
LOG_DIRS=("/var/log/veeam" "/var/log/veeam/Backup" "/var/log/veeamma")
SUPPORT_ARCHIVE_NAME="veeam-support-$(date +%Y%m%d-%H%M%S).tar.gz"
SUPPORT_DIR="/tmp/veeam-support"
README_PATH="/usr/local/share/ovhbackupagent/README.md"

# --- Built-in README (accessible via --readme or Help menu) ---
show_readme() {
  cat << 'READMEEOF'
OVHcloud - Backup Agent
=============================

This tool helps you install and manage the Veeam Backup Agent on your Linux server, in connection with the OVHcloud backup offer (Management Agent + Backup Agent).

You can open this menu at any time by running: sudo ovhbackupagent (or by running this script again).


What each menu option does
--------------------------

  A — Agent status
    Displays the current status of the Management Agent and Backup Agent (installed or not, etc.).

  V — Open Veeam interface
    Opens the Veeam Backup Agent interface (if the Backup Agent is already installed). You can configure or run backups from there.

  T — Test connection to VSPC
    Tests whether your server can reach the backup gateway (VSPC). Useful to check network or firewall issues.

  D — Run diagnostic
    Checks the connection to the backup gateway, displays the status of the agents (Management Agent and Backup Agent), and analyses the agent log. If known error messages are found, brief explanations and links are shown. This does not create any file to send.

  B — Create support bundle
    Creates an archive (logs, system information, agent status) that you can send to support. The path of the created file is displayed at the end. Use this when you are asked to provide a "support bundle" or "diagnostic archive".

  I — Install Management Agent
    Only if you want to reinstall the Veeam Management Agent. You will be asked for the path or download URL of the installation package (provided by your backup interface).

  J — Job stuck? Get help with force stop tool
    Lists running backup sessions and lets you force-stop one if a job is stuck. Use with care: force stop may cause backup corruption. See: https://helpcenter.veeam.com/docs/agentforlinux/userguide/backup_job_stop.html?ver=13

  H — Help / README
    Displays this help.

  Q — Quit
    Exits the menu.


Need help?
----------

If you encounter problems (agent not visible, backup failing, connection errors, etc.), you can:

  1. Run D — Run diagnostic to see possible causes and links to documentation.
  2. Run B — Create support bundle to generate an archive with logs and system information.
  3. Contact OVHcloud support and, if needed, send them the support bundle file created in step 2.

OVHcloud support: https://www.ovhcloud.com/en/support/
READMEEOF
}

# --- Colors (disabled if not a terminal) ---
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
  BG_GREEN='\033[42;1m'
  BG_RED='\033[41;1m'
else
  RED="" GREEN="" YELLOW="" BLUE="" BOLD="" NC="" BG_GREEN="" BG_RED=""
fi

info()  { echo -e "${BLUE}[Info]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[Warning]${NC} $*"; }
err()   { echo -e "${RED}[Error]${NC} $*"; }
title() { echo -e "\n${BOLD}$*${NC}\n"; }

# --- ASCII banner OVH logo ---
show_banner() {
  echo -e "${BLUE}"
  echo ' ▗▄▖ ▗▖  ▗▖▗▖ ▗▖ ▗▄▄▖▗▖    ▗▄▖ ▗▖ ▗▖▗▄▄▄     ▗▖  ▗▖    ▗▖  ▗▖▗▄▄▄▖▗▄▄▄▖ ▗▄▖ ▗▖  ▗▖'
  echo '▐▌ ▐▌▐▌  ▐▌▐▌ ▐▌▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌  █     ▝▚▞▘     ▐▌  ▐▌▐▌   ▐▌   ▐▌ ▐▌▐▛▚▞▜▌'
  echo '▐▌ ▐▌▐▌  ▐▌▐▛▀▜▌▐▌   ▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌  █      ▐▌      ▐▌  ▐▌▐▛▀▀▘▐▛▀▀▘▐▛▀▜▌▐▌  ▐▌'
  echo '▝▚▄▞▘ ▝▚▞▘ ▐▌ ▐▌▝▚▄▄▖▐▙▄▄▖▝▚▄▞▘▝▚▄▞▘▐▙▄▄▀    ▗▞▘▝▚▖     ▝▚▞▘ ▐▙▄▄▖▐▙▄▄▖▐▌ ▐▌▐▌  ▐▌'
  echo ''
  echo ''
  echo ''
  echo -e "${NC}"
  echo -e "      ${BOLD}Backup Agent${NC} — CLI Assistant"
  echo "  ─────────────────────────────────────"
  echo ""
}

# --- Root check ---
check_root() {
  if [[ $EUID -ne 0 ]]; then
    err "This script must be run as administrator (sudo)."
    echo "Use: sudo bash $0 $*"
    exit 1
  fi
}

# --- Connectivity test ---
check_connectivity() {
  title "Checking connection to VSPC server"
  local url="https://${VSPC_GATEWAY}:${VSPC_PORT}/"
  if curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 10 -k "$url" 2>/dev/null | grep -qE '^[0-9]+'; then
    ok "Connection to VSPC (${VSPC_GATEWAY}): successful"
    return 0
  else
    err "Connection to VSPC (${VSPC_GATEWAY}): failed"
    echo "  → Check: firewall, Internet access, port ${VSPC_PORT} (HTTPS)."
    return 1
  fi
}

# Short output for GUI (one line)
check_connectivity_msg() {
  local url="https://${VSPC_GATEWAY}:${VSPC_PORT}/"
  if curl -sS -o /dev/null -w "%{http_code}" --connect-timeout 10 -k "$url" 2>/dev/null | grep -qE '^[0-9]+'; then
    echo "Connection to VSPC (${VSPC_GATEWAY}:${VSPC_PORT}): SUCCESS"
    return 0
  else
    echo "Connection to VSPC (${VSPC_GATEWAY}:${VSPC_PORT}): FAILED — Check firewall and Internet access (port ${VSPC_PORT})."
    return 1
  fi
}

# --- Create support bundle (collect logs + system info + archive) ---
collect_diagnostics() {
  mkdir -p "$SUPPORT_DIR"
  local log_list=""

  title "Collecting system information"
  uname -a > "$SUPPORT_DIR/uname.txt" 2>/dev/null || true
  cat /etc/os-release 2>/dev/null > "$SUPPORT_DIR/os-release.txt" || true
  veeamconsoleconfig -s > "$SUPPORT_DIR/veeamconsoleconfig-s.txt" 2>/dev/null || true

  title "Searching for Veeam logs"
  for dir in "${LOG_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      ok "Directory found: $dir"
      mkdir -p "$SUPPORT_DIR/logs$(echo "$dir" | tr '/' '_')"
      cp -r "$dir"/* "$SUPPORT_DIR/logs$(echo "$dir" | tr '/' '_')/" 2>/dev/null || true
      for f in "$dir"/*.log "$dir"/*.txt; do
        [[ -f "$f" ]] && log_list="$log_list $f"
      done
    else
      warn "Directory not found: $dir"
    fi
  done

  # Services
  title "Service status"
  (systemctl list-units --type=service --all 2>/dev/null | grep -i veeam) > "$SUPPORT_DIR/veeam-services.txt" 2>/dev/null || true
  (systemctl status veeam* 2>&1) >> "$SUPPORT_DIR/veeam-services.txt" || true

  # Last lines of found logs
  if [[ -n "$log_list" ]]; then
    echo "=== Last lines of logs ===" > "$SUPPORT_DIR/last-logs.txt"
    for f in $log_list; do
      [[ -f "$f" ]] && echo "--- $f ---" >> "$SUPPORT_DIR/last-logs.txt" && tail -100 "$f" >> "$SUPPORT_DIR/last-logs.txt" 2>/dev/null
    done
  fi

  # Create archive (support directory contents only)
  title "Creating archive for support"
  (cd "$SUPPORT_DIR" && tar czf "$SUPPORT_ARCHIVE_NAME" --exclude="*.tar.gz" . 2>/dev/null)
  local archive_path="$SUPPORT_DIR/$SUPPORT_ARCHIVE_NAME"
  if [[ -f "$archive_path" ]]; then
    ok "Archive created: $archive_path"
    echo ""
    echo -e "${BOLD}Send this file to your support:${NC}"
    echo "  $archive_path"
  else
    warn "Partial archive creation. Directory contents: $SUPPORT_DIR"
  fi
}

# --- Management / Backup Agent status (veeamconsoleconfig -s) ---
check_agent_status() {
  title "Agent status (veeamconsoleconfig -s)"
  if ! command -v veeamconsoleconfig &>/dev/null; then
    warn "veeamconsoleconfig not found (Management Agent may not be installed)."
    return 0
  fi
  local config_out
  config_out=$(veeamconsoleconfig -s 2>/dev/null) || true
  if [[ -n "$config_out" ]]; then
    echo "$config_out"
    if echo "$config_out" | grep -qi "Backup agent.*Not installed"; then
      echo ""
      warn "The Backup Agent is not yet installed."
      echo "  This is normal after a first Management Agent installation: Backup Agent"
      echo "  deployment by VSPC may take a few minutes."
      echo "  If after a few minutes the Backup Agent still does not appear, check"
      echo "  the logs, create a support bundle (menu option B), or contact support."
    fi
  else
    warn "Unable to retrieve status (veeamconsoleconfig -s)."
  fi
}

# --- Short status summary (2 agents + last backup) for menu ---
VEEAM_BACKUP_LOG_DIR="/var/log/veeam/Backup"

show_menu_status() {
  local config_out mgmt_status backup_status backup_job_status
  mgmt_status="KO"
  backup_status="KO"
  backup_job_status="N/A"

  if command -v veeamconsoleconfig &>/dev/null; then
    config_out=$(veeamconsoleconfig -s 2>/dev/null) || true
    if [[ -n "$config_out" ]]; then
      if echo "$config_out" | grep -qi "Management.*[Aa]gent.*[Nn]ot installed"; then
        mgmt_status="KO"
      elif echo "$config_out" | grep -qi "Management"; then
        mgmt_status="OK"
      fi
      if echo "$config_out" | grep -qi "Backup agent.*Not installed"; then
        backup_status="KO"
      elif echo "$config_out" | grep -qi "Backup agent"; then
        backup_status="OK"
      fi
    fi
  fi

  if [[ -d "$VEEAM_BACKUP_LOG_DIR" ]]; then
    local latest_job_log
    latest_job_log=$(find "$VEEAM_BACKUP_LOG_DIR" -type f -name 'Job.log' 2>/dev/null | while read -r f; do
      echo "$(stat -c '%Y %n' "$f" 2>/dev/null)"
    done | sort -rn | head -1 | cut -d' ' -f2-)
    if [[ -n "$latest_job_log" && -f "$latest_job_log" && -s "$latest_job_log" ]]; then
      if grep -qi "Job has failed" "$latest_job_log" 2>/dev/null; then
        backup_job_status="KO"
      else
        backup_job_status="OK"
      fi
    fi
  fi

  local s_mgmt s_backup s_job
  case "$mgmt_status" in
    OK) s_mgmt="${BG_GREEN}  OK  ${NC}" ;;
    KO) s_mgmt="${BG_RED}  KO  ${NC}" ;;
    *)  s_mgmt=" N/A " ;;
  esac
  case "$backup_status" in
    OK) s_backup="${BG_GREEN}  OK  ${NC}" ;;
    KO) s_backup="${BG_RED}  KO  ${NC}" ;;
    *)  s_backup=" N/A " ;;
  esac
  case "$backup_job_status" in
    OK) s_job="${BG_GREEN}  OK  ${NC}" ;;
    KO) s_job="${BG_RED}  KO  ${NC}" ;;
    *)  s_job=" N/A " ;;
  esac

  echo "  ┌──────────────────────────────────────────────────────────────────────────┐"
  echo -e "     Management Agent: $s_mgmt   Backup Agent: $s_backup   Last backup: $s_job"
  echo "  └──────────────────────────────────────────────────────────────────────────┘"
  echo ""
}

# --- Conditional message for Agent status screen (between status and auto-refresh prompt) ---
print_agent_status_message() {
  local config_out="$1"
  [[ -z "$config_out" ]] && return 0
  if echo "$config_out" | grep -qi "disconnected"; then
    echo -e "${YELLOW}Your management agent can't reach our Veeam infrastructure, you may look at your network configuration (firewall, port used).${NC}"
  elif echo "$config_out" | tr '\n' ' ' | grep -qi "Backup.*not installed"; then
    echo -e "${YELLOW}Your management agent is connected to our Veeam infrastructure, your Backup Agent will be shortly deployed (however if this is not deployed 1 hour after the management agent connection, please look at the diagnostic menu).${NC}"
  elif echo "$config_out" | grep -qi "Backup agent" && ! echo "$config_out" | grep -qi "running"; then
    echo -e "${YELLOW}Your Backup Agent will be activated soon.${NC}"
  elif echo "$config_out" | grep -qi "Backup agent" && echo "$config_out" | grep -qi "running"; then
    echo -e "${GREEN}Your agents are running well.${NC}"
  fi
}

# --- Analyze agent.log for user messages (last 3000 lines) ---
AGENT_LOG="/var/log/veeamma/agent.log"
AGENT_LOG_LINES=3000
SYSTEM_REQUIREMENTS_URL="https://helpcenter.veeam.com/docs/agentforlinux/userguide/system_requirements.html?ver=13"
VEEAM_KB2260_URL="https://www.veeam.com/kb2260"

check_agent_log() {
  [[ ! -f "$AGENT_LOG" ]] && return 0
  title "Analyzing agent log (/var/log/veeamma/agent.log, last ${AGENT_LOG_LINES} lines)"
  local log_lines any_found=0 log_src
  log_src=$(mktemp)
  trap "rm -f '$log_src'" RETURN
  tail -n "${AGENT_LOG_LINES}" "$AGENT_LOG" > "$log_src" 2>/dev/null

  # All greps are case-insensitive (-i). Patterns are approximations; log lines shown before each help message.

  # OS not supported (case-insensitive)
  log_lines=$(grep -iE "Cannot deploy the backup agent|Guest OS.*not supported|remote machine is not supported" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Your OS is not compatible with Veeam Agent."
    echo "  You can find compatible OS information at this link:"
    echo "  $SYSTEM_REQUIREMENTS_URL"
    echo ""
    any_found=1
  fi

  # linux-headers (case-insensitive)
  log_lines=$(grep -iE "Unable to locate package linux-headers|Couldn't find any package.*linux-headers" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Your OS is missing important prerequisites for Veeam Agent to install."
    echo "  You can find prerequisite information at this link:"
    echo "  $SYSTEM_REQUIREMENTS_URL"
    echo ""
    any_found=1
  fi

  # EFI (case-insensitive)
  log_lines=$(grep -iE "Cannot find EFI boot manager entry|EFI System Partition GUID" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "You have an EFI partition configuration issue on your OS."
    echo "  The UUID must match between the log line about your EFI Boot"
    echo "  and the output of the command: efibootmgr"
    echo ""
    any_found=1
  fi

  # No space for snapshot / Retrieved less bytes (same message; case-insensitive)
  log_lines=$(grep -iE "No space for snapshot|Retrieved less bytes from the storage" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Your backup couldn't work because you don't have enough space to create the local snapshot that will be used to send the data. Please free space in your partition."
    echo ""
    any_found=1
  fi

  # Snapshot overflow (case-insensitive)
  log_lines=$(grep -i "Snapshot overflow" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "You need to increase your space allocated for the snapshot, follow this: 1. Edit /etc/veeam/veeam.ini 2. Double the portionSize."
    echo ""
    any_found=1
  fi

  # Authentication failed / Access Denied (case-insensitive)
  log_lines=$(grep -iE "Authentication failed|Access Denied|AccessDenied" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Please contact our support with this information."
    echo ""
    any_found=1
  fi

  # SSL / handshake (case-insensitive)
  log_lines=$(grep -iE "Failed to establish SSL|handshake failure|sslv3 alert" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Please look at your network settings if you are not blocking any needed ports or dns."
    echo ""
    any_found=1
  fi

  # Kernel module not found (case-insensitive)
  log_lines=$(grep -iE "kernel module not found|Veeam snapshot kernel module" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Please look at this KB from Veeam: $VEEAM_KB2260_URL"
    echo ""
    any_found=1
  fi

  # Invalid credentials AmazonS3 (case-insensitive)
  log_lines=$(grep -i "Invalid credentials for AmazonS3" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Even if the information about Amazon S3 can be misleading as we are not using Amazon S3 buckets, this is due to a time difference between your server and the gateway. Please make sure your server has the world time correctly setup (max 15 minutes of variation accepted)."
    echo ""
    any_found=1
  fi

  # RequestTimeTooSkewed (case-insensitive)
  log_lines=$(grep -i "RequestTimeTooSkewed" "$log_src" 2>/dev/null | head -5)
  if [[ -n "$log_lines" ]]; then
    echo ""
    echo "  Log:"
    echo "$log_lines" | sed 's/^/  | /'
    echo ""
    warn "Please make sure your server has the world time correctly setup (max 15 minutes of variation accepted)."
    echo ""
    any_found=1
  fi

  if [[ $any_found -eq 0 ]]; then
    ok "No known message detected in agent log."
  fi
}

# --- Diagnostic (connectivity + agent status + log analysis only, no bundle) ---
run_diagnostic() {
  check_root --diagnostic
  title "=== Veeam Agent Diagnostic ==="
  check_connectivity
  check_agent_status
  check_agent_log
  title "Diagnostic complete"
  return 0
}

# --- Create support bundle (archive to send to support) ---
run_support_bundle() {
  check_root --support-bundle
  SUPPORT_ARCHIVE_NAME="veeam-support-$(date +%Y%m%d-%H%M%S).tar.gz"
  title "=== Create support bundle ==="
  collect_diagnostics
  return 0
}

# --- Management Agent installation ---
run_install() {
  check_root "$@"
  local agent_url="${1:-}"
  local package_path=""

  # Check that no Management Agent is already installed
  if command -v veeamconsoleconfig &>/dev/null; then
    err "A Management Agent is already installed on this system."
    echo ""
    echo "  Current status (veeamconsoleconfig -s):"
    veeamconsoleconfig -s 2>/dev/null | sed 's/^/    /'
    echo ""
    echo "  To reinstall, uninstall the existing agent first."
    exit 1
  fi

  title "=== Backup Agent Installation ==="

  # Step 0: Connectivity test
  if ! check_connectivity; then
    warn "Installation may fail if the VSPC server is not reachable."
    read -p "Continue anyway? (y/N) " -r
    [[ ! $REPLY =~ ^[oOyY] ]] && exit 1
  fi

  # Step 1: Get package (URL or local path)
  title "Step 1/3 — Package download"
  echo "──────────────────────────────────────────────────────────────────────────"
  if [[ -n "$agent_url" ]]; then
    if [[ "$agent_url" =~ ^https?:// ]]; then
      package_path="/tmp/LinuxAgentPackages_$(date +%s).sh"
      info "Downloading from: $agent_url"
      if curl -sSL -o "$package_path" "$agent_url"; then
        ok "Download successful"
      else
        err "Download failed. Check the URL and your connection."
        exit 1
      fi
    else
      package_path="$agent_url"
      if [[ ! -f "$package_path" ]]; then
        err "File not found: $package_path"
        exit 1
      fi
      ok "Using local file: $package_path"
    fi
  else
    echo "Enter the path of the already downloaded file (e.g. /tmp/LinuxAgentPackages.*.sh)"
    echo "or a URL to download it (e.g. https://...)."
    read -p "Path or URL: " agent_url
    if [[ -z "$agent_url" ]]; then
      err "No file or URL provided."
      echo ""
      echo "From the VSPC portal, download the Management Agent package for Linux,"
      echo "then run this script again with the file path:"
      echo "  sudo bash $0 /path/to/LinuxAgentPackages.xxx.sh"
      exit 1
    fi
    if [[ "$agent_url" =~ ^https?:// ]]; then
      package_path="/tmp/LinuxAgentPackages_$(date +%s).sh"
      curl -sSL -o "$package_path" "$agent_url" || { err "Download failed."; exit 1; }
    else
      package_path="$agent_url"
      if [[ ! -f "$package_path" ]]; then
        err "File not found: $package_path"
        exit 1
      fi
      ok "File found: $package_path"
    fi
  fi

  chmod +x "$package_path"
  ok "Execute permission set (chmod +x)"

  # Step 2: Run installer (capture output for display on error)
  title "Step 2/3 — Management Agent Installation"
  echo "──────────────────────────────────────────────────────────────────────────"
  local install_log="/tmp/veeam-install-$$.log"
  if "$package_path" > "$install_log" 2>&1; then
    rm -f "$install_log"
    ok "Management Agent installation complete."
  else
    err "The installer returned an error."
    echo ""
    echo "Last 80 lines from the installer output:"
    echo "──────────────────────────────────────────────────────────────────────────"
    tail -80 "$install_log" 2>/dev/null | sed 's/^/  /'
    echo "──────────────────────────────────────────────────────────────────────────"
    rm -f "$install_log"
    echo ""
    echo "To create a support bundle and send to support, run:"
    echo "  sudo bash $0 --support-bundle"
    echo "  (or run 'sudo ovhbackupagent' and choose B — Create support bundle)"
    exit 1
  fi

  # Step 3: Next steps
  title "Step 3/3 — Next steps"
  echo "──────────────────────────────────────────────────────────────────────────"
  echo ""
  echo ""
  echo "If you have issues (agent not visible, Backup Agent not deployed, etc.),"
  echo "run the diagnostic (option D) or create a support bundle (option B) and contact OVHcloud support."
  sleep 4
}

# --- Force stop backup job (see https://helpcenter.veeam.com/docs/agentforlinux/userguide/backup_job_stop.html) ---
run_force_stop_menu() {
  echo ""
  title "Force stop backup job"
  if ! command -v veeamconfig &>/dev/null; then
    warn "veeamconfig not found (Backup Agent may not be installed)."
    read -p "Press Enter to return to menu..."
    return 0
  fi

  local list_out ids=() i sel session_id
  list_out=$(veeamconfig session list 2>&1) || true

  # Collect session IDs that are in Running state (parse list output or check each UUID with session info)
  while read -r uuid; do
    [[ -z "$uuid" ]] && continue
    if veeamconfig session info --id "$uuid" 2>/dev/null | grep -qi "State:.*Running"; then
      ids+=( "$uuid" )
    fi
  done < <(echo "$list_out" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | sort -u)

  # If no running sessions from list, try session list output lines containing "Running" and a UUID
  if [[ ${#ids[@]} -eq 0 ]] && [[ -n "$list_out" ]]; then
    while read -r line; do
      if echo "$line" | grep -qi "running"; then
        uuid=$(echo "$line" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
        [[ -n "$uuid" ]] && ids+=( "$uuid" )
      fi
    done <<< "$list_out"
  fi

  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "No session in progress."
  else
    echo "Running backup session(s):"
    printf "  %-3s %-18s %-42s %-10s %s\n" "#" "Job name" "ID" "State" "Started at"
    for i in "${!ids[@]}"; do
      local info job_name state start_time
      info=$(veeamconfig session info --id "${ids[i]}" 2>/dev/null) || true
      job_name=$(echo "$info" | sed -n 's/.*[Jj]ob name:[[:space:]]*//p' | head -1)
      [[ -z "$job_name" ]] && job_name="-"
      state=$(echo "$info" | sed -n 's/.*[Ss]tate:[[:space:]]*//p' | head -1)
      [[ -z "$state" ]] && state="Running"
      start_time=$(echo "$info" | sed -n 's/.*[Ss]tart time:[[:space:]]*//p' | head -1)
      if [[ -n "$start_time" ]]; then
        start_time=$(echo "$start_time" | sed 's/ UTC$//; s/:[0-9][0-9]$//')  # drop seconds and UTC
      else
        start_time="-"
      fi
      printf "  %-3s %-18s %-40s %-10s %s\n" "$((i + 1))" "$job_name" "{${ids[i]}}" "$state" "$start_time"
    done
    echo ""
    echo -e "${RED}Force stop a job may cause a corruption of the backup, please use it carefully.${NC}"
    echo ""
    read -p "Enter number to force stop (or Enter to skip): " sel
    if [[ -n "$sel" ]] && [[ "$sel" =~ ^[0-9]+$ ]] && [[ "$sel" -ge 1 ]] && [[ "$sel" -le ${#ids[@]} ]]; then
      session_id="${ids[sel - 1]}"
      echo ""
      if veeamconfig session stop --force --id "$session_id" 2>&1; then
        ok "Session $session_id has been stopped."
      else
        err "Failed to stop session $session_id."
      fi
    fi
  fi
  echo ""
  read -p "Press Enter to return to menu..."
}

# --- Text menu ---
run_gui() {
  check_root "[Interface]"
  local choice path readme_tmp diag_tmp

  # After --setup: open directly in Agent status (first run)
  if [[ "${1:-}" == "A" ]]; then
    shift 2>/dev/null || true
    local status_out config_out
    while true; do
      clear
      title "Agent status (veeamconsoleconfig -s)"
      if command -v veeamconsoleconfig &>/dev/null; then
        config_out=$(veeamconsoleconfig -s 2>&1) || true
        status_out="$config_out"
        if echo "$config_out" | grep -qi "Backup agent.*Not installed"; then
          status_out="$status_out"$'\n\n'"The Backup Agent is not yet installed. Wait a few minutes or check the logs."
        fi
      else
        config_out=""
        status_out="veeamconsoleconfig not found (Management Agent may not be installed)."
      fi
      echo "$status_out"
      echo ""
      print_agent_status_message "$config_out"
      echo ""
      if read -t 5 -p "Auto-refresh in 5s... Press Enter to return to menu. "; then break; fi
    done
  fi

  while true; do
    clear
    show_banner
    show_menu_status
    echo "  A  Agent status (veeamconsoleconfig -s)"
    echo "  V  Open Veeam interface (veeam command)"
    echo "  T  Test connection to VSPC"
    echo "  D  Run diagnostic (connection, agent status, log analysis)"
    echo "  B  Create support bundle (archive to send to support)"
    echo "  I  Install Management Agent (only if you want to reinstall it)"
    echo "  J  Job stuck? Get help with force stop tool"
    echo "  H  Help / README"
    echo "  Q  Quit"
    echo ""
    read -p "  Your choice (A/V/T/D/B/I/J/H/Q): " choice
    choice="${choice^^}"

    case "$choice" in
      I)
        echo ""
        read -p "Package file path or URL: " path
        if [[ -n "$path" ]]; then
          run_install "$path" || true
          echo ""
          read -p "Press Enter to return to menu..."
        else
          echo "No path or URL entered."
        fi
        ;;
      J)
        run_force_stop_menu
        ;;
      D)
        diag_tmp="/tmp/veeam-diag-$$.txt"
        run_diagnostic 2>&1 | tee "$diag_tmp"
        echo ""
        read -p "Press Enter to return to menu..."
        rm -f "$diag_tmp"
        ;;
      B)
        run_support_bundle || true
        echo ""
        read -p "Press Enter to return to menu..."
        ;;
      T)
        local msg
        msg=$(check_connectivity_msg 2>&1)
        echo ""; echo "$msg"; echo ""
        read -p "Press Enter to return to menu..."
        ;;
      A)
        local status_out config_out
        while true; do
          clear
          title "Agent status (veeamconsoleconfig -s)"
          if command -v veeamconsoleconfig &>/dev/null; then
            config_out=$(veeamconsoleconfig -s 2>&1) || true
            status_out="$config_out"
            if echo "$config_out" | grep -qi "Backup agent.*Not installed"; then
              status_out="$status_out"$'\n\n'"The Backup Agent is not yet installed. Wait a few minutes or check the logs."
            fi
          else
            config_out=""
            status_out="veeamconsoleconfig not found (Management Agent may not be installed)."
          fi
          echo "$status_out"
          echo ""
          print_agent_status_message "$config_out"
          echo ""
          if read -t 5 -p "Auto-refresh in 5s... Press Enter to return to menu. "; then break; fi
        done
        ;;
      V)
        if command -v veeam &>/dev/null; then
          clear
          exec veeam
        elif command -v veeamconfig &>/dev/null; then
          clear
          exec veeamconfig ui
        else
          warn "Command 'veeam' not found. The Backup Agent may not be installed yet."
          read -p "Press Enter to return to menu..."
        fi
        ;;
      H)
        if [[ -f "$README_PATH" ]]; then
          less "$README_PATH" 2>/dev/null || cat "$README_PATH"
        else
          readme_tmp="/tmp/veeam-readme-$$.txt"
          show_readme > "$readme_tmp"
          less "$readme_tmp" 2>/dev/null || cat "$readme_tmp"
          rm -f "$readme_tmp"
        fi
        read -p "Press Enter to return to menu..."
        ;;
      Q)
        clear
        echo "Goodbye."
        exit 0
        ;;
      *)
        echo "Choice not recognized."
        sleep 1
        ;;
    esac
  done
}

# --- Create README file on disk (for menu Help / README) ---
write_readme_file() {
  [[ $EUID -ne 0 ]] && return 0
  local dir
  dir="$(dirname "$README_PATH")"
  mkdir -p "$dir"
  show_readme > "$README_PATH" 2>/dev/null && ok "README written to $README_PATH" || true
}

# --- Install global ovhbackupagent command (and create README) ---
install_global_command() {
  if [[ $EUID -ne 0 ]]; then
    err "Installing the global command requires root privileges."
    echo "Run: sudo bash $0 --install-global"
    exit 1
  fi
  local script_path
  if [[ -f "$0" ]] && [[ "$(basename "$0")" != "bash" ]]; then
    script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    if [[ -z "$script_path" ]] || [[ ! -f "$script_path" ]]; then
      err "Unable to determine script path."
      exit 1
    fi
    if ! head -n 1 "$script_path" | grep -q '^#!'; then
      err "The script file does not look valid (missing shebang on line 1)."
      echo "  Do not run from 'curl | bash'. Save the script to a file, then run:"
      echo "  sudo bash /path/to/install-veeam-agent.sh --install-global"
      exit 1
    fi
    cp "$script_path" /usr/local/bin/ovhbackupagent
    chmod 755 /usr/local/bin/ovhbackupagent
    write_readme_file
    ok "Command installed: you can now run 'ovhbackupagent' from anywhere."
    echo "  (Make sure /usr/local/bin is in your PATH)"
  else
    err "The script must be run from a file (not via curl | bash)."
    echo "  Download the script, then: sudo bash install-veeam-agent.sh --install-global"
    exit 1
  fi
}

# --- Full setup: install Management Agent + ovhbackupagent command + README, then show menu ---
run_setup() {
  local mgmt_url="${1:-}"
  if [[ -z "$mgmt_url" ]]; then
    err "Management Agent URL or local path is required for --setup."
    echo "  Usage: sudo bash $0 --setup \"https://.../LinuxAgentPackages.xxx.sh\""
    echo "     or: sudo bash $0 --setup \"/path/to/LinuxAgentPackages.xxx.sh\""
    echo "  Or the one-liner from the UI (curl + --setup <URL>)."
    exit 1
  fi
  check_root --setup
  clear
  show_banner
  echo -e "  ${BOLD}Backup Agent Installation${NC}"
  echo ""
  echo "Dear customer,"
  echo ""
  echo "You are about to install your Backup Agent in your system. This script will do the whole configuration for you and then you will be able to use the command \"ovhbackupagent\" to interact with your product in your OS."
  echo ""
  echo "The script will now proceed with the installation..."
  echo "Please wait."
  echo ""
  sleep 10
  title "=== Full setup is about to launch: We will install Management Agent + Backup Agent + command 'ovhbackupagent' ==="
  run_install "$mgmt_url" || exit 1
  title "Installing global command 'ovhbackupagent' and README..."
  install_global_command
  echo "──────────────────────────────────────────────────────────────────────────"
  title "Setup complete. The connection is in progress, opening Agent Status menu..."
  echo "──────────────────────────────────────────────────────────────────────────"
  echo ""
  sleep 5
  run_gui "A"
}

# --- Entry point ---
case "${1:-}" in
  --diagnostic|-d) run_diagnostic ;;
  --support-bundle|-b) run_support_bundle ;;
  --test-connectivity|-t) check_connectivity_msg; exit $? ;;
  --setup) run_setup "${2:-}" ;;
  --install-global) install_global_command ;;
  --readme|--help|-h)
    if [[ "${1:-}" == "--readme" ]]; then
      show_readme
    else
      echo "Usage:"
      echo "  Client one-liner (from UI):"
      echo "  curl -sSL \"<SCRIPT_URL>\" -o /tmp/install-veeam-agent.sh && chmod +x /tmp/install-veeam-agent.sh && sudo bash /tmp/install-veeam-agent.sh --setup \"<MGMT_AGENT_URL>\""
      echo ""
      echo "  Menu             : sudo bash $0  (or: sudo ovhbackupagent)"
      echo "  Full setup       : sudo bash $0 --setup \"https://.../LinuxAgentPackages.xxx.sh\""
      echo "  Install only     : sudo bash $0 \"https://.../LinuxAgentPackages.xxx.sh\""
      echo "  Diagnostic       : sudo bash $0 --diagnostic"
      echo "  Support bundle   : sudo bash $0 --support-bundle"
      echo "  Install ovhbackupagent : sudo bash $0 --install-global"
      echo "  Help / README    : sudo bash $0 --readme"
    fi
    exit 0
    ;;
  "")
    if [[ -t 0 ]]; then
      run_gui
    else
      run_install "$@"
    fi
    ;;
  *) run_install "$@" ;;
esac
