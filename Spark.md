##Spark



### Spark起源
Spark是一种快速、通用、可扩展的大数据分析引擎，  
2009年诞生于加州大学伯克利分校AMPLab，  
2010年开源，  
2013年6月成为Apache孵化项目，  
2014年2月成为Apache顶级项目。  
项目是用Scala进行编写。

### 什么是Spark
Spark是基于内存计算的大数据并行计算框架  
扩展了广泛使用的MR计算模型，而且高效的支持更多的计算，包括交互式查询和流处理  

* Spark适用于各种各样原先需要多种不同的分布式平台的场景
	* 批处理--Spark
	* 迭代算法--从某个值开始，不断地由上一步的结果计算（或推断）出下一步的结果
	* 交互式查询--SparkSQL，提供易使用的交互式查询语言，如SQL.DBMS负责执行查询命令，并将查询结果显示在屏幕上
	* 流处理--SparkStreaming  
	通过在一个统一的框架下支持这些不同的计算，可以简单而低耗的把各种处理流程整合在一起。 这样的组合，在实际的数据分析过程中很有意义。  
	Spark的这种特性还大大减轻了原先需要对各种平台分别管理的负担

	> **大一统的软件栈**，各个组件关系密切并且可以相互调用，这种设计有几个好处：  
	> 1、软件栈中所有的程序库和高级组件 都可以从下层的改进中获益。  
	> 2、运行整个软件栈的代价变小了。不需要运 行 5 到 10 套独立的软件系统了，一个机构只需要运行一套软件系统即可。系统的部署、维护、测试、支持等大大缩减。  
	> 3、能够构建出无缝整合不同处理模型的应用。


### Spark使用场景

我们大致把Spark的用例分为两类：数据科学应用和数据处理应用。也就对应的有两种人群：数据科学家和工程师。

* 数据科学任务  
主要是数据分析领域，数据科学家要负责分析数据并建模，具备 SQL、统计、预测建模(机器学习)等方面的经验，以及一定的使用 Python、 Matlab 或 R 语言进行编程的能力。

* 数据处理应用  
工程师定义为使用 Spark 开发 生产环境中的数据处理应用的软件开发者，通过对接Spark的API实现对处理的处理和转换等任务。

### Spark的内置项目
* Spark Core：   
实现了Spark的基本功能，包含任务调度、内存管理、错误恢复、与存储系统交互等模块。 还包含对弹性分布式数据集（RDD）的API定义
* Spark SQL：   
是 Spark 用来操作结构化数据的程序包。通过 Spark SQL，我们可以使用 SQL 或者 Apache Hive 版本的 SQL 方言(HQL)来查询数据。Spark SQL 支持多种数据源，比 如 Hive 表、Parquet 以及 JSON 等。
* Spark Streaming：  
是 Spark 提供的对实时数据进行流式计算的组件。提供了用来操作数据流的 API，并且与 Spark Core 中的 RDD API 高度对应。
* Spark MLlib：   
提供常见的机器学习(ML)功能的程序库。包括分类、回归、聚类、协同过滤等，还提供了模型评估、数据 导入等额外的支持功能。
* 集群管理器：   
Spark 设计为可以高效地在一个计算节点到数千个计算节点之间伸缩计 算。为了实现这样的要求，同时获得最大灵活性，Spark 支持在各种集群管理器(cluster manager)上运行，包括Hadoop YARN、Apache Mesos，以及 Spark 自带的一个简易调度器，叫作独立调度器。

### 为什么要Spark

MapReduce模型的痛点:  
MR主要适用于批处理  

* 不擅长实时计算
MapReduce无法像MySQL一样，在毫秒或者秒级内返回结果。
* 不擅长流式计算
流式计算的输入数据是动态的，而MapReduce的输入数据集是静态的，不能动态变化。这是因为MapReduce自身的设计特点决定了数据源必须是静态的。
* 不擅长DAG（有向图）计算
DAG：多个应用程序存在依赖关系，后一个应用程序的输入为前一个的输出。  
在这种情况下，MapReduce并不是不能做，而是使用后，每个MapReduce作业的输出结果都会写入到磁盘，会造成大量的磁盘IO，导致性能非常的低下。


### Spark的特点

* 快  
与Hadoop的MapReduce相比，Spark基于内存的运算要快100倍以上，基于硬盘的运算也要快10倍以上。Spark实现了高效的DAG执行引擎，可以通过基于内存来高效处理数据流。计算的中间结果是存在于内存中的。

