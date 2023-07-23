#! /bin/bash

SCRIPT_DIR_NAME=`dirname "$0"`
source "$SCRIPT_DIR_NAME/logger.sh"
source "$SCRIPT_DIR_NAME/run.sh"
source "$SCRIPT_DIR_NAME/git.sh"

log.setPrefix "[blog]" "DARK_GRAY"
log_LEVEL=3

###############################################################
# Args
SRC_DIR="$1"
DST_DIR="$2"
DST_BASEDIR="$(basename -- $DST_DIR)"
SRC_BASEDIR="$(basename -- $SRC_DIR)"

REMOTE="origin"
BRANCH_DESTINY="gh-pages"
BASE_BRANCH="main"
COMMIT_MESSAGE="Update blog..."


###############################################################
# Setup

DRY_RUN=1
__arg_dry_run=""

if [[ -n "${DRY_RUN}" ]]; then
  warn "DRY RUN MODE"
  log_LEVEL=5
  __DEBUG_RUN=1
  __arg_dry_run="--dry-run"
fi

info "Starting deployment of Tobias' Blog"
info_sl "${log_DIM}* SRC_DIR:        ${SRC_DIR}"
info_sl "${log_DIM}* DST_DIR:        ${DST_DIR}"
info_sl "${log_DIM}* BRANCH_DESTINY: ${BRANCH_DESTINY}"


###############################################################
info "Checking pre-requisites"
if [[ -z "${DRY_RUN}" ]]; then
  verb "git: checking if current branch is dirty"
  if git.isDirty; then
    # errorStep "Local changes detected"
    error "Please commit your changes or stash them before you continue with deployment process."
    exit 1
  fi
else
  debug "Skipping dirty check"
fi

verb "git: checking existence of gh-pages branch on remote"
if ! git.existsRemoteBranch "${BRANCH_DESTINY}"; then
  error "The ${BRANCH_DESTINY} does not exists. Please create it first."
  exit 1
fi

info "Getting latest updates from remote"
if ! git.fetch "--prune --all"; then
  error "$ret_std"
  exit 1
fi

verb "git: checkout to BRANCH_DESTINY"
if ! git.checkout "${BRANCH_DESTINY}"; then
  error "Failed to checkout to ${BRANCH_DESTINY}"
  error "$ret_std"
  exit 1
fi

verb "git: resets REMOTE/BRANCH_DESTINY to remote"
if ! git.reset "${REMOTE}/${BRANCH_DESTINY}"; then
  error "Failed to reset ${REMOTE}/${BRANCH_DESTINY}"
  error "$ret_std"
  exit 1
fi

# Linux has a bug which causes:
# cannot stat 'path/to/_site/*': No such file or directory
# if [[ $_DEV_MODE -ne 1 ]]; then
#   ret=$(ls .)
#   verb "LS FILES: ${ret}"
# fi

###############################################################
# get files (exclude .git hidden folder and SRC_DIR)
#files=$(find . -maxdepth 1 -mindepth 1 -not -path '*/\.git' -not -path "*/\_site")

function resetToMain() {
  verb "Back to '${BASE_BRANCH}'"
  run.quietly "git reset --hard"
  run.quietly "git clean -fxd --exclude=node_modules -e ${SRC_BASEDIR}"
  run.quietly "git checkout ${BASE_BRANCH}"
}

verb "verify SRC_DIR existence"
if [ ! -d "${SRC_DIR}" ]; then
  warn "The SRC_DIR does not exists in gh-pages!"
  warn "Possible cause: git index cached wrong files. Run: 'git rm --cache _site -r'"
  resetToMain 
  exit 1
fi

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

info "Moving files from SRC_DIR to DST_DIR"
if ! run.quietly "cp -r ${SRC_DIR}/* ${DST_DIR}/"; then
  error "Failed to move SRC_DIR files to DST_DIR"
  resetToMain
  exit 1
fi

if ! run.quietly "git status -uno"; then
  error "Failed check git status"
  error "$ret_std"
  resetToMain
  exit 1
fi
if [[ -n "${DRY_RUN}" ]]; then
  debug "$ret_std"
fi

verb "git: add files to stage"
escapedSrcDir="${SRC_BASEDIR/_/\\_}" 
if ! git.addAll "$__arg_dry_run" "-- :!node_modules :!${escapedSrcDir}/*"; then
  error "Failed to add files to staging"
  error "$ret_std"
  resetToMain
  exit 1
fi
if [[ -n "${DRY_RUN}" ]]; then
   debug "$ret_std"
fi

info "Commiting changes"
if [[ -z "${DRY_RUN}" ]]; then
  if ! git commit -m "${COMMIT_MESSAGE}" --no-edit --no-verify; then
    error "Failed to commit files"
    resetToMain
    exit 1
  fi

  if ! git push ${REMOTE} ${BRANCH_DESTINY}; then
    error "Failed to push changes of BRANCH_DESTINY to REMOTE"
    resetToMain
    exit 1
  fi
fi


resetToMain