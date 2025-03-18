#!/bin/bash

PDF_FOLDER="$1"
START_NUMBER=4

if [ -z "$PDF_FOLDER" ]; then
    echo "Usage: $0 <path_to_pdf_folder>"
    exit 1
fi

# Ensure the folder exists
if [ ! -d "$PDF_FOLDER" ]; then
    echo "Error: Folder does not exist."
    exit 1
fi

# Get sorted list of PDFs
PDF_FILES=($(ls "$PDF_FOLDER"/*.pdf | sort))

for PDF in "${PDF_FILES[@]}"; do
    BUCH_FOLDER="$PDF_FOLDER/Buch$START_NUMBER"
    SOURCE_FOLDER="$BUCH_FOLDER/source"
    
    mkdir -p "$SOURCE_FOLDER"
    
    # Copy and rename PDF
    cp "$PDF" "$SOURCE_FOLDER/scan1.pdf"
    
    # Extract filename
    PDF_NAME=$(basename "$PDF")
    
    # Create Makefile
    cat <<EOF > "$BUCH_FOLDER/Makefile"
# Final output PDF
OUTPUT := $PDF_NAME

# Flags for Rotation
ROTATE_FRONT = 0
ROTATE_BACK = 0

include ../Makefile
EOF
    
    echo "Processed $PDF -> $BUCH_FOLDER"
    ((START_NUMBER++))
done