* 易用  
Spark支持Java、Python和Scala的API，还支持超过80种高级算法，使用户可以快速构建不同的应用。而且Spark支持交互式的Python和Scala的shell，可以非常方便的在这些shell中使用Spark集群来验证解决问题的方法

* 通用  
	* Spark提供了统一的解决方案，Spark可以用于：
		* 批处理
		* 交互式查询SparkSQL
		* 实时流处理SparkStreaming
		* 机器学习Spark MLlib
		* 图计算Graphx
	这些不同类型的处理都可以在同一个应用中无缝使用  
	Spark统一的解决方案非常具有吸引力  
	毕竟任何公司都想用统一的平台去处理遇到的问题，减少开发和维护的人力成本和部署平台的物理成本

* 兼容性
	* Spark可以非常方便地与其他的开源产品进行融合。
	* Spark可以使用Hadoop的YARN和Apache Mesos作为它的资源管理和调度器，并且可以处理所有Hadoop支持的数据，包括HDFS、HBase和Cassandra等。 这对于已经部署Hadoop集群的用户特别重要，因为不需要做任何数据迁移就可以使用Spark的强大处理能力。Spark也可以不依赖于第三方的资源管理和调度器，它实现了Standalone作为其内置的资源管理和调度框架，这样进一步降低了Spark的使用门槛，使得所有人都可以非常容易地部署和使用Spark。此外，Spark还提供了在EC2上部署Standalone的Spark集群的工具。


### Spark和MR的区别？ 
* Spark并不能完全替代Hadoop,主要用于替代Hadoop中MR的计算模型，借助于YARN实现资源调度管理，借助于HDFS实现分布式存储  
* Spark运算比Hadoop的MR快的原因  


|  | MR | Spark |
| ----| ---- | ---- |
| 计算模式 | 计算都必须转化成Map和Reduce两个操作，但是这个并不适合所有的情况，难以描述复杂的数据处理过程 | Spark的计算模式也属于MR但不局限于Map和Reduce操作。Spark提供的数据集操作类型有很多种，大致分为： Transformations和Actions两大类。   |
| 计算效率 | 磁盘IO开销大。每次执行时都需要从磁盘读取数据，并且在计算完成后需要将中间结果写入磁盘中，IO开销较大 | Spark提供内存计算，中间结果直接放内存中，带来的更高的迭代运算效率 |
| 计算效率 | 一次计算可能需要分解成一系列按顺序执行的MR任务，任务之间的衔接由于涉及到IO开销，会产生较高的延迟。而且，在前一个任务执行完成之前，其他任务无法开始，难以胜任复杂、多阶段的计算任务 | Spark基于DAG的任务调度执行机制，支持DAG图的分布式并行计算的编程框架，减少了迭代过程中数据的落地，挺高了处理的效率，要优于MR的迭代执行机制|


### Spark架构

* **Driver节点**  
	Spark的驱动器是执行开发程序中的main方法的进程。负责开发人员编写的用来：  
	* 创建SparkContext
	* 创建RDD
	* 进行RDD转化操作和行动操作代码的执行   
	如果使用Spark Shell，当你启动shell时，系统后台会自启动一个Spark驱动器程序，这就是在Spark Shell中加载的一个叫sc的Spark Context对象。如果驱动器程序终止，那么Spark应用也就结束了


>     运行Spark Application的main（）函数，会创建SparkContext。Spark Context负责和Cluster Manager通信，进行资源申请、任务分配和监控等。  
>     Driver在Spark作业执行时主要负责以下操作：    
>     把用户程序转为任务： 用户程序application->转换成Task->打包为Stage->打包发送至WorkNode  
>     跟踪Executor的运行状况
>     为执行器节点调度任务
>     UI展示应用运行状况



* Cluster Manager  
负责申请和管理在WorkNode上运行应用所需要的资源，目前包括Spark原生Cluster Manager、Mesos Cluster Manager和 Hadoop YARN Cluster Manager  

* WorkNode  
Executor是Application运行在WorkNode上的一个进程，负责运行Task，并负责将数据存在内存或者磁盘上，每个APP拥有各自独立的Executor。每个Executor则包含一定数量的资源来运行分配给他的任务

