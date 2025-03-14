# Tasks to do later

## Isolate and Backup Event Data
We need to find a way to extract just the relevant network traffic related to events of interest and move them to some other storage method, for use cases where the device might not be accessible through USB or inbound network requests, or in cases where the logs might be tampered with before we can access it. We can accomplish this either by modifying the existing code or by creating new code (which may borrow from the existing code).

Whenever an event is detected, the relevant network traffic will (as well as 3 before and after) should be preserved in an aggregated file to capture evidence for later analysis. Each subsequent event would then add data to this same file. In addition, we want to keep a record of which events were triggered in a separate file so we can know what we're looking for. Unlike the existing functionality, these files would be the same across reboots and any other time the core functionality is restarted.

Once these new, aggregated files have been updated, we will need to upload them to an online storage facility. For now, this should allow us to send to FTP, FTPS, and GitHub Gists. We should also update the files regularly, which can provide a signal that the core applications are running (or have failed, if the file is not updated in the time frame). This functionality should also account for possibilities that the network may be unavailable and attempt retries preiodically for both on-demand and regular backups.

In addition, we want a way to automate the process of setting up and installing the functionality on the device, which is connected over USB/adb.

## Implementation Plan

### Phase 1: Event Detection and Storage
1. Create event monitoring service
   - Watch NDJSON files for new events
   - Parse NDJSON format to identify event types
   - Track event timestamps and metadata
   - Implement basic file locking for thread safety

2. Implement event storage
   - Create persistent storage location
   - Store event metadata in NDJSON format
   - Implement file rotation for long-term storage
   - Add basic error handling and recovery

3. Add QMDL file aggregation
   - Parse single-session QMDL files to extract relevant traffic
   - Extract 3-5 packets before and after each event for safety buffer
   - Implement file copying and aggregation
   - Add metadata linking events to QMDL data
   - Test with existing event detection
   - Add error handling for timestamp mismatches

### Phase 2: Network Traffic Analysis
1. Implement traffic monitoring
   - Add continuous QMDL file monitoring
   - Create traffic classification system
   - Implement traffic pattern detection
   - Add basic traffic statistics

2. Add traffic storage
   - Create traffic log storage system
   - Implement traffic file rotation
   - Add traffic metadata tracking
   - Create traffic analysis reports

### Phase 3: Backup and Upload System
1. Implement file-based backup
   - Create backup directory structure
   - Implement backup file rotation
   - Add backup verification
   - Create backup status tracking

2. Add upload capabilities
   - Implement FTP upload using ftpd
   - Add HTTP upload using wget
   - Integrate GitHub Gist upload code
   - Add upload status tracking

3. Create retry mechanism
   - Implement exponential backoff
   - Add network status checking
   - Create retry queue system
   - Add retry status reporting

### Phase 4: System Integration
1. Create installation system
   - Build installation scripts
   - Add configuration management
   - Create service management
   - Add basic health checks

2. Implement monitoring
   - Add system status monitoring
   - Create health check system
   - Implement alert system
   - Add basic reporting

3. Add redundancy
   - Implement file system checks
   - Add backup verification
   - Create recovery procedures
   - Add system state persistence

### Technical Considerations
- Use BusyBox's built-in tools where possible (wget, ftpd, grep, etc.)
- Keep file operations simple and atomic
- Implement basic file locking to prevent corruption
- Use NDJSON format for maximum compatibility with existing code
- Consider implementing a simple state file to track upload status
- Add configuration options for upload frequency and retention
- Leverage existing GitHub Gist upload code for that functionality

### Next Steps
1. Create proof of concept for NDJSON file monitoring
2. Test resource usage on the device
3. Begin implementation of Phase 1
4. Regular testing and validation at each phase