##SparkStreaming  

###为什么要有SparkStreaming 

提到spark streaming，我们就必须了解一下BDAS（Berkeley Data Analytics Stack），这个伯克利大学提出的关于数据分析的软件栈。  
从它的视角来看，目前的大数据处理可以分为如下三个类型：  
1. **复杂的批量数据处理**（batch data processing），通常的时间跨度在数十分钟到数小时之间；  
2. **基于历史数据的交互式查询**（interactive query），通常的时间跨度在数十秒到数分钟之间；  
3. **基于实时数据流的数据处理**（streaming data processing），通常的时间跨度在数百毫秒到数秒之间；  

目前已经有很多相对成熟的开源软件来处理以上三种情况：   
1. MapReduce来进行批量数据处理；  
2. Impala进行交互式查询；  
3. 对于流式数据处理，我们可以采用storm  
  
对于大多数互联网公司来说，一般都会同时遇到以上三种数据处理情况，那么在使用的过程中这些公司可能会遇到如下的不便：  
1. 三种情况的输入输出数据无法无缝共享，需要进行格式相互转换  
2. 每个开源软件需要一个开发和维护团队，提高了成本  
3. 在同一个集群中对各个系统协调资源分配比较困难  

BDAS就是以Spark为基础的一套软件栈，利用基于内存的通用计算模型将以上三种场景一网打尽，同时支持Batch、Interactive、Streaming的处理，且兼容支持HDFS和S3等分布式文件系统，可以部署在YARN和Mesos等流行的集群资源管理器之上。

**批处理和流处理**  
Hadoop主导的大数据计算时代，主要是离线计算，当程序进行计算时，数据的大小和目录已经确定了。  
当数据产生时，并没有立即执行计算，而是被暂时存疑一段时间，然后等到累计到一定量的数据后，就执行一次离线计算。  

两次计算间隔很长的时间，这段时间内，新产生的数据根本没有执行计算  
比如，1:00和2:00分别执行一次计算，那么1:00~2:00之间的数据，只有在2:00启动任务计算才有结果  
以上可以满足业务的实现  
接下来我们追求性能的提升：  

统计一个演讲者演讲过程中所有单词的总数，有两个方法：  
1. 将演讲者的演讲内容全部记录到文件里，比如speech.txt，演讲结束后，对txt文件进行统计  
2. 没演讲一个字进行一次统计： 我+1 们+1 是+1 ....   
演讲结束，统计结果也就出来了  

### 什么是SparkStreaming  

SS接收实时输入数据流，根据时间将数据流切分为连续多个batch，然后由SparkCore引擎一次处理一批数据，最终生成批“形式”结果流  


### SS的核心参数  
SS的核心参数是设置流数据被分为多个Batch的**时间间隔**，每个Spark引擎处理的就是这个时间间隔内的数据。  
在SS中，Job之间有可能存在依赖关系，所以后面的作业必须确保前面的作业执行完后才被调度执行；  
如果批处理的时间超过batch duration，意味着数据处理速度跟不上数据接收速度，那么会导致后面提交的batch任务无法按时执行，随着时间的推移，越来越多的作业被延迟执行，最后导致整个Streaming作业被阻塞，所以需要设置一个合理的批处理间隔以确保作业能够在这个批处理间隔内执行完成。  


### SS特性 

* 高集成性  
	 1. 用于处理流式计算问题，能够与Spark其他模块无缝集合
* 高扩展性
	2. 可以运行在百台机器上，  目前在EC2上已能够线性扩展到100个节点（每个节点4Core）
	
* 高吞吐性
	1. 以数秒的延迟处理6GB/s的数据量（60M records/s），其吞吐量也比流行的Storm高2～5倍
	2. Berkeley利用WordCountg中的每个节点的吞吐量是670k records/s，而Storm是115k records/s。

* 高容错性  
	1. 对于Spark Streaming来说，其RDD的传承关系如图所示，图中的每一个椭圆形表示一个RDD，椭圆形中的每个圆形代表一个RDD中的一个Partition，图中的每一列的多个RDD表示一个DStream（图中有三个DStream），而每一行最后一个RDD则表示每一个Batch Size所产生的中间结果RDD。
	2. 我们可以看到图中的每一个RDD都是通过lineage相连接的，由于Spark Streaming输入数据可以来自于磁盘，例如HDFS（多份拷贝）或是来自于网络的数据流（Spark Streaming会将网络输入数据的每一个数据流拷贝两份到其他的机器）都能保证容错性。所以RDD中任意的Partition出错，都可以并行地在其他机器上将缺失的Partition计算出来。这个容错恢复方式比连续计算模型（如Storm）的效率更高。 
* 低延迟性（实时性）  
	1. Spark Streaming将流式计算分解成多个Spark Job，对于每一段数据的处理都会经过Spark DAG图分解，以及Spark的任务集的调度过程。
	2. 对于目前版本的Spark Streaming而言，其最小的Batch Size的选取在0.5~2秒钟之间（Storm目前最小的延迟是100ms左右），所以Spark Streaming能够满足除对实时性要求非常高（如高频实时交易）之外的所有流式准实时计算场景。


### SS工作原理
* 原理  
	* 接收实时输入数据流，将数据拆分为多个batch，比如每收集一秒的数据封装为一个batch，然后将每个batch交给spark的计算引擎进行处理，最后会生产出一个数据流，其中的数据就是也是由一个一个的batch所组成的  
	* 严格来说Spark Streaming并不是一个真正的实时框架，数据是分成多个batch分批次进行处理的  
* DStream
	* SS提供了一种高级抽象-DStream,Discretized Stream,离散流，代表了一个持续不断的数据流
	* DStream可以通过输入数据源来创建，比如Kafka、Flume、Kinesis
	* 也可以通过对其他DStream应用高阶函数来创建，比如map、reduce、join、window。
