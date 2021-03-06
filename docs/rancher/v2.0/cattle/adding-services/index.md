---
title: 服务
---


* Cattle对服务采用标准Docker Compose术语，并将基本服务定义为从同一Docker镜像创建的一个或多个容器。一旦服务（消费者）链接到同一个[应用]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/stacks/)中的另一个服务（生产者）相关的[DNS记录]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/internal-dns-service/) 会被自动创建，“消费”服务的容器可以发现这些容器。在Rancher创建服务的其他好处包括：

* 服务高可用性（HA）：Rancher会不断监控服务中的容器状态，并主动管理以确保所需的服务实例规模。当健康的容器小于（或者多于）正常服务所需容器规模，主机不可用，容器故障或者不能满足健康检查就会被触发。

* [健康检查]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/health-checks/): Rancher通过在主机上运行`healthcheck`的基础设施服务，从而实现了容器和服务的分布式健康检查系统。这个`healthcheck`服务内部使用HAProxy来检查应用程序的运行状况。当在单个容器或服务上启用健康检查时，Rancher将监控每个容器。

### 用户界面中的服务选项

在以下示例中，我们假设你已经创建了一个[应用]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/stacks/), 设置了你的[主机]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/hosts/)，并准备好开始构建应用程序来。

我们将在添加服务的过程中了解一些服务的选项，最后将介绍如何创建一个连接到Mongo数据库的[LetsChat](http://sdelements.github.io/lets-chat/)应用程序。

在`应用`中，你可以通过单击`添加服务`按钮添加服务。也可以在`应用`列表中添加服务 ，每个单个`应用`都可以看到`添加服务`按钮。

在**数量**部分，你可以使用滑块来指定要为服务启动的容器的数量。或者，你可以选择**总是在每台主机上运行一个此容器的实例**。使用此选项时，你的服务将被部署到该[环境]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/environments/)中的任何主机上。如果你在**调度**选项卡中创建了调度规则，则Rancher将仅在符合调度规则的主机上启动容器。

你还需要输入**名称**，如果需要，还可以输入服务**描述**。

为服务设置所需的**镜像**。你可以使用[DockerHub](https://hub.docker.com/)上的任何镜像，以及已添加到你的[环境]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/environments/)中的任何[镜像仓库]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/environments/registries)。镜像名称的语法与`docker run`命令中使用的语法相同。

镜像名称的语法。默认情况下，我们从Dockerhub中拉取。如果没有指定标签，我们将拉取标签为tag的镜像。

`[registry-name]/[namespace]/[imagename]:[version]`

在镜像名称下方，有一个复选框`创建前总是拉取镜像`。默认情况下，这是被勾选的。选择此选项后，每次在主机上启动容器的时候，都将**始终**尝试拉取镜像，即使该镜像已被缓存在了该主机上。

#### 选项

Rancher努力与Docker保持一致，我们的目标是，支持任何`docker run`所支持的选项。端口映射和服务链接显示在主页面上，但所有其他选项都在不同的选项卡中。

默认情况下，服务中的所有容器都以分离模式运行，例如：`docker run`命令中的`-d`。

##### 端口映射

当配置了映射端口后，你可以通过主机上的公共端口访问容器暴露的端口。在**端口映射**部分中，需要设置暴露在主机上的端口。该端口将流量指向你设置的私有端口。私有端口通常是容器上暴露的端口（例如：镜像的[Dockerfile](https://docs.docker.com/engine/reference/builder/#expose)中的`EXPOSE`）。当你映射一个端口时，Rancher将会在启动容器之前检查主机是否有端口冲突。

当使用端口映射时，如果服务的容器规模大于具有可用端口的主机数量时，你的服务将被阻塞在正在激活状态。如果你查看服务的详细信息，你将可以看到`Error`状态的容器，这表明容器由于无法在主机上找到未被占用的端口而失败。该服务将继续尝试，如果发现有主机/端口可用，则该服务将在该主机上启动一个容器。

> **注意：** 当在Rancher中暴露端口时，它只会显示创建时暴露端口。如果端口映射有任何改变，它不会在`docker ps`中更新，因为Rancher通过管理iptable规则，来实现端口动态变更的。

##### 随机端口映射

如果你想要利用Rancher的随机端口映射，公共端口可以留空，你只需要定义私有端口。

##### 链接服务

如果你的环境中已经创建了其他服务，则可以将已有服务链接到你正在创建的服务。正在创建的服务中的所有容器都会链接到目标服务中的所有容器。链接就像`docker run`命令中的`--link`功能一样。

链接是基于Rancher[内部DNS]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/internal-dns-service/)的附加功能，当你不需要按服务名称解析服务时，可以使用链接。

#### Rancher 选项

除了提供`docker run`支持的所有选项之外，Rancher还通过UI提供了额外选项。

##### 健康检查

如果Rancher中主机不能正常工作来（例如：处于`reconnecting`或`inactive`状态），你需要配置健康检查，以使Rancher将服务中的容器调度到其他的主机上。

> **注意：** 健康检查仅适用于托管网络的服务。如果你选择任何其他网络，则**不能**被监察到。

在**健康检查**选项卡中，你可以选择检查服务的TCP连接或HTTP响应。

阅读有关Rancher如何处理[健康检查]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/health-checks/)的更多详细信息。

