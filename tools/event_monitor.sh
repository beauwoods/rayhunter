#!/bin/sh

# Configuration
QMDL_DIR="/data/rayhunter/qmdl"
EVENT_LOG="/data/rayhunter/events.log"
STATE_FILE="/data/rayhunter/monitor.state"

echo "Starting event monitor..."
echo "QMDL_DIR: $QMDL_DIR"
echo "EVENT_LOG: $EVENT_LOG"
echo "STATE_FILE: $STATE_FILE"

# Function to parse a single NDJSON file
parse_ndjson() {
    local file="$1"
    local last_position="${2:-0}"
    
    echo "Parsing file: $file from position: $last_position"
    echo "File contents:"
    cat "$file"
    echo "---"
    
    # Skip the first line (analyzer definitions)
    if [ "$last_position" -eq 0 ]; then
        last_position=1
        echo "Skipping analyzer definitions line"
    fi
    
    # Read new lines since last position
    echo "Reading from position $last_position:"
    tail -n +"$last_position" "$file" 2>/dev/null | while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        echo "Processing line: $line"
        
        # Parse the JSON line
        timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        echo "Found timestamp: $timestamp"
        
        analysis=$(echo "$line" | grep -o '"analysis":\[[^]]*\]' | cut -d'[' -f2 | cut -d']' -f1)
        echo "Found analysis: $analysis"
        
        # If we have analysis data, it's an event
        if [ -n "$analysis" ] && [ "$analysis" != "[]" ]; then
            echo "Event detected: $timestamp - $analysis"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Event detected in $file at $timestamp" >> "$EVENT_LOG" 2>/dev/null
            echo "$file:$timestamp:$analysis" >> "$EVENT_LOG" 2>/dev/null
        else
            echo "No event in this line (empty analysis array)"
            # Show any error messages
            error=$(echo "$line" | grep -o '"skipped_message_reasons":\[[^]]*\]' | cut -d'[' -f2 | cut -d']' -f1)
            if [ -n "$error" ]; then
                echo "Error found: $error"
            fi
        fi
        echo "---"
    done
}

# First check our test file
echo "Checking test file..."
test_file="$QMDL_DIR/test.ndjson"
if [ -f "$test_file" ]; then
    echo "Found test file: $test_file"
    echo "File size: $(wc -l < "$test_file" 2>/dev/null || echo "0") lines"
    
    # Get last position for this file
    last_pos=$(grep "^$test_file:" "$STATE_FILE" 2>/dev/null | cut -d':' -f2 || echo "0")
    echo "Last position: $last_pos"
    
    # Parse new content
    parse_ndjson "$test_file" "$last_pos"
    
    # Update state file with current file size
    current_size=$(wc -l < "$test_file" 2>/dev/null || echo "0")
    sed -i "/^$test_file:/d" "$STATE_FILE" 2>/dev/null
    echo "$test_file:$current_size" >> "$STATE_FILE" 2>/dev/null
    echo "Updated state file with new size: $current_size"
fi

# Main monitoring loop
while true; do
    echo "Checking for NDJSON files in $QMDL_DIR..."
    
    # Get list of NDJSON files
    for file in "$QMDL_DIR"/*.ndjson; do
        [ -f "$file" ] || continue
        [ "$file" = "$test_file" ] && continue  # Skip test file since we already processed it
        
        echo "Found file: $file"
        echo "File size: $(wc -l < "$file" 2>/dev/null || echo "0") lines"
        
        # Get last position for this file
        last_pos=$(grep "^$file:" "$STATE_FILE" 2>/dev/null | cut -d':' -f2 || echo "0")
        echo "Last position: $last_pos"
        
        # Parse new content
        parse_ndjson "$file" "$last_pos"
        
        # Update state file with current file size
        current_size=$(wc -l < "$file" 2>/dev/null || echo "0")
        sed -i "/^$file:/d" "$STATE_FILE" 2>/dev/null
        echo "$file:$current_size" >> "$STATE_FILE" 2>/dev/null
        echo "Updated state file with new size: $current_size"
    done
    
    echo "Waiting 5 seconds before next check..."
    sleep 5
done 