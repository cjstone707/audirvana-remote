#!/bin/bash
set -e
cd "$(dirname "$0")"

swift build

APP="AudirvanaRemote.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/debug/AudirvanaRemote "$APP/Contents/MacOS/AudirvanaRemote"

pkill -x AudirvanaRemote 2>/dev/null || true
sleep 0.5

open "$APP"
echo "Launched $APP"
