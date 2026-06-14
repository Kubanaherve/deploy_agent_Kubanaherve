#!/bin/bash

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"


error() {
    echo ""
    echo -e "${RED}✖ ERROR: $1${NC}"
    echo -e "${YELLOW}→ Problem: $2${NC}"
    echo -e "${YELLOW}→ Fix: $3${NC}"
    echo ""
    exit 1
}


read -p "Enter project suffix: " PROJECT_NAME

BASE_DIR="attendance_tracker_${PROJECT_NAME}"


cleanup() {
    echo ""
    echo -e "${YELLOW}Interrupt detected. Creating backup...${NC}"

    ARCHIVE_NAME="${BASE_DIR}_archive"

    tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR" 2>/dev/null
    rm -rf "$BASE_DIR"

    echo -e "${GREEN} ✅ Backup created: ${ARCHIVE_NAME}.tar.gz${NC}"
    echo -e "${YELLOW} ✅ Incomplete project removed${NC}"

    exit 1
}

trap cleanup SIGINT


echo ""
echo "======================================================="
echo "1. ENVIRONMENT CHECK"
echo "======================================================="


if ! python3 --version >/dev/null 2>&1; then
    error \
    "Python3 not found" \
    "System cannot locate python3" \
    "Install Python3 before running this script"
else
    echo -e "${GREEN}✅ Python3 detected${NC}"
fi


echo ""
echo "======================================================="
echo "2. PROJECT STRUCTURE"
echo "======================================================="


mkdir -p "$BASE_DIR/Helpers" "$BASE_DIR/reports"

if [[ $? -ne 0 ]]; then
    error \
    "Directory creation failed" \
    "Cannot create project folder: $BASE_DIR" \
    "Check permissions or try a different name"
fi

echo -e "${GREEN} ✅ Project structure created${NC}"


echo ""
echo "======================================================="
echo "3. FILE GENERATION"
echo "======================================================="


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

echo -e "${GREEN} ✅ Files created successfully${NC}"


echo ""
echo "======================================================="
echo "4. CONFIGURATION"
echo "======================================================="


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
    "Adjust input and rerun script"
fi


if (( FAILURE < 0 || FAILURE > 100 )); then
    error \
    "Failure threshold out of range" \
    "Value must be between 0 and 100" \
    "Adjust input and rerun script"
fi


if (( FAILURE >= WARNING )); then
    error \
    "Invalid threshold logic" \
    "Failure must be lower than Warning" \
    "Example: Failure=50, Warning=75"
fi


echo -e "${GREEN}✔ Configuration validated${NC}"


JSON_FILE="$BASE_DIR/Helpers/config.json"


sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"


echo -e "${GREEN} ✅  Configuration updated${NC}"


echo ""
echo "======================================================="
echo "5. FINAL OUTPUT"
echo "======================================================="


echo "Project created at: $BASE_DIR"
echo ""
echo "Run command:"
echo "cd $BASE_DIR && python3 attendance_checker.py"
echo ""
echo -e "${GREEN}✅System ready...${NC}"


trap cleanup SIGINT
