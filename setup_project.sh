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

run() {
    echo -e "${CYAN}⏳ $1...${NC}"
}

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
    read -p "Enter project suffix: " PROJECT_NAME
    run "Validating project name"

    if [[ -n "$PROJECT_NAME" ]]; then
        ok "Project name accepted"
        break
    else
        fail "Project name cannot be empty"
    fi
done

BASE_DIR="attendance_tracker_${PROJECT_NAME}"

run "Checking project collision"

if [[ -d "$BASE_DIR" ]]; then
    fail "Directory already exists"
    exit 1
else
    ok "No conflicts found"
fi

# =========================
# ENV CHECK
# =========================
step "ENVIRONMENT CHECK"

run "Checking Python3 installation"
if python3 --version >/dev/null 2>&1; then
    ok "Python3 detected"
else
    fail "Python3 missing"
    exit 1
fi

# =========================
# DIRECTORY CREATION
# =========================
step "PROJECT STRUCTURE CREATION"

run "Creating base directory"
mkdir -p "$BASE_DIR"
ok "Base directory created"

run "Creating Helpers folder"
mkdir -p "$BASE_DIR/Helpers"
ok "Helpers created"

run "Creating reports folder"
mkdir -p "$BASE_DIR/reports"
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

run "Writing Python engine"
cat <<'PY' > "$BASE_DIR/attendance_checker.py"
import csv, json, os
from datetime import datetime

def run():
    with open('Helpers/config.json') as f:
        config = json.load(f)

    print("Loading configuration...")

    if os.path.exists('reports/reports.log'):
        print("Archiving old logs...")
        os.rename('reports/reports.log',
                  f'reports/reports_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

    print("Processing attendance data...")

    with open('Helpers/assets.csv') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)

        for row in reader:
            pct = (int(row['Attendance Count']) / config['total_sessions']) * 100

            print(f"Checking {row['Names']} -> {pct:.1f}%")

            msg = ""
            if pct < config['thresholds']['failure']:
                msg = f"URGENT: {row['Names']}"
            elif pct < config['thresholds']['warning']:
                msg = f"WARNING: {row['Names']}"

            if msg:
                log.write(msg + "\n")

    print("Report generation complete")

if __name__ == "__main__":
    run()
PY

ok "attendance_checker.py created"
# =========================
# CTRL + C TRAP SYSTEM
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
        tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR" >/dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            ok "Backup successful: ${ARCHIVE_NAME}.tar.gz"
        else
            fail "Backup failed"
        fi

        run "Cleaning workspace"
        rm -rf "$BASE_DIR"
        ok "Temporary files removed"

    else
        warn "No project directory found"
    fi

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN} SAFE EXIT COMPLETED${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    exit 0
}

trap cleanup SIGINT
# =========================
# CONFIGURATION
# =========================
step "CONFIGURATION SETUP"

while true; do
    read -p "Warning threshold (0-100): " WARNING
    run "Validating warning threshold"

    if [[ "$WARNING" =~ ^[0-9]+$ ]] && (( WARNING >= 0 && WARNING <= 100 )); then
        ok "Warning accepted"
        break
    else
        fail "Invalid warning value"
    fi
done

while true; do
    read -p "Failure threshold (0-100): " FAILURE
    run "Validating failure threshold"

    if [[ "$FAILURE" =~ ^[0-9]+$ ]] && (( FAILURE >= 0 && FAILURE <= 100 )); then

        if (( FAILURE < WARNING )); then
            ok "Failure accepted"
            break
        else
            warn "Failure must be less than warning ($WARNING)"
        fi

    else
        fail "Invalid failure value"
    fi
done

run "Updating configuration file"

JSON_FILE="$BASE_DIR/Helpers/config.json"

if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
    sed -i '' "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
else
    sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
fi

ok "Configuration updated"

# =========================
# FINAL VALIDATION
# =========================
step "FINAL VALIDATION"

run "Checking file integrity"

for file in \
"$BASE_DIR/Helpers/assets.csv" \
"$BASE_DIR/Helpers/config.json" \
"$BASE_DIR/attendance_checker.py"
do
    if [[ -f "$file" ]]; then
        ok "Found $(basename $file)"
    else
        fail "Missing $(basename $file)"
    fi
done

# =========================
# SUCCESS
# =========================
step "COMPLETION"

ok "Project successfully generated"

echo ""
echo -e "${GREEN}SYSTEM READY 🚀${NC}"
echo ""
echo "Next steps: Please run the following lines;"
echo "cd $BASE_DIR"
echo "python3 attendance_checker.py"


echo ""
echo ""

echo "=============================================="
echo "Created & Designed by  Herve Friend KUBANA 🎊"
echo "---------------------------------------------"
