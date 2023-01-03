# Golang DNS issue

Trying to build from <https://aur.archlinux.org/packages/heroic-games-launcher>
is failing for me:

``` console
$ makepkg --syncdeps .
<--- SNIP --->
build/electron/preload.js   10.33 KiB / gzip: 2.73 KiB
  • electron-builder  version=23.6.0 os=5.15.85-1-lts
  • loaded configuration  file=package.json ("build" field)
  • writing effective config  file=dist/builder-effective-config.yaml
  • rebuilding native dependencies  dependencies=register-scheme@0.0.2 platform=linux arch=x64
  • rebuilding native dependency  name=register-scheme version=0.0.2
  • packaging       platform=linux arch=x64 electron=21.2.1 appOutDir=dist/linux-unpacked
  ⨯ Get "https://github.com/electron/electron/releases/download/v21.2.1/electron-v21.2.1-linux-x64.zip": dial tcp: lookup github.com on [::1]:53: read udp [::1]:60445->[::1]:53: read: connection refused
github.com/develar/app-builder/pkg/download.(*Downloader).follow.func1
	/Volumes/data/Documents/app-builder/pkg/download/downloader.go:206
github.com/develar/app-builder/pkg/download.(*Downloader).follow
	/Volumes/data/Documents/app-builder/pkg/download/downloader.go:234
github.com/develar/app-builder/pkg/download.(*Downloader).DownloadNoRetry
	/Volumes/data/Documents/app-builder/pkg/download/downloader.go:128
github.com/develar/app-builder/pkg/download.(*Downloader).Download
	/Volumes/data/Documents/app-builder/pkg/download/downloader.go:112
github.com/develar/app-builder/pkg/electron.(*ElectronDownloader).doDownload
	/Volumes/data/Documents/app-builder/pkg/electron/electronDownloader.go:192
github.com/develar/app-builder/pkg/electron.(*ElectronDownloader).Download
	/Volumes/data/Documents/app-builder/pkg/electron/electronDownloader.go:177
github.com/develar/app-builder/pkg/electron.downloadElectron.func1.1
	/Volumes/data/Documents/app-builder/pkg/electron/electronDownloader.go:73
github.com/develar/app-builder/pkg/util.MapAsyncConcurrency.func2
	/Volumes/data/Documents/app-builder/pkg/util/async.go:68
runtime.goexit
	/usr/local/Cellar/go/1.17/libexec/src/runtime/asm_amd64.s:1581
  ⨯ /home/mjh/src/aurs/heroic-games-launcher/src/HeroicGamesLauncher/node_modules/app-builder-bin/linux/x64/app-builder process failed ERR_ELECTRON_BUILDER_CANNOT_EXECUTE
Exit code:
1  failedTask=build stackTrace=Error: /home/mjh/src/aurs/heroic-games-launcher/src/HeroicGamesLauncher/node_modules/app-builder-bin/linux/x64/app-builder process failed ERR_ELECTRON_BUILDER_CANNOT_EXECUTE
Exit code:
1
    at ChildProcess.<anonymous> (/home/mjh/src/aurs/heroic-games-launcher/src/HeroicGamesLauncher/node_modules/builder-util/src/util.ts:250:14)
    at Object.onceWrapper (node:events:628:26)
    at ChildProcess.emit (node:events:513:28)
    at maybeClose (node:internal/child_process:1098:16)
    at Process.ChildProcess._handle.onexit (node:internal/child_process:304:5)
error Command failed with exit code 1.
info Visit https://yarnpkg.com/en/docs/cli/run for documentation about this command.
==> ERROR: A failure occurred in build().
    Aborting...
```

Inspecting with `strace`, there is lots of `fork`/`clone`ing so combine merge
the logs to get a nice view:

    $ strace --absolute-timestamps --output-separately --follow-forks --output strace.log --string-limit=1000 -- makepkg --syncdeps .
    $ strace-log-merge strace.log > merged.log

Looking around for an `ECONNREFUSED` there is:

    12838 14:22:57 socket(AF_INET, SOCK_DGRAM|SOCK_CLOEXEC|SOCK_NONBLOCK, IPPROTO_IP) = 7
    12838 14:22:57 setsockopt(7, SOL_SOCKET, SO_BROADCAST, [1], 4) = 0
    12838 14:22:57 connect(7, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("127.0.0.1")}, 16) = 0
    12838 14:22:57 epoll_ctl(3, EPOLL_CTL_ADD, 7, {events=EPOLLIN|EPOLLOUT|EPOLLRDHUP|EPOLLET, data={u32=3435363976, u64=139937764834952}}) = 0
    12838 14:22:57 getsockname(7, {sa_family=AF_INET, sin_port=htons(49083), sin_addr=inet_addr("127.0.0.1")}, [112 => 16]) = 0
    12838 14:22:57 getpeername(7, {sa_family=AF_INET, sin_port=htons(53), sin_addr=inet_addr("127.0.0.1")}, [112 => 16]) = 0
    12838 14:22:57 clock_gettime(CLOCK_MONOTONIC, {tv_sec=1991, tv_nsec=856085738}) = 0
    12838 14:22:57 clock_gettime(CLOCK_MONOTONIC, {tv_sec=1991, tv_nsec=856107529}) = 0
    12838 14:22:57 clock_gettime(CLOCK_MONOTONIC, {tv_sec=1991, tv_nsec=856149155}) = 0
    12838 14:22:57 write(7, "\216\21\1\0\0\1\0\0\0\0\0\0\6github\3com\0\0\34\0\1", 28) = 28
    12838 14:22:57 clock_gettime(CLOCK_MONOTONIC, {tv_sec=1991, tv_nsec=856266978}) = 0
    12838 14:22:57 read(7, 0xc0002e0800, 512)     = -1 ECONNREFUSED (Connection refused)
    12838 14:22:57 epoll_ctl(3, EPOLL_CTL_DEL, 7, 0xc00033086c) = 0
    12838 14:22:57 close(7)                       = 0

