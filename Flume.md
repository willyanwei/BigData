#Flume  


## 什么是Flume  
Flume 是 Cloudera 提供的一种高可用、高可靠、分布式的海量日志采集、聚合和传输的系统。  
Flume 基于流式架构，灵活简单。  
Flume 最主要的作用是，实时读取服务器本地磁盘的数据，将数据写到 HDFS。 


## 为什么要用Flume  
Flume是一个分布式的、可靠的、可用的系统，用于有效地收集、聚合和移动大量的日志数据，从许多不同的源到一个集中的数据存储。
Flume的使用不仅限于日志数据聚合。由于数据源是可定制的，Flume可以用来传输大量的事件数据，包括但不限于网络流量数据、社交媒体生成的数据、电子邮件消息以及几乎任何可能的数据源。

Flume的设计宗旨是向类似hadoop分布式集群批量导入基于事件的海量数据。  
一个典型的例子就是利用flume从一组web服务器中收集日志文件，然后把这些文件中的日志事件转移到一个新的HDFS汇总文件中以做进一步的处理，  所以flume的终点sink一般是HDFS,  
当然因为flume本生的灵活性，又可以将采集到的数据输出到HDFS、hbase、hive、kafka等众多外部存储系统中



## Flume优点  
1. 可以和任意存储进程集成
2. 数据输入速率大于写入目标存储的速率（读写速率不同步），Flume会进行缓冲，减少HDFS的压力
3. Flume的事务基于Channel，使用了两个事务模型（sender+receiver），确保消息被可靠发送。  



## Flume的基础架构  
Flume使用两个独立的事务分别负责从source到channel，以及从channel到sink的事件传递。  
一旦事务中所有的数据全部成功提交到channel，那么source才认为该数据读取完成  
只有成功被sink写出去的数据，才会从channel中移除，  
失败后就重新提交  

**Agent**  
Agent是一个JVM进程，以事件形式将数据从源头送至目的地  
Agent 由 source+channel+sink构成  

**事务**  
Put事务流程：  
doPut：将批数据先写入临时缓冲区putList；  
doCommit：检查channel内存队列是否能够合并；  
doRollback：channel内存队列空间不足，回滚数据。  

Take事务：  
doTake：将数据取到临时缓冲区takeList；  
doCommit：如果数据全部发送成功，则清除临时缓冲区takeList；  
doRollback：数据发送过程中如果出现异常，rollback将临时缓存takeList中的数据归还给channel内存队列  

拉取事件到takeList中，尝试提交，如果提交成功就把takeList中数据清除掉；如果提交失败就重写提交，返回到channel后重写提交；

这种事务：flume有可能有重复的数据


**Event传输单元**    
数据传输的基本单位，以Event的形式将数据从源头送至目的地。  
Event由Header和Body两个部分组成。  
Header用来存放该Event的一些属性，为K-V结构；    
Body 用来存放该条数据，形式为字节数组。


**拦截器**  
拦截器是简单的插件式组件，设置在Source和Source写入数据的Channel之间。  
每个拦截器实例只处理同一个Source接收到的事件  
拦截器必须在事件写入channel之前完成转换操作，只有当拦截器成功转换事件后，channel（和任何其他可能产生超时的source）才会响应发送事件的客户端或Sink  
Flume官方提供了一些常用的拦截器，也可以自定义拦截器对日志进行处理


**Source+Channel+Sink**  

1. Source  
	负责接收数据到 Flume Agent 的组件。  
	Source 组件可以处理各种类型、各种格式的日志数据，包括 avro、thrif、exec、jms、spooling directory、netcat、sequence generator、syslog、http、legacy。  

2. Sink  
	1. 不断的轮询Channel中的事件并批量移除他们，并将这些事件批量写入到存储或者索引系统、或者发送到另一个Flume Agent    
	2. Sink组件的目的地包括HDFS、logger、avro、thrif、file、HBase、solr、自定义。
	
	**Sink是完全事务性的**：  
	在从Channel批量删除数据之前，每个Sink用Channel启动一个事务。  
	批量事件一旦成功写出到存储系统或者下一个Flume Agent，Sink就利用Channel提交事务。  
	事务一旦被提交，该Channel从自己的内部缓冲区删除事件  
		
	**Sink Group**  
	允许组织多个Sink到一个实体上，  
	Sink Processors处理器能够提供在组内所有Sink之间实现负载均衡的能力，而且在失败的情况下能够进行故障转移：从一个Sink到另一个Sink。  
	简单来说就是一个Source对应一个SinkGroup，即多个Sink。  
	这里其实跟复用、复制情况差不多，只是这里考虑的是可靠性和性能，即故障转移与负载均衡的设置  
  
    **Sink Processors**
	1. DefaultSink Processor 接收单一的Sink，不强制用户为Sink创建Processor
	2. FailoverSink Processor故障转移处理器会通过配置维护了一个优先级列表。保证每一个有效的事件都会被处理。
	工作原理是将连续失败sink分配到一个池中，在那里被分配一个冷冻期，在这个冷冻期里，这个sink不会做任何事。一旦sink成功发送一个event，sink将被还原到live 池中。
	3. Load balancing Processor负载均衡处理器提供在多个Sink之间负载平衡的能力。实现支持通过① round_robin（轮询）或者② random（随机）参数来实现负载分发，默认情况下使用round_robin  
	

