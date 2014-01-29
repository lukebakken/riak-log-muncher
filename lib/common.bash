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

function add_on_exit()
{
  local n=${#on_exit_items[*]}
  on_exit_items[$n]="$*"
  if [[ $n -eq 0 ]]; then
    echo "Setting trap"
    trap on_exit EXIT
  fi
}

