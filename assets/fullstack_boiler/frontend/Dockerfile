FROM nginx:latest
COPY ./build /var/www/public/
COPY ./nginx/nginx.conf /etc/nginx/
VOLUME /etc/nginx
EXPOSE 80 443
ENTRYPOINT ["nginx","-g", "daemon off;"]
