# Backend Port Changed to 6000 ✅

## Changes Made

Changed the backend server port from 3000 to 6000 to avoid conflict with Kowa High School application.

### Files Modified

1. **simple_server.rb** (2 changes)
   - Line 18: `def initialize(port = 6000)` (default port)
   - Line 571: `server = LegaStreamServer.new(6000)` (explicit port)

2. **frontend/vite.config.js**
   - Line 12: Proxy target changed to `http://localhost:6000`
   - Line 35: Health check proxy changed to `http://localhost:6000`

3. **start-native.ps1**
   - Updated display messages to show port 6000

4. **check_servers.ps1**
   - Updated to check port 6000 instead of 3000

5. **restart_backend_only.ps1**
   - Updated to check port 6000

6. **SERVER_STATUS.md**
   - Updated documentation

## Current Status

- ✅ **Backend**: Running on http://localhost:6000
- ✅ **Frontend**: Running on http://localhost:5173 (proxies to backend on 6000)

## Access Your Application

Open your browser and go to: **http://localhost:5173**

The frontend will automatically proxy all API calls to the backend on port 6000.

## Restart Instructions

### Full Restart
```powershell
# Stop all servers (close PowerShell windows)
# Then start again
./start-native.ps1
```

### Backend Only
```powershell
./restart_backend_only.ps1
```

### Check Status
```powershell
./check_servers.ps1
```

## Testing

1. Go to http://localhost:5173
2. Upload a document
3. Verify the analysis works correctly
4. Check that entities are displayed inline

## Notes

- Port 3000 is now free for Kowa High School application
- All API calls from frontend are proxied through Vite to port 6000
- No changes needed in frontend code (uses relative URLs like `/api/v1/documents`)
- Backend logs will show requests coming from the Vite proxy

---

**Status**: Port change complete, servers running
**Date**: February 25, 2026, 3:35 PM
