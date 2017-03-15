test-warp-wai
-------------

This is a repo containing code to reproduce a file handle leak in versions
0.2.6 and 0.2.7 of Haskell's hs-connection libraries.

This has been tested with both ghc 7.10.3 and ghc 8.0.1.

# Reproduction

I'm assuming that this will be reproduced on Linux, but it should probably also
work on OSX.

Clone this repo and the change into the freshly cloned source tree and do:

* `cabal sandbox init`
* `cabal install --dependencies-only`
* `cabal configure`

You will now need two more terminal windows (three total) and you will need to
change into the above source directory in all of them.

In the first window run:
```
cabal build && dist/build/dummy-https-server/dummy-https-server
```
which bulds everything and runs a trivially simple HTTPS server on port 3000.

In the second window run:
```
dist/build/test-warp-wai/test-warp-wai
```
which has two main threads, the first of which uses `http-conduit` to query the
HTTPS server started in the first window. The second thread (which deliberately
starts some time later) runs a trvially simple HTTP server. When it starts it
will print the message "Warp server running on port 2000."

When the "Warp server running on port 2000." message appears, int the third
window, run the shell script:
```
./hammer-continuous.sh
```
which uses `wget` to query the HTTP server running on port 2000.

# Results

With the above setup using version `0.2.6` or `0.2.7` of the `conection`
library, everything seems fine but then after a minute or two the
`hammer-continuous.sh` shell script will fail with:
```
Wget connection fail. Exiting.
```
and the `test-warp-wai` program terminate after printing:
```
accept: resource exhausted (Too many open files)
```

If instead the programs are all built with version `0.2.5` of the `connection`
library, no problem will be reported even after an hour or running.
