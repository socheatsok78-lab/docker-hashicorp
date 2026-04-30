.EXPORT_ALL_VARIABLES:
TARGET := $(shell basename $(CURDIR))
VERSION := $(shell ls **/Dockerfile | cut -d/ -f1 | sort -r --version-sort | sed -n '2p')

it: print
	@echo "TARGET: ${TARGET}"
	@echo "VERSION: ${VERSION}"
print:
	docker buildx bake $(TARGET) --print
build: print
	docker buildx bake $(TARGET) --set="*.platform="
