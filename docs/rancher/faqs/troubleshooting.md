---
title: 常见的故障排查与修复方法
---
## 一、Rancher server

### 1、Docker 运行Rancher server 容器应该注意什么？

需要注意运行rancher server 容器时，不要使用host模式。程序中有些地方定义的是localhost或者127.0.0.1，如果容器网络设置为host，将会去访问宿主机资源，因为宿主机并没有相应资源，rancher server 容器启动就出错。

```
PS：docker命令中，如果使用了 --network host参数，那后面再使用-p 8080:8080 就不会生效。
```
`docker run -d -p 8080:8080 rancher/server:stable`

此命令仅适用于单机测试环境，如果要生产使用Rancher server，请使用外置数据库(mysql)或者通过`-v /xxx/mysql/:/var/lib/mysql -v /xxx/log/:/var/log/mysql -v /xxx/cattle/:/var/lib/cattle`把数据挂载到宿主机上。如果用外置数据库，需提前对数据库做性能优化，以保证Rancher 运行的最佳性能。

### 2、如何导出Rancher Server容器的内部数据库？

你可以通过简单的Docker命令从Rancher Server容器导出数据库。

```
$ docker exec <CONTAINER_ID_OF_SERVER> mysqldump cattle > dump.sql
```

### 3、我正在运行的Rancher是什么版本的?

Rancher的版本位于UI的页脚的左侧。 如果你点击版本号，将可以查看其他组件的详细版本。

### 4、如果我没有在Rancher UI中删除主机而是直接删除会发生什么?

如果你的主机直接被删除，Rancher Server会一直显示该主机。主机会处于`Reconnecting`状态，然后转到`Disconnected`状态。你也可以通过添加主机再次把此节点添加到RANCHER 集群，如果不在使用此节点，可以在UI中删除。

如果你有添加了健康检查功能的服务自动调度到状态`Disconnected`主机上，CATTLE会将这些服务重新调度到其他主机上。  

`PS：如果使用了标签调度，如果你有多台主机就有相同的调度标签，那么服务会调度到其他具有调度标签的节点上；如果选择了指定运行到某台主机上，那主机删除后你的应用将无法在其他主机上自动运行。`

### 5、我如何在代理服务器后配置主机？

