---
title: 创建私有Catalogs模板
---

私有应用商店要遵循应用商店服务指定的格式才可以正常的在Rancher中显示出来。

### 模板文件夹

应用商店将会根据环境中的调度引擎来显示不同的应用商店模板。

#### 基于不同调度引擎的模板

* _Cattle_ 调度引擎: 界面中的应用模板来自`templates`文件夹
* _[Swarm]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/swarm/)_ 调度引擎: 界面中的应用模板来自`swarm-templates`文件夹
* _[Mesos]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/mesos/)_ 调度引擎: 界面中的应用模板来自`mesos-templates`文件夹

### 基础设施服务模板

Rancher的[基础设施服务]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/rancher-services/)可以从[环境模板]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/environments/#什么是环境模版)中启用, 这些模板来自于`infra-templates`文件夹。

这些服务从**应用商店**菜单中也可以看到, 你可以看到全部的基础设施服务包括那些和当前的编排调度引擎不兼容的服务. 我们建议从环境模板中启用基础设施服务，而不是直接从应用商店中启动。

### 目录结构

```
-- templates (Or any of templates folder)
  |-- cloudflare
  |   |-- 0
  |   |   |-- docker-compose.yml
  |   |   |-- rancher-compose.yml
  |   |-- 1
  |   |   |-- docker-compose.yml
  |   |   |-- rancher-compose.yml
  |   |-- catalogIcon-cloudflare.svg
  |   |-- config.yml
...
```

你需要创建一个`templates`文件夹作为根目录。`templates`文件夹将包含所有你想创建的应用的文件夹。我们建议为应用的文件夹起一个简单明了的名称。

在应用模板的文件夹中 (例如 `cloudflare`), 将包含该应用模板的各个版本所对应的文件夹。第一个版本为`0`，后续每个版本加1。比如，第二个版本应该在 `1` 文件夹中。每增加一个新版本的文件夹，你就可以使用这个新版本的应用模版来升级你的应用了。另外，你也可直接更新`0`文件夹中的内容并重新部署应用。

> **注意：** 应用文件夹名称需要为一个单词，文件名中不能包含空格。针对名字比较长的应用请使用`-` 连接符。在`config.yml`中的 `name`你可以使用空格。

### 在Rancher应用商店中展示出的Rancher Catalog文件

在应用商店模板的文件夹中，如何展示应用商店模板详细内容取决于两个文件。

* 第一个文件为 `config.yml`，包含了应用模板的详细信息。

```yaml
name: # 应用商店模板名称
description: |
  # 应用商店模板描述
version: # 应用商店模板对应的版本
category: # 用于模板搜索时的目录
maintainer: # 该模板的维护者
license: # 许可类型
projectURL: # 和模板相关的URL
```

* 另外一个文件为该模板的logo。该文件的前缀必须为 `catalogIcon-`。

对于每一个应用模板，将至少有以下三个部分组成： `config.yml`, `catalogIcon-entry.svg`, 以及 `0` 文件夹 - 包含该模板的第一个版本配置。

### Rancher 应用商店模板

 `docker-compose.yml`以及`rancher-compose.yml`为在Rancher中使用[Rancher Compose]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/adding-services/#使用-rancher-compose-添加服务)启动服务**必须**提供的两个文件. 该文件将被保存在版本文件夹中。 (如： `0`, `1`, 等等)。

 `docker-compose.yml`为一个可以使用 `docker-compose up`来启动的文件。 该服务遵循docker-compose格式。

 `rancher-compose.yml`将包含帮助你自定义应用模板的其他信息。在`catalog`部分中，为了应用模板可以被正常使用，有一些选项是必填的。

你也可以创建一个可选的 `README.md` , 可以为模板提供一些较长的描述以及如何使用他们。

**`rancher-compose.yml`**

```yaml
version: '2'
catalog:
  name: # Name of the versioned template of the Catalog Entry
  version: # Version of the versioned template of the Catalog Entry
  description: # Description of the versioned template of the Catalog Entry
  minimum_rancher_version: # The minimum version of Rancher that supports the template, v1.0.1 and 1.0.1 are acceptable inputs
  maximum_rancher_version: # The maximum version of Rancher that supports the template, v1.0.1 and 1.0.1 are acceptable inputs
  upgrade_from: # The previous versions that this template can be upgraded from
  questions: #Used to request user input for configuration options
```

对于 `upgrade_from`, 有三种值可以使用。

