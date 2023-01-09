# HTTP/1.1 Request

In one terminal:

``` console
$ sudo tcpdump -i wlp3s0 -s 65536 -w http_example.cap
```

In another:

``` console
$ curl -sv -H 'connection: close' -o /dev/null http://www.example.com
*   Trying 93.184.216.34:80...
* Connected to www.example.com (93.184.216.34) port 80 (#0)
> GET / HTTP/1.1
> Host: www.example.com
> User-Agent: curl/7.85.0
> Accept: */*
> connection: close
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Accept-Ranges: bytes
< Age: 384352
< Cache-Control: max-age=604800
< Content-Type: text/html; charset=UTF-8
< Date: Sat, 22 Oct 2022 20:46:05 GMT
< Etag: "3147526947+ident"
< Expires: Sat, 29 Oct 2022 20:46:05 GMT
< Last-Modified: Thu, 17 Oct 2019 07:18:26 GMT
< Server: ECS (nyb/1D04)
< Vary: Accept-Encoding
< X-Cache: HIT
< Content-Length: 1256
< Connection: close
< 
{ [1256 bytes data]
* Closing connection 0
```

Where did we get the IP address `Trying 93.184.216.34:80...`? Let's check for
DNS lookups:

``` console
$ tshark -r http_example.cap -- udp.port == 53 
    1   0.000000 192.168.0.21 → 194.168.8.100 DNS 75 Standard query 0x798b A www.example.com
    3   0.016153 194.168.8.100 → 192.168.0.21 DNS 91 Standard query response 0x798b A www.example.com A 93.184.216.34
```

Let's look at the response:

``` console
$ tshark -T fields -e dns.a -r http_example.cap -- udp.port == 53 and ip.src == 194.168.8.100
93.184.216.34
```

So that's where we got that.

Now let's look at and from TCP requests to and from that address:

``` console
$ tshark -r http_example.cap -- ip.src == 93.184.216.34 or ip.dst == 93.184.216.34
    2   0.000492 192.168.0.21 → 93.184.216.34 TCP 74 36852 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3534893825 TSecr=0 WS=128
    4   0.129000 93.184.216.34 → 192.168.0.21 TCP 76 80 → 36852 [SYN, ACK] Seq=0 Ack=1 Win=65535 Len=0 MSS=1460 SACK_PERM TSval=1127363737 TSecr=3534893825 WS=512
    5   0.129049 192.168.0.21 → 93.184.216.34 TCP 66 36852 → 80 [ACK] Seq=1 Ack=1 Win=64256 Len=0 TSval=3534893954 TSecr=1127363737
    6   0.129207 192.168.0.21 → 93.184.216.34 HTTP 164 GET / HTTP/1.1 
    7   0.234024 93.184.216.34 → 192.168.0.21 TCP 68 80 → 36852 [ACK] Seq=1 Ack=99 Win=65536 Len=0 TSval=1127363860 TSecr=3534893954
    8   0.239522 93.184.216.34 → 192.168.0.21 HTTP 1698 HTTP/1.1 200 OK  (text/html)
    9   0.239575 192.168.0.21 → 93.184.216.34 TCP 66 36852 → 80 [ACK] Seq=99 Ack=1633 Win=62720 Len=0 TSval=3534894064 TSecr=1127363860
   10   0.239869 192.168.0.21 → 93.184.216.34 TCP 66 36852 → 80 [FIN, ACK] Seq=99 Ack=1633 Win=64128 Len=0 TSval=3534894064 TSecr=1127363860
   11   0.251015 93.184.216.34 → 192.168.0.21 TCP 68 80 → 36852 [FIN, ACK] Seq=1633 Ack=99 Win=65536 Len=0 TSval=1127363860 TSecr=3534893954
   12   0.251101 192.168.0.21 → 93.184.216.34 TCP 66 36852 → 80 [ACK] Seq=100 Ack=1634 Win=64128 Len=0 TSval=3534894076 TSecr=1127363860
   13   0.362993 93.184.216.34 → 192.168.0.21 TCP 68 80 → 36852 [ACK] Seq=1634 Ack=100 Win=65536 Len=0 TSval=1127363976 TSecr=3534894064
```

