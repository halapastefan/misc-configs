#!/bin/bash

# Define an array of applications
applications=("Microsoft Outlook" "Visual Studio Code" "Microsoft Teams" "Slack" "MongoDB Compass" "DBeaver")

# Function to start applications
start_apps() {
    for app in "${applications[@]}"; do
        echo "Starting $app..."
        open -a "$app"
    done
}

# Function to stop applications
stop_apps() {
    for app in "${applications[@]}"; do
        echo "Stopping $app..."
        osascript -e "quit app \"$app\""
    done
}

# Main script logic
if [ "$1" == "start" ]; then
    echo "Starting work applications..."
    start_apps
    echo "Applications started."
elif [ "$1" == "stop" ]; then
    echo "Stopping work applications..."
    stop_apps
    echo "Applications stopped."
else
    echo "Usage: $0 {start|stop}"
    exit 1
fi