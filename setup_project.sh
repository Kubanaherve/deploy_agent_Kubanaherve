#!/bin/bash

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"


error() {
    echo ""
    echo -e "${RED}❌ ERROR: $1${NC}"
    echo -e "→ Problem: $2"
    echo -e "→ Fix: $3"
    echo ""
    exit 1
}


read -p "Enter project suffix: " PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
    error "Missing project name" "No input provided" "Enter a valid suffix like student1"
fi

BASE_DIR="attendance_tracker_${PROJECT_NAME}"


cleanup() {
    echo ""
    echo "❌ Interrupt detected. Creating backup..."

    ARCHIVE_NAME="${BASE_DIR}_archive"

    tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR" 2>/dev/null
    rm -rf "$BASE_DIR"

    echo "✅ Backup created: ${ARCHIVE_NAME}.tar.gz"
    echo "❌ Incomplete project removed"

    exit 1
}

trap cleanup SIGINT


echo ""
echo "================================================="
echo "1. ENVIRONMENT CHECK"
echo "================================================="

if ! python3 --version >/dev/null 2>&1; then
    error "Python3 not found" "python3 command missing" "Install Python3 first"
else
    echo "✅ Python3 detected"
fi


echo ""
echo "================================================="
echo "2. PROJECT STRUCTURE"
echo "================================================="

mkdir -p "$BASE_DIR/Helpers" "$BASE_DIR/reports" || \
error "Directory creation failed" "Permission or path issue" "Try another project name"

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


touch "$BASE_DIR/reports/reports.log"

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
    error "Invalid warning threshold" "Not numeric: $WARNING" "Use a number 0-100"
fi

if ! [[ "$FAILURE" =~ ^[0-9]+$ ]]; then
    error "Invalid failure threshold" "Not numeric: $FAILURE" "Use a number 0-100"
fi


if (( WARNING < 0 || WARNING > 100 )); then
    error "Warning out of range" "Must be 0–100" "Fix input value"
fi

if (( FAILURE < 0 || FAILURE > 100 )); then
    error "Failure out of range" "Must be 0–100" "Fix input value"
fi

if (( FAILURE >= WARNING )); then
    error "Logic error" "Failure must be lower than Warning" "Example: 50 < 75"
fi


echo "✅ Configuration validated"


JSON_FILE="$BASE_DIR/Helpers/config.json"


sed -i "s/\"warning\": [0-9]\+/\"warning\": $WARNING/" "$JSON_FILE"
sed -i "s/\"failure\": [0-9]\+/\"failure\": $FAILURE/" "$JSON_FILE"

echo "✅ Configuration updated"


echo ""
echo "================================================="
echo "5. SUCCESS"
echo "================================================="

echo "Project created at: $BASE_DIR"
echo ""
echo "To run:"
echo "cd $BASE_DIR"
echo "python3 attendance_checker.py"
echo ""
echo "✅ System ready"
