riak-log-muncher
================

To use:

Install bash 4 via homebrew:

```
# brew update
# brew install bash
```

Clone it and fire it up. The only argument is a path to where a set of `riak-debug` logs have been extracted. It expects to find a set of
directories matching the `*-riak-debug` glob:

```
$ git clone git://github.com/lukebakken/riak-log-muncher.git
$ cd riak-log-muncher
$ ./log-muncher ../../tickets/1234/comments/4
```

Per-node summary will be in `./summary`.

If you'd like a histogram of bitcask merge times, install R this way:

```
# brew update
# brew install gfortran
# brew tap homebrew/science
# brew install homebrew/science/r
```

