---
title: 20170808-Validation-test-summary
---

```bash
Validation-test可以对rancher环境进行综合性测试
```
## 一、基础环境准备

### 1、主机资源：

```
需要四个节点，每个至少2C8G。其中一个节点是Rancher-server，其他三个节点为Rancher-agent。
```
### 2、配置每个节点的hosts（/etc/hosts）

```
如果是云服务器，hosts配置中IP地址填写公网地址。
```
### 3、旧版本docker卸载和宿主机系统更新

```
zypper remove docker* #卸载原始docker版本
zypper update   #更新宿主机系统
reboot # 重启系统
```
### 4、安装指定版本docker

```
zypper install docker=1.12.6  #安装指定版本docker
```
## 二、Validation test服务器配置
Validation test 与rancher_server服务放在一台主机运行，登录 rancher_server 所在服务器：

### 1、Validation test 运行需要tox支持，我们通过pip来安装tox。
1.1、pip安装

```bash
wget https://pypi.python.org/packages/11/b6/abcb525026a4be042b486df43905d6893fb04f05aac21c32c638e939e447/pip-9.0.1.tar.gz#md5=35f01da33009719497f01a4ba69d63c9
tar -xzvf pip-*.tar.gz
cd pip-*
python setup.py install 
```
```
PS：如果安装过程中提示ImportError: No module named setuptools，则需要先安装setuptools 工具：
```
```
wget http://pypi.python.org/packages/source/s/setuptools/setuptools-0.6c11.tar.gz
tar zxvf setuptools-0.6c11.tar.gz
cd setuptools-0.6c11
python setup.py build
python setup.py install(最后需要回到pip*目录下执行这句)
```

1.2、安装tox

```bash
pip install tox
```

### 2、Validation test 文件准备
1、克隆Validation test 文件到本地

```
git clone https://github.com/rancher/validation-tests.git 
```
2、修改两个参数（目前这两个参数需手动修改，后期会添加进测试文件）

```bash
1、Edit the tox.ini file in v2_validation directory tests/v2_validation/tox.ini to run the specific tests you need and make sure to add passenv=*, it should look something like that
(如果需要执行特定的测试文件就不要修改，如果要运行某个文件就修改路径)
   
2、Change the line in scripts/test to pushd ./tests/v2_validation instead of pushd ./tests/validation

参考链接：https://github.com/rancher/validation-tests 
```

### 3、环境变量设置

```
export CATTLE_TEST_URL=http://xx.xx.xx.xx:8080  
export CATTLE_RESTART_SLEEP_INTERVAL=10
export ACCESS_KEY=xxxxxxxx
export SECRET_KEY=xxxxxxx
export PROJECT_ID=1a5

参考链接：https://github.com/rancher/validation-tests 
```

## 三、rancher集群安装 （略）

```
PS：rancher安装的时候，如果是云服务器不要用内网地址作为集群通信地址，会影响测试结果。
```

## 四、开始测试

```
进入validation-tests目录，执行：./scripts/test

python文件返回值：
s--skip跳过
F--failure失败
.--成功
```
