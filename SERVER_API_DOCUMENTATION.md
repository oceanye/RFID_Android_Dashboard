# EPC-Assemble Link Server API Documentation

## Overview
This document describes the REST API endpoint for the EPC-Assemble linking feature.

## Server Configuration
- **Server**: 175.24.178.44
- **Port**: 8082 (using port 8082 to avoid conflict with existing port 8081)
- **Username**: root
- **Password**: Rootroot!
- **Database**: MySQL (existing table structure should not be modified)

## API Endpoint

### POST /api/epc-assemble-link

Creates a new link between an EPC ID and an Assemble ID.

#### Request Headers
```
Content-Type: application/json
Authorization: Basic <base64-encoded-credentials>
```

#### Request Body
```json
{
  "epcId": "string",           // The scanned EPC ID (hex string)
  "assembleId": "string",      // The assemble/component ID
  "createTime": "2023-08-12T10:30:00.000Z",  // ISO 8601 timestamp
  "rssi": "string",            // Signal strength (optional)
  "uploaded": true,            // Always true for uploaded records
  "notes": "string"            // Additional notes (optional)
}
```

#### Response

**Success (200 OK)**
```json
{
  "success": true,
  "id": 12345,
  "message": "EPC-Assemble link created successfully"
}
```

**Error (400 Bad Request)**
```json
{
  "success": false,
  "error": "Invalid request data",
  "message": "EPC ID is required"
}
```

**Error (401 Unauthorized)**
```json
{
  "success": false,
  "error": "Authentication failed",
  "message": "Invalid credentials"
}
```

**Error (500 Internal Server Error)**
```json
{
  "success": false,
  "error": "Database error",
  "message": "Failed to insert record"
}
```

## Database Schema Suggestion

If you need to create a new table for this feature, here's a suggested schema that won't conflict with existing tables:

```sql
CREATE TABLE epc_assemble_links (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    epc_id VARCHAR(255) NOT NULL,
    assemble_id VARCHAR(255) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rssi VARCHAR(50),
    uploaded BOOLEAN DEFAULT TRUE,
    notes TEXT,
    INDEX idx_epc_id (epc_id),
    INDEX idx_assemble_id (assemble_id),
    INDEX idx_create_time (create_time)
);
```

## Implementation Notes

1. The Android app will send HTTP POST requests to this endpoint
2. Use HTTP Basic Authentication with the provided credentials
3. Validate that both `epcId` and `assembleId` are provided and non-empty
4. Store the current timestamp if `createTime` is not provided
5. The endpoint should be idempotent - multiple requests with the same EPC-Assemble combination should not create duplicates
6. Consider adding rate limiting to prevent abuse

## Testing

You can test the endpoint using curl:

```bash
curl -X POST http://175.24.178.44:8082/api/epc-assemble-link \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n 'root:Rootroot!' | base64)" \
  -d '{
    "epcId": "E2801170200002AA57A555BB",
    "assembleId": "ASM-12345",
    "rssi": "-45"
  }'
```

## Android App Features Implemented

The Android application now includes:

1. **EPC Scanning**: Uses the existing UHF-G SDK to scan EPC tags
2. **Manual Input**: Text field for manually entering assemble IDs
3. **OCR Support**: Camera integration with Google ML Kit for automatic text recognition
4. **Confirmation**: Review screen before uploading
5. **Server Upload**: HTTP POST to the configured endpoint
6. **Local Storage**: Option to save locally if server is unavailable
7. **Navigation**: New menu item "EPC-Assemble Link" in the app navigation

The feature follows the exact procedure you requested:
1. Scan/read the EPC ID
2. Input the assemble ID (manual or OCR from photo)
3. Confirm and upload to server