---
title: 创建集群
---



> 安装注意：
>
> 如果你当前节点曾经安装过Rancher 2.0,那需要进行初始化：
>
> docker rm -fv $(docker ps -aq) 
>
> docker volume rm  $(docker volume ls) 
>
> rm -rf /etc/kubernetes/
>
> rm -rf /var/lib/rancher/
>
> rm -rf /var/lib/etcd/