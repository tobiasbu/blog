#! /bin/bash

SCRIPT_DIR_NAME=`dirname "$0"`
source "$SCRIPT_DIR_NAME/logger.sh"

DST_DIR="$(pwd)"
SRC_DIR="${DST_DIR}/_site"
SRC_BASEDIR="$(basename -- $SRC_DIR)"

DRY_RUN=1

info "Diffing removal"
files=$(diff $DST_DIR $SRC_DIR -r --exclude={$SRC_BASEDIR,.git,node_modules} | sed -n 's/Only in //p')
while IFS= read -r line; do
    dir=${line%%:*}
    file=${line#*: }
    path="$dir/$file"
    if [[ ! "$path" =~ ^"$SRC_DIR" ]]; then
      debug "Removed: $path"
      if [[ -z "${DRY_RUN}" ]]; then
        if [[ -d "$path" ]]; then
          rm -rf "$path"
        else
          rm -f "$path"
        fi
      fi
    fi
done <<< "$files"