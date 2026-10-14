#!/bin/sh
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$TASK_ROOT"
: "${ANDROID_HOME:=$HOME/Library/Android/sdk}"
: "${JAVA_HOME:=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_HOME JAVA_HOME
python3 tools/stamp_build.py --local
python3 tools/prepare_android.py
chmod +x android/build/gradlew
android/build/gradlew -p platform/android_save testDebugUnitTest installPlugin --console=plain
mkdir -p build
python3 tools/checked_godot.py -- --headless --editor --import
python3 tools/checked_godot.py -- --headless --export-debug Android build/brackenward-debug.apk
