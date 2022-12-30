# Logging format and Sentry

Always pass args when logging as message, rather than using string formatting.
That is, instead of:

``` python
logging.info(f"Some interesting variable: {var}")
logging.info("Some interesting variable: %s" % var)
```

Use:

``` python
logging.info("Some interesting variable: %s", var)
```

This can be enforced with
[`flake8-logging-format`](https://pypi.org/project/flake8-logging-format/)

There are two reasons for this

## Performance

When logging with args
([docs](https://docs.python.org/3/howto/logging.html#optimization)):

> Formatting of message arguments is deferred until it cannot be avoided

However, when using explicit formatting, this will always be executed. Consider
the following:

``` python
import logging
import sys

logging.basicConfig(level=int(sys.argv[1]))

class SomeObject:
    def __str__(self) -> str:
        print("Some expensive computation")
        return hex(id(self))

obj = SomeObject()

logging.info(f"Info with formatted string: {obj}")
logging.info(f"Info with logging args: %s", obj)
```

If we run this script at log level `WARNING` (i.e. `30`) we expect no messages
to be logged:

``` console
$ python logging_example.py 30
Some expensive computation
```

We see nothing was logged, but the message from the object's `__str__` method
was printed all the same, due to the formatted message. Compare with running
this script at the `INFO` level:

``` console
$ python logging_example.py 20
Some expensive computation
INFO:root:Info with formatted string: 0x7fcde3b217d0
Some expensive computation
INFO:root:Info with logging args: 0x7fcde3b217d0
```

## Grouping log messages

Tools like Sentry can easily group messages according to the log message, so two
calls like `logger.warning("Some value: %s", val)` will be grouped together
regardless of the value of `val`, however to calls like `logger.warning(f"Some
value: {val}")` will not be grouped.

As an example consider the following:

``` python
import logging

def with_formatted_log(foo: str, bar: str) -> None:
    logging.warning(f"Bad foo: {foo} and bar {bar}")

def with_logging_args(foo: str, bar: str) -> None:
    logging.warning("Bad foo: %s and bar: %s", foo, bar)

with_formatted_logs("first attempt", "goes here")
with_formatted_log("this is the second", "attempt")
with_logging_args("now with logging args", "this should be grouped with the next")
with_logigng_args("again with logging args", "grouped?")
```

Running this under Sentry, locally we see the expected output:

``` console
$ python grouping_example.py
WARNING:root:Bad foo: first attempt and bar goes here
WARNING:root:Bad foo: this is the second and bar attempt
WARNING:root:Bad foo: now with logging args and bar: this should be grouped with the next
WARNING:root:Bad foo: again with logging args and bar: grouped?
```

But in Sentry this produced:

  - A Sentry issue with one event with message: "Bad foo: first attempt and bar
    goes here"
  - A Sentry issue with one event with message: "Bad foo: this is the second and
    bar attempt"
  - A Sentry issue with two events with messages:
      - "Bad foo: now with logging args and bar: this should be grouped with the
        next"
      - "Bad foo: again with logging args and bar: grouped?"
