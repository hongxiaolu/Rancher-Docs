---
title: 青云上部署RANCHER
---

青云简介
--------
青云是一个提供按需分配、弹性可伸缩的计算能力的公有云服务。通过使用青云，您不必再为了软件开发、测试、以及应用
	服务上线运行而购买物理设备了，也不必投入人力物力进行设备维护。您可以直接在青云中迅速得到任意您需要的计算、存	储、网络、安全等方方面面的能力，并可以随时调整它们的规模。青云执行按用量收费原则，即，您只需要为您使用了的资	源付费。而且，青云是按秒计费的，青云中的任何资源都是可以随时调整尺寸/规模的，这最大程度地降低了您的费用、并为	弹性计算提供了计费基础。

基础环境准备
------------

1.  通过访问[[https://console.qingcloud.com/]{.underline}](https://console.qingcloud.com/)登录控制台，根据需要选择区域：

	![](qinyun/image1.png)

2.  网络基础配置

	1)  路由器（Router）（有的区域叫VPC网络）

	用于受管私有网络之间互联，并提供以下附加服务：DHCP服务、端口转发、隧道服务、VPN服务和过滤控制。如果您还希望	路由器能接入互联网，请捆绑一个公网 IP给该路由器即可。
		
	![](qinyun/image2.png)

	基本属性

	![](qinyun/image3.png)

	2)  私有网络（Vxnet）

	用于主机之间互联，它类似物理世界中使用交换机（L2Switch）组成的局域网。私有网络之间是100%隔离的。

	![](qinyun/image4.png)

	3)  私有网络配置

	点击网络ID

	![](qinyun/image5.png)

	连接到已有路由器

	![](qinyun/image6.png)

	DHCP 服务为您的私有网络提供 IP
	地址分配。分配的地址都是固定地址，即一个主机在其生命周期内获得的地址是保持不变的。

	![](qinyun/image7.png)

	提交后：

	![](qinyun/image8.png)

	4)  公网IP（Elastic IP）

	互联网上合法的静态IP地址。在QingCloud系统中，公网IP地址与您的账户而非特定的资源（主机或路由器）关联，您可	以将申请到的公网
	IP地址分配到任意位于基础私有网络 vxnet-0
	中的主机或路由器，并随时可以解绑、再分配到其他主机或路由器，如此可以快速替换您的对外主机或路由器。

	为了可以通过互联网访问RANCHER
	SERVER以及其他节点可以通过互联网下载镜像，需要申请一个公网IP，点击申请：

	![](qinyun/image9.png)

	点击ID

	![](qinyun/image10.png)

	绑定到已有的路由器上

	![](qinyun/image11.png)

	基本属性

	![](qinyun/image12.png)

RANCHER 部署
------------

1.  控制台左侧点击容器平台，接着点击Rancher

	![](qinyun/image13.png)

2.  接着点击创建，点击后跳转到应用配置页面

	![](qinyun/image14.png)

3.  基本设置，可以保持默认

	![](qinyun/image15.png)

4.  Rancher server 节点设置

	![](qinyun/image16.png)

5.  Rancher agent设置

	![](qinyun/image17.png)

6.  网络设置

	![](qinyun/image18.png)

7.  点击提交后，跳转到新页面

	![](qinyun/image19.png)

8.  端口转发映射

	1)  进入 网络与CDN \| 路由器，点击端口转发

	![](qinyun/image20.png)

	2)  点击添加规则(IP地址在第九步查询)
	
	![](qinyun/image21.png)

	3)  最后点击提交并点击应用修改。

	![](qinyun/image22.png)
	
9. 防火墙配置

	1)  进入 安全 | 防火墙，点击默认防火墙规则ID

	![](qinyun/image23.png)

	2)  默认情况下，只开放了ping ICMP和ssh端口，点击添加规则：

	![](qinyun/image24.png)

3)  最后点击应用修改

![](qinyun/image25.png)

访问RANCHER 
------------

1.  通过Elastic IP:8080访问Rancher server

	![](qinyun/image26.png)
	![](qinyun/image27.png)

2.  添加第一个应用

	1)  创建空应用栈

	![](qinyun/image28.png)

	2)  添加服务

	![](qinyun/image29.png)

	3)  通过调度指定服务运行到某台主机上

	![](qinyun/image30.png)

	4)  进入主机界面查看主机的IP地址

	![](qinyun/image31.png)

	5)  返回青云控制台进入路由器，将主机内网端口映射到公网端口上，最后应用修改

	![](qinyun/image32.png)

	6)  在安全\|防火墙中，放行8888端口,并应用修改

	![](qinyun/image33.png)

	7)  通过映射的端口访问应用

	![](qinyun/image34.png)

	PS:为了访问的便捷性，可以手动搭建一台Nginx或者Haproxy反向代理服务器。
