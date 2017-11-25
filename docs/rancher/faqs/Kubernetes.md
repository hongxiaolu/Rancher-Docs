---
title: Kubernetes 常见问题
---

### 1、部署Kubernetes时候出现以下有关cgroup的问题

```
Failed to get system container stats for "/system.slice/kubelet.service": 
failed to get cgroup stats for "/system.slice/kubelet.service": failed to 
get container info for "/system.slice/kubelet.service": unknown container 
"/system.slice/kubelet.service"
```
```
Expected state running but got error: Error response from daemon: 
oci runtime error: container_linux.go:247: starting container 
process caused "process_linux.go:258: applying cgroup configuration 
for process caused \"mountpoint for devices not found\""
```
以上问题为Kubernetes版本与docker 版本不兼容导致cgroup功能失效

### 2、Kubernetes  err: [nodes \"iZ2ze3tphuqvc7o5nj38t8Z\" not found]"
Rancher-Kubernetes中，节点之间通信需要通道hostname，如果没有内部DNS服务器，那么需要为每台节点配置hosts文件。

### 3、如何验证你的主机注册地址设置是否正确？

如果你正面临Rancher Agent和Rancher Server的连接问题，请检查主机设置。当你第一次尝试在UI中添加主机时，你需要设置主机注册的URL，该URL用于建立从主机到Rancher Server的连接。这个URL必须可以从你的主机访问到。为了验证它，你需要登录到主机并执行curl命令：

```
curl -i <Host Registration URL you set in UI>/v1
```
你应该得到一个json响应。 如果开启了认证，响应代码应为401。如果认证未打开，则响应代码应为200。

> **注意：** 普通的HTTP请求和websocket连接（ws://）都将被使用。 如果此URL指向代理或负载平衡器，请确保它们可以支持Websocket连接。
>
