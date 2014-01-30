declare -i emfile_total=0

emfile_summary_file_tmp=$(mktemp -t emfile-summary)

function emfile_onexit
{
  if [[ -f $emfile_summary_file_tmp ]]
  then
    rm -f $emfile_summary_file_tmp
  fi
}
add_on_exit emfile_onexit

function process_emfile
{
  local node_log_subdir="$1"
  local node_log_file="$2"

  if [[ $node_log_file == *console.log* ]]
  then

    local -i emfile_count=$(fgrep -ci emfile $node_log_file)
    if ((emfile_count > 0))
    then
      exec 3>>$emfile_summary_file_tmp

echo "------------------------------------------------------------------------
$emfile_count emfile matches in $node_log_file:
" >&3

      fgrep emfile "$node_log_file" >&3

      echo "------------------------------------------------------------------------" >&3

      exec 3>&-

      (( emfile_total += emfile_count ))
    fi
  fi
}

function consolidate_emfile_output
{
  local summary_dir="$1"
  if [[ -s $emfile_summary_file_tmp ]]
  then
    mv -f $emfile_summary_file_tmp "$summary_dir/emfile"
  else
    rm -f $emfile_summary_file_tmp
  fi
}

function summary_emfile
{
  pinfo "total: emfile $emfile_total"
}

