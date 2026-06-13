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

echo "✔ Project directories created at $BASE_DIR"
