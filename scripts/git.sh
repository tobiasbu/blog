# Git utilities 

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

source "$DIR/run.sh"

#
# Get current branch name
#
# Returns:  
#   If operation was successful returns 0, otherwise 1.
#
# Globals:
#   ret     Branch name
#
function git.currentBranch() {
  if ret=$(git symbolic-ref --short -q HEAD); then
    return 0;
  fi
  return 1;
}

#
# Check if the HEAD pointer is detached
#
# Returns:  
#   If is detached returns 0, otherwise 1.
#
# Globals:
#   ret     Branch name. 'HEAD' indicates detached head
#
# See: https://www.git-tower.com/learn/git/faq/detached-head-when-checkout-commit/
#
function git.isDetachedHead() {
  ret=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
  if [[ "$ret" -eq "HEAD" ]]; then
    return 0;
  fi
  return 1;
}

#
# Detect if current branch is dirty (has uncommited changes)
# This not check untracked files.
#
# NOTE: This command check file timestamps too.
# So even there's no changes in your file but a file is modified
# like package-lock.json it'll consider dirty.
#
# Returns:  
#   If is dirty returns 0, otherwise 1.
#
function git.unsafe_isDirty() {
  if run.quietly "git diff-index --quiet HEAD --"; then
    return 1;
  fi
  return 0;
}

#
# Detect if current branch is dirty (has uncommited changes)
# This not check untracked files.
#
# Returns:  
#   If is dirty returns 0, otherwise 1.
#
function git.isDirty() {
  run.quietly "git update-index --refresh"

  git.unsafe_isDirty
  return $?;
}

# Fetch remote changes
function git.fetch() {
  local args=

  if [ $# -gt 0 ]; then
    args="$@"
  else
    args="origin"
  fi

  if ! run.quietly "git fetch $args"; then
    return 1;
  fi
  return 0;
}

#
# Cleans current git branch removing files that are not under version control
#
# Arguments:
#   #1 <string>  Additional command args
#
# Returns:  
#   If the command failed returns 1, otherwise 0.
#
function git.clean() {
  if ! run.quietly "git clean -f --quiet $1"; then
    ret_std="git.clean: failed to clean git repository"
    return 1;
  fi
}

function git.rm() {
  if ! run.quietly "git rm --ignore-unmatch -r -f "$1""; then
    ret_std="git.rm: failed to remove unversioned files"
    return 1;
  fi
}

# Reset hard current branch to given branch (ex: origin/main)
function git.reset() {
  if ! run.quietly "git reset --hard "$1""; then
    ret_std="git.reset: failed to reset branch to $1"
    return 1;
  fi
}

# Change branch/commit
function git.checkout() {
  local args=
  if [ $# -gt 0 ]; then
    args="$@"
  else
    ret_std="No branch/commit specified"
    return 1
  fi

  if ! run.quietly "git checkout ${args}"; then
    ret_std="Could not checkout to '$1':\n${ret_std}"
    return 1
  fi

  git.currentBranch
  if [[ "$ret" != "$1" ]]; then
    ret_std="Failed to checkout to '$1'. Did you specify a correct branch/commit?"
    return 1
  fi 
}

# Add all files to staging
function git.addAll() {
  if ! run.quietly "git add --all $*"; then
    ret_std="git.addAll: Could not add all files: ${ret_std}"
    return 1
  fi
}

#
# Create a branch based in given base branch
# If operation fails the program will be aborted.
#
# Arguments:
#   #1 [REQUIRED]  <string>  Branch name to create
#   #2 [REQUIRED]  <string>  Base branch name
#
function git.createBranchFrom() {
  local branchToCreate=$1
  local baseBranch=$2
  if ! run.quietly "git branch "$branchToCreate" "$baseBranch" --quiet"; then
    ret_std="Could not create '$branchToCreate' branch:\n${ret_std}"
    return 1
  fi
}

# Creates an orphan branch from given name
function git.createOrphanBranch() {
  local branch=$1
  if ! run.quietly "git checkout --orphan "$branch""; then
    ret_std="Could not create orphan branch '$branch':\n${ret_std}"
    return 1
  fi
}

# Check if local repository a branch exists
function git.existsLocalBranch() {
  local branch=$1
  if [ -n "`git branch --list $branch`" ]; then
    return 0
  fi
  return 1
}

# Check if in local repository an remote ref branch exists
# Consider first call 'git fetch --prune' before this command
function git.existsRemoteBranchLocally() {
  local branch=$1
  ret_std=$(git branch -r -l "$branch")
  if [ -z $ret_std ]; then
    return 1
  fi
  return 0
}

# Check if remote origin exists given branch
function git.existsRemoteBranch() {
  local branch=$1
  local remote=$2
  local heads=

  if [ -z "$remote" ]; then
    remote="origin"
  fi

  if ! run.quietly "git ls-remote --exit-code --quiet . ${remote}/${branch}"; then
    ret_std="git.existsRemoteBranch: failed check remote: ${ret_stderr}"
    return 1;
  fi

  # Exit with status "2" when no matching refs are found in the remote repository
  local branchExists=$?
  if [[ "$branchExists" -eq "2" ]]; then
    return 1
  fi
  return 0
}

#
# Remove a branch.
# If the HEAD is pointing to the branch that will be removed,
# it will checkout to "develop".
#
# Arguments:
#   #1 [REQUIRED]  <string>  Branch name to be removed
#   #2             <string>  Checkout branch name (default: "main")
#
function git.removeBranch() {
  local branchToRemove=$1
  local branchToCheckout=$2

  if git.existsLocalBranch "$branchToRemove"; then
    if [ -z $branchToCheckout ]; then
      branchToCheckout="main"
    fi

    git.currentBranch
    if [[ "$ret" == "$branchToRemove" ]]; then
      if ! run.quietly "git checkout $branchToCheckout"; then
        ret_std="git.removeBranch: Could not checkout to '$branchToCheckout'"
        return 1;
      fi
    fi
    
    if ! run.quietly "git branch -D "$branchToRemove""; then
      ret_std="git.removeBranch: Unexpected error happened while removing '$branchToRemove' branch\n${ret_std}"
      return 1;
    fi
  fi
}