* 计算流程：
	1. 将流式计算分解成一系列短小的批处理作业，这里的批处理引擎是Spark Core，也就是把SparkStreaming的输入数据按照batch size（如一秒）分成一段一段的数据（Discretized Stream）
	2. 每和Grep两个用例所做的测试，在Grep这个测试中，Spark Streamin一段数据都转换成Spark中的RDD（Resilient Distributed Dataset）
	3. 然后将Spark Streaming中对DStream的Transformation操作变为针对Spark中对RDD的Transformation操作，将RDD经过操作变成中间结果保存在内存中。 整个流式计算根据业务的需求可以对中间的结果进行叠加，或者存储到外部设备。  
* 底层实现
	1. 对于DStream应用的算子，比如map，在底层会被翻译成DStream中每个RDD的操作  
	2. 比如对一个DS执行一个map操作，产生一个新的DStream  
	3. 但是在底层，对输入DStream中每个时间段的RDD，都应用一遍map操作，然后生成新的RDD，即作为新的DStream中的那个时间段的一个RDD，底层的RDD的map操作其实还是由Spark Core的计算引擎来实现  
	4. SparkStreaming对Spark Core进行一层封装，隐藏了细节，为开发人员提供了方便易用的高层次API   


* 运行流程  
	SparkStreaming为每个数据源启动对应的Reciver接收器，接收器以任务形式运行在应用的Executor进程中，从输入源接收数据，把数据分组为小的批次batch，并保存为RDD，最后提交Spark Job执行  
	三大步骤：  
	1. 启动流计算引擎（启动JobScheduler和JobGenerator）
		1. 校验启动StreamingContext的合法性
		2. 启动JobScheduler任务调度器
		3. 将当前StreamingContext对象设置为活跃单例对象
		4. 在指标体系中注册流计算相关指标
		5. 在Spark UI界面中添加StreamingTab页面
	2. 接收并存储数据（启动Receiver，接收数据，生成Block）
		1. Driver端初始化ReceiverTracker，
		2. 将所有的Receiver封装成RDD，并发送的Executor执行
		3. 将Executor端的Receiver启动后不断的接收消息，并调用其store()方法将数据存储。
	3. 生成Batch Job处理数据（流数据转换为RDD，生成并接收Job）
		1. 以batchDuration为周期生成GenerateJobs消息
		2. 生成并提交Job


* 案例 
	* wordcount 
		1. 将Spark Streaming相关的类和StreamingContext的一些隐式转换导入到我们的环境中，以便为我们需要的其他类（如DStream）添加有用的方法。  
		StreamingContext是所有流功能的主要入口点。我们创建一个带有两个执行线程的本地StreamingContext，并且设置流数据每批的间隔为1秒
		>     	import org.apache.spark.SparkConf;
		>     	import org.apache.spark.streaming.StreamingContext;
		>     	import org.apache.spark.streaming.api.java.JavaDStream;
		>     	import org.apache.spark.streaming.api.java.JavaReceiverInputDStream;
		>     	import java.util.Arrays;
		>     	 
		>     	// Create a local StreamingContext with two working thread and batch interval of 1 
		>
		>     	second.
		>     	// The master requires 2 cores to prevent from a starvation scenario.
		>     	SparkConf conf = new SparkConf().setMaster("local[2]").setAppName("NetworkWordCount");
		>     	JavaStreamingContext jssc = new JavaStreamingContext(conf, Durations.seconds(1));    

		2. 使用此Context可以创建一个DStream，表示来自特定主机名（例如localhost）和端口（例如9999）TCP源的流数据  
		>     // Create a DStream that will connect to hostname:port, like localhost:9999
		      JavaReceiverInputDStream<String> lines = jssc.socketTextStream("localhost", 9999);
  
		1. 在这行代码中，DStream表示从数据服务器接受的数据流。DStream中每个记录都是一行文本，接下来要将每行文本以空格符为分隔符切分成一个个单词  
		>     // Split each line into words
		      JavaDStream<String> words = lines.flatMap(x -> Arrays.asList(x.split(" ")).iterator()); 

		1. flatmap是一个一对多的DStream操作，该操作从源DStream中的每个记录生成多个新纪录来创建新的DStream。  
		在这种情况下，每一行被分割成多个单词，并将单词流表示为单词DStream，接下来对单词进行计数    
		用PairFunction对象将单词DStream进一步映射（一对一变换）到(word,1) 键值对的DStream，  
		然后用function2进行聚合以获得每批数据中的单词的频率。  
		最后，wordCounts.print()将打印每秒产生的计数结果中的若干条记录。
		>     // Count each word in each batch
		     JavaPairDStream<String, Integer> pairs = words.mapToPair(s -> new Tuple2<>(s, 1));
		     JavaPairDStream<String, Integer> wordCounts = pairs.reduceByKey((i1, i2) -> i1 + i2);
 
		>     // Print the first ten elements of each RDD generated in this DStream to the console
		      wordCounts.print();
 
		1. 注意，当执行这些代码时，SparkStreaming仅仅是设置了预计算流程，目前为止这些计算还没有真正的开始执行。在设置好所有计算操作后，要开始真正的执行过程，我们最终需要调用如下方法：  
		>       jssc.start();              // Start the computation  
		      jssc.awaitTermination();   // Wait for the computation to terminate
 * 补充  
	 * 要从SparkStreaming核心API中不存在的Kafka、Flume和Kinesis等源中提取数据，必须将相应的工件spark-streaming-xyz_2.11添加到依赖中  
	 * Initializing StreamingContext  
	 要初始化SparkStreaming程序，必须创建一个StreamingContext对象，它是所有SparkStreaming功能的主要入口点  
		