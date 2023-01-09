# Python

## Typing

### Be general with parameters

Consider:

``` python
def do_some_sum(data: list[int]) -> int:
    # sum the data in some way and return the result

do_some_sum([1,2,3])    # ok
do_some_sum((1,2,3))    # fail: tuple not list
do_some_sum(range(10))  # fail: range not list
```

The function works fine for all calls above, but the type checker will complain.
Compare with:

``` python
from collections.abc import Iterable

def do_some_sum(data: Iterable[int]) -> int;
    # sum the data in some way and return the result

do_some_sum([1,2,3])    # ok
do_some_sum((1,2,3))    # ok
do_some_sum(range(10))  # ok
```
