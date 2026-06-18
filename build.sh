#!/bin/bash
# Builds "xCloud Sites.app" for Apple Silicon (arm64) and assembles a runnable bundle.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="xCloud Sites"
EXEC_NAME="xCloudSites"
BUILD_DIR=".build/release"
APP_BUNDLE="dist/${APP_NAME}.app"

echo "▸ Compiling (release, arm64)…"
swift build -c release --arch arm64

echo "▸ Assembling ${APP_BUNDLE}…"
rm -rf "$APP_BUNDLE"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${EXEC_NAME}" "${APP_BUNDLE}/Contents/MacOS/${EXEC_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "▸ Ad-hoc code signing…"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✓ Built ${APP_BUNDLE}"
echo "  Open with:  open \"${APP_BUNDLE}\""