It looks to be connection was refused when making a DNS request on local host
for `github.com`

Compare with a DNS lookup from `getent` which runs via systemd resolve

``` console
$ strace -e 'trace=!clock_gettime' --string-limit=1000 -- getent hosts github.com
<--- SNIP --->
socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 3
connect(3, {sa_family=AF_UNIX, sun_path="/run/systemd/resolve/io.systemd.Resolve"}, 42) = 0
sendto(3, "{\"method\":\"io.systemd.Resolve.ResolveHostname\",\"parameters\":{\"name\":\"github.com\",\"family\":2,\"flags\":0}}\0", 104, MSG_DONTWAIT|MSG_NOSIGNAL, NULL, 0) = 104
brk(0x55f26b4ef000)                     = 0x55f26b4ef000
recvfrom(3, 0x55f26b4ae3b0, 131080, MSG_DONTWAIT, NULL, NULL) = -1 EAGAIN (Resource temporarily unavailable)
ppoll([{fd=3, events=POLLIN}], 1, {tv_sec=119, tv_nsec=999900000}, NULL, 8) = 1 ([{fd=3, revents=POLLIN}], left {tv_sec=119, tv_nsec=991839058})
recvfrom(3, "{\"parameters\":{\"addresses\":[{\"ifindex\":4,\"family\":2,\"address\":[140,82,121,4]}],\"name\":\"github.com\",\"flags\":8388609}}\0", 131080, MSG_DONTWAIT, NULL, NULL) = 117
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
close(3)                                = 0
newfstatat(1, "", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x3), ...}, AT_EMPTY_PATH) = 0
write(1, "140.82.121.4    github.com\n", 27140.82.121.4    github.com
) = 27
exit_group(0)                           = ?
+++ exited with 0 +++
```

Trying with a basic `go` program:

``` go
package main

import (
	"fmt"
	"io"
	"net/http"
)

func main() {
	resp, err := http.Get("http://github.com/")

	if err != nil {
		fmt.Printf("Get Error: %s", err)
	}

	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)

	if err != nil {
		fmt.Printf("Read Error: %s", err)
	}
	fmt.Println(body);

	fmt.Println("hello")
}
```

Which also uses `systemd.resolve`:

``` console
$ go build main.go
$ strace -e 'trace=!clock_gettime' --string-limit=1000 -- ./main
<--- SNIP --->
socket(AF_UNIX, SOCK_STREAM|SOCK_CLOEXEC|SOCK_NONBLOCK, 0) = 6
connect(6, {sa_family=AF_UNIX, sun_path="/run/systemd/resolve/io.systemd.Resolve"}, 42) = 0
sendto(6, "{\"method\":\"io.systemd.Resolve.ResolveHostname\",\"parameters\":{\"name\":\"github.com\",\"flags\":0}}\0", 93, MSG_DONTWAIT|MSG_NOSIGNAL, NULL, 0) = 93
mmap(NULL, 135168, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f4cb0193000
recvfrom(6, 0x7f4cb0193010, 135152, MSG_DONTWAIT, NULL, NULL) = -1 EAGAIN (Resource temporarily unavailable)
ppoll([{fd=6, events=POLLIN}], 1, {tv_sec=119, tv_nsec=999870000}, NULL, 8) = 1 ([{fd=6, revents=POLLIN}], left {tv_sec=119, tv_nsec=991828815})
recvfrom(6, "{\"parameters\":{\"addresses\":[{\"ifindex\":4,\"family\":2,\"address\":[140,82,121,3]}],\"name\":\"github.com\",\"flags\":9437185}}\0", 135152, MSG_DONTWAIT, NULL, NULL) = 117
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
close(6)
<--- SNIP --->
```

I worked around this by just manually setting some values in `/etc/hosts` so the
DNS could be skipped, i.e. by writing the values of working DNS lookups

``` console
$ getent hosts github.com
140.82.121.4    github.com
$ getent hosts objects.githubusercontent.com
185.199.109.133 objects.githubusercontent.com
```

To `/etc/hosts`:

``` console
$ cat /etc/hosts
# Static table lookup for hostnames.
# See hosts(5) for details.
140.82.121.4 github.com
185.199.109.133 objects.githubusercontent.com
```

I think the cause of this was an empty `/etc/resolv.conf`, adding
`nameserver 1.1.1.1` there also resolved the issue