要在代理服务器后配置主机，你需要配置Docker的守护进程。详细说明参考在代理服务器后[添加自定义主机](https://docs.xtplayer.cn/rancher/installing/installing-server/#使用aws的elasticclassic-load-balancer作为rancher-server-ha的负载均衡器)。

### 6、为什么同一主机在UI中多次出现?

宿主机上`var/lib/rancher/state`这个文件夹，这是Rancher用来存储用于标识主机的必要信息. .registration_token中保存了主机的验证信息，如果里面的信息发生变化，RANCHER会认为这是一台新主机， 在你执行添加主机后，UI上将会出现另外一台相同的主机，第一台主机接着处于失联状态。

### 7、在哪能找到 Rancher Server 容器的详细日志？

运行`docker logs`可以查看在Rancher Server容器的基本日志。要获取更详细的日志，你可以进入到Rancher Server容器内部并查看日志文件。

```
# 进入 Rancher　Server　容器内部
$ docker exec -it <container_id> bash

# 跳转到 Cattle 日志所在的目录下
$ cd /var/lib/cattle/logs/
$ cat cattle-debug.log
```

在这个目录里面会出现`cattle-debug.log`和`cattle-error.log`。 如果你长时间使用此Rancher Server，你会发现我们每天都会创建一个新的日志文件。

### 8、将Rancher Server的日志复制到主机上。

以下是将Rancher Server日志从容器复制到主机的命令。

```
$ docker cp <container_id>:/var/lib/cattle/logs /local/path
```


### 9、如果Rancher Server的IP改变了会怎么样？

如果更改了Rancher Server的IP地址，你需要用新的IP重新注册主机。

在Rancher中，点击**系统管理**->**系统设置**更新 Rancher Server的**主机注册地址**。注意必须包括Rancher Server暴露的端口号。默认情况下我们建议按照安装手册中使用8080端口。

主机注册更新后，进入**基础架构**->**添加主机**->**自定义**。 添加主机的`docker run`命令将会更新。 使用更新的命令，在Rancher Server的所有环境中的所有主机上运行该命令。

### 10、Rancher Server运行变得很慢，怎么去优化它？

很可能有一些任务由于某些原因而处于僵死状态，如果你能够用界面查看**系统管理** -> **系统进程**，你将可以看到`Running`中的内容，如果这些任务长时间运行（并且失败），则Rancher会最终使用太多的内存来跟踪任务。这使得Rancher Server处于了内存不足的状态。

为了使服务变为可响应状态，你需要添加更多内存。通常4GB的内存就够了。

你需要再次运行Rancher Server命令并且添加一个额外的选项`-e JAVA_OPTS="-Xmx4096m"`

```
$ docker run -d -p 8080:8080 --restart=unless-stopped -e JAVA_OPTS="-Xmx4096m" rancher/server
```

根据MySQL数据库的设置方式的不同，你可能需要进行升级才能添加该选项。

如果是由于缺少内存而无法看到**系统管理** -> **系统进程**的话，那么在重启Rancher Server之后，已经有了更多的内存。你现在应该可以看到这个页面了，并可以开始对运行时间最长的进程进行故障分析。

### 11、Rancher Server数据库数据增长太快.

Rancher Server会自动清理几个数据库表，以防止数据库增长太快。如果对你来说这些表没有被及时清理，请使用API来更新清理数据的时间间隔。

在默认情况下，产生在2周以前的`container_event`和`service_event`表中的数据则数据会被删除。在API中的设置是以秒为单位的(`1209600`)。API中的设置为`events.purge.after.seconds`.

默认情况下，`process_instance`表在1天前产生的数据将会被删除，在API中的设置是以秒为单位的(`86400`)。API中的设置为`process_instance.purge.after.seconds`.

为了更新API中的设置，你可以跳转到`http://<rancher-server-ip>:8080/v1/settings`页面， 搜索要更新的设置，点击`links -> self`跳转到你点击的链接去设置，点击侧面的“编辑”更改'值'。 请记住，值是以秒为单位。

###  12、为什么Rancher Server升级失败导致数据库被锁定？

如果你刚开始运行Rancher并发现它被永久冻结，可能是liquibase数据库上锁了。在启动时，liquibase执行模式迁移。它的竞争条件可能会留下一个锁定条目，这将阻止后续的流程。

如果你刚刚升级，在Rancher　Server日志中，MySQL数据库可能存在尚未释放的日志锁定。

```bash
....liquibase.exception.LockException: Could not acquire change log lock. Currently locked by <container_ID>
```
#### 释放数据库锁

> **注意：** 请不要释放数据库锁，除非有相关日志锁的**异常**。如果是由于数据迁移导致升级时间过长，在这种情况下释放数据库锁，可能会使你遇到其他迁移问题。

如果你已根据升级文档创建了Rancher Server的数据容器，你需要`exec`到`rancher-data`容器中升级`DATABASECHANGELOGLOCK`表并移除锁，如果你没有创建数据容器，你用`exec`到包含有你数据库的容器中。

```bash
$ sudo docker exec -it <container_id> mysql
```

一旦进入到 Mysql 数据库, 你就要访问`cattle`数据库。

```bash
mysql> use cattle;

#检查表中是否有锁
mysql> select * from DATABASECHANGELOGLOCK;

# 更新移除容器的锁
mysql> update DATABASECHANGELOGLOCK set LOCKED="", LOCKGRANTED=null, LOCKEDBY=null where ID=1;

# 检查锁已被删除
mysql> select * from DATABASECHANGELOGLOCK;
+----+--------+-------------+----------+
| ID | LOCKED | LOCKGRANTED | LOCKEDBY |
+----+--------+-------------+----------+
|  1 |        | NULL        | NULL     |
+----+--------+-------------+----------+
1 row in set (0.00 sec)
```
### 13、开了访问控制但不能访问Rancher了，我该如何重置Rancher禁用访问控制？

如果你的身份认证出现问题（例如你的GitHub身份认证已损坏），则可能无法访问Rancher。 要重新获得对Rancher的访问权限，你需要在数据库中关闭访问控制。 为此，你需要访问运行Rancher Server的主机。

```bash
$ docker exec -it <rancher_server_container_ID> mysql
```
> **注意：** 这个 `<rancher_server_container_ID>`是具有Rancher数据库的容器。 如果你升级并创建了一个Rancher数据容器，则需要使用Rancher数据容器的ID而不是Rancher Server容器。

访问Cattle数据库。

```bash
mysql> use cattle;
```

查看`setting`表。

```bash
mysql> select * from setting;
```
更改`api.security.enabled`为`false`，并清除`api.auth.provider.configured`的值。此更改将关闭访问控制，任何人都可以使用UI / API访问Rancher Server。

```bash
mysql> update setting set value="false" where name="api.security.enabled";
mysql> update setting set value="" where name="api.auth.provider.configured";
```
确认更改在`setting`表中生效。

```bash
mysql> select * from setting;
```

可能需要约1分钟才能在用户界面中关闭身份认证，然后你可以通过刷新网页来登陆没有访问控制的Rancher Server。

### 14、Rancher Compose Executor和Go-Machine-Service不断重启.

在高可用集群中，如果你正在使用代理服务器后，如果rancher-compose-executor和go-machine-service不断重启，请确保你的代理使用正确的协议。
###  15、我怎么样在代理服务器后运行Rancher Server?

请参照[在HTTP代理后方启动Rancher Server]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/installing-rancher/installing-server/#在http代理后方启动-rancher-server).

###  16、为什么在日志中看到Go-Machine-Service在不断重新启动？ 我该怎么办？

Go-machine-service是一种通过websocket连接到Rancher API服务器的微服务。如果无法连接，则会重新启动并再次尝试。

如果你运行的是单节点的Rancher Server，它将使用你为主机注册地址来连接到Rancher API服务。 检查从Rancher Sever容器内部是否可以访问主机注册地址。

```bash
$ docker exec -it <rancher-server_container_id> bash
# 在 Rancher-Server 容器内
$ curl -i <Host Registration URL you set in UI>/v1
```

你应该得到一个json响应。 如果认证开启，响应代码应为401。如果认证未打开，则响应代码应为200。

验证Rancher API Server 能够使用这些变量，通过登录go-machine-service容器并使用你提供给容器的参数进行`curl`命令来验证连接:

```
$ docker exec -it <go-machine-service_container_id> bash
# 在go-machine-service 容器内
$ curl -i -u '<value of CATTLE_ACCESS_KEY>:<value of CATTLE_SECRET_KEY>' <value of CATTLE_URL>
```

你应该得到一个json响应和200个响应代码。

如果curl命令失败，那么在`go-machine-service`和Rancher API server之间存在连接问题。

如果curl命令没有失败，则问题可能是因为go-machine-service尝试建立websocket连接而不是普通的http连接。 如果在go-machine-service和Rancher API服务器之间有代理或负载平衡，请验证代理是否支持websocket连接。



## 二、Rancher agent

### 1、Rancher Agent无法启动的原因是什么？

#### 1.1、添加 `--name rancher-agent` （老版本）

如果你从UI中编辑`docker run .... rancher/agent...`命令并添加`--name rancher-agent`选项，那么Rancher Agent将启动失败。Rancher Agent在初始运行时会启动3个不同容器，一个是运行状态的，另外两个是停止状态的。Rancher Agent要成功连接到Rancher Server必须要有两个名字分别为`rancher-agent`和`rancher-agent-state`的容器，第三个容器是docker自动分配的名称，这个容器会被移除。

#### 1.2、使用一个克隆的虚拟机

如果你使用了克隆其他Agent主机的虚拟机并尝试注册它，它将不能工作。在rancher-agent容器的日志中会产生`ERROR: Please re-register this agent.`字样的日志。Rancher主机的唯一ID保存在`/var/lib/rancher/state`，因为新添加和虚拟机和被克隆的主机有相同的唯一ID，所以导致无法注册成功。

解决方法是在克隆的VM上运行以下命令： `rm -rf /var/lib/rancher/state; docker rm -fv rancher-agent; docker rm -fv rancher-agent-state`, 完成后可重新注册。

### 2、我在哪里可以找到Rancher agent容器的详细日志?

从v1.6.0起，在rancher-agent容器上运行`docker logs`将提供agent相关的所有日志。

### 3、主机是如何自动探测IP的？我该怎么去修改主机IP？如果主机IP改变了（因为重启），我该怎么办？

当Agent连接Rancher Server时，它会自动检测Agent的IP。有时，自动探测的IP不是你想要使用的IP，或者选择了docker网桥的IP，如. `172.17.x.x`。

或者，你有一个已经注册的主机，当主机重启后获得了一个新的IP, 这个IP将会和Rancher UI中的主机IP不匹配。

你可以重新配置“CATTLE_AGENT_IP”设置，并将主机IP设置为你想要的。

当主机IP地址不正确时，容器将无法访问管理网络。要使主机和所有容器进入管理网络，只需编辑添加自定义主机的命令行，将新的IP指定为环境变量“CATTLE_AGENT_IP”。 在主机上运行编辑后的命令。 不要停止或删除主机上的现有的Rancher Agent容器！

```bash
$ sudo docker run -d -e CATTLE_AGENT_IP=<NEW_HOST_IP> --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    rancher/agent:v0.8.2 http://SERVER_IP:8080/v1/scripts/xxxx
```

### 4、错误提示如下：INFO: Attempting to connect to: http://192.168.xx.xx:8080/v1    ERROR: http://192.168.xx.xx:8080/v1 is not accessible (Failed to connect to 192.168.xx.xx port 8080: No route to host)

这个问题主要有以下几种情况：

1.RANCHER SERVER服务器防火墙没有开通8080端口;

2.云平台安全组没有放行8080端口;

3.Agent 服务器没有开启IP转发规则[为什么我的容器无法连接到网络?]({{site.baseurl}}/rancher/faqs/troubleshooting/1为什么我的容器无法连接到网络);

4.主机hosts(`/etc/hosts`)文件没有配置;


## 三、Kubernetes

### 1、部署Kubernetes时候出现以下有关cgroup的问题
```
Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
```
```
Expected state running but got error: Error response from daemon: oci runtime error: container_linux.go:247: starting container process caused "process_linux.go:258: applying cgroup configuration for process caused \"mountpoint for devices not found\""
```
以上问题为Kubernetes版本与docker 版本不兼容导致cgroup功能失效

### 2、Kubernetes  err: [nodes \"iZ2ze3tphuqvc7o5nj38t8Z\" not found]"
Rancher-Kubernetes中，节点之间通信需要通道hostname，如果没有内部DNS服务器，那么需要为每台节点配置hosts文件。

###  如何验证你的主机注册地址设置是否正确？

如果你正面临Rancher Agent和Rancher Server的连接问题，请检查主机设置。当你第一次尝试在UI中添加主机时，你需要设置主机注册的URL，该URL用于建立从主机到Rancher Server的连接。这个URL必须可以从你的主机访问到。为了验证它，你需要登录到主机并执行curl命令：

```
curl -i <Host Registration URL you set in UI>/v1
```

你应该得到一个json响应。 如果开启了认证，响应代码应为401。如果认证未打开，则响应代码应为200。

> **注意：** 普通的HTTP请求和websocket连接（ws://）都将被使用。 如果此URL指向代理或负载平衡器，请确保它们可以支持Websocket连接。
>
> 

## 四、Docker
### 1、镜像下载慢，如何提高下载速度？

```
touch /etc/docker/daemon.json
cat >> /etc/docker/daemon.json <<EOF
{
"insecure-registries": ["0.0.0.0/0"],
"registry-mirrors": ["https://7bezldxe.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload && systemctl restart docker
```
`PS:0.0.0.0/0 表示信任所有非https地址的镜像仓库，对于内网测试，这样配置很方便。对于线上生产环境，为了安全请不要这样配置`

### 2、如何配置Docker后端存储驱动？
以overlay为例

```
touch /etc/docker/daemon.json
cat >> /etc/docker/daemon.json <<EOF
{
"storage-driver": "overlay"
}
EOF
systemctl daemon-reload && systemctl restart docker
```
## 五、服务/容器

### 1、为什么我只能编辑容器的名称？

Docker容器在创建之后就不可更改了。唯一可更改的内容是我们要存储的不属于Docker容器本身的那一部分数据。 无论是停止、启动或是重新启动，它始终在使用相同的容器。如需改变任何内容都需要删除或重新创建一个容器。
你可以**克隆**，即选择已存在的容器，并基于已有容器的配置提前在**添加服务**界面中填入所有要设置的内容，如果你忘记填入某项内容，可以通过克隆来改变它之后删除旧的容器。

### 2、关联的容器/服务在Rancher中是如何工作的？

在Docker中，关联的容器（在 `docker run`中使用`--link`）会出现在容器的`/etc/hosts`中。在Rancher中，我们不需要更改容器的`/etc/hosts`文件，而是通过运行一个内部DNS服务器来关联容器，DNS服务器会返回给我们正确的IP。

### 3、不能通过Rancher的界面打开命令行或查看日志。Rancher是如何去访问容器的命令行和日志的?

Agent主机有可能会暴露在公网上，Agent上接受到的访问容器命令行或者日志的请求是不可信的。Rancher Server中发出的请求包括一个JWT（JSON Web Token)，JWT是由服务器签名并且可由Agent校验的，Agent可以判断出请求是否来自服务器，JWT中包括了有效期限，有效期为5分钟。这个有效期可以防止它被长时间使用。如果JWT被拦截而且没有用SSL时，这一点尤为重要。