> 每个WN上的Executor服务于不同的APP，他们之间是不可以共享数据的。  
> 与MR计算框架相比，Spark采用Executor具有两大优势：  
> 1. Executor利用多线程来执行具体的任务，相比较于MR进程模型，使用的资源和启动的开销要小很多  
> 2. Executor中有一个BlockManager存储模块，会将内存和磁盘共同作为存储设备，当需要多轮迭代计算的时候，可以将中间结果存储到这个存储模块中，供下次需要时直接使用，而不需要从磁盘中读取，从而有效的减少I/O开销，在交互式查询场景下，可以预先将数据缓存到BlockManager存储模块上，从而提高I/O读写能力
> 


### 运行流程

* 简述
	1. 构建Spark Application的运行环境，由Driver创建一个Spark Context，分配并监控资源使用情况
	2. Spark Context向资源管理器YARN申请运行Executor资源，并启动Executor进程
	* SparkContext根据RDD的依赖关系构建DAG图，DAG图提交给DAGScheduler解析成Stage，然后提交给底层的TaskScheduler处理
	* Executor向SparkContext申请Task，TaskSheduler将Task发放给Executor运行并提供应用程序代码
	* Task在Executor运行，并把结果反馈到TaskScheduler，一层一层反馈上去
	* 运行完最后释放资源

