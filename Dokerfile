FROM ruby:alpine
RUN apk add --no-cache nginx && rm -rf  /etc/nginx/nginx.conf && mkdir /data/site
COPY nginx.conf /etc/nginx/
COPY  docs  /data/docs/
RUN cd /data/docs && bundle install && jekyll build --destination /data/site && rm -rf /data/docs
EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]