如果你运行`docker logs -f (rancher-agent名称或ID）`。日志会显示令牌过期的信息，随后检查Rancher Server主机和Rancher Agent主机的时钟是否同步。

### 4、在哪里可以看到我的服务日志?

在服务的详细页中，我们提供了一个服务日志的页签**日志**。在**日志**页签中，列出了和服务相关的所有事件，包括时间戳和事件相关描述，这些日志将会保留24小时。

### 5、RANCHER SERVER 点击WEB shell屏幕白屏

如果RANCHER SERVER 运行在V1.6.2版本，点击WEB shell出现白屏，这是UI上的一个BUG，请选择升级server服务。

## 六、跨主机通信

如果容器运行在不同主机上，不能够ping通彼此, 可能是由一些常见的问题引起的.

### 1、如何检查跨主机通信是否正常?

在**应用**->**基础设施**中，检查 `healthcheck` 应用的状态。如果是active跨主机通信就是正常的。

手动测试，你可以进入任何一个容器中，去ping另一个容器的内部IP。在主机页面中可能会隐藏掉基础设施的容器，如需查看点击“显示系统容器”的复选框。

### 2、UI中显示的主机IP是否正确?

有时，Docker网桥的IP地址会被错误的作为了主机IP，而并没有正确的选择真实的主机IP。这个错误的IP通常是`172.17.42.1`或以`172.17.x.x`开头的IP。如果是这种情况，在使用`docker run`命令添加主机时，请用真实主机的IP地址来配置`CATTLE_AGENT_IP`环境变量。

