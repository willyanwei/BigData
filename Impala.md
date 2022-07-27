# Impala  

Cloudera成立于2008年，在企业和大型机构在寻求解决棘手的大数据问题时，往往会使用开源软件基础架构Hadoop的服务。  
2018年10月，均为开源平台的Cloudera与Hortonworks公司宣布他们以52亿美元的价格合并。
由于Hadoop深受客户欢迎，许多公司都推出了各自版本的Hadoop，也有一些公司则围绕Hadoop开发产品。  
在Hadoop生态系统中，规模最大、知名度最高的公司则是Cloudera。

## Impala简介
1. 实时SQL查询引擎
2. 基于MPP （Massively Parallel Processor ，大规模并行处理）   
3. Cloudera在受到Google的Dremel启发下开发的实时交互SQL大数据查询工具；    
4. Impala没有再使用缓慢的Hive+MR批处理，而且通过使用与商用并行关系数据库中类似的分布式查询引擎，可以直接从HDFS或HBase中的Select、Join和统计函数查询数据，能查询存储在Hadoop的HDFS和HBase中的PB级大数据，从而大大降低延迟；      
5. Impala最大的卖点就是——快速

## Impala的定位  
Impala 是可用于查询大数据的工具的补充。  
Impala 不会替代基于 MapReduce 构建的批处理框架，例如 Hive。Hive 和其他基于 MapReduce 构建的框架最适合长时间运行的批处理作业，例如涉及提取、转换和加载 (ETL) 类型作业的批处理。

Impala是spark萌芽时期cdh开源的c++编写的sql执行引擎，也用到了有向无环图和RDD的思路，我想当初可能是CDH想跟spark竞争一下内存计算这块的市场，后来发现争不过spark，现在也就处于半开发半维护的状态了。  
从核心上来说，执行原理跟hive完全不一样，  
hive是把sql转译成java，编译了jar包提交给hadoop，剩下的事情就是hadoop的mr的事了，hive只需要等着获取结果就好了。  
而impala则调用C语言层的libhdfs来直接访问HDFS，从NN获取到数据块信息后，直接将数据块读入内存，会使用hadoop的一个配置项叫dfs.client.short.read.circuit。看得出来，这是一个client端配置，作用是直接读取本地的数据块而不是通过HDFS读取整合后的文件。所以impala需要在每个dn节点都安装impalad去完成本地读取的工作。数据块读进内存之后就开始做有向无环图，完成计算之后会将热数据保存在内存里供下次读取。

## Impala优缺点
* Impala优点  
基于内存运算，不需要把中间结果写入磁盘，省掉了大量的I/O开销。  
无需转换为Mapreduce,直接访问存储在HDFS, HBase中的数据进行作业调度，速度快。  
使用了支持Data locality的I/O调度机制，尽可能地将数据和计算分配在同一台机器上进行，减少了网络开销。  
支持各种文件格式,如TEXTFILE、SEQUENCEFILE、RCFile. Parqueto  
可以访问hive的metastore,对hive数据直接做数据分析。

* Impala缺点  
对内存的依赖大，且完全依赖于hive。  
实践中，分区超过1万，性能严重下降。  
只能读取文本文件，而不能直接读取自定义二进制文件。  
每当新的记录/文件被添加到HDFS中的数据目录时，该表需要被刷新。  


## Impala系统架构  
Impala主要由Impalad， State Store和CLI组成。  

