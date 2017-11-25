---
title: Rancher CNI Driver
---
## Macvlan
### 基本原理
参见[这里](http://niusmallnan.com/2016/09/19/docker-cnm-practice/)。

```
# 1. 开启混杂模式
ip link set dev eth1 promisc on
# 2. 新增命名空间
ip netns add ns1
# 3. 新增macvlan网卡，模式是 bridge
ip link add mv1 link eth1 type macvlan mode bridge
# 4. 将网卡置于命名空间
ip link set mv1 netns ns1
# 5. 启动网卡
ip netns exec ns1 ip link set dev mv1 up
# 6. 分配IP
ip netns exec ns1 ifconfig mv1 192.168.1.60/24 up
```
在同个主机或者其他主机，按照上面步骤创建新的命名空间和macvlan网卡。在命名空间内能给ping同其他IP。

### 实现方案
创建一个新的catalog，类型是networking，参见[这里](https://github.com/zionwu/flatnet-catalog/tree/test/infra-templates/macvlan)。cni plugin的实现在官方cni macvlan plugin代码上进行调整，参见[这里](https://github.com/zionwu/rancher-cni-macvlan)。另外需要解决在容器内如何访问metadata service的问题，目前有两个方案。

#### metadata路由方案1
通过在主机添加一个macvlan的网卡，也链接到和容器同一个网卡如eth1上。分配和容器同一网段的IP。在容器内，添加一条路由：

```
# 172.22.101.100是主机的macvlan网卡的IP
ip add route 169.254.169.250 via 172.22.101.100
```
这样，在容器内就可以访问metadata了。 但是需要解决主机macvlan网卡的ipam问题。目前解决的思路是：
所有主机上macvlan网卡用同一个ip，通过iptables和eatables把这个设备的arp广播禁掉，这样内部可以用，然后又不会IP冲突。这样在容器内可以设置静态路由。    

注意：这种方案，macvlan使用的子网要和主机的接口的子网不同。

#### metadata路由方案2
创建一堆veth设备，一个的master是docker0网桥，另一个置于容器中，分配与docker0网桥同一网段的IP，如 172.17.0.100。在容器内，添加一条路由：
```
ip add route 169.254.169.250 via 172.22.101.1
```
这样，在容器内就可以访问metadata了。 但是需要解决容器内veth设备的ipam问题。目前的思路是通过调用docker libnetwork来使用docker bridge的ipam。

### 进度

方案二更加优雅，因此先研究其可行性。
       
2017-04-28:     

* 调研如何调用libnetwork中的ipam，需要看docker engine的代码。   
 
2017-05-02:    

* libnetwork有提供REST API, 在api/api.go里面，这里的[slides](http://7u2psl.com5.z0.glb.qiniucdn.com/dockercon/Networking%20Breakout.pdf)有提到。通过curl命令调用libnetwork的unix socket失败，错误是：“invalid character 'G' looking for beginning of value”。 需要进一步研究docker engine的代码，看它如何调用libnetwork的。     


2017-05-03  
        
* 方案一：    
由于主机macvlan的子网要和主机的接口的子网不同，因此该macvlan的IP地址可以使用网关如192.168.22.1， 然后在主机做SNAT。这种方案更加简单。这种方案有以下限制：
    1.  macvlan的子网不能和物理网卡的网络在同一子网。
    2.  如果有物理网关，那么当前方案需要改动。

* 方案二：   
发现libnetwork中的REST API是被cmd dnet使用，这是一个libnetwork测试服务器。在docker engine中，在daemon/daemon_unix.go的函数initNetworkController中，调用了libnetwork.New(netOptions...)来初始化NetworkController。 New方法会将初始化一些资源比如store，并将原来机器上的资源如endpoint清除。docker engine对网络的操作都是调用NetworkController。第三方无法自己调用NetworkController来使用daemon的网络资源，因为初始化NetworkController需要创建资源和回收遗留资源，这和daemon有冲突。docker虽然将libnetwork抽离出来，但是设计上这个组件并不能共用，对网络的操作只能使用engine提供的API，但是engine没有提供创建endpoint的API。     

2017-05-04    
使用方案一，进行兼容性测试。    
scheduler一度出现: 

```
Expected state running but got stopped: Couldn't bring up network: failed to rename macvlan to "eth0": file exists
```

health check第二个节点状态处于初始化，日志出现: 

```
2017/5/4 下午4:48:01time="2017-05-04T08:48:01Z" level=info msg="healthCheck -- reloading haproxy config with the new config changes\n[WARNING] 123/084801 (89) : config : 'option forwardfor' ignored for proxy 'web' as it requires HTTP mode.\n"
2017/5/4 下午4:48:01time="2017-05-04T08:48:01Z" level=info msg="Scheduling apply config"
2017/5/4 下午4:48:01time="2017-05-04T08:48:01Z" level=info msg="Monitoring 1 backends"
2017/5/4 下午4:48:01time="2017-05-04T08:48:01Z" level=info msg="healthCheck -- no changes in haproxy config\n"
2017/5/4 下午4:48:01time="2017-05-04T08:48:01Z" level=info msg="Scheduling apply config"
2017/5/4 下午4:48:01time="2017-05-04T08:48:01Z" level=info msg="healthCheck -- no changes in haproxy config\n"
2017/5/4 下午4:48:03time="2017-05-04T08:48:03Z" level=info msg="6cc494a7-24d2-4867-8bbf-5a6d102cf0d9_8751fb3c-e944-440f-86b9-c94e125713a9_1=DOWN"
```

metadata：    
添加-xff后，在容器内使用命令 curl  --header "X-Forwarded-For: 192.168.22.138" http://169.254.169.250/latest/self/service 能够获取到数据。     

lb:
使用niusmallnan/lb-service-haproxy:dev镜像后，lb不再出现访问 http://169.254.169.250/latest/self/service 404。但是一直处于初始化的状态，日志出现：

```
2017/5/4 下午7:11:09time="2017-05-04T11:11:09Z" level=info msg=" -- reloading haproxy config with the new config changes\n * Reloading haproxy haproxy\n[WARNING] 123/111109 (3729) : config : 'option forwardfor' ignored for proxy 'default' as it requires HTTP mode.\n[WARNING] 123/111109 (3731) : config : 'option forwardfor' ignored for proxy 'default' as it requires HTTP mode.\n   ...done.\n"
```

2017-05-05        

* lb:   
重新部署环境后，lb的状态是正常的。没有重现5.4的情况。         
部署wordpress, link database,将database rename 为mysql, 在容器内ping mysql不通--》待追踪。        
不rename的话，通过lb访问wordpres正常。 

* scheduler:
重新部署的环境里，后面出现了“Couldn't bring up network: failed to rename macvlan”错误。 然后状态一直是初始化中。在容器中，存在一个eth0接口，但是没有分配到IP。 将此设备手动删除后，重启容器，状态恢复正常。  

2017-05-08   
   
* “Couldn't bring up network: failed to rename macvlan”错误是因为network-manager里有重试机制，第一次CNIAdd失败后，会重试15次。 当重试时，第一次创建的接口eth0已经存在，而对应的CNIDel还没调用，因此重试到rename这一步都会报错。 

* 修复方案：用netlink.LinkByName检查args.IfName，如果已经存在就不重新创建接口。

2017-05-09      

1. 添加了上述修复后，在重试不会报重命名失败，但是在设置mac地址这一步报：”Device or resource busy“。 添加setInterfaceDown方法，如果接口存在则尝试将其设置为down。    

2. 添加1的改动后，重试时设置IP addr这一步报“file exists”错误。 使用cni-bridge的util.go的configureInterface， 替代ipam.ConfigureIface， 前者会忽略“file exists”的错误。    
   
3. 添加2的改动后，重试出现“invalid character 'r' looking for beginning of value”错误。 这是在network manager中报的错，cni driver已经正常执行完。 network manager调用cniglue , cniglue调用libcni的AddNetwork, 该方法会将cni driver的output用json.Unmarshal转化为Result对象。转化失败报错，network manager判断err非空进行重试。查看macvlan代码发现里面调用了fmt.Fprintf打印日志到stdout中， 将其改为使用logrus.Infof后，不再出现错误。 因此实现cni driver一个重要的关注点是：

```
cni driver的标准输入，必须只是Result的json报文
```

改动的PR可参见 https://github.com/niusmallnan/rancher-cni-macvlan/pull/1