1. 只允许从某一个版本升级： `"1.0.0"`
2. 可以从高于或低于某一个版本升级： `">=1.0.0"`, `"<=2.0.0"`
3. 定义一个[区间升级](https://github.com/blang/semver#ranges): `">1.0.0 <2.0.0 || >3.0.0"`

> **注意：** 如同例子中的配置，请确保你配置的版本号或版本范围带上双引号。

### `rancher-compose.yml`中的问题部分

 `应用商店`中`questions` 部分允许用户更改一个服务的一些配置选项。 其`答案` 将在被服务启动之前被预配置在 `docker-compose.yml` 中.

每一个配置选项都在`rancher-compose.yml`的 `questions` 部分配置.

```yaml
version: '2'
catalog:
  questions:
    - variable: # A single word that is used to pair the question and answer.
      label: # The "question" to be answered.
      description: | # The description of the question to show the user how to answer the question.
      default: # (Optional) A default value that will be pre-populated into the UI
      required: # (Optional) Whether or not an answer is required. By default, it's considered `false`.
      type: # How the questions are formatted and types of response expected
```
#### 类型

 `type` 控制了问题如何在UI中展现以及需要什么样的答案。
 
合法的格式有:

* `string` UI中将显示文本框来获取答案，获取到的答案将被设置为字符串型格式。
* `int` UI中将显示文本框来获取答案，获取到的答案将被设置为整型格式。 UI会在服务启动前对输入进行校验。
* `boolean` UI中将通过单选按钮获取答案，获取到的答案将被格式化为`true` 或者 `false`。 如果用户选择了单选按钮，答案将被格式化为 `true`。
* `password` UI中将显示文本框来获取答案，获取到的答案将被设置为字符串型格式。
* `service` UI中将展示一个下拉框，所有该环境的服务都会显示出来。
* `enum` UI中将展示一个下拉框，`options`中的配置将会被展示出来。

```yaml
version: '2'
catalog:
  questions:
    - variable:
      label:
      description: |
      type: enum
      options: # List of options if using type of `enum`
        - Option 1
        - Option 2
```
* `multiline` 多行文本框会被显示在UI中。

```yaml
version: '2'
catalog:
  questions:
    - variable:
      label:
      description: |
      type: multiline
      default: |
        Each line
        would be shown
        on a separate
        line.
```
* `certificate` 该环境的所有可用证书都会显示出来。

```yaml
version: '2'
catalog:
  questions:
    - variable:
      label:
      description: |
      type: certificate
```
### 例如: 制作oracle DB模板

*  新建oracle-databases文件夹
*  新建“0”文件夹（0表示第一个版本），在同级目录下再新建config.yml和catalogIcon-oracledb.svg
*  在config.yml填写以下内容：

```
name: oracle databases
description: |
  oracle databases
version: 11.2.0.4-ee
category: Applications
```
* 进入0文件夹，新建 docker-compose.yml.tpl 和 rancher-compose.yml 
* docker-compose.yml.tpl 内容如下：

```
version: '2'
services:
    oracle-db:
        labels:
            io.rancher.container.pull_image: always
            io.rancher.sidekicks: db-storage

        image: oracle/database:12.2.0.1-ee
        shm_size: ${SHM_SIZE}g
        environment:
            - "ORACLE_SID=${ORACLE_SID}"
            - "ORACLE_PDB=${ORACLE_PDB}"
            - "ORACLE_PWD=${ORACLE_PWD}"
            - "ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET}"
        ports:
            - ${EMR_PROT}:1521/tcp
            - ${EMWC_PROT}:5500/tcp
            - ${XE_PROT}:8080/tcp
            
        volumes_from:
            - db-storage

    db-storage:
        labels:
            io.rancher.container.start_once: true
        network_mode: none
        image: library/alpine
    
        volumes:
            - db-storage-volume:/opt/oracle/oradata
            - db-storage-volume:/opt/oracle/scripts/startup

volumes:
  db-storage-volume:
    driver: ${VOLUME_DRIVER}
    per_container: true


```
* rancher-compose.yml 内容如下

```
version: '2'
catalog:
    name: oracle databases
    version: 11.2.0.4-ee
    description: oracle databases-11.2.0.4-ee

    questions:
        - variable: "SHM_SIZE"
          type: "int"
          required: true
          label: ""
          description: "The Oracle Database SID that should be used (default: 1)"
          default: 1

        - variable: "ORACLE_SID"
          type: "string"
          required: true
          label: ""
          description: "The Oracle Database SID that should be used (default: ORCLCDB)"
          default: ORCLCDB

        - variable: "ORACLE_PDB"
          type: "string"
          required: true
          label: ""
          description: "The Oracle Database PDB name that should be used (default: ORCLPDB1)"
          default: "ORCLPDB1"

        - variable: "ORACLE_PWD"
          type: "password"
          required: true
          label: ""
          description: "The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated)"
          default: ""

        - variable: "ORACLE_CHARACTERSET"
          type: "string"
          required: true
          label: ""
          description: "The character set to use when creating the database (default: AL32UTF8)"
          default: "AL32UTF8"

        - variable: "XE_PROT"
          type: "int"
          required: true
          label: ""
          description: "Oracle XMLDB HTTP port"
          default: 8080

        - variable: "EMWC_PROT"
          type: "int"
          required: true
          label: ""
          description: "Oracle Enterprise Manager Web Console"
          default: 5500

        - variable: "EMR_PROT"
          type: "int"
          required: true
          label: ""
          description: "Oracle Enterprise Manager Repository port"
          default: 1521

        - variable: "VOLUME_DRIVER"
          description: "The VOLUME driver to associate with this server"
          label: "VOLUME Driver"
          required: true
          default: "local"
          type: enum
          options:
            - local
            - rancher-nfs
           
services:
  oracle-db:
    scale: 1
    start_on_create: true
    health_check:
      response_timeout: 2000
      healthy_threshold: 2
      port: 1521
      unhealthy_threshold: 3
      initializing_timeout: 60000
      interval: 2000
      strategy: recreate
      reinitializing_timeout: 60000
      
  db-storage:
    scale: 1
    start_on_create: true

```