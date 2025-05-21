#!/bin/bash

# Define the source and target paths
SOURCE_SCRIPT="/Users/s.halapa/Development/scripts/development.sh"
TARGET_SCRIPT="/usr/local/bin/dev"

# Check if the source script exists
if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo "Error: $SOURCE_SCRIPT does not exist."
    exit 1
fi

# Copy the script to /usr/local/bin and rename it to 'dev'
echo "Installing the script..."
sudo cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"

# Make the script executable
echo "Making the script executable..."
sudo chmod +x "$TARGET_SCRIPT"

# Confirm installation
if [ -f "$TARGET_SCRIPT" ]; then
    echo "Installation complete. You can now run the script using 'dev start' or 'dev stop'."
else
    echo "Error: Installation failed."
    exit 1
fi