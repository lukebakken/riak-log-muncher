bitcask_summary_file_tmp=$(mktemp -t bitcask-summary)

function bitcask_onexit
{
  if [[ -f $bitcask_summary_file_tmp ]]
  then
    rm -f $bitcask_summary_file_tmp
  fi
}
add_on_exit bitcask_onexit

function process_bitcask
{
  local node_log_subdir="$1"
  local node_log_file="$2"

  # host=${DIR##*/}
  if [[ $node_log_file == *console.log* ]]
  then
    local -i bitcask_count=$(egrep -c 'Merged.*in [[:digit:]]+(\.[[:digit:]]+)? seconds' $node_log_file)
    if ((bitcask_count > 0))
    then
      perl -ane"/Merged.*in (\\d+(?:\\.\\d+)?) seconds/ && print(q(HOST TODO: ), qq(\$F[0] \$F[1] \$1\n))" $node_log_file >> $bitcask_summary_file_tmp
    fi
  fi
}

function consolidate_bitcask_output
{
  local summary_dir="$1"
  mv -f $bitcask_summary_file_tmp "$summary_dir/bitcask"
}

function summary_bitcask
{
  echo "bitcask merge data TODO"
}

