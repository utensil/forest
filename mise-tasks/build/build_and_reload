#!/bin/bash
# Orchestrate XML-to-HTML build and live reload trigger
# AGENT-NOTE: Ensures live reload is triggered only after HTML conversion is complete

set -e

# Step 1: Start XML-to-HTML build in background
mise run build:xml_to_html &
pid1=$!

# Step 2: (Optional) Start HTML-to-live-reload conversion if separate
# If you have a separate conversion step, start it here and capture its PID as pid2
# mise run html_to_live_reload &
# pid2=$!

# Step 3: Wait for both to finish
wait $pid1
# wait $pid2

# Step 4: Trigger live reload (write to trigger files)
mkdir -p build/live
# For now, always trigger reload for index.html (customize as needed)
echo "output/index.html" > build/live/updated_file.txt
touch build/live/trigger.txt

echo "✅ Build and reload orchestration complete."

# AGENT-NOTE: To customize which file triggers reload, update the echo line above.
# AGENT-NOTE: This script is called by mise-tasks/dev for dev workflow orchestration.
