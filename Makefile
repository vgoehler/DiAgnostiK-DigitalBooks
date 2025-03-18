.PHONY: all
.PHONY: clean-pdf clean clean-all
.PHONY: *.extract *.crop *.rotate compress ocr

# Optimization Lvl

OPTIMIZE ?= 1
#
# Final output PDF
OUTPUT ?= output.pdf
OPT_OUTPUT := $(basename $(OUTPUT))_opt$(OPTIMIZE).pdf
OCR_OUTPUT := $(basename $(OPT_OUTPUT))_ocr.pdf

# Temporary directories for extracted images and processed (cropped) PDFs
IMAGEDIR := extracted_images
PROCESSDIR := cropped_pdfs
SRC := source

# Flags for 180 degree Rotation

ROTATE_FRONT ?= 0
ROTATE_BACK ?= 0


# Files
FILES := $(sort $(wildcard $(SRC)/*.pdf ))
# separate Files in front, middle and back
FRONT := $(wildcard $(SRC)/*[fF]ront*.pdf)
BACK := $(wildcard $(SRC)/*[bB]ack*.pdf)
MIDDLE := $(filter-out $(FRONT) $(BACK), $(FILES))

TO_PROCESS := $(FRONT) $(BACK)

FRONT_PROC := $(patsubst $(SRC)/%.pdf,$(PROCESSDIR)/%-cropped.pdf,$(FRONT))
BACK_PROC := $(patsubst $(SRC)/%.pdf,$(PROCESSDIR)/%-cropped.pdf,$(BACK))
FINAL_PDFS := $(FRONT_PROC) $(MIDDLE) $(BACK_PROC)

all: $(OCR_OUTPUT)

$(IMAGEDIR):
	@mkdir -p $(IMAGEDIR)

$(PROCESSDIR):
	@mkdir -p $(PROCESSDIR)

# we extract only front and back
IMAGETARGETS := $(IMAGEDIR)/front-extract.stamp $(IMAGEDIR)/back-extract.stamp
$(IMAGETARGETS): $(IMAGEDIR)/%-extract.stamp: $(SRC)/%.pdf | $(IMAGEDIR)
	@echo "Extracting images from $< into $(IMAGEDIR)"
	pdfimages -png $< $(IMAGEDIR)/$*
	@touch $@

# all extracted are then cropped
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

# and maybe rotated inplace overwrite
# ISSUE: if the scanned image has rotate flags, then these are lost in the process
$(IMAGEDIR)/%-rotate.stamp: $(IMAGEDIR)/%-cropped.stamp
	@echo "Rotating images for $*..."
	@case "$*" in (front|back)\
		if ( [ "$*" = "front" ] && [ "$(ROTATE_FRONT)" -eq "1" ] ) || \
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

merge-%: $(PROCESSDIR)/%-cropped.pdf
	@echo "$* merged"

# and reassembled
$(PROCESSDIR)/%-cropped.pdf: $(IMAGEDIR)/%-rotate.stamp | $(PROCESSDIR)
	@echo "Merging cropped images for $* into $@"
	@files=$$(ls $(IMAGEDIR)/$*-*-cropped.png 2>/dev/null); \
	if [ -z "$$files" ]; then \
		echo "no cropped files found"; \
		exit 1; \
	fi; \
	convert $${files} $@

# --- Final PDF Creation ---
$(OUTPUT): $(FINAL_PDFS)
	@echo "Merging the following PDFs into $(OUTPUT):"
	@echo $(FINAL_PDFS)
	pdfunite $(FINAL_PDFS) $(OUTPUT)

$(OPT_OUTPUT): $(OUTPUT)
	@echo "Optimize images in $(OUTPUT)"
	ocrmypdf --tesseract-timeout=0 --optimize $(OPTIMIZE) --deskew --skip-text $< $@

# doing OCR on all text pages, excluding title and back
LAST_PAGE = $(shell pdfinfo "$(OUTPUT)" | grep "Pages" | awk '{print $$2}')
$(OCR_OUTPUT): $(OPT_OUTPUT)
	@echo "Doing OCR on $(OPT_OUTPUT)"
	ocrmypdf -l deu --optimize $(OPTIMIZE) --deskew --clean --pages 2-$$(($(LAST_PAGE)-1)) --output-type pdfa $< $@ --sidecar $(basename $@).txt

# === Clean-up ===
clean:
	rm -rf $(IMAGEDIR) $(PROCESSDIR)
	rm -rf $(OUTPUT) $(OPT_OUTPUT)

clean-pdf:
	rm -rf $(basename $(OUTPUT))*

clean-all: clean clean-pdf

