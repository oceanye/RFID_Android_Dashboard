# Android Studio Build Troubleshooting Guide

## 🔧 Quick Fixes for Common Errors:

### 1. **Gradle Sync Failed**
```
File → Invalidate Caches and Restart
Tools → SDK Manager → Install Android SDK 34
File → Sync Project with Gradle Files
```

### 2. **"SDK location not found"**
- Check: File → Project Structure → SDK Location
- Should be: `C:\Users\bimpub5\AppData\Local\Android\Sdk`
- If missing: Tools → SDK Manager → Install

### 3. **"Unsupported Java version"**
- File → Settings → Build → Gradle → Gradle JDK
- Select: "Use Project JDK" or Java 8/11

### 4. **Dependency Resolution Failed**
```
Build → Clean Project
Build → Rebuild Project
```

### 5. **"Failed to resolve dependencies"**
- Check internet connection
- File → Settings → HTTP Proxy → Check proxy settings
- Try: Build → Refresh Gradle Dependencies

## 🚨 Common Error Messages & Solutions:

### Error: "Could not resolve all dependencies"
**Solution:**
1. Open `build.gradle` (Module: app)
2. Add at top of dependencies block:
```gradle
configurations.all {
    resolutionStrategy.force 'androidx.core:core:1.6.0'
}
```

### Error: "Duplicate class found"
**Solution:**
1. In `app/build.gradle`, add:
```gradle
android {
    packagingOptions {
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/LICENSE.txt'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/NOTICE.txt'
    }
}
```

### Error: "AAPT2 error"
**Solution:**
```gradle
android {
    aaptOptions {
        noCompress "tflite"
        noCompress "lite"
    }
}
```

## 📋 Step-by-Step Build Process:

1. **Open Project:**
   - File → Open
   - Select: `C:\Users\bimpub5\AndroidStudioProjects\UHFG_SDK_V3.6\demo\UHF-G_V3.6_20230821`

2. **Wait for Initial Sync:**
   - Let Android Studio download dependencies
   - Check bottom status bar for progress

3. **If Sync Fails:**
   - File → Invalidate Caches and Restart
   - Tools → SDK Manager → Install missing SDKs

4. **Build:**
   - Build → Clean Project
   - Build → Rebuild Project
   - Build → Build Bundle(s)/APK(s) → Build APK(s)

## 🔍 Check These Settings:

### File → Project Structure:
- **Project SDK:** Android API 34
- **Project Language Level:** 8 or higher
- **Gradle Version:** 7.5
- **Android Gradle Plugin:** 7.4.2

### Tools → SDK Manager:
- ✅ Android 14 (API 34) - SDK Platform
- ✅ Android SDK Build-Tools 34.0.0
- ✅ Android SDK Platform-Tools
- ✅ Android SDK Tools

## 💡 Pro Tips:
- Always build with internet connection first time
- If stuck, restart Android Studio
- Check Event Log (bottom right) for detailed errors
- Use "Build → Make Project" before "Build APK"

Please share the specific error message you're seeing, and I'll provide targeted solutions!