##### 标签/调度

在**标签**选项卡中，Rancher允许将任何标签添加到服务的容器中。标签在创建调度规则时非常有用。在**调度**选项卡中，你可以使用[主机标签]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/hosts/#主机标签)，容器/服务标签，和容器/服务名称来创建你服务需要的调度规则。

阅读有关[标签与调度]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/scheduling/)的更多细节。

### 在UI中添加服务

首先，我们通过设置`数量`为1个容器的服务来创建我们的数据库，给它设置名称`database`，并使用`mongo:latest`镜像。不需要其他的配置，点击**创建**。该服务将立即启动。

现在我们已经启动了我们的数据库服务，我们将把web服务添加到我们的`应用`中。这一次，我们将服务规模设置为2个容器，创建一个名称为`web`并使用`sdelements/lets-chat`作为镜像的服务。我们没有暴露Web服务中的任何端口，因为我们将添加负载均衡来实现服务访问。我们已经创建了数据库服务，我们将在**服务链接**的`目标服务`选择数据库服务，在`名称`中填写`mongo`。点击**创建**，我们的[LetsChat](http://sdelements.github.io/lets-chat/)应用程序已准备好了，我们马上可以用负载均衡服务来暴露端口了。

### Rancher Compose 中的服务选项

阅读更多关于[配置Rancher Compose]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/rancher-compose/)的细节。

Rancher Compose工具的工作方式和Docker Compose一样，并支持V1和V2版本的docker-compose.yml文件。要启用Rancher支持的功能，你还可以使用扩展或重写了docker-compose.yml的rancher-compose.yml文档。例如，rancher-compose.yml文档包含了服务的`scale`和`healthcheck`。

如果你不熟悉Docker Compose或Rancher Compose，我们建议你使用UI来启动你的服务。你可以通过单击`应用`的下拉列表中的**查看配置**来查看整个应用的配置（例如：与你的应用等效的docker-compose.yml文件和rancher-compose.yml文件）。

#### 链接服务

在Rancher中，环境中的所有服务都是可以通过DNS解析的，因此不需要明确设置服务链接，除非你希望使用特定的别名进行DNS解析。

> **注意：** 我们目前不支持将从服务与主服务相关联，反之亦然。阅读更多关于[Rancher内部DNS工作原理]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/internal-dns-service/)。

应用中的服务都是可以通过服务名称`service_name`来解析的，当然，你也可以通过链接来使用其他名称进行解析。

##### 例子  `docker-compose.yml`

```yaml
version: '2'
services:
  web:
    labels:
      io.rancher.container.pull_image: always
    tty: true
    image: sdelements/lets-chat
    links:
    - database:mongo
    stdin_open: true
  database:
    labels:
      io.rancher.container.pull_image: always
    tty: true
    image: mongo
    stdin_open: true
```
<br>

在这个例子中，`mongo`可以解析为`database`。如果没有链接，`web`服务需要通过服务名称`database`来解析数据库服务。

对于不同`应用`中的服务，可以使用`service_name.stack_name`对服务进行解析。如果你希望使用特定别名进行DNS解析，则可以在`docker-compose.yml`中使用`external_links`。

##### 例子  `docker-compose.yml`

```yaml
version: '2'
services:
  web:
    image: sdelements/lets-chat
    external_links:
    - alldbs/db1:mongo
```
<br>

在此示例中，`alldbs`应用中的`db1`服务将链接到`web`服务。在web服务中，`mongo`将可解析为`db1`。没有外部链接时，`db1.alldbs`将可解析为`db1`。

> **注意：** 跨应用的服务发现受环境的限制（特意设计的）。不支持应用的跨环境发现。

### 使用 Rancher Compose 添加服务

阅读更多关于[配置Rancher Compose]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/rancher-compose/)的详情.

我们将创建与上面通过UI创建的相同示例。首先，你将需要创建一个`docker-compose.yml`文件和一个`rancher-compose.yml`文件。使用Rancher Compose，我们可以一次启动应用程序中的所有服务。如果没有`rancher-compose.yml`文件，则所有服务将以1个容器的规模启动。

