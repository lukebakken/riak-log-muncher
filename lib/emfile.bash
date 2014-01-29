declare -i emfile_total=0

emfile_summary_file_tmp="./emfile-summary.$$.tmp"
# TODO
# emfile_summary_file_tmp=$(mktemp -d -t emfile-summary)
# add_on_exit rm -vf $emfile_summary_file_tmp

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

function summary_emfile
{
  pinfo "emfile $emfile_total"
}

