#!/bin/sh

# Configuration
QMDL_DIR="/data/rayhunter/qmdl"
EVENT_LOG="/data/rayhunter/events.log"
STATE_FILE="/data/rayhunter/monitor.state"
LOCK_DIR="/data/rayhunter/locks"
EVENT_LOCK="$LOCK_DIR/events.lock"
STATE_LOCK="$LOCK_DIR/state.lock"

echo "Starting event monitor..."
echo "QMDL_DIR: $QMDL_DIR"
echo "EVENT_LOG: $EVENT_LOG"
echo "STATE_FILE: $STATE_FILE"

# Create lock directory if it doesn't exist
mkdir -p "$LOCK_DIR"

# Function to acquire a lock
acquire_lock() {
    local lock_file="$1"
    local max_attempts=30
    local attempt=1
    local wait_time=1

    while [ $attempt -le $max_attempts ]; do
        if mkdir "$lock_file" 2>/dev/null; then
            # Lock acquired
            return 0
        fi
        echo "Lock $lock_file is held, waiting... (attempt $attempt/$max_attempts)"
        sleep $wait_time
        attempt=$((attempt + 1))
    done

    echo "Failed to acquire lock $lock_file after $max_attempts attempts"
    return 1
}

# Function to release a lock
release_lock() {
    local lock_file="$1"
    rm -rf "$lock_file" 2>/dev/null
}

# Function to write to event log with locking
write_event_log() {
    local message="$1"
    if acquire_lock "$EVENT_LOCK"; then
        echo "$message" >> "$EVENT_LOG" 2>/dev/null
        release_lock "$EVENT_LOCK"
    else
        echo "WARNING: Could not write to event log: $message"
    fi
}

# Function to update state file with locking
update_state() {
    local file="$1"
    local size="$2"
    if acquire_lock "$STATE_LOCK"; then
        sed -i "/^$file:/d" "$STATE_FILE" 2>/dev/null
        echo "$file:$size" >> "$STATE_FILE" 2>/dev/null
        release_lock "$STATE_LOCK"
        echo "Updated state file with new size: $size"
    else
        echo "WARNING: Could not update state for $file"
    fi
}

# Function to read state with locking
read_state() {
    local file="$1"
    local position="0"
    if acquire_lock "$STATE_LOCK"; then
        position=$(grep "^$file:" "$STATE_FILE" 2>/dev/null | cut -d':' -f2 || echo "0")
        release_lock "$STATE_LOCK"
    else
        echo "WARNING: Could not read state for $file"
    fi
    echo "$position"
}

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
            write_event_log "$(date '+%Y-%m-%d %H:%M:%S') - Event detected in $file at $timestamp"
            write_event_log "$file:$timestamp:$analysis"
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

# Function to process a single file
process_file() {
    local file="$1"
    echo "Processing file: $file"
    echo "File size: $(wc -l < "$file" 2>/dev/null || echo "0") lines"
    
    # Get last position for this file
    local last_pos=$(read_state "$file")
    echo "Last position: $last_pos"
    
    # Parse new content
    parse_ndjson "$file" "$last_pos"
    
    # Update state file with current file size
    local current_size=$(wc -l < "$file" 2>/dev/null || echo "0")
    update_state "$file" "$current_size"
}

# First check our test file
echo "Checking test file..."
test_file="$QMDL_DIR/test.ndjson"
if [ -f "$test_file" ]; then
    process_file "$test_file"
fi

# Cleanup function for proper lock removal
cleanup() {
    echo "Cleaning up locks..."
    release_lock "$EVENT_LOCK"
    release_lock "$STATE_LOCK"
    exit 0
}

# Set up signal handlers
trap cleanup INT TERM

# Main monitoring loop
while true; do
    echo "Checking for NDJSON files in $QMDL_DIR..."
    
    # Get list of NDJSON files
    for file in "$QMDL_DIR"/*.ndjson; do
        [ -f "$file" ] || continue
        [ "$file" = "$test_file" ] && continue  # Skip test file since we already processed it
        
        process_file "$file"
    done
    
    echo "Waiting 5 seconds before next check..."
    sleep 5
done 