# App Update System - Setup Guide

## Overview
The GASMAN app now includes an automatic update checker that allows users to download and install new versions directly from within the app.

## How It Works

1. **Check for Updates**: Users tap "Check for Updates" button in the drawer
2. **Version Comparison**: App fetches version info from the backend API
3. **Download**: If update available, user can download the APK
4. **Install**: After download, system prompts user to install the APK

## Backend API Setup

### Endpoint
```
GET https://gasman.poscloud.co.zw/api/pos/app-version
```

### Response Format
```json
{
  "version": "1.0.1",
  "build_number": "2",
  "download_url": "https://drive.google.com/uc?export=download&id=YOUR_FILE_ID",
  "release_notes": "- Fixed camera permission issues on Android 10+\n- Improved transaction processing screen\n- Bug fixes and performance improvements"
}
```

### Response Fields
- `version` (string): Version number in format "X.Y.Z"
- `build_number` (string): Build number (integer as string)
- `download_url` (string): Direct download link to the APK file
- `release_notes` (string): What's new in this version

## Google Drive Setup

### Step 1: Upload APK to Google Drive
1. Build release APK: `flutter build apk --release`
2. Upload `app-release.apk` to Google Drive
3. Right-click the file → Share → Get link
4. Set sharing to "Anyone with the link can view"

### Step 2: Get Direct Download Link
From the share link:
```
https://drive.google.com/file/d/1a2b3c4d5e6f7g8h9i/view?usp=sharing
```

Extract the FILE_ID (`1a2b3c4d5e6f7g8h9i`) and create direct download URL:
```
https://drive.google.com/uc?export=download&id=1a2b3c4d5e6f7g8h9i
```

### Step 3: Update Backend Response
Use the direct download URL in the `download_url` field.

## Version Management

### Current Version
The app reads its current version from `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- `1.0.0` = version number
- `1` = build number

### Incrementing Version
When releasing a new version:

1. **Update `pubspec.yaml`**:
   ```yaml
   version: 1.0.1+2  # Increment both version and build number
   ```

2. **Build new APK**:
   ```bash
   flutter build apk --release
   ```

3. **Upload to Google Drive**

4. **Update backend API** to return new version info

## Update Comparison Logic

The app compares **build numbers** (not version strings) to determine if an update is available:

```
if (latest_build_number > current_build_number) {
    // Update available
}
```

This ensures reliable version comparison regardless of version number format.

## Permissions Required

The app requests these permissions for update functionality:
- `INTERNET` - To check for updates and download APK
- `WRITE_EXTERNAL_STORAGE` - To save downloaded APK
- `MANAGE_EXTERNAL_STORAGE` - For Android 11+ compatibility
- `REQUEST_INSTALL_PACKAGES` - To install the downloaded APK

All permissions are already configured in `AndroidManifest.xml`.

## Testing the Update System

### Test Scenario 1: No Update Available
1. Backend returns same build number as current
2. App shows: "You are already on the latest version"

### Test Scenario 2: Update Available
1. Backend returns higher build number
2. App shows update dialog with release notes
3. User can download and install

### Test Scenario 3: Download Failed
1. Invalid download URL or network error
2. App shows error message
3. User can retry

## Example Backend Implementation (Node.js/Express)

```javascript
app.get('/api/pos/app-version', (req, res) => {
  res.json({
    version: "1.0.1",
    build_number: "2",
    download_url: "https://drive.google.com/uc?export=download&id=YOUR_FILE_ID",
    release_notes: `
- Fixed camera permission issues on Android 10+
- Improved transaction processing screen
- Updated manual code entry screens
- Bug fixes and performance improvements
    `.trim()
  });
});
```

## Troubleshooting

### Issue: Download fails
- **Solution**: Verify Google Drive link is set to "Anyone with link can view"
- Check that download_url uses the correct format with FILE_ID

### Issue: APK won't install
- **Solution**: Ensure device allows "Install from Unknown Sources"
- Settings → Security → Unknown Sources (Android 7)
- Settings → Apps → Special Access → Install Unknown Apps (Android 8+)

### Issue: "Unable to check for updates"
- **Solution**:
  - Check internet connection
  - Verify backend API endpoint is accessible
  - Check API response format matches expected structure

## Security Notes

- APK downloads are over HTTPS
- Users must manually approve installation
- App signature verification happens at install time
- Consider code signing certificates for production

## Future Enhancements

Potential improvements:
- [ ] Auto-check for updates on app launch
- [ ] Delta updates (download only changed files)
- [ ] In-app update library (Google Play alternative)
- [ ] Update notifications
- [ ] Mandatory vs optional updates
- [ ] Update changelog history

---

**Last Updated**: 2026-01-06
**Implemented By**: Poscloud Private Ltd
