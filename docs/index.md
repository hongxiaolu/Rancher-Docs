---
description: Home page for Docker's documentation
keywords: Docker, documentation, manual, guide, reference, api, samples
landing: true
title: 首页
#notoc: true
notags: true
noratings: true
---

Rancher是一个开源的软件平台，可以让企业在生产中运行和管理Docker和Kubernetes。使用Rancher，
企业不再需要使用不同的开源技术从头开始构建容器服务平台。Rancher提供管理生产中的容器所需的整个软件堆栈。

Rancher 主要由四个主要部分组成:

### 基础组件编排

Rancher能够运行在支持Docker运行的多种Linux发行版上。无论是公有云VM还是私有云VM，或者是物理机主机，
从Rancher的角度来看，它们都是为系统层和应用层提供计算资源，都一样没有区别。

Rancher实现了专门为容器应用提供支持的便携式基础架构服务层，Rancher基础架构服务包括网络，
存储，负载平衡器，DNS和安全性。Rancher基础架构服务通常作为容器部署，以便基础架构服务可以在任何Linux主机上运行。

### 容器编排与调度

许多用户选择使用容器编排和调度框架来运行容器化应用程序. Rancher包含了当前发布的所有受欢迎的容器编排和调度框架，
包括Docker Swarm，Kubernetes和Mesos。同一用户可以创建多个Swarm或Kubernetes群集。然后，他们可以使用本机Swarm或Kubernetes工具来管理创建的应用程序。
除了Swarm，Kubernetes和Mesos之外，Rancher还支持自己的容器编排和调度框架，称为“Cattle”。
Cattle被Rancher广泛用于编排基础设施服务，以及创建，管理和升级Swarm，Kubernetes和Mesos群集。

### 应用目录

Rancher用户可以从应用程序目录中部署整个多容器集群应用程序，只需单击一个按钮即可。用户可以管理已部署的应用程序，
并在新版本的应用程序可用时执行全自动升级。 Rancher维护着一个由Rancher社区提供的主流应用程序组成的公共目录。 Rancher用户可以创建自己的私有目录。

### 企业级控制中心

Rancher支持灵活的用户验证插件，并与Active Directory，LDAP和GitHub通过预先建立的用户进行验证集成。
Rancher在环境层面支持基于角色的访问控制（RBAC），允许用户和组分享或拒绝访问，例如开发和生产环境。

下图显示了Rancher的主要组件和功能。

## RancherOS 概述
---
RancherOS是一个轻量级Linux分发版，操作系统完全由Docker容器组成。
RancherOS中的所有内容都是由Docker管理的容器，包括系统服务，如udev和syslog。RancherOS仅包含运行Docker所需的最少量的软件。

## 一个由容器组成的操作系统

在RancherOS中，Docker守护进程是内核启动时运行的第一个程序。我们将这个Docker实例称为“System Docker”，因为它负责启动系统服务，如udev、DHCP和控制台。
每一个这种系统服务都是以容器形式运行的。System Docker代替了其他Linux分发版中的init系统，如sysvinit或systemd。

## 在独立的Docker守护进程中运行的User Docker

RancherOS创建了一个名为User Docker的特殊的系统服务容器，它是由System Docker创建的。User Docker容器中运行着一个独立的Docker守护进程。
因为所有的用户容器都在User Docker容器中运行，即使删除所有用户容器，都不会破坏运行着RancherOS服务的系统容器。

## 简单的更新与回滚

RancherOS利用极其强大的Docker包装和分装支持，来提供操作系统的更新和功能。一切系统服务都作为Docker容器被提供，而内核和初始RAM磁盘不是Docker容器，因此我们也用Docker包装和分装来提供内核和RAM磁盘的更新。

## 管理RancherOS

传统的Linux分发版通常被主要设计为由管理员手动操作。然而，RancherOS最开始设计的初衷就是要利用Docker API和主机复杂管理代理，让它们可以在大规模生产中通过Rancher这样的容器管理平台被轻松管理。
