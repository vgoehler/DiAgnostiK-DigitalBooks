.PHONY: all
.PHONY: clean-pdf clean
.PHONY: *.extract *.crop *.rotate compress ocr
.SECONDEXPANSION:

# Final output PDF
OUTPUT ?= output.pdf

# Temporary directories for extracted images and processed (cropped) PDFs
IMAGEDIR := extracted_images
CROPPEDDIR := cropped_pdfs
SRC := source

# Flags for Rotation

ROTATE_FRONT ?= 0
ROTATE_BACK ?= 0

# Files
FILES := $(sort $(wildcard $(SRC)/*.pdf ))
# separate Files in front, middle and back
FRONT := $(wildcard $(SRC)/*[fF]ront*.pdf)
BACK := $(wildcard $(SRC)/*[bB]ack*.pdf)
MIDDLE := $(filter-out $(FRONT) $(BACK), $(FILES))
# Order: Front first, then middle, then back
ORDERED = $(FRONT) $(MIDDLE) $(BACK)

# It converts each source PDF in ORDERED into its corresponding cropped PDF.
FINAL_PDFS := $(patsubst $(SRC)/%.pdf,$(CROPPEDDIR)/%-cropped.pdf,$(ORDERED))

all: $(OUTPUT)

$(IMAGEDIR):
	@mkdir -p $(IMAGEDIR)

$(CROPPEDDIR):
	@mkdir -p $(CROPPEDDIR)

$(IMAGEDIR)/%-extract.stamp: $(SRC)/%.pdf | $(IMAGEDIR)
	@echo "Extracting images from $< into $(IMAGEDIR)"
	pdfimages -png $< $(IMAGEDIR)/$*
	@touch $@

$(IMAGEDIR)/%-cropped.stamp: $(IMAGEDIR)/%-extract.stamp
	@echo "Cropping images for $*..."
	@for img in $(IMAGEDIR)/$*-[0-9][0-9][0-9].png; do \
	    cropped=$$(echo $$img | sed 's/\.png/-cropped.png/'); \
	    if [ ! -f $$cropped ]; then \
	        echo "  Cropping $$img -> $$cropped"; \
	        convert $$img -trim +repage $$cropped; \
	    fi; \
	done
	@touch $@

# inplace overwrite
$(IMAGEDIR)/%-rotate.stamp: $(IMAGEDIR)/%-cropped.stamp
	@echo "Rotating images for $*..."
	@case "$*" in (front|back)\
		if [ "$*" = "front" ] && [ "$(ROTATE_FRONT)" -eq "1" ] || \
		   ( [ "$*" = "back"  ] && [ "$(ROTATE_BACK)" -eq "1" ] ); then \
			for img in $(IMAGEDIR)/$*-*-cropped.png; do \
				echo "  Rotating $$img in place"; \
				convert $$img -rotate 180 +repage $$img; \
			done \
		fi \
		;; \
	esac
	@touch $@

crop-%: $(IMAGEDIR)/%-cropped.stamp
	@echo "$* cropped"

rotate-%: $(IMAGEDIR)/%-rotate.stamp
	@echo "$* rotated"

merge-%: $(CROPPEDDIR)/%-cropped.pdf
	@echo "$* merged"

$(CROPPEDDIR)/%-cropped.pdf: $(IMAGEDIR)/%-rotate.stamp | $(CROPPEDDIR)
	@echo "Merging cropped images for $* into $@"
	@files=$$(ls $(IMAGEDIR)/$*-*-cropped.png 2>/dev/null); \
	if [ -z "$$files" ]; then \
		echo "no cropped files found"; \
		exit 1; \
	fi; \
	convert $${files} $@

# --- Final PDF Creation ---
# Merge all the cropped PDFs in the order specified by ORDERED.
$(OUTPUT): $(FINAL_PDFS)
	@echo "Merging the following PDFs into $(OUTPUT):"
	@echo $(FINAL_PDFS)
	pdfunite $(FINAL_PDFS) $(OUTPUT)
	@echo "Final PDF created: $(OUTPUT)"

process: create_final crop2pdf crop_all extract_all
	@echo "Master Process Done"

compress: $(OUTPUT)
	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$(basename $<)_compressed.pdf $<

ocr: $(OUTPUT)
	ocrmypdf -l deu --optimize 1 --deskew --clean --output-type pdfa $< $(basename $<)_ocr.pdf --sidecar $(basename $<).txt


# === Clean-up ===
clean:
	rm -rf $(IMAGEDIR) $(CROPPEDDIR)

clean-pdf:
	rm -rf $(OUTPUT)