#### 例子 `docker-compose.yml`

```yaml
version: '2'
services:
  web:
    labels:
      io.rancher.container.pull_image: always
    tty: true
    image: sdelements/lets-chat
    links:
    - database:mongo
    stdin_open: true
  database:
    labels:
      io.rancher.container.pull_image: always
    tty: true
    image: mongo
    stdin_open: true
```

#### 例子 `rancher-compose.yml`

```yaml
# 你想要拓展的效果服务
version: '2'
services:
  web:
    scale: 2
  database:
    scale: 1
```
<br>

创建文件后，可以将服务部署到Rancher Server。

```bash
#创建并启动一个没有环境变量的服务并选择一个应用
#如果没有提供应用名称，应用的名称将是命令运行的文件夹名称
#如果该应用没有存在于Rancher中，它将会被创建
$ rancher-compose --url URL_of_Rancher --access-key <username_of_environment_api_key> --secret-key <password_of_environment_api_key> -p LetsChatApp up -d

#创建并运行一个已经设置好环境变量的服务
$ rancher-compose -p LetsChatApp up -d
```

### 从服务

Rancher支持通过使用从服务的概念对服务进行分组，从而使一组服务可以同时进行调度和扩缩容。通常创建具有一个或多个从服务的服务，来支持容器之间共享卷（即`--volumes_from`）和网络（即`--net=container`）。

你可能希望你的服务的使用`volumes_from`和`net`去连接其他服务。为了实现这一点，你需要在服务直接建立一个从属关系。通过从属关系，Rancher可以将这些服务作为一个单元进行扩容和调度。例如：B是A的从服务，Rancher始终将A和B作为一对进行部署，服务的数量规模将始终保持一致。

如果你有多个服务总需要部署在同一主机上，你也可以通过定义从属关系来实现它。

当给一个服务定义一个从服务时，你不需要链接该服务，因为从服务会自动被DNS解析到。

当在服务中使用[负载均衡]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/adding-load-balancers/)时，而该服务又拥有从服务的时候，你需要使用主服务作为负载均衡器的目标。从服务**不能**成为目标。
了解更多关于[Rancher内部DNS]({{site.baseurl}}/rancher/{{page.version}}/{{page.lang}}/cattle/internal-dns-service/)的详情。

#### 在UI中添加从服务

要设置一个从服务，你可以点击**+添加从容器**按钮，按钮位于页面的`数量`那部分。第一个服务被认为是主服务，后面每个附加的从服务都是辅助服务。

#### 通过Rancher Compose添加从服务

要设置`sidekick`关系，请向其中一个服务添加标签。标签的键是`io.rancher.sidekicks`，该值是从服务。如果你要将多个服务添加为从服务，可以用逗号分隔。例：`io.rancher.sidekicks: sidekick1, sidekick2, sidekick3`

##### 主服务

无论哪个服务包含sidekick标签都被认为是主服务，而各个sidekicks被视为从服务。主服务的数量将用作sidekick标签中所有从服务的数量。如果你的所有服务中的数量不同，则主服务的数量将用于所有服务。

当使用负载均衡器指向带有从服务的服务时，你只能指向主服务，从服务**不能**成为目标。

##### Rancher Compose里面的从容器例子:

例子`docker-compose.yml`

```yaml
version: '2'
services:
  test:
    tty: true
    image: ubuntu:14.04.2
    stdin_open: true
    volumes_from:
    - test-data
    labels:
      io.rancher.sidekicks: test-data
  test-data:
    tty: true
    command:
    - cat
    image: ubuntu:14.04.2
    stdin_open: true
```

<br>
例子 `rancher-compose.yml`

```yaml
version: '2'
services:
  test:
    scale: 2
  test-data:
    scale: 2
```

##### Rancher Compose里面的从服务例子:多服务使用来自同一个服务`volumes_from`

如果你有多个服务，他们将使用相同的容器去做一个`volumes_from`，你可以添加第二个服务作为主服务的从服务，并使用相同的数据容器。由于只有主服务可以作为负载均衡的目标，请确保选择了正确的服务作为主服务（即，具有sidekick标签的服务）。
示例 `docker-compose.yml`

```yaml
version: '2'
services:
  test-data:
    tty: true
    command:
    - cat
    image: ubuntu:14.04.2
    stdin_open: true
  test1:
    tty: true
    image: ubuntu:14.04.2
    stdin_open: true
    labels:
      io.rancher.sidekicks: test-data, test2
    volumes_from:
    - test-data
  test2:
    tty: true
    image: ubuntu:14.04.2
    stdin_open: true
    volumes_from:
    - test-data
```
