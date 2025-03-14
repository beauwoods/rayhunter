# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Event monitoring system that watches NDJSON files for security events
  - Monitors directory for new NDJSON files
  - Parses files for security-relevant events (IMSI requests, null cipher suggestions, etc.)
  - Maintains state between runs to avoid duplicate processing
  - Logs events with timestamps and details
  - Handles various error cases (decoding errors, malformed data)
  - Implements file locking for thread safety
    - Separate locks for event log and state file operations
    - Automatic lock cleanup on script exit
    - Signal handlers for graceful termination
- Test data and files for validating event monitoring functionality
- Installation script for the event monitor
- Basic daemon management script 