#!/bin/bash

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

error() {
    echo ""
    echo -e "${RED}❌ ERROR: $1${NC}"
    echo "→ Problem: $2"
    echo "→ Fix: $3"
    echo ""
    exit 1
}

read -p "Enter project suffix: " PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
    error \
    "Missing project name" \
    "No project suffix was provided" \
    "Enter a valid suffix such as student1"
fi

BASE_DIR="attendance_tracker_${PROJECT_NAME}"

if [[ -d "$BASE_DIR" ]]; then
    error \
    "Project already exists" \
    "Directory '$BASE_DIR' already exists" \
    "Use a different suffix or remove the existing directory"
fi

cleanup() {
    echo ""
    echo "❌ Interrupt detected. Creating backup archive..."

    ARCHIVE_NAME="${BASE_DIR}_archive"

    if [[ -d "$BASE_DIR" ]]; then
        tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR"

        if [[ $? -eq 0 ]]; then
            rm -rf "$BASE_DIR"
            echo "✅ Backup created: ${ARCHIVE_NAME}.tar.gz"
            echo "❌ Incomplete project removed"
        else
            echo "❌ Failed to create backup archive"
        fi
    fi

    exit 1
}

trap cleanup SIGINT

echo ""
echo "================================================="
echo "1. ENVIRONMENT CHECK"
echo "================================================="

if ! python3 --version >/dev/null 2>&1; then
    error \
    "Python3 not found" \
    "python3 command is unavailable on this system" \
    "Install Python3 and run the script again"
fi

echo "✅ Python3 detected"

echo ""
echo "================================================="
echo "2. PROJECT STRUCTURE"
echo "================================================="

mkdir -p "$BASE_DIR/Helpers" "$BASE_DIR/reports" || \
error \
"Directory creation failed" \
"Unable to create required project folders" \
"Check permissions and available disk space"

echo "✅ Project structure created"

echo ""
echo "================================================="
echo "3. FILE GENERATION"
echo "================================================="

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

cat <<'PYTHON' > "$BASE_DIR/attendance_checker.py"
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

    with open('Helpers/assets.csv', 'r') as f, \
         open('reports/reports.log', 'w') as log:

        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(
            f"--- Attendance Report Run: {datetime.now()} ---\n"
        )

        for row in reader:

            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            attendance_pct = (
                attended / total_sessions
            ) * 100

            message = ""

            if attendance_pct < config['thresholds']['failure']:
                message = (
                    f"URGENT: {name}, your attendance is "
                    f"{attendance_pct:.1f}%. "
                    f"You will fail this class."
                )

            elif attendance_pct < config['thresholds']['warning']:
                message = (
                    f"WARNING: {name}, your attendance is "
                    f"{attendance_pct:.1f}%. "
                    f"Please be careful."
                )

            if message:

                if config['run_mode'] == "live":

                    log.write(
                        f"[{datetime.now()}] "
                        f"ALERT SENT TO {email}: "
                        f"{message}\n"
                    )

                    print(f"Logged alert for {name}")

                else:

                    print(
                        f"[DRY RUN] Email to "
                        f"{email}: {message}"
                    )

if __name__ == "__main__":
    run_attendance_check()
PYTHON

touch "$BASE_DIR/reports/reports.log" || \
error \
"Report file creation failed" \
"Unable to create reports.log" \
"Check permissions"

echo "✅ Files created successfully"

echo ""
echo "================================================="
echo "4. CONFIGURATION"
echo "================================================="

read -p "Warning threshold (default 75): " WARNING
read -p "Failure threshold (default 50): " FAILURE

WARNING=${WARNING:-75}
FAILURE=${FAILURE:-50}

if ! [[ "$WARNING" =~ ^[0-9]+$ ]]; then
    error \
    "Invalid warning threshold" \
    "Value '$WARNING' is not numeric" \
    "Enter a number between 0 and 100"
fi

if ! [[ "$FAILURE" =~ ^[0-9]+$ ]]; then
    error \
    "Invalid failure threshold" \
    "Value '$FAILURE' is not numeric" \
    "Enter a number between 0 and 100"
fi

if (( WARNING < 0 || WARNING > 100 )); then
    error \
    "Warning threshold out of range" \
    "Value must be between 0 and 100" \
    "Choose a valid percentage"
fi

if (( FAILURE < 0 || FAILURE > 100 )); then
    error \
    "Failure threshold out of range" \
    "Value must be between 0 and 100" \
    "Choose a valid percentage"
fi

if (( FAILURE >= WARNING )); then
    error \
    "Invalid threshold logic" \
    "Failure threshold must be lower than warning threshold" \
    "Example: Warning=75 and Failure=50"
fi

echo "✅ Configuration validated"

JSON_FILE="$BASE_DIR/Helpers/config.json"

sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE" || \
error \
"Configuration update failed" \
"Unable to update warning threshold" \
"Check config.json"

sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE" || \
error \
"Configuration update failed" \
"Unable to update failure threshold" \
"Check config.json"

echo "✅ Configuration updated"

echo ""
echo "================================================="
echo "5. STRUCTURE VALIDATION"
echo "================================================="

[[ -f "$BASE_DIR/attendance_checker.py" ]] || \
error "Validation failed" "attendance_checker.py is missing" "Check file generation"

[[ -f "$BASE_DIR/Helpers/assets.csv" ]] || \
error "Validation failed" "assets.csv is missing" "Check file generation"

[[ -f "$BASE_DIR/Helpers/config.json" ]] || \
error "Validation failed" "config.json is missing" "Check file generation"

[[ -f "$BASE_DIR/reports/reports.log" ]] || \
error "Validation failed" "reports.log is missing" "Check file generation"

echo "✅ Structure validation passed"

echo ""
echo "================================================="
echo "6. SUCCESS"
echo "================================================="

echo "✅ Project created successfully"
echo ""
echo "Project location:"
echo "$BASE_DIR"
echo ""
echo "Run the application with:"
echo "cd $BASE_DIR"
echo "python3 attendance_checker.py"
echo ""
echo "✅ System ready"
