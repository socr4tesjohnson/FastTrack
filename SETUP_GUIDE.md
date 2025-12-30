# Garmin Watch App Development Setup Guide

## Installation Checklist

### Step 1: Install Java Development Kit (JDK)
**Status:** ⏳ Required

1. Download Microsoft Build of OpenJDK 17:
   - URL: https://learn.microsoft.com/en-us/java/openjdk/download
   - Choose: **Windows x64 MSI installer**

2. Run the installer and follow the prompts

3. Verify installation:
   ```bash
   java -version
   ```
   You should see output like: `openjdk version "17.x.x"`

---

### Step 2: Install Garmin Connect IQ SDK Manager
**Status:** ⏳ Required

1. Download SDK Manager:
   - URL: https://developer.garmin.com/connect-iq/sdk/
   - Select your OS: **Windows**

2. Run the SDK Manager installer

3. Launch SDK Manager and complete first-time setup:
   - Download the latest Connect IQ SDK (8.2.1)
   - Download device simulators for your target devices

4. Note the SDK installation path (you'll need this for VS Code)

---

### Step 3: Install VS Code Monkey C Extension
**Status:** ⏳ Required

1. Open Visual Studio Code

2. Go to Extensions (Ctrl + Shift + X)

3. Search for: **Monkey C**

4. Install the extension by **Garmin**

5. Restart VS Code

6. Verify installation:
   - Press `Ctrl + Shift + P`
   - Type: `Monkey C: Verify Installation`
   - Follow any prompts to configure SDK path

---

### Step 4: Optional - Install Python (Recommended)
**Status:** ⚪ Optional

Python can be useful for automation scripts and tooling.

1. Download Python 3.11+:
   - URL: https://www.python.org/downloads/

2. Run installer (check "Add Python to PATH")

3. Verify:
   ```bash
   python --version
   ```

---

## Current Environment Status

✅ **Node.js**: v22.20.0 (Installed)
✅ **Git**: 2.51.0 (Installed)
⏳ **Java JDK**: Not installed - **INSTALL THIS FIRST**
⏳ **Garmin SDK**: Not installed
⏳ **VS Code Monkey C**: Not installed

---

## Next Steps After Installation

1. Verify all tools are installed
2. Create your first Garmin Connect IQ project
3. Configure device simulator
4. Build and test your first watch app

---

## Useful Resources

- **Garmin Developer Portal**: https://developer.garmin.com/connect-iq/
- **Connect IQ Basics**: https://developer.garmin.com/connect-iq/connect-iq-basics/
- **API Documentation**: https://developer.garmin.com/connect-iq/api-docs/

---

## Support

If you encounter any issues during installation, check:
- Garmin Forums: https://forums.garmin.com/developer/connect-iq/
- SDK Documentation: https://developer.garmin.com/connect-iq/sdk/
