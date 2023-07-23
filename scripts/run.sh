# Helpers to run commands without outputing to console messages or/and catching only errors

__DEBUG_RUN=0

#
# Execute command with stdout and stderr indirection.
# Command will not print messages or errors
#
# Arguments:
#   #1 [REQUIRED]  <string | ...args[]>  The command to be execute silently
# Returns:  
#   If command fails returns 1, otherwise 0.
# Globals:
#   ret           Same has return value
#   ret_std       Represents the command stdout, stderr or both.
#
function run.quietly() {
  ret_std=""
  local commandExec=
  if [ "$#" -gt 1 ]; then
    commandExec=("$@")
    [ $__DEBUG_RUN -eq 1 ] && echo ">>>>>> (\$@) ${commandExec}"

    if ret_std=$(${commandExec[@]} 2>&1); then
      ret=0
    else
      ret=1
    fi
  else
    commandExec="$1"
    [ $__DEBUG_RUN -eq 1 ] && echo ">>>>>> (\$1) ${commandExec}"

    if ret_std=$($commandExec 2>&1); then
      ret=0
    else
      ret=1
    fi
  fi

  return $ret;
}

#
# Execute command with stderr indirection.
# Command will print messages but no errors
#
# Arguments:
#   #1 [REQUIRED]  <string | ...args[]>  The command to be execute silently
# Returns:  
#   If command fails returns 1, otherwise 0.
# Globals:
#   ret           Same has return value
#   ret_std       Represents the command stderr.
#
function run.catch() {
  ret_std=""
  local commandExec="$1"
  if [ "$#" -gt 1 ]; then
    commandExec=("$@")
    if { ret_std=$(${commandExec[@]} 2>&1 >&3 3>&-); } 3>&1; then
      ret=0
    else
      ret=1
    fi
  else
    commandExec="$1"
    if { ret_std=$($commandExec 2>&1 >&3 3>&-); } 3>&1; then
      ret=0
    else
      ret=1
    fi
  fi

  return $ret;
}

#
# Execute command with stderr indirection
# Command will not print any messages
#
# Arguments:
#   #1 [REQUIRED]  <string | ...args[]>  The command to be execute silently
# Returns:  
#   If command fails returns 1, otherwise 0.
# Globals:
#   ret           Same has return value
#   ret_std       Represents the command stderr.
#
function run.catchOnly() {
  ret_std=""
  local commandExec="$1"
  if [ "$#" -gt 1 ]; then
    commandExec=("$@")
    if ret_std=$(${commandExec[@]} 2>&1 >/dev/null); then
      ret=0
    else
      ret=1
    fi
  else
    commandExec="$1"
    if ret_std=$($commandExec 2>&1 >/dev/null); then
      ret=0
    else
      ret=1
    fi
  fi

  return $ret;
}