The first 3 requests are a TCP handshake, and we expect the following to be our
HTTP request:

``` console
$ tshark -T fields -e tcp.payload -r http_example.cap -- frame.number == 6 | xxd -revert -plain
GET / HTTP/1.1
Host: www.example.com
User-Agent: curl/7.85.0
Accept: */*
connection: close

```

The server then acknowledges our request and sends a response, which we then
acknowledge. Finally we close the connection. Response from the server:

``` console
$ tshark -T fields -e tcp.payload -r http_example.cap -- frame.number == 8 | xxd -revert -plain
HTTP/1.1 200 OK
Accept-Ranges: bytes
Age: 384352
Cache-Control: max-age=604800
Content-Type: text/html; charset=UTF-8
Date: Sat, 22 Oct 2022 20:46:05 GMT
Etag: "3147526947+ident"
Expires: Sat, 29 Oct 2022 20:46:05 GMT
Last-Modified: Thu, 17 Oct 2019 07:18:26 GMT
Server: ECS (nyb/1D04)
Vary: Accept-Encoding
X-Cache: HIT
Content-Length: 1256
Connection: close

<!doctype html>
<html>
<head>
    <title>Example Domain</title>

    <meta charset="utf-8" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style type="text/css">
    body {
        background-color: #f0f0f2;
        margin: 0;
        padding: 0;
        font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
        
    }
    div {
        width: 600px;
        margin: 5em auto;
        padding: 2em;
        background-color: #fdfdff;
        border-radius: 0.5em;
        box-shadow: 2px 3px 7px 2px rgba(0,0,0,0.02);
    }
    a:link, a:visited {
        color: #38488f;
        text-decoration: none;
    }
    @media (max-width: 700px) {
        div {
            margin: 0 auto;
            width: auto;
        }
    }
    </style>    
</head>

<body>
<div>
    <h1>Example Domain</h1>
    <p>This domain is for use in illustrative examples in documents. You may use this
    domain in literature without prior coordination or asking for permission.</p>
    <p><a href="https://www.iana.org/domains/example">More information...</a></p>
</div>
</body>
</html>
```

# HTTP/1.1 Request with TLS

## Attempt 1: No secrets logged

Similar setup to before, in one console:

``` console
$ sudo tcpdump -i wlp3s0 -s 65536 -w https_example.cap
```

In another

``` console
$ curl --http1.1 -sv -H 'connection: close' -o /dev/null https://www.example.com
*   Trying 93.184.216.34:443...
* Connected to www.example.com (93.184.216.34) port 443 (#0)
* ALPN: offers http/1.1
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: none
} [5 bytes data]
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
} [512 bytes data]
* TLSv1.3 (IN), TLS handshake, Server hello (2):
{ [88 bytes data]
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
} [1 bytes data]
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
} [512 bytes data]
* TLSv1.3 (IN), TLS handshake, Server hello (2):
{ [155 bytes data]
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
{ [21 bytes data]
* TLSv1.3 (IN), TLS handshake, Certificate (11):
{ [3103 bytes data]
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
{ [264 bytes data]
* TLSv1.3 (IN), TLS handshake, Finished (20):
{ [52 bytes data]
* TLSv1.3 (OUT), TLS handshake, Finished (20):
} [52 bytes data]
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN: server accepted http/1.1
* Server certificate:
*  subject: C=US; ST=California; L=Los Angeles; O=Internet Corporation for Assigned Names and Numbers; CN=www.example.org
*  start date: Mar 14 00:00:00 2022 GMT
*  expire date: Mar 14 23:59:59 2023 GMT
*  subjectAltName: host "www.example.com" matched cert's "www.example.com"
*  issuer: C=US; O=DigiCert Inc; CN=DigiCert TLS RSA SHA256 2020 CA1
*  SSL certificate verify ok.
} [5 bytes data]
> GET / HTTP/1.1
> Host: www.example.com
> User-Agent: curl/7.85.0
> Accept: */*
> connection: close
> 
{ [5 bytes data]
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
{ [233 bytes data]
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
{ [233 bytes data]
* old SSL session ID is stale, removing
{ [5 bytes data]
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Accept-Ranges: bytes
< Age: 453352
< Cache-Control: max-age=604800
< Content-Type: text/html; charset=UTF-8
< Date: Sat, 22 Oct 2022 21:04:30 GMT
< Etag: "3147526947"
< Expires: Sat, 29 Oct 2022 21:04:30 GMT
< Last-Modified: Thu, 17 Oct 2019 07:18:26 GMT
< Server: ECS (nyb/1D1E)
< Vary: Accept-Encoding
< X-Cache: HIT
< Content-Length: 1256
< Connection: close
< 
{ [5 bytes data]
* Closing connection 0
} [5 bytes data]
* TLSv1.3 (OUT), TLS alert, close notify (256):
} [2 bytes data]
```