1. Impalad   
	* 运行节点  
	Impala与DataNode运行在同一个节点；   
	通常每一个HDFS的DataNode上部署一个Impalad进程，由于HDFS存储数据通常是多副本的，所以这样的部署可以保证数据的本地性，查询尽可能的从本地磁盘读取数据而非网络，从这点可以推断出Impalad对于本地数据的读取应该是通过直接读本地文件的方式，而非调用HDFS的接口。  
	为了实现查询分割的子任务可以做到尽可能的本地数据读取，Impalad需要从Metastore中获取表的数据存储路径，并且从NameNode中获取每一个文件的数据块分布。
	
	
	* Impalad服务 
	在Impalad中启动三个ThriftServer:   
		1. beeswax_server（连接客户端），  
		2. hs2_server（借用Hive元数据），   	
		3. be_server（Impalad内部使用）  
		和一个ImpalaServer服务。

	* Impalad负责查询工作的进程：   
		1. Query Planner  		查询计划者   
		2. Query Coordinator	查询协调者  
		3. Query Exec Engine  	查询执行者  
	
	* 前端进程  
		* Query Planner Query Coordinator	  
		两个进程组成前端，负责接收SQL查询请求，解析SQL并转换成执行计划，交由后端执行

		* Query Planner   
		两步生成物理执行计划：  
			1.  生成单节点执行计划    
			根据类似于RDBMS进行执行优化的过程，决定join顺序，对join执行谓词下推，根据关系运算公式进行一些转换等，这个执行计划的生成过程依赖于Impala表和分区的统计信息  
			2. 根据得到分区生成并行的执行计划
			根据上一步生成的单节点执行计划得到分布式执行计划，可参照Dremel的执行过程。在上一步已经决定了join的顺序，这一步需要决定join的策略：使用hash join还是broadcast join，前者一般针对两个大表，根据join键进行hash分区以使得相同的id散列到相同的节点上进行join，后者通过广播整个小表到所有节点，Impala选择的策略是依赖于网络通信的最小化。
			
		* Query Coordinator  
			1. 查询协调：  
			接收客户端的查询请求--接收客户端查询请求的Impala为Coordinator，Coordinator通过JNI调用JAVA前端解释SQL查询语句，生成查询计划树，在通过调度器把执行计划分发给具有相应数据的其他Impala执行   
			语法方面它既支持基本的操作（select、project、join、group by、filter、order by、limit等），  
			也支持关联子查询和非关联子查询，  
			支持各种outer-join和窗口函数，这部分按照通用的解析流程分为查询解析->语法分析->查询优化，最终生成物理执行计划。

			2. 聚合操作：  
			通常需要首先在每个节点上执行预聚合，然后再根据聚合键的值进行hash将结果散列到多个节点再进行一次merge，最终在coordinator节点上进行最终的合并（只需要合并就可以了），当然对于非group by的聚合运算，则可以将每一个节点预聚合的结果交给一个节点进行merge。sort和top-n的运算和这个类似。 
			3. 返回结果  
			由Coordinator最终汇集结果返回给用户

	* 后端进程
		*  Query Exec Engine
			Query Coordinator初始化查询任务后，  Query Exec Engine执行，Query Coordinator  的聚合操作在这一步之后  

			对于当前Impalad和其它Impalad进程而言，同时是本次查询的执行者，完成数据读取、物理算子的执行并将结果返回给协调者Impalad。  这种无中心查询节点的设计能够最大程度的保证容错性并且很容易做负载均衡。
			

	* Impala和State Store联系  
	Impalad与State Store关系类似于HDFS的DataNode和NameNode  
	Impalad与State Store保持连接，用于确定哪个Impalad是健康和可以接受新的工作  
	
