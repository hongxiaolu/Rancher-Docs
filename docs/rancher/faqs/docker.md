---
title: Docker 常见问题
---

### 1、镜像下载慢，如何提高下载速度？

```bash
touch /etc/docker/daemon.json
cat >> /etc/docker/daemon.json <<EOF
{
"insecure-registries": ["0.0.0.0/0"],
"registry-mirrors": ["https://7bezldxe.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload && systemctl restart docker
```

```
PS:0.0.0.0/0 表示信任所有非https地址的镜像仓库，对于内网测试，这样配置很方便。对于线上生产环境，为了安全请不要这样配置
```

### 2、如何配置Docker后端存储驱动？
以overlay为例

```bash
touch /etc/docker/daemon.json
cat >> /etc/docker/daemon.json <<EOF
{
"storage-driver": "overlay"
}
EOF
systemctl daemon-reload && systemctl restart docker
```

### 3、docker info 出现 WARNING

```
WARNING: No swap limit support
WARNING: No kernel memory limit support
```

编辑`/etc/default/grub` 文件，并设置：
`GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"`

接着

SUSE

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```
Cetos

```
Update grub
```
Ubuntu

```
update-grub