We can see from `curl`s output that there's a lot more going on. Let's look at
the captured packets.

Unsurprisingly, there's a DNS query yielding the same address:

``` console
 tshark -r https_example.cap -- udp.port == 53 
    1   0.000000 192.168.0.21 → 194.168.8.100 DNS 86 Standard query 0x2d59 A www.example.com OPT
    3   0.015208 194.168.8.100 → 192.168.0.21 DNS 102 Standard query response 0x2d59 A www.example.com A 93.184.216.34 OPT
```

And looking at the exchange, there's some more detail this time:

``` console
$ tshark -r https_logged_example.cap -- ip.src == 93.184.216.34 or ip.dst == 93.184.216.34
    7   0.022119 192.168.0.21 → 93.184.216.34 TCP 74 39468 → 443 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3543293514 TSecr=0 WS=128
   10   0.143746 93.184.216.34 → 192.168.0.21 TCP 76 443 → 39468 [SYN, ACK] Seq=0 Ack=1 Win=65535 Len=0 MSS=1460 SACK_PERM TSval=4005876093 TSecr=3543293514 WS=512
   11   0.143792 192.168.0.21 → 93.184.216.34 TCP 66 39468 → 443 [ACK] Seq=1 Ack=1 Win=64256 Len=0 TSval=3543293635 TSecr=4005876093
   12   0.148232 192.168.0.21 → 93.184.216.34 TLSv1 583 Client Hello
   13   0.254857 93.184.216.34 → 192.168.0.21 TCP 68 443 → 39468 [ACK] Seq=1 Ack=518 Win=67072 Len=0 TSval=4005876222 TSecr=3543293640
   14   0.255399 93.184.216.34 → 192.168.0.21 TLSv1.3 165 Hello Retry Request, Change Cipher Spec
   15   0.255417 192.168.0.21 → 93.184.216.34 TCP 66 39468 → 443 [ACK] Seq=518 Ack=100 Win=64256 Len=0 TSval=3543293747 TSecr=4005876222
   16   0.255797 192.168.0.21 → 93.184.216.34 TLSv1.3 589 Change Cipher Spec, Client Hello
   17   0.371695 93.184.216.34 → 192.168.0.21 TCP 68 443 → 39468 [ACK] Seq=100 Ack=1041 Win=68096 Len=0 TSval=4005876336 TSecr=3543293747
   18   0.372375 93.184.216.34 → 192.168.0.21 TLSv1.3 2962 Server Hello, Application Data
   19   0.372385 93.184.216.34 → 192.168.0.21 TLSv1.3 858 Application Data, Application Data, Application Data
   20   0.372455 192.168.0.21 → 93.184.216.34 TCP 66 39468 → 443 [ACK] Seq=1041 Ack=3788 Win=60672 Len=0 TSval=3543293864 TSecr=4005876337
   21   0.373115 192.168.0.21 → 93.184.216.34 TLSv1.3 140 Application Data
   22   0.373269 192.168.0.21 → 93.184.216.34 TLSv1.3 186 Application Data
   23   0.474505 93.184.216.34 → 192.168.0.21 TCP 68 443 → 39468 [ACK] Seq=3788 Ack=1115 Win=68096 Len=0 TSval=4005876441 TSecr=3543293865
   24   0.474536 93.184.216.34 → 192.168.0.21 TCP 68 443 → 39468 [ACK] Seq=3788 Ack=1235 Win=68096 Len=0 TSval=4005876442 TSecr=3543293865
   25   0.474541 93.184.216.34 → 192.168.0.21 TLSv1.3 321 Application Data
   26   0.474549 93.184.216.34 → 192.168.0.21 TLSv1.3 321 Application Data
   27   0.474753 93.184.216.34 → 192.168.0.21 TLSv1.3 1736 Application Data, Application Data
   28   0.474845 192.168.0.21 → 93.184.216.34 TCP 66 39468 → 443 [ACK] Seq=1235 Ack=5968 Win=61952 Len=0 TSval=3543293966 TSecr=4005876442
   29   0.475269 192.168.0.21 → 93.184.216.34 TLSv1.3 90 Application Data
   30   0.476245 192.168.0.21 → 93.184.216.34 TCP 66 39468 → 443 [FIN, ACK] Seq=1259 Ack=5968 Win=64128 Len=0 TSval=3543293968 TSecr=4005876442
   31   0.486294 93.184.216.34 → 192.168.0.21 TLSv1.3 92 Application Data
   32   0.486416 192.168.0.21 → 93.184.216.34 TCP 54 39468 → 443 [RST] Seq=1235 Win=0 Len=0
   33   0.486452 93.184.216.34 → 192.168.0.21 TCP 68 443 → 39468 [FIN, ACK] Seq=5992 Ack=1235 Win=68096 Len=0 TSval=4005876442 TSecr=3543293865
   34   0.486466 192.168.0.21 → 93.184.216.34 TCP 54 39468 → 443 [RST] Seq=1235 Win=0 Len=0
   35   0.594929 93.184.216.34 → 192.168.0.21 TCP 68 443 → 39468 [ACK] Seq=5993 Ack=1260 Win=68096 Len=0 TSval=4005876548 TSecr=3543293967
   36   0.594966 192.168.0.21 → 93.184.216.34 TCP 54 39468 → 443 [RST] Seq=1260 Win=0 Len=0
```

