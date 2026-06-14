#!/bin/bash

echo "Welcome! Initializing Attendance Tracker Project Factory"

PROJECT_NAME=""
read -p "Enter project suffix (like ex: student1): " PROJECT_NAME

BASE_DIR="attendance_tracker_${PROJECT_NAME}"

echo "Currently checking Python3 installation ..."

if python3 --version >/dev/null 2>&1; then
  echo "✅ Python3 is available !"
else
  echo "⚠ ️ Warning: Python3 is not installe. Please run " pip install python3 " "
fi


echo "📁 Creating project structure..."

mkdir -p "$BASE_DIR/Helpers"
mkdir -p "$BASE_DIR/reports"

echo "✅ Project directories created at $BASE_DIR ..."
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "🧾 Generating application files..."

# Create assets.csv
cat <<CSV > "$BASE_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSV

# Create config.json
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

# Create reports log file
touch "$BASE_DIR/reports/reports.log"

echo "✅  Core files created successfully ..."

echo "⚙️  Configuring attendance thresholds..."

read -p "Enter warning threshold (Note that default is 75): " WARNING
read -p "Enter failure threshold (Note that default is 50): " FAILURE

WARNING=${WARNING:-75}
FAILURE=${FAILURE:-50}

echo " ✅ Using thresholds -> Warning: $WARNING | Failure: $FAILURE"


validate_number() {

  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: threshold must be a numeric value"
    exit 1
  fi
}


validate_range() {
  local name=$1
  local value=$2
  if (( value < 0 || value > 100 )); then
    echo "❌ Error: $name must be between 0 and 100"
    exit 1
  fi
}


echo " 🔄 Validating inputs wait a second..."

validate_number "$WARNING"
validate_number "$FAILURE"

validate_range "Warning threshold" "$WARNING"
validate_range "Failure threshold" "$FAILURE"

if (( FAILURE >= WARNING )); then
  echo "❌ Error: Failure threshold must be lower than Warning threshold"
  exit 1
fi

echo "✅ Inputs validated successfully"

echo " ✅ Updating configuration file with new thresholds..."

JSON_FILE="$BASE_DIR/Helpers/config.json"

sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"

echo "✔ Configuration updated successfully"


echo "🛡️ Setting up interrupt handler (Ctrl + C)..."

cleanup() {
  echo ""
  echo "⚠️ Interrupt detected. Creating backup archive..."

  ARCHIVE_NAME="${BASE_DIR}_archive"

  tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR"

  rm -rf "$BASE_DIR"

  echo "✅ Backup created: ${ARCHIVE_NAME}.tar.gz"
  echo "⚠️  Incomplete directory removed"
  exit 1
}

trap cleanup SIGINT


echo ""
echo "✅ Setup completed successfully."


echo "📁 Project created at: $BASE_DIR"
echo "👉 You can now navigate into the project directory."


echo "🚀 To run the application:"
echo "cd $BASE_DIR && python3 attendance_checker.py"
echo ""
echo "⚡ System ready."

