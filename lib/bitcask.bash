bitcask_summary_file_tmp=$(make_temp_file bitcask-summary)

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
      echo "time,duration" > $bitcask_summary_file_tmp
      perl -ne '/([0-9-]+ [0-9:.]+)[A-Z ]+\[info\].*Merged.*in (\d+(?:\.\d+)?) seconds/ && print "$1,$2\n"' $node_log_file >> $bitcask_summary_file_tmp
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
      local rscript=$(make_temp_file bitcask-rscript)

      exec 3>$rscript
      # NB: leading spaces are OK in R scripts
      echo "bitcask_data <- \"${bitcask_data}\"" >&3
      echo "summary_dir <- \"${summary_dir}\"" >&3
      echo '
        library(ggplot2)
        library(scales)
        library(reshape2)
        require(grid)

        merges <- read.csv(bitcask_data)
        merges$time <- as.POSIXlt(merges$time, format="%Y-%m-%d %H:%M:%S")
        write(paste("Read in ", bitcask_data, " successfully. Summarizing to ", summary_dir, sep=""), stdout())

        png(paste(summary_dir, "merges_binned.png", sep="/"), height=800, width=1400)
        plt = ggplot(data=merges, aes(x=time))                    +
                geom_bar(aes(weight=duration))                    +
                geom_point(aes(y=duration), colour="orange")      +
                ylab("Grouped Merge Duration (sec)")              +
                xlab("")                                          +
                scale_x_datetime(labels=date_format("%b-%d-%Y"))  +
                ggtitle("Merge Durations Binned over Time")
        plt
        dev.off()
        write(paste("Plotted merges_binned successfully.", sep=""), stdout())

        png(paste(summary_dir, "merges_histogram.png", sep="/"), height=800, width=1400)
        plt = ggplot(data=merges, aes(x=duration))   +
                geom_histogram()                     +
                ylab("Event Count")                  +
                xlab("Merge Duration (sec)")         +
                ggtitle("Merge Duration Counts (Histogram)")
        plt
        dev.off()
        write(paste("Plotted merges_histogram successfully.", sep=""), stdout())

        png(paste(summary_dir, "merges_scatter.png", sep="/"), height=800, width=1400)
        plt = ggplot(data=merges, aes(x=time, y=duration))     +
                geom_point(colour="orange")                    +
                geom_smooth(colour="cyan", method="loess")     +
                geom_smooth(colour="red", se=F, method="lm")   +
                xlab("")                                       +
                ylab("Merge Duration (sec)")                   +
                ggtitle("Merge Durations over Time")           +
                scale_colour_manual(name="Plots",
                                    values=c("orange"="orange",
                                             "cyan"="cyan",
                                             "red"="red"),
                                    labels=c("merges",
                                             "loess_reg",
                                             "linear_reg"))    +
                scale_fill_identity(name="Intervals",
                                    guide="legend",
                                    labels=c("loess_ci"))
        plt
        dev.off()
        write(paste("Plotted merges_scatter successfully.", sep=""), stdout())

        q()
      ' >&3
      exec 3>&-

      # TODO: different redirect if debug/verbose?
      rscript --vanilla --silent $rscript #>/dev/null 2>&1

      rm -f $rscript
      pinfo "bitcask merge duration analysis built"
    else
      perr "bitcask merge duration analysis skipped - merge data present, but rscript not available"
    fi
  else
    rm -f $bitcask_data
    pwarn "bitcask merge duration analysis skipped - no merge data"
  fi
}

