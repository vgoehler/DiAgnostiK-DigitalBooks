# DiAgnostiK -- Digital Books

## Information

A makefile to clean up, stitch together, and read a scanned book.

### Prerequisites

- `pipx install ocrmypdf`
- `apt-get install tesseract-ocr-deu`

    - for ocr: `ocrmypdf -l deu`

- `apt-get install unpaper`

    - for ocr: `ocrmypdf --clean`

- `apt install pngquant`

    - for optimize 2 and 3: `ocrmypdf --optimize 3`

- `apt install jbig2`

    - also for optimize 2 and 3

- `apt install poppler`
    
    - for `pdfimages`
    - for `pdfunite`
    - for `pdfinfo`

- `apt install imagemagick`

    - for `convert`
