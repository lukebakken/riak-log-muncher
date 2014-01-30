declare -i riak_kv_total=0

riak_kv_summary_file_tmp=$(mktemp -t riak_kv-summary)

function riak_kv_onexit
{
  if [[ -f $riak_kv_summary_file_tmp ]]
  then
    rm -f $riak_kv_summary_file_tmp
  fi
}
add_on_exit riak_kv_onexit

function process_riak_kv
{
  local node_log_subdir="$1"
  local node_log_file="$2"

  if [[ $node_log_file == *console.log* ]]
  then
    local -i riak_kv_count=$(fgrep -ci riak_kv $node_log_file)
    if ((riak_kv_count > 0))
    then
      exec 3>>$riak_kv_summary_file_tmp
echo "------------------------------------------------------------------------
$riak_kv_count riak_kv matches in $node_log_file:
" >&3
      fgrep riak_kv "$node_log_file" >&3
      echo '' >&3
      exec 3>&-
      (( riak_kv_total += riak_kv_count ))
    fi
  fi
}

function consolidate_riak_kv_output
{
  local summary_dir="$1"
  mv -f $riak_kv_summary_file_tmp "$summary_dir/riak_kv"
}

function summary_riak_kv
{
  pinfo "total: riak_kv $riak_kv_total"
}