3. Channel  
	位于Source和Sink之间的缓冲区，Channel允许Source和Sink运作在不同的速率上。  
	Channel是线程安全的，可以同时处理几个Source的写入操作和几个Sink的读取操作  
	* Flume常用的Channel：Memory Channel和File Channel  
		* Memory Channel是内存中的队列，Memory Channel适用于不关心数据丢死的情景；如果需要关心数据丢失，那么Memory Channel就不应该使用，因为程序死亡，机器宕机，或者重启都会导致数据丢失  
		* File Channel将所有时间写到磁盘，因此在程序关闭或者机器宕机的情况下不会丢失数据  
	* Channel 选择器是决定Source接收的一定特定事件写入哪些Channel的组件，他们告知Channel处理器，然后由其将事件写入到每个Channel   
	Channel Selector有两种类型： 
		* Replicating Channel Selector-Default，会把所有的数据发给所有的Channel  
		  	复制选择器: 一个 Source 以复制的方式将一个 Event 同时写入到多个 Channel 中，不同的 Sink 可以从不同的 Channel 中获取相同的 Event，比如一份日志数据同时写 Kafka 和 HDFS，一个 Event 同时写入两个 Channel，然后不同类型的 Sink 发送到不同的外部存储。该选择器复制每个事件到通过Source的channels参数所指定的所有的Channels中。  
			复制Channel选择器还有一个可选参数optional，该参数是空格分隔的channel名字列表。  此参数指定的所有channel都认为是可选的，所以如果事件写入这些channel时，若有失败发生，会忽略。而写入其他channel失败时会抛出异常。
		* Multiplexing Channnel Selector-选择把哪个数据发到哪个channel  
			（多路）复用选择器: 需要和拦截器配合使用，根据 Event 的头信息中不同键值数据来判断 Event 应该写入哪个 Channel 中。
		* 自定义选择器  


##Flume的拓扑结构  
1. 串联：  
channel多，但是Flume的层数不宜过多。  
这种模式是将多个Flume给顺序连接起来，从最初的source开始到最终的sink传送的目的存储系统。  
此模式不建议桥接过多的Flume数量，Flume数量多不仅仅影响传输速率，而且一旦传输过程中某个节点flume宕机，会影响整个传输系统。  

2. 单source，多channel、sink；   
一个channel对应多个sink：  
	                  ---->sink1  
　
　　　　　　　　
单source ---> channel---->sink2              

　　　　　　　　　　   ----->sink3　　　　　　　　  


多个channel对应多个sink：  
  				---->channel1 --->sink1  
单source --->  
				---->channel2---->sink  	

Flume支持将事件流向一个或者多个目的地。这种模式将数据源复制到多个channel中，每个channel都有相同的数据，sink可以选择传送的不同的目的地。

3. 负载均衡  
Flume支持使用将多个Sink逻辑上分到一个Sink组，Flume将数据发送到不同的Sink，主要解决负载均衡和故障转移的问题  
负载均衡：  
并排的是三个channel都是轮询的，好处是增大流量并且保证数据的安全；（一个挂了，三个不会都挂；缓冲区比较长，如果hdfs出现问题，两层的channel，多个flune的并联可以保证数据的安全且增大缓冲区）  

4. Flume agent聚合    
日常web应用通常分布在上百个服务器，大者甚至上千个、上万个服务器。  
产生的日志，处理起来也非常麻烦。  
flume的这种组合方式能很好的解决这一问题，每台服务器部署一个flume采集日志，传送到一个集中收集日志的flume，再由此flume上传到hdfs、hive、hbase、jms等，进行日志分析。  


## 场景模拟
1. 监控端口数据--netcat  
监控端口数据:  
端口(netcat)--->flume--->Sink(logger)到控制台

2. 实时读取本地文件到HDFS  
实时读取本地文件到HDFS:  
hive.log(exec)--->flume--->Sink(HDFS)  

取Linux系统中的文件，就得按照Linux命令的规则执行命令。由于Hive日志在Linux系统中所以读取文件的类型选择：exec即execute执行的意思。表示执行Linux命令来读取文件。  

3. 实时读取目录文件到HDFS  

实时读取目录文件到HDFS:  
目录dir(spooldir)--->flume--->Sink(HDFS)  

4. 单数据源多出口（选择器）  
单Source多Channel、Sink  

单数据源多出口(选择器):单Source多Channel、Sink  
hive.log(exec)---->flume1--Sink1(avro)-->flume2--->Sink(HDFS)
　　　　　　　　　　　---Sink2(avro)-->flume3--->Sink(file roll本地目录文件data)

5. 单数据源多出口案例(Sink组)  
单Source、Channel多Sink(负载均衡)    

Flume 的负载均衡和故障转移  

目的是为了提高整个系统的容错能力和稳定性。简单配置就可以轻松实现，首先需要设置 Sink 组，同一个 Sink 组内有多个子 Sink，不同 Sink 之间可以配置成负载均衡或者故障转移。  

单数据源多出口(Sink组): flum1-load_balance
端口(netcat)--->flume1---Sink1(avro)-->flume2---Sink(Logger控制台)
　　　　　　　　　　---Sink2(avro)-->flume3---Sink(Logger控制台)

6. 多数据源汇总  
多Source汇总数据到单Flume  