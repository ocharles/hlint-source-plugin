# hlint-source-plugin

This repository contains a proof-of-concept for a source plugin that calls
HLint. This means that at compilation time, HLint is called, rather than having
HLint being a separate extra compilation step.

## Example

There is an example project in [`example`](./example), which demonstrates many
coding practices that can be detected by HLint. When you compile this module,
you'll see HLint warnings:

```sh
$ cabal new-build all
Build profile: -w ghc-8.6.1.20180716 -O1
In order, the following will be built (use -v for more details):
 - example-0.1.0.0 (exe:example) (dependency rebuilt)
Preprocessing executable 'example' for example-0.1.0.0..
Building executable 'example' for example-0.1.0.0..
[1 of 1] Compiling Main             ( Main.hs, /home/ollie/work/hlint-source-plugin/dist-newstyle/build/x86_64-linux/ghc-8.6.1.20180716/example-0.1.0.0/x/example/build/example/example-tmp/Main.o ) [Plugin forced recompilation]
Main.hs:4:8: warning:
    • Redundant do
    • Why not: (putStrLn $ (show "Hello"))
  |
4 | main = do
  |        ^^...

Main.hs:4:8: warning:
    • Redundant bracket
    • Why not: do putStrLn $ (show "Hello")
  |
4 | main = do
  |        ^^...

Main.hs:5:4: warning:
    • Use print
    • Why not: print "Hello"
  |
5 |   (putStrLn $ (show "Hello"))
  |    ^^^^^^^^^^^^^^^^^^^^^^^^^

Main.hs:5:4: warning:
    • Redundant bracket
    • Why not: putStrLn $ show "Hello"
  |
5 |   (putStrLn $ (show "Hello"))
  |    ^^^^^^^^^^^^^^^^^^^^^^^^^

Main.hs:5:4: warning:
    • Redundant $
    • Why not: putStrLn (show "Hello")
  |
5 |   (putStrLn $ (show "Hello"))
  |    ^^^^^^^^^^^^^^^^^^^^^^^^^
```

Here we see that HLint has detected a redundant do, and this has been turned
into a GHC warning.

## Future Work

Currently this plugin simply hooks into the parse stage and calls HLint with a
file path. This means HLint will re-parse all source code. The next logical step
is to use the actual parse tree, as given to us by GHC, and HLint that. This
means that HLint can lose the special logic to run CPP, along with the hacky
handling of fixity resolution (we get that done correctly by GHC's renaming
phase).

This isn't hard work, just fairly tedious. Contributions welcome!
