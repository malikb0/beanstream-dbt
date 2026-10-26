SHELL := /bin/bash
VENV := .venv
PY := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
DBT := $(VENV)/bin/dbt
PROFILES := --profiles-dir .

.PHONY: help setup up down raw build test full-refresh docs serve clean all

help:
	@echo "setup  - create .venv, install dbt, create profiles.yml"
	@echo "up     - start Postgres 16 on :5434"
	@echo "down   - stop Postgres (keeps the volume)"
	@echo "raw    - load the synthetic CSVs into raw_beanstream"
	@echo "build  - dbt build (seeds + models + tests)"
	@echo "test   - alias for build"
	@echo "full-refresh - rebuild the incremental fact from scratch"
	@echo "docs   - dbt docs generate"
	@echo "serve  - serve the dbt docs site"
	@echo "all    - setup up raw build docs"
	@echo "clean  - remove generated target/docs/packages/logs"

setup:
	@if [ ! -x "$(PY)" ]; then python3 -m venv $(VENV); fi
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@if [ ! -f profiles.yml ]; then cp profiles.example.yml profiles.yml; fi
	@$(DBT) --version

up:
	docker compose up -d --wait
	@docker compose ps

down:
	docker compose down

raw:
	$(PY) scripts/load_raw.py

build:
	$(DBT) build $(PROFILES)

test: build

full-refresh:
	$(DBT) build $(PROFILES) --full-refresh

docs:
	$(DBT) docs generate $(PROFILES)

serve:
	$(DBT) docs serve $(PROFILES)

all: setup up raw build docs

clean:
	rm -rf target dbt_packages logs
