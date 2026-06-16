#!/bin/bash

# =========================
# COLORS
# =========================
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

step() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

ok() { echo -e "${GREEN}✔ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✖ $1${NC}"; }
run() { echo -e "${CYAN}⏳ $1...${NC}"; }

# =========================
# TRAP - SIGINT HANDLER
# =========================
cleanup() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠ INTERRUPT DETECTED (CTRL + C)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    run "Starting safe shutdown procedure"

    if [[ -d "$BASE_DIR" ]]; then
        ok "Project directory detected"
        ARCHIVE_NAME="${BASE_DIR}_archive"
        run "Creating backup archive"
        if tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR" >/dev/null 2>&1; then
            ok "Backup successful: ${ARCHIVE_NAME}.tar.gz"
        else
            fail "Backup failed"
        fi
        run "Cleaning workspace"
        rm -rf "$BASE_DIR"
        ok "Temporary files removed"
    else
        warn "No project directory found - nothing to archive"
    fi

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} SAFE EXIT COMPLETED${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
}

trap cleanup SIGINT

# =========================
# HEADER
# =========================
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  ATTENDANCE TRACKER BOOTSTRAPPER    ${NC}"
echo -e "${BLUE}======================================${NC}"

# =========================
# INPUT PHASE
# =========================
step "PROJECT INITIALIZATION"

while true; do
    read -p "Enter the school/institution name : " PROJECT_NAME
    run "Validating school name"
    if [[ -n "$PROJECT_NAME" ]]; then
        ok "School name accepted"
        break
    else
        fail "School name cannot be empty"
    fi
done

BASE_DIR="attendance_tracker_${PROJECT_NAME}"

run "Checking project collision"
if [[ -d "$BASE_DIR" ]]; then
    fail "Directory '$BASE_DIR' already exists"
    exit 1
fi
ok "No conflicts found"

# =========================
# ENV CHECK
# =========================
step "ENVIRONMENT CHECK"
run "Checking Python3 installation"
if python3 --version >/dev/null 2>&1; then
    PY_VER=$(python3 --version 2>&1)
    ok "Python3 detected: ${PY_VER}"
else
    warn "Python3 is not installed - the application requires Python 3"
fi

# =========================
# DIRECTORY CREATION
# =========================
step "PROJECT STRUCTURE CREATION"

run "Creating base directory"
if ! mkdir -p "$BASE_DIR" 2>/dev/null; then
    fail "Permission denied: cannot create directory '$BASE_DIR'"
    exit 1
fi
ok "Base directory created"

run "Creating Helpers folder"
if ! mkdir -p "$BASE_DIR/Helpers" 2>/dev/null; then
    fail "Permission denied: cannot create Helpers directory"
    exit 1
fi
ok "Helpers created"

run "Creating reports folder"
if ! mkdir -p "$BASE_DIR/reports" 2>/dev/null; then
    fail "Permission denied: cannot create reports directory"
    exit 1
fi
ok "Reports created"

# =========================
# FILE GENERATION
# =========================
step "FILE GENERATION"

run "Writing assets.csv"
cat <<CSV > "$BASE_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSV
ok "assets.csv created"

run "Writing config.json"
cat <<JSON > "$BASE_DIR/Helpers/config.json"
{
  "thresholds": {
    "warning": 75,
    "failure": 50
  },
  "run_mode": "live",
  "total_sessions": 15
}
JSON
ok "config.json created"

run "Writing attendance_checker.py"
cat <<'PY' > "$BASE_DIR/attendance_checker.py"
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log',
                  f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
PY
ok "attendance_checker.py created"

run "Writing reports.log placeholder"
cat <<LOG > "$BASE_DIR/reports/reports.log"
--- Attendance Report Run: $(date) ---
LOG
ok "reports.log created"

# =========================
# CONFIGURATION - THRESHOLDS
# =========================
step "CONFIGURATION SETUP"

WARNING=75
FAILURE=50

echo -e "${YELLOW}Default thresholds: Warning = ${WARNING}% | Failure = ${FAILURE}%${NC}"
echo ""
while true; do
    read -p "Would you like to update the thresholds? (Y/n): " CHOICE
    CHOICE="${CHOICE:-Y}"
    if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
        ok "Proceeding with threshold configuration"

        while true; do
            read -p "Warning threshold (0-100, default ${WARNING}): " WARNING_INPUT
            WARNING_INPUT="${WARNING_INPUT:-$WARNING}"
            if [[ "$WARNING_INPUT" =~ ^[0-9]+$ ]] && (( WARNING_INPUT >= 0 && WARNING_INPUT <= 100 )); then
                WARNING=$WARNING_INPUT
                ok "Warning threshold set to ${WARNING}%"
                break
            else
                fail "Invalid: enter a whole number between 0 and 100"
            fi
        done

        while true; do
            read -p "Failure threshold (0-100, default ${FAILURE}): " FAILURE_INPUT
            FAILURE_INPUT="${FAILURE_INPUT:-$FAILURE}"
            if [[ "$FAILURE_INPUT" =~ ^[0-9]+$ ]] && (( FAILURE_INPUT >= 0 && FAILURE_INPUT <= 100 )); then
                if (( FAILURE_INPUT < WARNING )); then
                    FAILURE=$FAILURE_INPUT
                    ok "Failure threshold set to ${FAILURE}%"
                    break
                else
                    warn "Failure (${FAILURE_INPUT}) must be less than Warning (${WARNING})"
                fi
            else
                fail "Invalid: enter a whole number between 0 and 100"
            fi
        done

        break
    elif [[ "$CHOICE" =~ ^[Nn]$ ]]; then
        warn "Using default thresholds: Warning = ${WARNING}% | Failure = ${FAILURE}%"
        break
    else
        fail "Please enter Y or N"
    fi
done

run "Applying configuration to config.json"
JSON_FILE="$BASE_DIR/Helpers/config.json"
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
    sed -i '' "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
else
    sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
fi
ok "Configuration applied (warning=${WARNING}%, failure=${FAILURE}%)"

# =========================
# FINAL VALIDATION
# =========================
step "FINAL VALIDATION"
run "Checking file integrity"

MISSING=0
for file in \
    "$BASE_DIR/Helpers/assets.csv" \
    "$BASE_DIR/Helpers/config.json" \
    "$BASE_DIR/attendance_checker.py" \
    "$BASE_DIR/reports/reports.log"
do
    if [[ -f "$file" ]]; then
        ok "Found $(basename $file)"
    else
        fail "Missing $(basename $file)"
        MISSING=1
    fi
done

if [[ MISSING -eq 1 ]]; then
    fail "Some required files are missing - setup incomplete"
    exit 1
fi

# =========================
# SUCCESS
# =========================
step "COMPLETION"
ok "Project successfully generated"
echo ""
echo -e "${GREEN}  ATTENDANCE TRACKER is ready${NC}"
echo ""
echo "  Next steps:"
echo "  cd $BASE_DIR"
echo "  python3 attendance_checker.py"
echo ""
echo "=============================================="
echo "  Created by Herve Friend KUBANA"
echo "=============================================="
echo ""