2. State Store    
	* StateStore服务完成两个工作：  
		1. 消息订阅服务  
		1. 状态监测功能    
		Catalog中的元数据就是通过StateStore服务进行广播分发的，它实现了一个Pub-Sub服务，Impalad可以注册它们希望获得的事件类型，Statestore会周期性的发送两种类型的消息给Impalad进程:  
		**一种**为该Impalad注册监听的事件的更新，基于版本的增量更新（只通知上次成功更新之后的变化）可以减小每次通信的消息大小;  
		**另一种**消息为心跳消息，StateStore负责统计每一个Impalad进程的状态，Impalad可以根据此了解其余Impalad进程的状态，用于判断分配查询任务到哪些节点。 

		> **不需要保证所有Impalad状态一致**   
		>     由于周期性的推送并且每一个节点的推送频率不一致可能会导致每一个Impalad进程获得的状态不一致，  
		>     由于每一次查询只依赖于协调者Impalad进程获取的状态进行任务的分配，  
		>     而不需要多个进程进行再次的协调，因此并不需要保证所有的Impalad状态是一致的。   
		> **单个服务器宕机怎么办？**  
		>     StateStore进程是单点的，并且不会持久化任何数据到磁盘，如果服务挂掉，Impalad则依赖于上一次获得元数据状态进行任务分配，  
		>     官方并没有提供可靠性部署的方案，通常可以使用DNS方式绑定多个服务以应对单个服务挂掉的情况
	
	* **跟踪集群中的Impalad的健康状态及位置信息**    
	由statestored进程表示，它通过创建多个线程来处理Impalad的注册订阅和与各Impalad保持心跳连接，各Impalad都会缓存一份State Store中的信息，当State Store离线后（Impalad发现State Store处于离线时，会进入recovery模式，反复注册，当State Store重新加入集群后，自动恢复正常，更新缓存数据）因为Impalad有State Store的缓存仍然可以工作，但会因为有些Impalad失效了，而已缓存数据无法更新，导致把执行计划分配给了失效的Impalad，导致查询失败。

	* **协调各个运行impalad的实例之间的信息关系**  
	Impala正是通过这些信息去定位查询请求所要的数据。换句话说，state store的作用主要为跟踪各个impalad实例的位置和状态，让各个impalad实例以集群的方式运行起来。

	* **State Store宕机后，新加入的impalad实例不为现有集群中的其他impalad实例所识别**  
	与HDFS的NameNode不一样，State Store一般只安装一份，不会像NN一样做主备，  
	但一旦State Store挂掉了，各个impalad实例却仍然会保持集群的方式处理查询请求，只是无法将各自的状态更新到State Store中，  
	如果这个时候新加入一个impalad实例，则新加入的impalad实例不为现有集群中的其他impalad实例所识别（事实上，经测试，如果impalad启动在statestored之后，根本无法正常启动，因为impalad启动时是需要指定statestored的主机信息的）。  
	然而，State Store一旦重启，则所有State Store所服务的各个impalad实例（包括state store挂掉期间新加入的impalad实例）的信息（由impalad实例发给state store）都会进行重建。

	