```bash
$ sudo docker run -d -e CATTLE_AGENT_IP=<HOST_IP> --privileged \
    -v /var/run/docker.sock:/var/run/docker.sock \
    rancher/agent:v0.8.2 http://SERVER_IP:8080/v1/scripts/xxxx
```

### 3、Rancher的默认子网（`10.42.0.0/16`）在我的网络环境中已经被使用或禁止使用，我应该怎么去更改这个子网？

Rancher Overlay网络默认使用的子网是`10.42.0.0/16`。如果这个子网已经被使用，你将需要更改Rancher网络中使用的默认子网。你要确保基础设施服务里的Network组件中使用着合适的子网。这个子网定义在该服务的`rancher－compose.yml`文件中的`default_network`里。

要更改Rancher的IPsec或VXLAN网络驱动，你将需要在环境模版中修改网络基础设施服务的配置。创建新环境模板或编辑现有环境模板时，可以通过单击**编辑**来配置网络基础结构服务的配置。在编辑页面中，选择**配置选项**　>　**子网**输入不同子网，点击**配置**。在任何新环境中将使用环境模板更新后的子网，编辑已经有的环境模板不会更改现在已有环境的子网。

这个实例是通过升级网络驱动的`rancher-compose.yml`文件去改变子网为`10.32.0.0/16`.

