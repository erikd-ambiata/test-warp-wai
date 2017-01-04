test-warp-wai
-------------

This is a repo containing code to reproduce and extremely odd bug in Haskell's
Warp, Wai of http-conduit libraries.

This has been tested with both ghc 7.10.3 and ghc 8.0.1.

# Reproduction

I'm assuming that this will be reproduced on Linux, but it should probably also
work on OSX. I'm also assuming that you have `wget` and `hexdump` installed.

Clone this repo and the change into the freshly cloned source tree and do:

* `git submodule update --init --recursive`
* `cabal sandbox init`
* `cabal sandbox add-source hs-connection`
* `cabal install --dependencies-only`
* `cabal build`

You will now need four more terminal windows and you will need to change into
the above source directory in all of them.

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

When the "Warp server running on port 2000." message appear, in each of the
remaining three (or more) windows, run the shell script:
```
./hammer-continuous.sh
```
which uses `wget` to query the HTTP server running on port 2000.

# Results

With the above setup, as soon as the first `hammer-continuous.sh` shell script
is run, the `dummy-https-server` process will start reporting:
```
HandshakeFailed (Error_Packet_Parsing "Failed reading: cannot decode alert level\nFrom:\talerts\n\n")
```
and the HTTPS client will report:
```
ConnectionFailure sendBuf: resource vanished (Broken pipe)
```
but everything keeps running until one of these things happens:

* The `test-warp-wai` process runs out of file descriptors which will caise the
  `hammer-continuous.sh` scripts to terminate. When this happens the
  `test-warp-wai` should be stopped and then restarted and when the "Warp server
  running on port 2000." message appears, the three `hammer-continuous.sh` scripts
  should be restarted.

* One or more of the three `hammer-continuous.sh` scripts will print something
  like the following and terminate.
  ```
�v����_"͏HTTP/1.1 200 OK
Transfer-Encoding: chunked
Date: Wed, 31 Aug 2016 02:54:34 GMT
Server: Warp/3.2.8
Content-Type: text/plain

001C
HTTP: What's that function?

0


00000000  15 03 03 00 1a 00 00 00  00 00 00 00 05 b5 cd b1  |................|
00000010  0d f1 1f 19 10 76 ff 07  90 9a 89 5f 22 cd 8f 48  |.....v....._"..H|
00000020  54 54 50 2f 31 2e 31 20  32 30 30 20 4f 4b 0d 0a  |TTP/1.1 200 OK..|
00000030  54 72 61 6e 73 66 65 72  2d 45 6e 63 6f 64 69 6e  |Transfer-Encodin|
00000040  67 3a 20 63 68 75 6e 6b  65 64 0d 0a 44 61 74 65  |g: chunked..Date|
00000050  3a 20 57 65 64 2c 20 33  31 20 41 75 67 20 32 30  |: Wed, 31 Aug 20|
00000060  31 36 20 30 32 3a 35 34  3a 33 34 20 47 4d 54 0d  |16 02:54:34 GMT.|
00000070  0a 53 65 72 76 65 72 3a  20 57 61 72 70 2f 33 2e  |.Server: Warp/3.|
00000080  32 2e 38 0d 0a 43 6f 6e  74 65 6e 74 2d 54 79 70  |2.8..Content-Typ|
00000090  65 3a 20 74 65 78 74 2f  70 6c 61 69 6e 0d 0a 0d  |e: text/plain...|
000000a0  0a 30 30 31 43 0d 0a 48  54 54 50 3a 20 57 68 61  |.001C..HTTP: Wha|
000000b0  74 27 73 20 74 68 61 74  20 66 75 6e 63 74 69 6f  |t's that functio|
000000c0  6e 3f 0a 0d 0a 30 0d 0a  0d 0a                    |n?...0....|
000000ca
```

Its this second failure that is interesting, an injection of a TLS alert packet
into what should have been a HTTP response.


