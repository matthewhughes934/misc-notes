# Test speed

Some notes on test speed in Go, and how to speed things up

## `-race`

Testing with the race detector adds 1 second of sleep to every package tested
(see [issue](https://github.com/golang/go/issues/20364)). A naive count of
testable packages in your module can be given by something like:

    $ go list -json ./... | jq --raw-output 'select((.TestGoFiles | length > 0) or (.XTestGoFiles | length > 0)) | .ImportPath' | wc --lines

Which will be the *minimum* run time for your tests (in seconds) if you run with
the `-race` flag and standard option
