#!/bin/bash

# =========================
# COLORS (STRICT UI SYSTEM)
# =========================
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# =========================
# UI FUNCTIONS
# =========================
error() {
    echo ""
    echo -e "${RED}❌ ERROR: $1${NC}"
    echo -e "${RED}→ Problem: $2${NC}"
    echo -e "${RED}→ Fix: $3${NC}"
    echo ""
    exit 1
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# =========================
# HEADER
# =========================
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  ATTENDANCE TRACKER BOOTSTRAPPER    ${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# =========================
# INPUT
# =========================
read -p "Enter project suffix: " PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
    error "Missing project name" "No input provided" "Enter a valid suffix like student1"
fi

BASE_DIR="attendance_tracker_${PROJECT_NAME}"

if [[ -d "$BASE_DIR" ]]; then
    error "Project exists" "Directory already exists" "Delete it or choose another name"
fi

# =========================
# CLEANUP ON CTRL + C
# =========================
cleanup() {
    echo ""
    echo -e "${YELLOW}⚠ Interrupt detected... creating backup${NC}"

    ARCHIVE_NAME="${BASE_DIR}_archive"

    if [[ -d "$BASE_DIR" ]]; then
        tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR" >/dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            rm -rf "$BASE_DIR"
            success "Backup created: ${ARCHIVE_NAME}.tar.gz"
            success "Cleanup completed"
        else
            error "Backup failed" "tar error" "Check disk space"
        fi
    fi

    exit 1
}

trap cleanup SIGINT

# =========================
# ENVIRONMENT CHECK
# =========================
echo ""
echo -e "${BLUE}[1/5] ENVIRONMENT CHECK${NC}"

if ! python3 --version >/dev/null 2>&1; then
    error "Python3 missing" "python3 not installed" "Install Python3 first"
fi

success "Python3 detected"

# =========================
# STRUCTURE CREATION
# =========================
echo ""
echo -e "${BLUE}[2/5] CREATING STRUCTURE${NC}"

mkdir -p "$BASE_DIR/Helpers" "$BASE_DIR/reports"
if [[ $? -ne 0 ]]; then
    error "Folder creation failed" "Permission denied or invalid path" "Try different directory"
fi

success "Project structure created"

# =========================
# FILE GENERATION
# =========================
echo ""
echo -e "${BLUE}[3/5] GENERATING FILES${NC}"

cat <<CSV > "$BASE_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSV

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

cat <<'PY' > "$BASE_DIR/attendance_checker.py"
import csv
import json
import os
from datetime import datetime

def run_attendance_check():

    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename(
            'reports/reports.log',
            f'reports/reports_{timestamp}.log.archive'
        )

    with open('Helpers/assets.csv', 'r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total = config['total_sessions']

        log.write(f"--- Attendance Report {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            pct = (attended / total) * 100

            message = ""

            if pct < config['thresholds']['failure']:
                message = f"URGENT: {name} FAIL RISK ({pct:.1f}%)"
            elif pct < config['thresholds']['warning']:
                message = f"WARNING: {name} LOW ATTENDANCE ({pct:.1f}%)"

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] {email}: {message}\n")
                    print(f"Logged: {name}")
                else:
                    print(f"[DRY RUN] {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
PY

success "All project files created"

# =========================
# CONFIG UPDATE
# =========================
echo ""
echo -e "${BLUE}[4/5] CONFIGURATION${NC}"

read -p "Warning threshold (default 75): " WARNING
read -p "Failure threshold (default 50): " FAILURE

if [[ -z "$WARNING" ]]; then WARNING=75; fi
if [[ -z "$FAILURE" ]]; then FAILURE=50; fi

if ! [[ "$WARNING" =~ ^[0-9]+$ ]]; then
    error "Invalid warning" "Not numeric" "Enter 0-100"
fi

if ! [[ "$FAILURE" =~ ^[0-9]+$ ]]; then
    error "Invalid failure" "Not numeric" "Enter 0-100"
fi

if (( FAILURE >= WARNING )); then
    error "Logic error" "Failure must be less than warning" "Example: 50 < 75"
fi

JSON_FILE="$BASE_DIR/Helpers/config.json"

if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
    sed -i '' "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
else
    sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
fi

success "Configuration updated"

# =========================
# VALIDATION
# =========================
echo ""
echo -e "${BLUE}[5/5] VALIDATION${NC}"

if [[ ! -f "$BASE_DIR/attendance_checker.py" ]]; then
    error "Missing file" "attendance_checker.py not found" "Check generation step"
fi

if [[ ! -f "$BASE_DIR/Helpers/assets.csv" ]]; then
    error "Missing file" "assets.csv not found" "Check generation step"
fi

if [[ ! -f "$BASE_DIR/Helpers/config.json" ]]; then
    error "Missing file" "config.json not found" "Check generation step"
fi

if [[ ! -f "$BASE_DIR/reports/reports.log" ]]; then
    error "Missing file" "reports.log not found" "Check generation step"
fi

success "Structure validated"

# =========================
# FINAL OUTPUT
# =========================
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   PROJECT CREATED SUCCESSFULLY      ${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

success "Setup complete"
info "Location: $BASE_DIR"
info "Run commands:"
echo "cd $BASE_DIR"
echo "python3 attendance_checker.py"
echo ""

echo -e "${GREEN}SYSTEM READY 🚀${NC}"
