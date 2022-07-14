# Ambari  


## Hadoop管理工具  


当你利用 Hadoop 进行大数据分析和处理时，首先你需要确保配置、部署和管理集群。这个即不容易也没有什么乐趣，但却受到了开发者们的钟爱。本文提供了5款工具帮助你实现。

* Apache Ambari

Apache Ambari是对Hadoop进行监控、管理和生命周期管理的开源项目。它也是一个为Hortonworks数据平台选择管理组建的项目。Ambari向Hadoop MapReduce、HDFS、 HBase、Pig, Hive、HCatalog以及Zookeeper提供服务。


* Apache Mesos

Apache Mesos是集群管理器，可以让用户在同一时间同意集群上运行多个Hadoop任务或其他高性能应用。Twitter的开放源代码经理Chris Aniszczyk表示，Mesos可以在数以百计的设备上运行，并使其更容易执行工作。

* Platform MapReduce

Platform MapReduce提供了企业级可管理性和可伸缩性、高资源利用率和可用性、操作便利性、多应用支持以及一个开放分布式系统架构，其中包括对于Hadoop分布式文件系统(HDFS)和Appistry Cloud IQ的即时支持，稍后还将支持更多的文件系统和平台，这将确保企业更加关注将MapReduce应用程序转移至生产环境中。

* StackIQ Rocks+ Big Data

StackIQ Rock+ Big Data是一款Rocks的商业流通集群管理软件，该公司已加强支持Apache Hadoop。Rock+支持Apache、Cloudera、Hortonworks和MapR的分布，并且处理从裸机服务器来管理Hadoop集群配置的整个过程。

* Zettaset Orchestrator

Zettaset Orchestrator是端到端的Hadoop管理产品，支持多个Hadoop的分布。Zettaset吹捧Orchestrator的基于UI的经验和MAAPS(管理、可用性、自动化、配置和安全)的处理能力。


## 什么是Ambari  
Ambari 跟 Hadoop 等开源软件一样，也是 Apache Software Foundation 中的一个项目，并且是顶级项目。  
Ambari 的作用来说，就是创建、管理、监视 Hadoop 的集群，但是这里的 Hadoop 是广义，指的是 Hadoop 整个生态圈（例如 Hive，Hbase，Sqoop，Zookeeper 等），而并不仅是特指 Hadoop。  
用一句话来说，Ambari 就是为了让 Hadoop 以及相关的大数据软件更容易使用的一个工具。


## 为什么需要Ambari
那些苦苦花费好几天去安装、调试 Hadoop 的初学者是最能体会到 Ambari 的方便之处的。   
而且，Ambari 现在所支持的平台组件也越来越多，例如流行的 Spark，Storm 等计算框架，以及资源调度平台 YARN 等，我们都能轻松地通过 Ambari 来进行部署。

## Ambari架构和工作原理  
1. 架构
Ambari 自身也是一个分布式架构的软件，主要由两部分组成：  
（1）Ambari Server   
（2）Ambari Agent  

2. 工作原理  
	* 简单来说：  
	用户通过 Ambari Server 通知 Ambari Agent 安装对应的软件；Agent 会定时地发送各个机器每个软件模块的状态给 Ambari Server，最终这些状态信息会呈现在 Ambari 的 GUI，方便用户了解到集群的各种状态，并进行相应的维护。  

	* 详细步骤：  
		1. Ambari Server 会读取 Stack 和 Service 的配置文件。  
		当用 Ambari 创建集群时，Ambari Server 传送 Stack 和 Service 的配置文件以及 Service 生命周期的控制脚本到 Ambari Agent；  
		2. Agent 拿到配置文件后，会下载安装公共源里软件包（Redhat，就是使用 yum 服务）；  
		3. 安装完成后，Ambari Server 会通知 Agent 去启动 Service。之后 Ambari Server 会定期发送命令到 Agent 检查 Service 的状态，Agent 上报给 Server，并呈现在 Ambari 的 GUI 上。
	> Ambari Server 支持 Rest API，这样可以很容易的扩展和定制化 Ambari。  
	> 甚至于不用登陆 Ambari 的 GUI，只需要在命令行通过 curl 就可以控制 
	> Ambari，以及控制 Hadoop 的 cluster


## Ambria+HDP安装大数据集群  
Ambari + HDP介绍：  
* Ambari：WEB应用程序，后台为Ambari Server，负责与HDP部署的集群工作节点进行通讯，集群控制节点包括Hdfs，Spark，Zk，Hive，Hbase等等。  
* HDP：HDP包中包含了很多常用的工具，比如Hadoop，Hive，Hbase，Spark等。  
* HDP-Util：包含了公共包，比如ZK等一些公共组件。  
  
CentOS7+Ambria2.6.1.0+HDP2.6.4.0安装详细步骤  
https://blog.csdn.net/weixin_39565641/article/details/103522830  
