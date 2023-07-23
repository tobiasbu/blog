# Logger Helpers

###############################################################
# Constants
log_RESET="\x1B[0m"
log_BOLD="\x1B[1m"
log_DIM="\x1B[2m"
log_UNDERLINE="""\x1B[4m"

log_BLACK="\x1B[30m"
log_RED="\x1B[31m"
log_YELLOW="\x1B[33m"
log_BLUE="\x1B[34m"
log_MAGENTA="\x1B[35m"
log_CYAN="\x1B[36m"
log_DEFAULT="\x1B[39m"

log_LIGHT_GRAY="\x1B[37m"
log_DARK_GRAY="\x1B[90m"

log_LIGHT_GREEN="\x1B[92m"
log_LIGHT_YELLOW="\x1B[93m"
log_LIGHT_BLUE="\x1B[94m"
log_LIGHT_CYAN="\x1B[96m"
log_WHITE="\x1B[97m"

log_BG_RESET="\x1B[49m"
log_BG_CYAN="\x1B[46m"
log_BG_LIGHT_GRAY="\x1B[47m"
log_BG_DARK_GRAY="\x1B[100m"
log_BG_LIGHT_GREEN="\x1B[102m"
log_BG_WHITE="\x1B[107m"

###############################################################
# Core definitions

#
# Print given string nth times
#
# Arguments:
#   #1 [REQUIRED]  <string>  String to be printed
#   #2 [REQUIRED]  <number>  Times to print
#
function repeat() {
  for (( i=0; i<$2; i++ )); do echo -ne "$1"; done 
}

log_SHOW_LEVEL=1
log_LEVEL=5

log_VERB_COLOR="${log_DARK_GRAY}"
log_DEBG_COLOR=""
log_INFO_COLOR="${log_LIGHT_BLUE}"
log_WARN_COLOR="${log_YELLOW}"
log_ERRO_COLOR="${log_RED}"

log_PREFIX_TEXT=" >>>"
log_PREFIX="${log_MAGENTA}${log_PREFIX_TEXT}${log_RESET}${log_BG_RESET}"
log_PREFIX_SPACER=$(repeat " " ${#log_PREFIX_TEXT})
log_SUFFIX="${log_RESET}${log_BG_RESET}"
log_LAST_LEVEL=
log_LAST_MESSAGE=

answer=

###############################################################
# Implementation

# Stderr echo
function print_error() { 
  if [[ ! -z $2 ]]; then
    >&2 echo -ne "\r$1"
  else
    >&2 echo -e "$1"; 
  fi
  tput el
}

# Stdout echo
function print() { 
  if [[ ! -z $2 ]]; then
    echo -ne "\r$1"
  else
    echo -e "$1"
  fi
  tput el
}

# Reset logger prefix
function log.resetPrefix() {
  log_PREFIX="${log_MAGENTA}[log]${log_RESET}${log_BG_RESET}"
}

#
# Helper function to get a valid color.
# In case the color does not exist, it will return the default color.
#
# Arguments
#   #1  [REQUIRED]  <string>  Default color
#   #2  [REQUIRED]  <string>  Desired color
#
function log.getColor() {
  ret=$2
  if [[ ! -z "$1" ]]; then
    ret="log_$( echo "$1" | tr a-z A-Z )"
  fi
  if [[ -z "${!ret}" ]]; then
    ret=$2
  else
    ret=${!ret}
  fi
}

#
# Set logger prefix
#
# Arguments
#   #1 [REQUIRED]   <string>    Prefix string
#   #2              <string>    Prefix color
#
function log.setPrefix() {
  log_PREFIX_TEXT="$1"
  if [[ $2 -eq -1 ]]; then
    log_PREFIX="$log_PREFIX_TEXT"
  else
    log.getColor $2 $log_MAGENTA
    log_PREFIX="${ret}$log_PREFIX_TEXT${log_RESET}${log_BG_RESET}"
  fi
  log_PREFIX_SPACER=$(repeat " " ${#log_PREFIX_TEXT})
}

function log.getLevelStr() {
  local str=""
  case $1 in
    0 ) str=""      ;;
    1 ) str="erro"  ;;
    2 ) str="warn"  ;;
    3 ) str="info"  ;;
    4 ) str="debg"  ;;
    5 ) str="verb"  ;;
  esac
  log.getColor "${str}_COLOR"
  __ret_color="${ret}"
  ret="${str}"
}

#
# Private - Common function to log messages
#
# Arguments
#   #1  <0 to 5>    Log level
#   #2  <string>    Message
#   #3  <1 or 0>    Should use carriage return for console replacement?
#   #4  <0, 1 or 2> Prefix mode (0=no prefix, 1=log_PREFIX, 2=log_PREFIX_SPACER)
#   #5  <string>    Custom message prefix
#
function __log.printer() {
  if [[ $1 -le 0 ]]; then
    log_LAST_LEVEL=$1
    return
  fi

  local prefixMode=$4
  local messagePrefix=$5
  local msg=""
  local levelPrefix=""
  local isStderr=0

  if [ $1 -le 2 ]; then
    isStderr=1
  fi
 
  
  if [[ -z "$prefixMode" ]]; then
    prefixMode=1
  fi

  if [ -n $log_SHOW_LEVEL ]; then
    if [[ $prefixMode -lt 3 ]]; then
      log.getLevelStr "$1"
      local level="${ret}"

      if [ "$1" -le 2 ]; then
        if  [ $1 -ne $log_LAST_LEVEL ]; then
          level="${log_BOLD}${level}"
        else
          level=""
        fi
      fi

      if [ -n "$level" ]; then
        level="${level}: "
      fi

      levelPrefix="${__ret_color}${level}${log_DEFAULT}"
    else
      levelPrefix=""
    fi
  fi

  if [[ $prefixMode -eq 1 ]]; then
    msg="${log_PREFIX}"
  elif [[ $prefixMode -ge 2 ]]; then
    msg="${log_PREFIX_SPACER}"
  fi

  msg="${msg} ${levelPrefix}${messagePrefix}$2${log_SUFFIX}"
  if [[ ! -z $isStderr ]]; then
    print_error "${msg}" "$3"
  else
    print "${msg}" "$3"
  fi
  log_LAST_MESSAGE=$2
  log_LAST_LEVEL=$1
}

#
# Verbose level log function
#
# Arguments
#   #1  <string>    Message
#   #2  <1 or 0>    Should use carriage return for console replacement?
#   #3  <0, 1 or 2> Prefix Mode 
#
function verb() {
  if [ $log_LEVEL -lt 5 ]; then
    return
  fi
  __log.printer 5 "$1" "$2" "$3"
}

#
# Debug level function
#
# Arguments
#   #1  <string>    Message
#   #2  <1 or 0>    Should use carriage return for console replacement?
#   #3  <0, 1 or 2> Prefix Mode 
#
function debug() {
  if [ $log_LEVEL -lt 4 ]; then
    return
  fi
  __log.printer 4 "$1" "$2" "$3"
}

#
# Info level log function
#
# Arguments
#   #1  <string>    Message
#   #2  <1 or 0>    Should use carriage return for console replacement?
#   #3  <0, 1 or 2> Prefix Mode 
#
function info() {
  if [ $log_LEVEL -lt 3 ]; then
    return
  fi
  __log.printer 3 "$1" "$2" "$3"
}

# Info without logger prefix
function info_n() {
  info "$1" "$2" 0
}

# Info with spaced prefix
function info_s() {
  info "$1" "$2" 2
}

# Info with spaced prefix and without logger level
function info_sl() {
  info "$1" "$2" 3
}


#
# Warning log function
#
# Arguments
#   #1  <string>  Message
#
function warn() {
  if [ $log_LEVEL -lt 2 ]; then
    return
  fi

  local prefix=
  if [[ $log_LAST_LEVEL -eq 2 ]]; then
    prefix="${log_LIGHT_YELLOW}WARNING: "
    log_LAST_LEVEL=2
  else
    prefix="${log_LIGHT_YELLOW}"
  fi
  __log.printer 2 "$1" "$2" "$3" "${prefix}"
}

#
# Error log function
#
# Arguments
#   #1  <string>    Message
#   #2  <1 or 0>    Should use carriage return for console replacement?
#   #3  <0, 1 or 2> Prefix Mode 
#
function error() {
  if [ $log_LEVEL -lt 1 ]; then
    return
  fi
  __log.printer 1 "$1" "$2" 1 "${log_RED}"
}

#
# Same as error function, but with spaced prefix
#
function error_s() {
  error "$1" "$2" "${log_RED}"
}

#
# Success log function
#
# Arguments
#   #1  <string>  Message
#
function success() {
  if [ $log_LEVEL -lt 3 ]; then
    return
  fi

  __log.printer "$1" "$2" "${log_LIGHT_GREEN}"
}

function console.clear() {
  tput clear
}

function console.saveCursor() {
  tput sc
}

function console.restoreCursor() {
  tput rc
}

