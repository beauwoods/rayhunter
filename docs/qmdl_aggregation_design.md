# QMDL Aggregation Design

## 1. System Overview
```
QMDL Files --> Parser --> Event Detection --> Packet Extraction --> Aggregated Storage
     ^                         |                    |                     |
     |                        v                    v                     v
 Raw Data              Event Metadata        Context Buffer         Final Archive
```

## 2. Key Components

### A. QMDL Parser
- Input: Raw QMDL files
- Functionality:
  - Read QMDL file format
  - Extract packet data and timestamps
  - Map packets to events
- Output: Structured packet data with timestamps

### B. Context Buffer System
- Purpose: Maintain rolling buffer of packets around events
- Features:
  - Store 3-5 packets before event
  - Store 3-5 packets after event
  - Track packet timestamps
  - Handle packet boundaries

### C. Aggregation System
- Storage Structure:
  ```
  /data/rayhunter/
  ├── aggregated/
  │   ├── events/
  │   │   └── YYYYMMDD_HHMMSS_event_type.json
  │   └── packets/
  │       └── YYYYMMDD_HHMMSS_event_type.qmdl
  └── metadata/
      └── packet_event_map.json
  ```
- Metadata tracking:
  - Event ID
  - Source QMDL file
  - Timestamp ranges
  - Packet offsets

### D. Timestamp Management
- Handle:
  - Packet timestamps
  - Event timestamps
  - System timestamps
  - Timestamp mismatches
  - Time zone considerations

## 3. Implementation Phases

### Phase 1: Basic QMDL Processing
- Implement QMDL file reading
- Extract basic packet information
- Set up storage structure
- Basic timestamp handling

### Phase 2: Context Buffer
- Implement packet buffering
- Add before/after packet capture
- Handle buffer management
- Basic error handling

### Phase 3: Aggregation
- Implement file copying
- Add metadata tracking
- Create packet-event mapping
- Handle storage management

### Phase 4: Error Handling & Recovery
- Add timestamp mismatch handling
- Implement recovery mechanisms
- Add validation checks
- Improve error reporting

## 4. Error Handling Strategy
- Timestamp mismatches
- Corrupted QMDL files
- Missing packets
- Storage failures
- Resource constraints

## 5. Testing Strategy
- Unit tests for each component
- Integration tests for full flow
- Test with corrupted data
- Performance testing
- Resource usage monitoring 