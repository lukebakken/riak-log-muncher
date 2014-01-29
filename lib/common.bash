function now
{
  date '+%Y-%m-%d %H:%M:%S'
}

function perr
{
  echo "$(now) [error]: $@" 1>&2
}

function pinfo
{
  echo "$(now) [info]: $@"
}

function errexit
{
  perr "$@"
  exit 1
}

declare -a on_exit_items

function on_exit()
{
  for i in "${on_exit_items[@]}"
  do
    echo "on_exit: $i"
    eval $i
  done
}

function add_on_exit
{
  local n=${#on_exit_items[*]}
  on_exit_items[$n]="$*"
  if [[ $n -eq 0 ]]; then
    # TODO: if debug echo "Setting trap"
    trap on_exit EXIT
  fi
}

function verify_commands
{
  for required_command in "$@"
  do
    if ! is_command_present $required_command
    then
      errexit "required command '$required_command' not in PATH, exiting."
    fi
  done
}

function is_command_present
{
  hash "$1" 2>/dev/null
}

