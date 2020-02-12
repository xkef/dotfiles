stip-uat-test.westeurope.cloudapp.azure.com
https://umbrella.cisco.com/blog/2015/11/03/lets-talk-about-proxies-pt-2-nginx-as-a-forward-http-proxy/

---


https://daniel.haxx.se/docs/sshproxy.html

If you cannot find any useful port or if CONNECT is not allowed at all,
you need to establish a tunnel using normal HTTP, using for example
httptunnel. httptunnel is a client/server application, and you want the
server ("hts") to run on your home computer, listening on port 80, and
you run the client ("htc") on your work computer setting up the tunnel.

on adecco:

- ProxyCommand /usr/local/bin/corkscrew 40.114.208.54 443 %h %p
- ssh -D 80 frontend-user@stip-uat-test.westeurope.cloudapp.azure.com -p 443

---

tcp   ESTAB  0       0                                        10.0.0.7:35316                                 169.254.169.254:http
tcp   ESTAB  0       0                                        10.0.0.7:48554                                   52.71.178.162:https
tcp   ESTAB  0       36                                       10.0.0.7:ssh                                     31.10.136.160:57134
(END)

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    # include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         /var/www/sti-uat.adecco.net;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {

         index index.html index.htm index.php;
        }
         location /backend {

            proxy_pass http://10.204.97.49:8000/backend;
            # include snippets/proxy.conf;
        }
        location /verification {

            proxy_pass http://10.204.97.49:8000/verification;
            # proxy_http_version 1.1;
            #proxy_cache_bypass $http_upgrade;
        }
   }
}
