nginx catches almost everything:

- pi4

- small payload

- network limiting factor

```shell
❯ wrk -t6 -c100000 -d30s -H 'x-token: ...' http://192.168.0.45:80/backend?query=%7Bme%20%7Bid%7D%7D

  6 threads and 100000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   157.55ms  124.80ms   1.99s    88.01%
    Req/Sec     1.28k   837.67     3.98k    64.37%
  180448 requests in 30.12s, 95.34MB read
  Socket errors: connect 98981, read 0, write 0, timeout 142
Requests/sec:   5991.82
Transfer/sec:      3.17MB
```

vs comparable rust barebone over the network server:

(pressure is on the network)

```shell
❯ wrk -t2 -c200000 -d30s  http://192.168.0.45:80
Running 30s test @ http://192.168.0.45:80
  2 threads and 200000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    55.07ms  220.01ms   1.99s    95.28%
    Req/Sec     1.29k     2.24k   12.61k    91.93%
  66165 requests in 30.15s, 20.21MB read
  Socket errors: connect 198981, read 0, write 0, timeout 471
  Non-2xx or 3xx responses: 62736
Requests/sec:   2194.63
Transfer/sec:    686.47KB