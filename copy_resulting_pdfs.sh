#!/bin/bash

set -e

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <start_number> <end_number> <target_directory> [filename_pattern]"
    echo "Default pattern: output*.pdf"
    exit 1
fi

START=$1
END=$2
TARGET_DIR="$3"
PATTERN=${4:-output*.pdf}

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

for i in $(seq "$START" "$END"); do
    DIR="Buch$i"
    if [ -d "$DIR" ]; then
        echo "📁 Searching in $DIR for pattern: $PATTERN"
        FOUND=0
        for file in "$DIR"/$PATTERN; do
            if [ -f "$file" ]; then
                BASENAME=$(basename "$file")
                DEST="$TARGET_DIR/$BASENAME"

                # Check if file exists; if so, add numbered suffix
                if [ -e "$DEST" ]; then
                    BASE="${BASENAME%.pdf}"
                    EXT=".pdf"
                    N=1
                    while [ -e "$TARGET_DIR/${BASE}_$N$EXT" ]; do
                        N=$((N+1))
                    done
                    DEST="$TARGET_DIR/${BASE}_$N$EXT"
                fi

                cp "$file" "$DEST"
                echo "✅ Copied $(basename "$file") → $(basename "$DEST")"
                FOUND=1
            fi
        done
        if [ "$FOUND" -eq 0 ]; then
            echo "⚠️ No matching files in $DIR"
        fi
    else
        echo "⚠️ Skipping $DIR (does not exist)"
    fi
done

echo "🎉 Done! Files copied to $TARGET_DIR"
