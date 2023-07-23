
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := ${ROOT_DIR}/_site

setup:
	@npm install

run: clean
	@npx @11ty/eleventy --serve

build: clean
	@npx @11ty/eleventy

clean:
	@rm -rf _site

deploy:
	@make build -s
	@./scripts/deploy.sh "${BUILD_DIR}" "${ROOT_DIR}"
