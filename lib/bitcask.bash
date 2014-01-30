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
      # perl -ane"/Merged.*in (\\d+(?:\\.\\d+)?) seconds/ && print(q(HOST TODO: ), qq(\$F[0] \$F[1] \$1\n))" $node_log_file >> $bitcask_summary_file_tmp
      perl -ane"/Merged.*in (\\d+(?:\\.\\d+)?) seconds/ && print(qq(\$1\\n))" $node_log_file >> $bitcask_summary_file_tmp
    fi
  fi
}

function consolidate_bitcask_output
{
  local summary_dir="$1"
  mv -f $bitcask_summary_file_tmp "$summary_dir/bitcask.dat"
}

function summary_bitcask
{
  local summary_dir="$1"
  local bitcask_data="$summary_dir/bitcask.dat"

  if [[ -s $bitcask_data ]]
  then
    if is_command_present 'rscript'
    then
      local histogram_png="$summary_dir/bitcask.png"
      local rscript=$(mktemp -t bitcask-rscript)

      exec 3>$rscript
      # NB: leading spaces are OK in R scripts
      echo "
        bitcask <- scan('$bitcask_data', what=numeric(0))
        png('$histogram_png')
        hist(bitcask)
        q()
      " >&3
      exec 3>&-

      # TODO: different redirect if debug/verbose?
      rscript --vanilla --silent $rscript >/dev/null 2>&1

      rm -f $rscript
      pinfo "bitcask merge times histogram built"
    else
      perr "bitcask merge times histogram skipped - merge data present, but rscript not available"
    fi
  else
    rm -f $bitcask_data
    pwarn "bitcask merge times histogram skipped - no merge data"
  fi
}

