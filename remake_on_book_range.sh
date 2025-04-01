#!/bin/bash

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <start_number> <end_number>"
    exit 1
fi

START=$1
END=$2

ORIG_DIR=$(pwd)

for (( i=START; i<=END; i++ )); do
    DIR="Buch$i"
    if [ -d "$DIR" ]; then
        echo "📁 Entering $DIR..."
        cd "$DIR"
        
        echo "🔧 Running remake..."
        if remake; then
            echo "🧹 Running remake clean..."
            remake clean
        else
            echo "❌ remake failed in $DIR, skipping clean"
        fi

        cd "$ORIG_DIR"
    else
        echo "⚠️ Folder $DIR does not exist, skipping."
    fi
done

echo "✅ Done!"