* 详述
	* 登录客户端，提交App，例如wordcount
		* Spark Submit
			* 只能提交任务，不能交互
			* spark-submit --master
		* Spark Shell
			* 本地模式
				* 不需要连接到Spark集群上
				* spark-shell
			* 集群模式
				* 需要连接到Spark集群，启动时需要指定Spark Master节点
				* spark-shell --master
	* 启动Driver，创建一个SparkContext对象
		* 以Client模式为例，会在提交的节点上启动一个Driver进程，Driver就是我们的Application（wordcount），  
		由Driver创建一个SparkContext对象，会在内部创建DAGSheduler和TaskScheduler  
		
			* 启动Driver：运行程序的main函数，并且创建SparkContext的进程，这里的应用程序就是我们自己编写并提交给Spark集群的程序		
		
			* 创建SparkContext：SC是Spark功能的主要入口，其代表与Spark集群的连接，能够用来在集群上创建RDD、累加器、广播变量。每个JVM里只能存在一个处于激活状态的SC，在创建新的SC之前必须调用stop()来关闭之前的SC  
				1. 创建DAGScheduler
				DAG是基于用户的transformations操作和Stage阶段划分算法，将一个Spark任务分解成若干个Stage，然后为每个Stage构建一个TaskSet，并交由TaskScheduler（实质上就是逻辑上将Spark任务进行拆分，用户分布式计算）  
				2. 创建TaskScheduler  
				TS是在DS之前创建的，主要用于接收DS分配的TaskSet，通过网络传递给对应的Executor
			

			要创建Spark应用程序之前，需要先创建SC对象，创建SC之前需要构建一个包含有关应用程序信息的SparkConf对象  
			
			SparkConf主要用于配置Spark应用程序，以键值对的方式，对Spark的关键参数做设置，我们在创建SparkConf对象设置的Spark参数优先级会高于Spark环境中的配置信息  
			
			SparkContext在Spark应用中起到Master的作用,主要职能是作为每个Spark应用程序的入口，会告知如何连接到Spark集群，比如local、standalone、yarn、mesos，创建RDD、广播变量到集群  
			
	* 创建Job
		在Driver里的代码，如果遇到actions算子，就会创建一个Job，多个actions对应多个Job  
	* 生成DAG		
		DS会接收Job，会为这个Job生成DAG

		> DAG全称Directed Acyclic Graph，有向无环图。  
		> 一个由顶点和有方向的边构成的图，从任意一个顶点出发，没有任何一条路径会将其带回到出发的顶点  
		
	* 划分Stage
		DAG图中，遇到窄依赖，就将其加入Stage，一旦遇到宽依赖，就另起同一个新的Stage，所以Stage可以是一个或者多个
		
		> DAGScheduler把Job根据宽依赖划分为多个Stage，对划分出来的每个Stage都抽象成一个TaskSet任务集，交给TaskScheduler来进行进一步的调度运行
		
		Stage的划分是以ShuffleDependency宽依赖为依据，也就是说某个RDD的运算需要将数据进行Shuffle时，这个包含了Shuffle依赖关系的RDD将被用作输入信息，构建一个新的Stage,由此为依据划分Stage，可以确保有依赖关系的数据能够按照正确的顺序得到处理和运算  
		
		宽依赖Shuffle Dependency：父RDD的每个分区都可能被多个子RDD分区使用  
		窄依赖Narrow Dependency： 父RDD的每个分区只被某一个子RDD分区使用  
		
		**提交Stage**  
		得到一个或多个有依赖关系的Stage,其中直接触发Job的RDD所关联的Stage作为FinalStage生成一个Job实例，这两者的关系进一步存储在resultStageToJob映射表中，用于在该Stage全部完成时做一些后续处理，如报告状态，清理Job相关数据等  
		
		具体提交一个Stage时，首先判断该Stage所依赖的父Stage的结果是否可用：  
		如果父Stage的结果都可用，则提交该Stage  
		如果任何一个父Stage的结果不可用，则迭代尝试提交父Stage  
		> 没有成功提交的Stage会放入到waitingStages列表中 
		> 当一个属于中间过程的Stage任务完成后，DAGScheduler会检查对应Stage的所有任务是否完成，如果都完成了，则DS重新扫描一次waitingStages中的所有Stage，检查他们是否还有任何依赖的Stage没完成，如果没有就可以提交该Stage了   
		
	* 切分Task  
		每个Stage里面Task数目由该Stage最后一个RDD中的Partiton个数决定，一个Partition对应一个task，生成TaskSet
		> TaskScheduler从DAGScheduler的每个Stage接收一组Task，并负责将它们发送到集群上，运行它们   
		
	* TaskScheduler接收TaskSet后调度Task,将task分配给worker节点执行  
		每个Stage的提交，最终是转换成一个TaskSet任务集的提交，DS通过TS接口提交TaskSet，这个TaskSet最终会触发TS构建一个TaskSetManager的实例来管理这个TaskSet的生命周期，对于DS来说，提交Stage的工作到此完成。

		**任务作业完成状态的监控**  
		要保证相互依赖的Job/Stage能够得到顺利的调度执行，DS就必然要监控当前Job/Stage乃至Task的完成情况。  
		
		通过对外（主要是对TS）暴露一系列的回调函数来实现，对于TS来说，这些回调函数主要包括任务的开始结束失败，任务集的失败，DS根据这些Task的生命周期信息进一步维护Job和Stage的状态信息   

		TS可以通过回调函数通知DS具体的Executor的生命状态，如果一个Executor崩溃了，或者由于任何原因与Driver失联，则对应的Stage的ShuffleMapTask的输出结果也将被标记为不可用，这也将导致对应Stage状态的变更，进而影响到相关Job的状态，进一步可能触发对应Stage的重新提交来重新计算获取相关的数据。  
		**任务结果的获取**  
		一个具体的任务在Executor执行完毕后，其结果需要以某种形式返回给DS，根据任务类型的不同，任务的结果返回方式也不同：  
		1. 对于FinalStage所对应的任务，对应类为ResultTask，返回给DS的是运算结果本身；  
		2. 对于ShuffleMapTask，返回给DS的是一个MapStatus对象，MapStatus对象管理了ShuffleMapTask的运算输出结果在BlockManager中的相关存储信息，而非结果本身，这些存储信息将作为下一个Stage任务的获取输入数据的依据。
	
	* Executor执行Task  
		1. Executor通过taskrunner来执行task  
		2. executor接收到的是一个序列化文件，先反序列化/拷贝等，生成Task，Task里有RDD执行算子，一些方法需要的常量。  
		3. 如果接收到很多Task，没接收一个Task，就会从线程池里获取一条线程，用taskrunner来执行task  
		> Task分为两种：  
		> 1. ResultTask： 最后一个Stage对应的Task  
		> 2. ShuffleMapTask：之前所有Stage对应Task
		> Spark程序就是Stage被切分成很多Task，封装到TaskSet里，提交给Executor执行，一个Stage一个Stage执行，每个Task对应一个RDD的partiton，这个task执行就是我们写的算子操作。  
		

###RDD  
* 概念  
	Resilient Distributed Dataset
	弹性分布式数据集  
	是Spark中最基本的数据抽象，代表了一个不可变、可分区、元素可并行计算的集合。    	

	RDD是将数据项拆分成多个分区的集合，存储在集群的工作节点上的内存中，并执行正确的操作  
	* 分布式数据集  
		RDD是只读的，分区记录的集合，每个分区分布在集群的不同节点上  
		RDD并不存储真正的数据，只是对数据和操作的描述
	* 弹性  
		RDD默认存放在内存中，当内存不足时，Spark自动将RDD写入磁盘
	* 容错性
		根据数据血统，可以自动从节点失败中恢复数据


