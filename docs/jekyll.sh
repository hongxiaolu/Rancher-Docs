#!/bin/sh
docker run --rm -ti -p 4000:4000 -v  $PWD:/home/site  registry.cn-shenzhen.aliyuncs.com/rancher_cn/rancher-docs:base jekyll  clean
docker run --rm -ti -p 4000:4000 -v  $PWD:/home/site  registry.cn-shenzhen.aliyuncs.com/rancher_cn/rancher-docs:base jekyll s w -H 0.0.0.0
