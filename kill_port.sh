#!/bin/bash

# Check if port number is provided
if [ -z "$1" ]; then
    echo "Please provide a port number"
    exit 1
fi

PORT=$1

# Find PIDs using the port
PIDs=$(lsof -ti :$PORT)

# Check if any processes were found
if [ -z "$PIDs" ]; then
    echo "No processes found using port $PORT"
    exit 0
fi

# Kill all processes using the port
for PID in $PIDs; do
    echo "Killing process $PID using port $PORT"
    kill -9 $PID 2>/dev/null
done

# Verify that the port is now free
sleep 1
if [ -z "$(lsof -ti :$PORT)" ]; then
    echo "Successfully killed all processes using port $PORT"
else
    echo "Failed to kill all processes using port $PORT"
    exit 1
fi
