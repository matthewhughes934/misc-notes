# Diagnosing slow Pytest startup

On a project at work I found even basic tests would take an unusual amount of
time (most of this appeared during setup, as the test run itself was quick)
e.g.:

``` console
$ cat test.py
def test_foo():
    assert True
$ time pytest test.py >/dev/null
real    0m4.484s
user    0m2.285s
sys    0m0.196s
```

I profiled using Python [standard library's profile
tools](https://docs.python.org/3/library/profile.html) First, profiling the test
using
[`cProfile`](https://docs.python.org/3/library/profile.html#module-cProfile):

``` console
$ python -m cProfile --outfile log.pstats /opt/venv/bin/pytest test.py
```

Then inspecting the result using
[`pstats`](https://docs.python.org/3/library/profile.html#module-pstats)

``` console
$ python -m pstats log.pstats
```

    Welcome to the profile statistics browser.
    log.pstats% sort tottime
    log.pstats% stats 1
    Thu Jun 30 09:57:59 2022    log.pstats
    
             4070271 function calls (3950247 primitive calls) in 4.735 seconds
    
       Ordered by: internal time
       List reduced from 15335 to 1 due to restriction <1>
    
       ncalls  tottime  percall  cumtime  percall filename:lineno(function)
            2    2.002    1.001    2.002    1.001 {method 'connect' of '_socket.socket' objects}

So something was trying to connect over a socket, probably a network request
that was timing out. We can use `strace` to show any connect `syscalls`:

``` console
$ strace -e trace=connect pytest test.py >/dev/null
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=507, si_uid=0, si_status=0, si_utime=0, si_stime=0} ---
connect(8, {sa_family=AF_INET, sin_port=htons(80), sin_addr=inet_addr("169.254.169.254")}, 16) = -1 EINPROGRESS (Operation now in progress)
connect(8, {sa_family=AF_INET, sin_port=htons(80), sin_addr=inet_addr("169.254.169.254")}, 16) = -1 EINPROGRESS (Operation now in progress)
```

`169.254.169.254` is the address [used by AWS to query EC2 instance
metadata](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html),
which `boto3` [will query if credentials can't be found
elsewhere](https://boto3.amazonaws.com/v1/documentation/api/1.18.3/guide/credentials.html#configuring-credentials),
specifically from those docs: reading from the environment should take
precedence over the metadata query (note: since we don't do anything with this
client the credentials don't need to be valid), which cuts down the startup
time:

``` console
$ time AWS_ACCESS_KEY_ID=foo AWS_SECRET_ACCESS_KEY=bar pytest test.py >/dev/null

real        0m2.320s
user        0m2.139s
sys 0m0.179s
```

This was occurring because a `boto3` session object was being created in the
global scope off a module that was imported at `pytest` startup time via
`conftest.py`