* RDD缓存  
	Spark RDD是惰性求值的，有时候希望能多次使用同一个RDD，如果简单的对RDD调用行动操作，Spark每次都会重新计算RDD以及它的依赖，这样会带来太大的消耗，为了避免多次计算同一个RDD，可以让Spark读数据进行持久化   
	Spark可以使用Transformation算子persist和cache将任意RDD缓存到内存、磁盘文件系统中，这两个算子是Transformations算子，调用这两个算子时不会立即执行缓存，只是做一个要缓存标记，等到后面action算子触发计算时，才会将标记点的数据缓存到指定位置，以供后续的算子快速重用。  
	**持久化级别StorageLevel:**  
	* MEMORY_ONLY
	* MEMORY_ONLY_SER
	* MEMORY_AND_DISK
	* MEMORY_AND_DISK_SER
	* DISK_ONLY  
	
	> 缓存有可能丢失，或者存储于内存中的数据由于内存不足而被删除，RDD的缓存容错机制保证了即使缓存丢失也能保证计算的正确执行。  
	> 通过基于RDD的一系列转换，丢失的数据会被重新计算，由于RDD的各个Parition是相对独立的，因此只需要计算丢失部分即可，不需要重新计算全部Partition的数据。  


### SparkSQL  
* 概述  
	SparkSQL是Spark用来处理结构化数据的一个模块，提供了一个编程抽象叫做DataFrame作为分布式SQL查询引擎的作用  
	外部结构化数据源包括：Parquet默认、JSON、RMDBS、HIVE等。
* 为什么使用SparkSQL  
首先：   
HIVE-SQL-MR: HIVE，将HiveSQL转换成MR然后提交到集群上执行，大大简化了编写MR的程序复杂性  
SparkSQL-SQL-RDD：SparkSQL，将SQL查询转换成SparkCore的应用程序，然后提交到集群执行  
SparkSQL是一个统一的数据处理技术栈，spark整体hive，可以无缝处理hive数据仓库中的数据  

* 特点  
	* 容易整合
	* 统一的数据访问格式
	* 兼容Hive
	* 标准的数据接口  

* 步骤


	* 创建SparkSession对象  
	在Spark2.0版本中，引用SparkSession作为DataSet、DataFrame API的切入点，SparkSession封装了SparkConf、SparkContext和SQLContext。为了向后兼容，HiveContext也被保存下来。   
	所以，在SQLContext和HiveContext上可用的API在SparkSession上同样可以使用。  
	SparkSession内部封装了SparkContext，所以计算实际上是由SparkContext完成的。  
	**创建方式**  
		1. 在spark-shell中创建  
	SparkSession会被自动初始化一个对象叫做spark，为了向后兼容，Spark-Shell还提供了一个SparkContext初始对象  
		1. 在IDEA中创建    

	* 读取数据源创建DataFrame
		* 读取文本文件创建DataFrame
			* 在本地创建一个文件，有三列，分别为ID/NAME/AGE，用空格分隔，然后上传到HDFS上： hdfs dfs -put person.txt /  
			* 在spark shell执行下面命令，读取数据，将每一行的数据使用列分隔符分割  
			先执行 spark-shell --master local[2]  
			val lineRDD= sc.textFile("/person.txt").map(_.split(" "))
			* 定义case class（相当于表的schema）  
			case class Person(id:Int, name:String, age:Int)  
			* 将RDD和case class关联  
			val personRDD = lineRDD.map(x => Person(x(0).toInt, x(1), x(2).toInt))  
			* 将RDD转换成DataFrame  
			val personDF = personRDD.toDF  
			* 通过SparkSession构建DataFrame  
			使用spark-shell中已经初始化好的SparkSession对象spark生成DataFrame  
			val dataFrame=spark.read.text("/person.txt")

		* 读取Parquet文件创建DataFrame      
			val usersDF = spark.read.load(".../.../.../users.parquet")  
		> 	Parquet格式是SparkSQL的默认数据源,可以通过spark.sql.sources.default文件配置    
		* 读取CSV文件创建DataFrame   
			val usersDF = spark.read.format("csv").load(".../.../.../users.csv")
		* 读取JSON文件创建DataFrame  
			val usersDF = spark.read.format("JSON").load(".../.../.../users.json")

	* DF常用操作   
	**在DF、DS上进行transformation、action，编写SQL语句** 
		* DSL风格语法  
	DataFrame提供了一个领域特定语言(DSL)以方便操作结构化数据。下面是一些使用示例

		（1）查看DataFrame中的内容，通过调用show方法  
			personDF.show  
		（2）查看DataFrame部分列中的内容  
			查看name字段的数据  
			personDF.select(personDF.col("name")).show  

		（3）打印DataFrame的Schema信息  
			personDF.printSchema    
		（4）查询所有的name和age，并将age+1
			personDF.select(col("id"), col("name"), col("age") + 1).show  
		（5）过滤age大于等于25的，使用filter方法过滤
			personDF.filter(col("age") >= 25).show  
		（6）统计年龄大于30的人数
			personDF.filter(col("age")>30).count()  
		（7）按年龄进行分组并统计相同年龄的人数
			personDF.groupBy("age").count().show   

		* SQL风格语法  
		DF的强大之处是我们可以将它看做是一个关系型数据库，然后可以通过在程序中使用spark.sql（）来执行SQL查询，结果将作为一个DF返回。  
		如果想使用SQL风格的语法，需要将DataFrame注册成表,采用如下的方式：
		personDF.registerTempTable("t_person")

		（1）查询年龄最大的前两名  
			spark.sql("select * from t_person order by age desc limit 2").show  
		（2）显示表的Schema信息  
			spark.sql("desc t_person").show  
		（3）查询年龄大于30的人的信息  
			spark.sql("select * from t_person where age > 30 ").show

	* 保存结果  
		usersDF.select($"name")  
		.write  
		.format("csv")    
		.mode("overwrite")    
		.save("/root/tmp/result1")    
		> 存储模式mode  
		> 1. SaveMode.ErrorIfExists--默认存储模式,表已存在则报错    
		> 2. SaveMode.Append  --若表存在，则追加，若不存在，则创建表，再插入数据  
		> 3. SaveMode.Overwrite  --将已有的表和数据删除，重新创建表再插入数据  
		> 4. SaveMode.Ignore  --若表存在，直接跳过数据存储，不存储；若表不存在，创建表，存入数据  