3. Impala Catalog  
	Catalog服务提供了元数据的服务，它以单点的形式存在，它既可以从外部系统（例如HDFS NameNode和Hive Metastore）拉取元数据，也负责在Impala中执行的DDL语句提交到Metatstore，由于Impala没有update/delete操作，所以它不需要对HDFS做任何修改。
	
	向Impalad中导入数据（DDL）：  
	1. 通过Hive：   
	通过hive则改变的是Hive metastore的状态，此时需要通过在Impala中执行REFRESH以通知元数据的更新  
	2. 通过Impalad  
	Impalad会将该更新操作通知Catalog，后者通过广播的方式通知其它的Impalad进程  
	

	> 默认情况下Catalog是异步加载元数据的，因此查询可能需要等待元数据加载完成之后才能进行（第一次加载）。该服务的存在将元数据从Impalad进程中独立出来，可以简化Impalad的实现，降低Impalad之间的耦合。`  

	**statestored和catalogd这两个进程在同一节点上**    
	Imppalla catalog服务将SQL语句做出的元数据变化通知给集群的各个节点，catalog服务的物理进程名称是catalogd，在整个集群中仅需要一个这样的进程。由于它的请求会跟statestore daemon交互，所以最好让statestored和catalogd这两个进程在同一节点上。

4. CLI  
	提供给用户查询使用的命令行工具（Impala Shell使用python实现），同时Impala还提供了Hue，JDBC， ODBC使用接口。  
	该客户端工具提供一个交互接口，供使用者发起数据查询或管理任务，比如连接到impalad。  
	这些查询请求会传给ODBC这个标准查询接口。

## Impala查询执行过程  

**版本一**  
1. 用户提交查询前，Impala创建一个Impalad进程，该进程向Impala State Store注册申请；State Store产生一个StateStored进程，用于监测所有Impalad进程  
2. 用户通过CLI客户端提交查询到一个Impalad进程，Query Planner进行一系列操作（SQL语句 → 语法树 → 查询块），然后给Query Coordinator  
3. Query Coordinator从MySQL元数据库获取元数据，从HDFS名称节点获取数据地址  
4. Query Coordinator初始化查询任务，分配给所有相关的数据节点
各个Query Exec Engine之间通过流式交换中间输出（流式就像水管里的水，源源不断但不要求实时），并向Query Coordinator汇聚结果  
5. Query Coordinator汇总结果，返回给CLI客户端   

----------
**版本优化后**  

impalad分为frontend和backend两个层次：  
frondend用java实现（通过JNI嵌入impalad）， 负责查询计划生成；  
backend用C++实现， 负责查询执行。  
   
1. 用户提交查询前，    
	Impala创建一个Impalad进程，该进程向Impala State Store注册申请；  
	State Store产生一个StateStored进程，用于监测所有Impalad进程  
2. 客户端通过ODBC/JDBC/Shell 向Impala集群的任意节点发送SQL语句，  
该节点的Query Planner进行一系列的操作（SQL语句 → 语法树 → 查询块），  
生成查询计划分为两个阶段：
（1）生成单机查询计划，单机执行计划与关系数据库执行计划相同，所用查询优化方法也类似。
（2）生成分布式查询计划。 根据单机执行计划， 生成真正可执行的分布式执行计划，降低数据移动， 尽量把数据和计算放在一起。

3. 将这个节点的Impala实例作为这个查询的协调器Coordinator  
3. Impala解析和分析这个查询语句来决定集群中的哪个impalad实例来执行某个任务  
4. HDFS和HBase给本地的Impala的实例提供数据访问：  
Query Coordinator初始化查询任务，分配给所有相关的数据节点  
5. 各个Query Exec Engine之间通过流式交换中间输出（流式就像水管里的水，源源不断但不要求实时），执行SQL结束以后，将结果返回给Query Coordinator，汇聚结果 
6. 再由Query Coordinator 将结果返回给CLI客户端

## Impala实例
1. impala-shell进入到impala的交互窗口  
	impala-shell可以全局使用；进入impala-shell命令行  

	>     [root@linux123 conf]# impala-shell
	>     Connected to linux123:21000
	>     Server version: impalad version 2.3.0-cdh5.5.0 RELEASE (build
	>     0c891d79aa38f297d244855a32f1e17280e2129b)
	>     ******************************************************************************
	>     *****
	>     Welcome to the Impala shell. Copyright (c) 2015 Cloudera, Inc. All rights
	>     reserved.
	>     (Impala Shell v2.3.0-cdh5.5.0 (0c891d7) built on Mon Nov 9 12:18:12 PST 2015)
	>     The SET command shows the current value of all shell and query options.
	>     ******************************************************************************
	>     *****
	>     [linux123:21000] >


	查看所有数据库:     

	>     show databases;  
	>     Fetched 0 row(s) in 4.74s  
	>     [linux123:21000] show databases;  
	>     Query: show databases  
	>     +------------------+  
	>     | name |  
	>     +------------------+  
	>     | _impala_builtins |  
	>     | default |  
	>     | |  
	>     +------------------+  

2. 加载数据至Impalad  
如果想要使用Impala ,需要将数据加载到Impala中 ：   
	（1）使用Impala的外部表，这种适用于已经有数据文件，只需将数据文件拷贝到HDFS上，创建一张 Impala外部表，将外部表的存储位置指向数据文件的位置即可。（类似Hive）  

	（2）通过Insert方式插⼊数据，适用于我们没有数据文件的场景。  
步骤：  
	1. 准备数据  
	user.csv  
		>     392456197008193000,张三,20,0
		>     267456198006210000,李四,25,1
		>     892456199007203000,王五,24,1
		>     492456198712198000,赵六,26,2
		>     392456197008193000,张三,20,0
		>     392456197008193000,张三,20,0
	2. 创建HDFS 存放数据的路径  
		>     hadoop fs -mkdir -p /user/impala/t1
		>     #上传本地user.csv到hdfs /user/impala/table1
		>     hadoop fs -put user.csv /user/impala/t1
	3. 创建表  
		>     #进入impala-shell
		>     impala-shell
		>     #表如果存在则删除
		>     drop table if exists t1;
		>     #执建创建
		>     create external table t1(id string,name string,age int,gender int)
		>     row format delimited fields terminated by ','
		>     location '/user/impala/t1';

	4. 查询数据  
		>     [linux122:21000] select * from t1;  
		>     Query: select * from t1  
		>     +--------------------+------+-----+--------+  
		>     | id | name | age | gender |  
		>     +--------------------+------+-----+--------+  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     | 267456198006210000 | 李四 | 25 | 1 |  
		>     | 892456199007203000 | 王五 | 24 | 1 |  
		>     | 492456198712198000 | 赵六 | 26 | 2 |  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     +--------------------+------+-----+--------+  
		> 
	5. 创建t2表       
		>     #创建⼀个内部表
		>     create table t2(id string,name string,age int,gender int)
		>     row format delimited fields terminated by ',';
		>     #查看表结构
		>     desc t1;
		>     desc formatted t2;
	6. 插入数据到t2  

		>     insert overwrite table t2 select * from t1 where gender =0;  
		>     -- 验证数据  
		>     select * from t2;  
		>     [linux122:21000] select * from t2;
		>     Query: select * from t2
		>     +--------------------+------+-----+--------+  
		>     | id | name | age | gender |  
		>     +--------------------+------+-----+--------+  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     +--------------------+------+-----+--------+  

	7. 更新元数据  
	使用Beeline连接Hive查看Hive中的数据，发现通过Impala创建的表，导⼊的数据都可以被Hive感知到。  
		>     0: jdbc:hive2://linux123:10000show tables;   
		>     +-----------+   
		>     | tab_name |  
		>     +-----------+  
		>     | t1 |  
		>     | t2 |  
		>     +-----------+  
		>     select * from t1;  
		>     0: jdbc:hive2://linux123:10000select * from t1;  
		>     +---------------------+----------+---------+------------+  
		>     | t1.id | t1.name | t1.age | t1.gender |  
		>     +---------------------+----------+---------+------------+  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     | 267456198006210000 | 李四 | 25 | 1 |  
		>     | 892456199007203000 | 王五 | 24 | 1 |  
		>     | 492456198712198000 | 赵六 | 26 | 2 |  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     | 392456197008193000 | 张三 | 20 | 0 |  
		>     +---------------------+----------+---------+------------+  
		>     




## Impala的优缺点  

* 优点   
	1. 不需要把中间结果写入磁盘，省去了大量的I/O开销  
	2. 省掉了MapReduce作业启动的开销。MapReduce速度很慢（心跳间隔是3秒钟）；Impala直接开启进程进行作业调度，速度快了很多
	3. 完全抛弃了MapReduce这个不太适合做SQL查询的范式，而是像Dremel一样借鉴了MPP并行数据库的思想另起炉灶，省掉不必要的shuffle、sort等开销
	4. 用**C++**实现，做了很多有针对性的硬件优化，例如使用SSE指令。
	5. 使用了支持Data locality的I/O调度机制，尽可能地将数据和计算分配在同一台机器上进行，减少了网络开销。



* 缺点

	1. Catalogd守护进程和StateStored监控进程都是单点服务。如果Catalogd或Statestored挂掉，所有的Impalad进程就成了一座座孤岛
	2. web信息不持久，Impala重启则信息丢失
	2. 通过Hive操作MetaStore需要手动同步Impala。
	3. 底层存储不能区分用户
	4. MPP架构要求节点配置均衡，否则最慢的节点会拖慢整个执行速度（短板效应）


## Impala与Hive的比较
* 相同点  
都把数据存储与HDFS和HBase中  
都使用相同的元数据（MetaData）  
ODBC/JDBC驱动、SQL语法、灵活的文件格式、存储资源池
对SQL语句的处理极为相似  

* 不同点  
Hive适合长时间的批处理分析；Impala适合实时交互查询  
Hive依赖MapReduce计算框架；Impala直接抛弃MapReduce而直接开启进程  
Hive在内存不够时会使用外存；Impala不会使用外存（这也是Impala查询时受到限制的原因）  

* 总结  
Impala和Hive之间不是你死我活的关系，实际应用中往往是配合使用（和传统SQL与NoSQL的关系类似——配合而非取代）  
一种思路是：Impala给数据分析人员提供了快速实验、验证想法的大数据分析工具。  
可以先使用hive进行数据转换处理，之后使用Impala在Hive处理后的结果数据集上进行快速的数据分析（批处理 + 实时）   