Though if we try to inspect any of the data transferred we won't have much luck,
since it's encrypted, for example the 6th frame's payload appears to be
nonsense:

``` console
$ tshark -T fields -e tcp.payload -r https_example.cap -- frame.number == 8 
1603030058020000540303cf21ad74e59a6111be1d8c021e65b891c2a211167abb8c5e079e09e2c8a8339c2029180b0272ffd901d32b214cb2aae9d98f0f54b68f3c4d8b6f79a0f3c27e7869130200000c002b00020304003300020017140303000101
```

Instead, we'll instruct `curl` to dump TLS secrets and `tshark` can then use to
decrypt these.

## Attempt 2: Logging secrets

Setting up again:

``` console
$ sudo tcpdump -i wlp3s0 -s 65536 -w https_logged_example.cap
```

``` console
$ SSLKEYLOGFILE=sslkey.log curl --http1.1 -sv -H 'connection: close' -o /dev/null https://www.example.com
```

Then if we set the `tls.keylog_file` option in `tshark` we can view the
decrypted flow:

``` console
$ tshark -o tls.keylog_file:sslkey.log -r https_logged_example.cap 
    1   0.000000 192.168.0.21 → 194.168.4.100 DNS 86 Standard query 0x1b1d A www.example.com OPT
    2   0.000040 192.168.0.21 → 194.168.4.100 DNS 86 Standard query 0x7ef6 AAAA www.example.com OPT
    3   0.000291 192.168.0.21 → 93.184.216.34 TCP 74 36478 → 443 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3545630647 TSecr=0 WS=128
    4   0.012888 194.168.4.100 → 192.168.0.21 DNS 102 Standard query response 0x1b1d A www.example.com A 93.184.216.34 OPT
    5   0.018549 194.168.4.100 → 192.168.0.21 DNS 114 Standard query response 0x7ef6 AAAA www.example.com AAAA 2606:2800:220:1:248:1893:25c8:1946 OPT
    6   0.121631 93.184.216.34 → 192.168.0.21 TCP 76 443 → 36478 [SYN, ACK] Seq=0 Ack=1 Win=65535 Len=0 MSS=1460 SACK_PERM TSval=924226306 TSecr=3545630647 WS=512
    7   0.121721 192.168.0.21 → 93.184.216.34 TCP 66 36478 → 443 [ACK] Seq=1 Ack=1 Win=64256 Len=0 TSval=3545630769 TSecr=924226306
    8   0.126042 192.168.0.21 → 93.184.216.34 TLSv1 583 Client Hello
    9   0.151150 192.168.0.21 → 13.248.212.111 TLSv1.2 127 Application Data
   10   0.186025 13.248.212.111 → 192.168.0.21 TCP 68 443 → 40368 [ACK] Seq=1 Ack=62 Win=265 Len=0 TSval=3287691817 TSecr=2471744947
   11   0.229657 93.184.216.34 → 192.168.0.21 TCP 68 443 → 36478 [ACK] Seq=1 Ack=518 Win=67072 Len=0 TSval=924226429 TSecr=3545630773
   12   0.229682 93.184.216.34 → 192.168.0.21 TLSv1.3 165 Hello Retry Request, Change Cipher Spec
   13   0.229700 192.168.0.21 → 93.184.216.34 TCP 66 36478 → 443 [ACK] Seq=518 Ack=100 Win=64256 Len=0 TSval=3545630877 TSecr=924226429
   14   0.230130 192.168.0.21 → 93.184.216.34 TLSv1.3 589 Change Cipher Spec, Client Hello
   15   0.250371 13.248.212.111 → 192.168.0.21 TLSv1.2 219 Application Data
   16   0.250401 192.168.0.21 → 13.248.212.111 TCP 66 40368 → 443 [ACK] Seq=62 Ack=154 Win=500 Len=0 TSval=2471745046 TSecr=3287691894
   17   0.330492 93.184.216.34 → 192.168.0.21 TCP 68 443 → 36478 [ACK] Seq=100 Ack=1041 Win=68096 Len=0 TSval=924226529 TSecr=3545630877
   18   0.332361 93.184.216.34 → 192.168.0.21 TLSv1.3 2962 Server Hello, Encrypted Extensions
   19   0.332402 93.184.216.34 → 192.168.0.21 TLSv1.3 858 Certificate, Certificate Verify, Finished
   20   0.332471 192.168.0.21 → 93.184.216.34 TCP 66 36478 → 443 [ACK] Seq=1041 Ack=3788 Win=60672 Len=0 TSval=3545630979 TSecr=924226531
   21   0.333592 192.168.0.21 → 93.184.216.34 TLSv1.3 140 Finished
   22   0.333842 192.168.0.21 → 93.184.216.34 HTTP 186 GET / HTTP/1.1 
   23   0.435298 93.184.216.34 → 192.168.0.21 TCP 68 443 → 36478 [ACK] Seq=3788 Ack=1115 Win=68096 Len=0 TSval=924226635 TSecr=3545630980
   24   0.435326 93.184.216.34 → 192.168.0.21 TCP 68 443 → 36478 [ACK] Seq=3788 Ack=1235 Win=68096 Len=0 TSval=924226635 TSecr=3545630981
   25   0.435330 93.184.216.34 → 192.168.0.21 TLSv1.3 321 New Session Ticket
   26   0.435337 93.184.216.34 → 192.168.0.21 TLSv1.3 321 New Session Ticket
   27   0.435628 192.168.0.21 → 93.184.216.34 TCP 66 36478 → 443 [ACK] Seq=1235 Ack=4298 Win=64128 Len=0 TSval=3545631082 TSecr=924226635
   28   0.436469 93.184.216.34 → 192.168.0.21 TLSv1.3 1514 [TLS segment of a reassembled PDU]
   29   0.437725 93.184.216.34 → 192.168.0.21 HTTP 272 HTTP/1.1 200 OK  (text/html)
   30   0.437802 192.168.0.21 → 93.184.216.34 TCP 66 36478 → 443 [ACK] Seq=1235 Ack=5952 Win=64128 Len=0 TSval=3545631085 TSecr=924226635
   31   0.437891 192.168.0.21 → 93.184.216.34 TLSv1.3 90 Alert (Level: Warning, Description: Close Notify)
   32   0.438547 192.168.0.21 → 93.184.216.34 TCP 66 36478 → 443 [FIN, ACK] Seq=1259 Ack=5952 Win=64128 Len=0 TSval=3545631085 TSecr=924226635
   33   0.449063 93.184.216.34 → 192.168.0.21 TLSv1.3 92 Alert (Level: Warning, Description: Close Notify)
   34   0.449106 192.168.0.21 → 93.184.216.34 TCP 54 36478 → 443 [RST] Seq=1235 Win=0 Len=0
   35   0.449118 93.184.216.34 → 192.168.0.21 TCP 68 443 → 36478 [FIN, ACK] Seq=5976 Ack=1235 Win=68096 Len=0 TSval=924226635 TSecr=3545630981
   36   0.449126 192.168.0.21 → 93.184.216.34 TCP 54 36478 → 443 [RST] Seq=1235 Win=0 Len=0
   37   0.557425 93.184.216.34 → 192.168.0.21 TCP 68 443 → 36478 [ACK] Seq=5977 Ack=1260 Win=68096 Len=0 TSval=924226741 TSecr=3545631085
   38   0.557463 192.168.0.21 → 93.184.216.34 TCP 54 36478 → 443 [RST] Seq=1260 Win=0 Len=0
   39   0.696640 192.168.0.21 → 194.242.2.2  DNS 59 Standard query 0xe430 A <Root>
   40   0.699300 162.254.196.68 → 192.168.0.21 TLSv1.2 459 Application Data
   41   0.699351 192.168.0.21 → 162.254.196.68 TCP 54 43729 → 27025 [ACK] Seq=1 Ack=406 Win=32160 Len=0
   42   0.724555  194.242.2.2 → 192.168.0.21 ICMP 87 Destination unreachable (Port unreachable)
   43   0.791978 162.254.196.68 → 192.168.0.21 TLSv1.2 458 Application Data
   44   0.792008 192.168.0.21 → 162.254.196.68 TCP 54 43729 → 27025 [ACK] Seq=1 Ack=810 Win=32160 Len=0
```

Inspecting the response at frame 29:

``` console
$ tshark -o tls.keylog_file:sslkey.log -T fields -e http.file_data -r https_logged_example.cap -- frame.number == 29 | sed 's/\\n/\n/g'
<!doctype html>
<html>
<head>
    <title>Example Domain</title>

    <meta charset="utf-8" />
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style type="text/css">
    body {
        background-color: #f0f0f2;
        margin: 0;
        padding: 0;
        font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
        
    }
    div {
        width: 600px;
        margin: 5em auto;
        padding: 2em;
        background-color: #fdfdff;
        border-radius: 0.5em;
        box-shadow: 2px 3px 7px 2px rgba(0,0,0,0.02);
    }
    a:link, a:visited {
        color: #38488f;
        text-decoration: none;
    }
    @media (max-width: 700px) {
        div {
            margin: 0 auto;
            width: auto;
        }
    }
    </style>    
</head>

<body>
<div>
    <h1>Example Domain</h1>
    <p>This domain is for use in illustrative examples in documents. You may use this
    domain in literature without prior coordination or asking for permission.</p>
    <p><a href="https://www.iana.org/domains/example">More information...</a></p>
</div>
</body>
</html>
```