```yaml
ipsec:
  network_driver:
    name: Rancher IPsec
    default_network:
      name: ipsec
      host_ports: true
      subnets:
      # After the configuration option is updated, the default subnet address is updated
      - network_address: 10.32.0.0/16
      dns:
      - 169.254.169.250
      dns_search:
      - rancher.internal
    cni_config:
      '10-rancher.conf':
        name: rancher-cni-network
        type: rancher-bridge
        bridge: docker0
        # After the configuration option is updated, the default subnet address is updated
        bridgeSubnet: 10.32.0.0/16
        logToFile: /var/log/rancher-cni.log
        isDebugLevel: false
        isDefaultGateway: true
        hostNat: true
        hairpinMode: true
        mtu: 1500
        linkMTUOverhead: 98
        ipam:
          type: rancher-cni-ipam
          logToFile: /var/log/rancher-cni.log
          isDebugLevel: false
          routes:
          - dst: 169.254.169.250/32
```

> **注意：** 随着Rancher通过升级基础服务来更新子网，以前通过API更新子网的方法将不再适用。

## 七、DNS

### 1、如何查看我的DNS是否配置正确?

如果你想查看Rancher　DNS配置，点击**应用** > **基础服务**。点击`network-services`应用，选择`metadata`，在`metadata`中，找到名为`network-services-metadata-dns-X`的容器，通过UI点击**执行命令行**后，可以进入该容器的命令行，然后执行如下命令。

