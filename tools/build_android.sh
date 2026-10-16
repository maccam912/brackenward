#!/bin/sh
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$TASK_ROOT"
: "${ANDROID_HOME:=$HOME/Library/Android/sdk}"
: "${JAVA_HOME:=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
export ANDROID_HOME JAVA_HOME
case "${1:---debug}" in
  --debug) TASK_EXPORT=--export-debug; TASK_APK=build/brackenward-debug.apk ;;
  --release)
    TASK_EXPORT=--export-release; TASK_APK=build/brackenward-release.apk
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set the release signing keystore path}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set the release signing alias}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set the release signing password}"
    ;;
  *) echo 'Usage: tools/build_android.sh [--debug|--release]' >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo 'Expected at most one build-mode argument.' >&2; exit 2; }
python3 tools/stamp_build.py --local
python3 tools/prepare_android.py
chmod +x android/build/gradlew
android/build/gradlew -p platform/android_save testDebugUnitTest testReleaseUnitTest installPlugin --console=plain
mkdir -p build
python3 tools/checked_godot.py -- --headless --editor --import
python3 tools/checked_godot.py -- --headless "$TASK_EXPORT" Android "$TASK_APK"
