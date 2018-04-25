---
title: 快速入门指南
layout: rancher-default-v2.0
version: v2.0
---

## 快速入门指南

在本指南中，您将学习如何开始使用Rancher v2.0，其中包括：

*	准备Linux主机
*	启动Rancher服务器并访问Rancher UI
*	通过Rancher UI创建集群
*	导入现有的Kubernetes群集
*	通过Rancher UI添加Pod
*	使用Kubeconfig文件

### 准备Linux主机
1.	准备一个64位Ubuntu 16.04的Linux主机，至少4GB的内存。
2.	在主机上安装支持的Docker，支持的Docker版本目前有：1.12.6，1.13.1或17.03.2。
	
	>	要在服务器上安装Docker，请按照Docker的安装说明进行操作。

### 启动Rancher服务器
只需要一条命令，不到一分钟即可安装并启动Rancher服务器。安装完成后，您可以打开Web浏览器访问Rancher UI。

1.	在你的主机上运行以下Docker命令：
```
sudo docker run -d --restart unless-stopped -p 80:80 -p 443:443 rancher/server:preview
```

2.	通过https://<SERVER_IP> 访问Rancher UI，<SERVER_IP>为主机可外部访问的IP地址。Rancher会自动使用默认管理员进行身份验证。您将需要使用此用户（admin）和密码（admin）登录。首次登录时，系统会要求您更改默认管理员的密码。

	>	Rancher仅支持HTTPS，并且默认配置为使用自签名证书。GA之前将提供替换此证书的功能。因此，在继续之前，浏览器会提示您信任此证书。

3.	在Rancher服务中添加集群。目前有以下几种创建方式：

	* 	**创建Cloud Cluster** 
	*	**创建Custom Cluster(RKE)** 
	* 	**导入现有Kubernetes Cluster** 

### **创建Cloud Cluster**
在Rancher v2.0中，您可以从云平台(如Google Container Engine（GKE））创建新的Kubernetes群集。

1.	点击添加群集按钮，然后在云平台提供商中点击选择。

2.	按照Rancher UI中的说明创建并添加群集。根据网络情况，整个过程可能需要十几分钟或者更长时间。集群准备就绪后，您可以在“集群”页面上查看其状态。一旦您的群集开始运行，Rancher将创建一个Default项目和一个default命名空间。一旦群集处于活动状态，您就可以开始将角色添加到您的命名空间中。

### 创建Custom Cluster(RKE)
您可以使用自定义方式创建一个集群，它将在您集群中的任何节点上安装Kubernetes服务。您可以从Rancher v2.0支持的各种云提供商添加主机节点，并为Kubernetes群集的每个节点指定角色。


1.	按照Rancher UI中的说明创建并添加您的RKE集群。

2.	在“节点”部分中，单击添加新节点以选择要添加的节点类型。您可以配置新节点模板以启动节点或从现有节点模板中进行选择（即，如果以前启动了节点）。启动任何新节点时，节点模板将与您的配置一起保存，以允许您重新使用此配置来添加其他节点。

3.	选择要创建的节点后，选择您希望节点在Rancher管理的Kubernetes群集中执行的角色。

	从以下角色中选择：

	*	etcd - 在此节点etcd上启动。Etcd是一个分布式可靠的键值存储库，可存储所有Kubernetes状态。我们建议使用etcd角色运行1,3或5个节点。
	*	管理 -在此节点，主部件将运行（kube-api，kube-scheduler，kube-controller），以及kubelet和kubeproxy。这些节点用于帮助管理Kubernetes集群以及您的应用程序（即pod）可以启动的位置。
	*	工作节点 -在这些节点中，只有工人的组件（kubelet，kubeproxy，nginx-proxy）的推出，这些节点将只有您的应用程序（即豆荚）运行。

4.	点击创建完成创建群集。这个过程可能需要几分钟才能完成。集群准备就绪后，您可以在“集群”页面上查看其状态。一旦群集处于活动状态，您就可以开始将角色添加到您的名称空间中。

### 导入Kubernetes集群
在Rancher v2.0中，您可以导入现有的Kubernetes v1.8的外部安装。在这种情况下，群集提供程序管理Rancher外部的主机。

1.	按照Rancher UI中的说明导入现有的Kubernetes集群。导入现有群集的kubeconfig文件。
2.	点击导入。集群准备就绪后，您可以在“集群”页面上查看其状态。一旦群集处于活动状态，您就可以开始将角色添加到您的名称空间中。

### Rancher2.0概念
Rancher支持将资源分组为多个群集，项目和名称空间。

1.	**cluster**是一组物理（或虚拟）的计算资源。每个项目都绑定到一个群集并在群集节点上运行它的群集。您可以共享具有多个项目的群集，并为不同的用户提供访问权限来管理群集的各种资源。

**project**是定义工作负载的一组命名空间。。项目中的窗格可以通过共享托管网络相互通信，并且您可以授予不同用户访问权限以管理项目的各种资源。

### 添加Pods
在创建并激活了至少包含一个节点的群集后，即可创建第一个Pod。您可以通过单击群集或查看所有群集的全局视图上的状态来检查群集状态。

1.	点击进入Default集群的项目。
2.	点击部署。显示添加Pod页面。
3.	输入名称，例如“first-pod”。
4.	输入托管在Docker Hub上的Docker镜像。
5.	点击启动。这个过程可能需要几分钟才能完成。一旦您的pod开始运行，您可以在工作负载页面上查看其状态。

现在您已经添加了节点，并且您的第一个Pod已启动并运行，您可以在Rancher v2.0中查看我们的其他新功能。

### 使用Kubeconfig文件
您可以生成要kubectl在桌面上使用的Kubernetes配置文件。Kubernetes配置文件（即kubeconfig）允许您从桌面配置对一个或多个群集的访问。

在Rancher UI菜单上，选择群集。
在仪表板中，点击Kubeconfig File按钮。将生成一个kubeconfig文件，以便您可以kubectl在桌面上使用。将显示的代码复制并粘贴到您的~/.kube/config文件中，然后开始使用kubectl。点击关闭返回到Rancher界面。
### 在Ubuntu上部署
可以使用Rancher来控制在Ubuntu上运行的Canonical Kubernetes（cdk）集群。Canonical已经提供了一套完整的说明，可以在这里进行：https : //kubernetes.io/docs/getting-started-guides/ubuntu/rancher/。