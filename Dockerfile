FROM ruby:2.4.2
RUN apt-get update && apt-get upgrade -y && apt-get install  nginx && mkdir /data
#COPY nginx.conf /etc/nginx/
ADD  docs  /data
RUN cd /data/docs \
    && gem install bundler --pre \
    && bundle install 
    && jekyll build --destination /var/www/html/  \
    && rm -rf /data/docs  && apt-get autoremove && apt-get clean
EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]