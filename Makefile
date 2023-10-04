# Copyright 2019-2020 Richard Lincoln. All rights reserved.

TAG = gchr.io/rwl/opendsscmd
TARGET = cmdbuilder
CMD ?=

all: build

.PHONY: build
build:
	docker build --target $(TARGET) -t $(TAG) .

.PHONY: run
run:
	docker run -it --rm -p 8080:8246 $(TAG) $(CMD)

DESTDIR = $(HOME)/bin

.PHONY: cp
cp:
	docker run -it --rm -d $(TAG)
	CONTAINER_ID=$$(docker ps -alq) && \
	docker cp $$CONTAINER_ID:$/usr/local/bin/opendsscmd $(DESTDIR) && \
	docker stop $$CONTAINER_ID
