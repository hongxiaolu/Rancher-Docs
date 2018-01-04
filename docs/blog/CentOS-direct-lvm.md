---
title: CentOS手动配置Storage Driver 为 direct-lvm
---

`Device Mapper`是基于内核的框架，支持Linux上的许多高级卷管理技术。Docker的`devicemapper`存储驱动程序利用此框架的精简配置和快照功能进行映像和容器管理。本文将`Device Mapper`存储驱动程序称为`devicemapper`，并将内核框架称为Device Mapper。

对于支持它的系统，Linux内核中包含支持。但是，Docker需要使用特定的配置。例如，在RHEL或CentOS操作系统中，Docker将默认为`overlay`，`overlay`官方不建议在生产中使用。

该devicemapper驱动程序使用专用于Docker的块设备，并在块级而非文件级进行操作。这些设备可以通过将物理存储添加到Docker主机来扩展，并且比在操作系统级别使用文件系统性能更好。

# 配置用于生产的direct-lvm驱动模式
CentOS安装好Docker后，默认Storage Driver为devicemapper的loop-lvm模式，这种模式从性能和稳定性上都不可靠，此模式仅适用于测试环境。

## 配置direct-lvm模式
生产环境使用`devicemapper`存储驱动程序的主机必须使用direct-lvm模式。此模式使用块设备来创建精简池。这比使用loop-lvm设备更快，更有效地使用系统资源，并且块设备可以根据需要扩增。

在Docker 17.06及更高版本中，Docker可以为您管理块设备，简化direct-lvm模式的配置。这仅适用于新的Docker设置，并且只能使用一个块设备。

>如果您需要使用多个块设备，需要手动配置direct-lvm模式。

| 选项 | 描述   | 需要? | 默认 | 示例  |
|:------------|:--------------|:----------|:--------|:--------------|
| `dm.directlvm_device`           | The path to the block device to configure for `direct-lvm`.                                                                                                                        | Yes       |   | `dm.directlvm_device="/dev/xvdf"`  |
| `dm.thinp_percent`              | The percentage of space to use for storage from the passed in block device.                                                                                                        | No        | 95      | `dm.thinp_percent=95`              |
| `dm.thinp_metapercent`          | The percentage of space to for metadata storage from the passed=in block device.                                                                                                   | No        | 1       | `dm.thinp_metapercent=1`           |
| `dm.thinp_autoextend_threshold` | The threshold for when lvm should automatically extend the thin pool as a percentage of the total storage space.| No        | 80      | `dm.thinp_autoextend_threshold=80` |
| `dm.thinp_autoextend_percent`   | The percentage to increase the thin pool by when an autoextend is triggered.                                                                                                       | No        | 20      | `dm.thinp_autoextend_percent=20`   |
| `dm.directlvm_device_force`     | Whether to format the block device even if a filesystem already exists on it. If set to `false` and a filesystem is present, an error is logged and the filesystem is left intact. | No        | false   | `dm.directlvm_device_force=true`   |

编辑daemon.json文件并设置适当的选项，然后重新启动Docker以使更改生效。以下daemon.json设置了上表中的所有选项。

```bash
{
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.directlvm_device=/dev/xdf",
    "dm.thinp_percent=95",
    "dm.thinp_metapercent=1",
    "dm.thinp_autoextend_threshold=80",
    "dm.thinp_autoextend_percent=20",
    "dm.directlvm_device_force=false"
  ]
}
```
## 手动配置DIRECT-LVM模式
假定有一 100G 空闲块设备 /dev/sdb 。设备标识符和音量大小在您的环境中可能不同，您应该在整个过程中替换您自己的值。
### 停止docker
```bash
sudo systemctl stop docker
```
### 安装依赖
RHEL / CentOS的：device-mapper-persistent-data，lvm2，和所有的依赖
### 把整块硬盘创建物理卷(PV)
```bash
sudo pvcreate /dev/sdb
```
### 创建dockervg卷组(VG)
```bash
sudo vgcreate dockervg /dev/sdb
```
### 划分三个逻辑卷(LV)，分别用于：`docker_data，docker_metadata，docker_dir`
```bash
sudo lvcreate --wipesignatures y -n data dockervg -L 35G
sudo lvcreate --wipesignatures y -n metadata dockervg -L 1G
sudo lvcreate --wipesignatures y -n dockerdir dockervg -l+100%FREE
```
### 转换为thin pool
```bash
sudo lvconvert -y --zero n -c 512K --thinpool dockervg/data --poolmetadata dockervg/metadata
```
### 配置自动扩展
```bash
cat>>/etc/lvm/profile/dockervg-data.profile<<EOF
activation {
    thin_pool_autoextend_threshold=80
    thin_pool_autoextend_percent=20
}
EOF
```
### 应用以上配置
```bash
lvchange --metadataprofile dockervg-data dockervg/data
```
### 启用磁盘空间监控
```bash
lvs -o+seg_monitor
```
### 映射相应目录
```bash
mkfs -t xfs /dev/dockervg/dockerdir
mkdir /var/lib/docker 
mount /dev/dockervg/dockerdir /var/lib/docker
cat>> /etc/fstab <<EOF
/dev/dockervg/dockerdir /var/lib/docker xfs defaults 0 0
EOF
```
### 设置Docker启动参数
```bash
echo 'DOCKER_OPTS="--config-file=/etc/docker/daemon.json"' > /etc/default/docker
mkdir /etc/docker
cat>>/etc/docker/daemon.json<<EOF
{
  "storage-driver": "devicemapper",
   "storage-opts": [
     "dm.thinpooldev=/dev/mapper/dockervg-data",
     "dm.use_deferred_removal=true",
     "dm.use_deferred_deletion=true"
   ]
}
EOF
```

## 存储池扩容
假定现在有一块100G的块设备  /dev/sdc
### 通过pvdisplay查看卷组与物理卷/块设备的对应关系
```bash
sudo pvdisplay |grep docker
PV Name               /dev/sdb
VG Name               docker
```
### 通过vgextend命令进行卷组扩容
```bash
sudo vgextend docker /dev/sdc
info: Physical volume "/dev/sdc" successfully created.
info: Volume group "docker" successfully extended
```
### 给逻辑卷(LV)扩容
```bash
sudo lvextend -l+100%FREE  -n docker/docker
resize2fs /dev/docker/docker
-l+100%FREE: 表示使用全部空闲空间，改为-L 10G指定扩展大小；
-n docker/thinpool: 指定逻辑卷名(卷组/逻辑卷名)
```
### 激活逻辑卷(LV)
```bash
# LV扩容重启后，可能会出现“Non existing device" 的提示，需要对LV卷进行激活操作:
sudo lvchange -ay docker/thinpool
```

