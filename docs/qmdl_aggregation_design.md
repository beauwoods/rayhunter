# QMDL Aggregation Design

## Overview
When security events are detected, we need to preserve both the event data and the relevant network traffic for later analysis. This design outlines a simple approach to aggregate this data into two files that persist across reboots.

## Storage
Two aggregated files will store all relevant data:
- `/data/rayhunter/aggregated_events.ndjson`: Contains all detected events
- `/data/rayhunter/aggregated_packets.qmdl`: Contains the QMDL data corresponding to those events

## Process Flow
1. Event Detection
   - Monitor NDJSON files for security events (already implemented)
   - When event detected, append to aggregated events file

2. QMDL Processing
   - Find corresponding QMDL file based on event timestamp
   - Extract relevant section from QMDL file
   - Append to aggregated packets file

## Implementation Plan

### Phase 1: Basic Implementation
1. Set up aggregated files
   - Create files if they don't exist
   - Implement append operations
   - Handle basic error cases (permissions, disk space)

2. QMDL Processing
   - Implement QMDL file reading
   - Extract relevant sections
   - Basic timestamp matching

### Testing
- Manual testing with existing QMDL files
- Verify correct sections are extracted
- Check file integrity after appending

## Error Cases to Handle
- QMDL file not found
- Permission issues
- Disk space issues
- Basic timestamp mismatches 