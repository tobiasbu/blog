
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := ${ROOT_DIR}/_site

install: setup

setup:
	@npm install

run: clean
	@NODE_ENV=development npx @11ty/eleventy --serve

build: clean
	@npx @11ty/eleventy

clean:
	@rm -rf _site

deploy:
	@make build -s
	@./scripts/deploy.sh "${BUILD_DIR}" "${ROOT_DIR}"
