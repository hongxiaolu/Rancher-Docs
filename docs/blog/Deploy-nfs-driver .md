---
typora-copy-images-to: ./img
typora-root-url: ./img
---

NFS卷驱动插件是什么就不再叙述，直接上步骤。

## 一、NFS服务端配置

```
实验环境：Ubuntu16.04 、Rancherv1.5.10 、 rancher/storage-nfs:v0.6.5
```

1. NFS服务器安装

   apt-get install nfs-kernel-server -y


2. 在/etc/exports最后添加NFS共享路径，例如： /home/nfs  *(rw,sync,no_root_squash,no_subtree_check)
3. 3.配置NFS服务端开机启动，并重启host:   systemctl enable nfs-blkmap.target && reboot
4. 本机测试NFS服务器连通性：mount -t nfs 远程IP:/远程路径  /local路径

## 二、NFS驱动卷安装配置

在应用商店（catalog）中搜索NFS，接着点击VIEW Details 进入配置详情页。![img](https://www.xtplayer.cn/wp-content/uploads/2017/06/11111111111-1.png)

[![img](https://www.xtplayer.cn/wp-content/uploads/2017/06/1111111-1.png)](https://www.xtplayer.cn/wp-content/uploads/2017/06/1111111-1.png)

NFS  Server ：NFS服务器的IP地址，端口默认2049；

Mount Dirctory:NFS配置的共享存储路径；

MoutOptions: 默认可以不用填，如果server端口有变动，可以在这里通过 port=2049 来指定新端口；

NFS Version:默认4版本；

最后点击launch，接着会自动跳转到应用栈（stack）页面。参考链接：http://rancher.com/setting-shared-volumes-convoy-nfs/

[![img](https://www.xtplayer.cn/wp-content/uploads/2017/06/5.png)](https://www.xtplayer.cn/wp-content/uploads/2017/06/5.png)

## 三、配置应用调用驱动卷

在STACKE中添加一个空的stack, 并点击ADD Service. 我创建了一个名为test的应用栈并添加了两个应用实例。配置如图：[![img](https://www.xtplayer.cn/wp-content/uploads/2017/06/1.png)](https://www.xtplayer.cn/wp-content/uploads/2017/06/1.png)[![img](https://www.xtplayer.cn/wp-content/uploads/2017/06/2.png)](https://www.xtplayer.cn/wp-content/uploads/2017/06/2.png)

注意：在配置选项 卷 中，第一个卷书写格式为 卷名（volumename）：容器内路径。

下面卷驱动填写rancher-nfs，最后点击创建。