### RDD/DataFrame/DataSet  

  

|  | 定义 | 优缺点 |
| ----| ---- | ---- |
| RDD |  Resilient Distributed Dataset 弹性分布式数据集，是Spark中最基本的数据抽象，代表一个不可变、可分区、元素可并行计算的集合  | RDD仅表示数据集，RDD没有元数据，也就是说没有字段语义定义，他需要用户自己优化程序，对程序员要求较高，从不同数据源读取数据相对困难，读取不同的格式数据都必须用户自己定义转换方式合并 |
| DataFrame | DateFrame(表) = RDD（表数据） + Schema（表结构） 可以认为DF就是Spark中的数据表，按列名的方式去组织的一个分布式的数据集RDD，是SparkSQL对结构化数据的抽象  | 与RDD类似，DF也是一个分布式数据容器，DF更像传统数据库的二维表格，除了数据外还记录了数据的结构信息Schema |
| DataSet | 分布式的数据集合，不仅包含数据本身，还记录了数据结构信息（Schema），还包括数据集的类型 | DF是一种特殊的DataSet，DF=DataSet[Row]，即DataSet的子集，相比DataFrame，Dataset提供了编译时类型检查，对于分布式程序来讲，提交一次作业太费劲了（要编译、打包、上传、运行），到提交到集群运行时才发现错误，这会浪费大量的时间，这也是引入Dataset的一个重要原因 |

**什么是DataSet**  
DataSet是数据的分布式集合；   
是Spark1.6版本中新添加的一个接口，是DF之上更高一级的抽象  
提供了RDD强类型化，能够使用强大的Iambda函数的优点，以及SparkSQL优化后的执行引擎的优点  

**为什么引入DataSet**  
由于DF的数据类型统一是Row，这是有缺点的：  
Row运行时才进行类型检查，比如salary的类型是字符串，只有语句执行时才进行类型检查；  
所以SparkSQL引入了DataSet，扩展了DF API，提供了编译时类型检查，面向对象风格的API；  

**DataFrame与DataSet的互转**  
DF是一种特殊的DS。   
（1）DataFrame转为 DataSet

df.as[ElementType]这样可以把DataFrame转化为DataSet。

（2）DataSet转为DataFrame 

ds.toDF()这样可以把DataSet转化为DataFrame。

 


