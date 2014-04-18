declare -A keywords_out

declare -A keyword_totals
keyword_totals['dummy']=0 # NB: so nounset works

keywords_pl=$(mktemp -t keywords-pl)

exec 3>$keywords_pl
echo 'use strict;
use warnings;
use File::Temp qw/tempfile/;
my @keywords = qw(emfile system_memory_high_watermark eaddrinuse eaddrnotavail badarg noproc econnrefused insufficient_vnodes_available invalid_ring_state_dir not_reachable all_nodes_down local_put_failed precommit_fail busy_dist_port);
my %kw_totals;
my $log_file = $ARGV[0];
my $out_file = $ARGV[1];
open(my $infh, "<", $log_file)
  or die "can not open input file $log_file: $!";
while (<$infh>) {
    for my $kw (@keywords) {
        if (index($_, $kw) != -1) {
            if ($kw_totals{$kw}) {
                my $kw_ary = $kw_totals{$kw};
                $$kw_ary[0]++;
                my $fh = $$kw_ary[1];
                $fh->print($_);
            } else {
                (my $fh, my $filename) = tempfile();
                $fh->print("FILE:$log_file\n");
                $fh->print($_);
                $kw_totals{$kw} = [1, $fh, $filename];
            }
        } 
    }
}
close($infh);
open(my $outfh, ">>", $out_file)
  or die "can not open output file $out_file: $!";
for my $kw (keys %kw_totals) {
    my $kw_ary = $kw_totals{$kw};
    my $total = $$kw_ary[0];
    my $tmpfh = $$kw_ary[1];
    my $tmpfile = $$kw_ary[2];
    close($tmpfh);
    if ($total > 0) {
        my $outstr = "$kw $total $tmpfile\n";
        $outfh->print($outstr);
    } else {
        unlink($tmpfile);
    }
}
close($outfh);' >&3
exec 3>&-

function keywords_onexit
{
  set +o nounset
  for outfile in "${keywords_out[@]}"
  do
    rm -f $outfile
  done
  set -o nounset
  if [[ -f $keywords_pl ]]
  then
    rm -f $keywords_pl
  fi
}
add_on_exit keywords_onexit

function process_keywords
{
  local node_log_subdir="$1"
  local node_log_file="$2"
  local nodename="$3"

  set +o nounset
  local keywords_out_tmp="${keywords_out[$nodename]}"
  if [[ ! -f $keywords_out_tmp ]]
  then
    keywords_out_tmp="$(mktemp -t $nodename-keywords)"
    keywords_out[$nodename]="$keywords_out_tmp"
  fi
  set -o nounset

  perl "$keywords_pl" "$node_log_file" "$keywords_out_tmp"
}

function consolidate_keywords_output
{
  local summary_dir="$1"
  for nodename in "${!keywords_out[@]}"
  do
    local outfile="${keywords_out[$nodename]}"
    if [[ -s $outfile ]]
    then
      local node_summary_dir="$summary_dir/$nodename"
      mkdir $node_summary_dir

      while read -r out_data
      do
        set -- $out_data

        local keyword=$1
        local -i total=$2
        local tmpfile=$3

        cat $tmpfile >> "$node_summary_dir/$keyword.dat"
        rm -f $tmpfile

        (( keyword_totals[$keyword] += $total ))

      done < $outfile
    else
      pwarn "empty $nodename outfile: $outfile"
    fi
  done
}

function summary_keywords
{
  for keyword in "${!keyword_totals[@]}"
  do
    local -i keyword_total=${keyword_totals[$keyword]}
    if (( keyword_total > 0 ))
    then
      pinfo "keyword $keyword: $keyword_total"
    fi
  done
}