```bash
$ cat /etc/rancher-dns/answers.json
```
### 2、在Ubuntu上运行容器时彼此间不能正常通信。

如果你的系统开启了`UFW`，请关闭`UFW`或更改`/etc/default/ufw`中的策略为：

```
DEFAULT_FORWARD_POLICY="ACCEPT"
```
## 八、CentOS

### 1、为什么容器无法连接到网络?

如果你在主机上运行一个容器（如：`docker run -it ubuntu`）该容器不能与互联网或其他主机通信，那可能是遇到了网络问题。
Centos默认设置`/proc/sys/net/ipv4/ip_forward`为`0`，这从底层阻断了Docker所有网络。

解决办法：

vi /usr/lib/sysctl.d/00-system.conf

添加如下代码：

net.ipv4.ip_forward=1

net.bridge.bridge-nf-call-ip6tables = 1

net.bridge.bridge-nf-call-iptables = 1

net.bridge.bridge-nf-call-arptables = 1

重启network服务

systemctl restart network

查看是否修改成功

sysctl net.ipv4.ip_forward

如果返回为“net.ipv4.ip_forward = 1”则表示成功了

## 九、负载均衡

### 1、为什么我的负载均衡一直是`Initializing`状态?

负载均衡器自动对其启用健康检查。 如果负载均衡器处于初始化状态，则很可能主机之间无法进行跨主机通信。

### 2、我如何查看负载均衡的配置?

如果要查看负载均衡器的配置，你需要用进入负载均衡器容器内部查找配置文件，你可以在页面选择负载均衡容器的**执行命令行**

```bash
$ cat /etc/haproxy/haproxy.cfg
```

该文件将提供负载均衡器的所有配置详细信息。

### 3、我在哪能找到HAproxy的日志?

HAProxy的日志可以在负载均衡器容器内找到。 负载均衡器容器的`docker logs`只提供与负载均衡器相关的服务的详细信息，但不提供实际的HAProxy日志记录。

```
$ cat /var/log/haproxy
```

## 十、健康检查

### 1、为什么健康检查服务一直显示黄色初始化状态？
healthcheck不仅为其他服务提供健康检查，对系统组件(比如调度服务)也提供健康检查服务，healthcheck也对自己进行健康检查。多个healthcheck组件时，它们会相互交叉检查，只有健康检查通过后，容器状态才会变成绿色。而healthcheck一直显示黄色初始化状态，说明一直没有通过健康检查。健康检查都是通过网络访问的，所以一定是网络通信异常导致。



