#!/bin/bash
# Script to start both backend and frontend applications

# Define project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print directories for debugging
echo "Project directory: ${PROJECT_DIR}" | tee debug.log
echo "Flutter app directory: ${PROJECT_DIR}/flutter_app" | tee -a debug.log
echo "Flutter binary: ${PROJECT_DIR}/venv/flutter/bin/flutter" | tee -a debug.log

# Verify directories exist
if [ ! -d "${PROJECT_DIR}/flutter_app" ]; then
    echo "ERROR: Flutter app directory does not exist: ${PROJECT_DIR}/flutter_app" | tee -a debug.log
    exit 1
fi

if [ ! -f "${PROJECT_DIR}/venv/flutter/bin/flutter" ]; then
    echo "ERROR: Flutter binary does not exist: ${PROJECT_DIR}/venv/flutter/bin/flutter" | tee -a debug.log
    exit 1
fi

# Kill any processes on port 8001
if [ -f kill_port.sh ]; then
    chmod +x kill_port.sh
    ./kill_port.sh
else
    lsof -ti:8001 | xargs kill -9 2>/dev/null
fi

# Start the backend API server
echo "Starting backend API server..." | tee -a debug.log
export PYTHONPATH="${PROJECT_DIR}"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 &
BACKEND_PID=$!

# Wait for backend to start
echo "Waiting for backend to start..." | tee -a debug.log
sleep 5

# Start the Flutter app
echo "Starting Flutter app..." | tee -a debug.log
export PATH="$PATH:${PROJECT_DIR}/venv/flutter/bin" 
cd ${PROJECT_DIR}/flutter_app && flutter run -d chrome

# When Flutter app exits, kill the backend
kill -9 $BACKEND_PID
echo "Backend server stopped" | tee -a debug.log
