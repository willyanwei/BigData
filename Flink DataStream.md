#Flnk DataStream开发

## Flink流处理程序一般流程  
1. 获取Flink流处理执行环境
2. 构建Source
3. 数据处理
4. 构建Sink  


## 简单示例  
* 课题  
简单的流处理的词频统计  
编写Flink程序，可以来接收 socket 的单词数据，并进行单词统计  

* 实现思路  
	1. 获取流处理运行环境
	2. 构建socket流数据源，并指定IP地址和端口号
	3. 对接收到的数据转换成单词元组
	4. 使用 keyBy 进行分流（分组）
	5. 使用 timeWinodw 指定窗口的长度（每5秒计算一次）
	6. 使用sum执行累加
	7. 打印输出
	8. 启动执行
	9. 在Linux中，使用 nc -lk 端口号 监听端口，并发送单词
	
	>     package cn.itcast.stream
	>     
	>     import org.apache.flink.api.java.tuple.Tuple
	>     import org.apache.flink.streaming.api.scala._
	>     import org.apache.flink.streaming.api.windowing.time.Time
	>     import org.apache.flink.streaming.api.windowing.windows.TimeWindow
	>     
	>     object StreamWordCount {
	>       def main(args: Array[String]): Unit = {
	
	>     //1. 获取流处理运行环境
	>     val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
	>     
	>     env.setParallelism(1)
	>     
	>     //2. 构建socket流数据源，并指定IP地址和端口号
	>     val textDataStream: DataStream[String] = env.socketTextStream("node01", 9999)
	>     
	>     //3. 对接收到的数据转换成单词元组
	>     val wordDataStream: DataStream[(String, Int)] = textDataStream.flatMap(_.split(" ")).map(_ -(_,1))
	>     
	>     //4. 使用 keyBy 进行分流（分组）
	>     //在批处理中针对于dataset， 如果分组需要使用groupby
	>     //在流处理中针对于datastream， 如果分组（分流）使用keyBy
	>     val groupedDataStream: KeyedStream[(String, Int), Tuple] = wordDataStream.keyBy(0)
	>     
	>     //5. 使用 timeWinodw 指定窗口的长度（每5秒计算一次）
	>     //spark-》reduceBykeyAndWindow
	>     val windowDataStream: WindowedStream[(String, Int), Tuple, TimeWindow] = groupedDataStream.timeWindow(Time.seconds(5))
	>     
	>     //6. 使用sum执行累加
	>     val sumDataStream = windowDataStream.sum(1)
	>     sumDataStream.print()
	>     env.execute()
	>       }
	>     }  


##输入数据集DataSources  
Flink 中你可以使用 StreamExecutionEnvironment.addSource(source) 来为你的程序添加数据来源。  
	**四大DataSource**  
	1. 基于本地集合的source（Collection-based-source）  
	2. 基于文件的source（File-based-source）- 读取文本文件，即符合 TextInputFormat 规范的文件，并将其作为字符串返回  
	3. 基于网络套接字的source（Socket-based-source）- 从 socket 读取。元素可以用分隔符切分  
	4. 自定义的source（Custom-source）    


###基于集合的Source  
一般情况下，可以将数据临时存储到内存中，形成特殊的数据结构后，作为数据源使用    

>     
>     import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}  
>     
>     import scala.collection.immutable.{Queue, Stack}  
>     import scala.collection.mutable  
>     import scala.collection.mutable.{ArrayBuffer, ListBuffer}  
>     import org.apache.flink.api.scala._  
>     
>     object StreamDataSourceDemo {
>       def main(args: Array[String]): Unit = {
>     val senv = StreamExecutionEnvironment.getExecutionEnvironment  
>     
>     //0.用element创建DataStream(fromElements)  
>     val ds0: DataStream[String] = senv.fromElements("spark", "flink")  
>     ds0.print()  
>     
>     //1.用Tuple创建DataStream(fromElements)
>     val ds1: DataStream[(Int, String)] = senv.fromElements((1, "spark"), (2, "flink"))
>     ds1.print()
>     
>     //2.用Array创建DataStream
>     val ds2: DataStream[String] = senv.fromCollection(Array("spark", "flink"))
>     ds2.print()
>     
>     //3.用ArrayBuffer创建DataStream
>     val ds3: DataStream[String] = senv.fromCollection(ArrayBuffer("spark", "flink"))
>     ds3.print()
>     
>     //4.用List创建DataStream
>     val ds4: DataStream[String] = senv.fromCollection(List("spark", "flink"))
>     ds4.print()
>     
>     //5.用List创建DataStream
>     val ds5: DataStream[String] = senv.fromCollection(ListBuffer("spark", "flink"))
>     ds5.print()
>     
>     //6.用Vector创建DataStream
>     val ds6: DataStream[String] = senv.fromCollection(Vector("spark", "flink"))
>     ds6.print()
>     
>     //7.用Queue创建DataStream
>     val ds7: DataStream[String] = senv.fromCollection(Queue("spark", "flink"))
>     ds7.print()
>     
>     //8.用Stack创建DataStream
>     val ds8: DataStream[String] = senv.fromCollection(Stack("spark", "flink"))
>     ds8.print()
>     
>     //9.用Stream创建DataStream（Stream相当于lazy List，避免在中间过程中生成不必要的集合）
>     val ds9: DataStream[String] = senv.fromCollection(Stream("spark", "flink"))
>     ds9.print()
>     
>     //10.用Seq创建DataStream
>     val ds10: DataStream[String] = senv.fromCollection(Seq("spark", "flink"))
>     ds10.print()
>     
>     //11.用Set创建DataStream(不支持)
>     //val ds11: DataStream[String] = senv.fromCollection(Set("spark", "flink"))
>     //ds11.print()
>     
>     //12.用Iterable创建DataStream(不支持)
>     //val ds12: DataStream[String] = senv.fromCollection(Iterable("spark", "flink"))
>     //ds12.print()
>     
>     //13.用ArraySeq创建DataStream
>     val ds13: DataStream[String] = senv.fromCollection(mutable.ArraySeq("spark", "flink"))
>     ds13.print()
>     
>     //14.用ArrayStack创建DataStream
>     val ds14: DataStream[String] = senv.fromCollection(mutable.ArrayStack("spark", "flink"))
>     ds14.print()
>     
>     //15.用Map创建DataStream(不支持)
>     //val ds15: DataStream[(Int, String)] = senv.fromCollection(Map(1 -"spark", 2 -"flink"))
>     //ds15.print()
>     
>     //16.用Range创建DataStream
>     val ds16: DataStream[Int] = senv.fromCollection(Range(1, 9))
>     ds16.print()
>     
>     //17.用fromElements创建DataStream
>     val ds17: DataStream[Long] = senv.generateSequence(1, 9)
>     ds17.print() 
>       }
>     }  
>     

###基于文件的source（File-based-source）  

  
通常情况下，我们会从存储介质中获取数据，比较常见的就是将日志文件作为数据源     
1. 读取本地文件  
val text1 = env.readTextFile("data2.csv")  
text1.print()  
2. 读取hdfs文件  
val text2 = env.readTextFile("hdfs://hadoop01:9000/input/flink/README.txt")  


> 		import org.apache.flink.streaming.api.scala._
> 		 
> 		object SourceFile {
> 		 
> 		  def main(args: Array[String]): Unit = {
> 		    //1.创建执行的环境
> 		    val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment  
> 		    
> 		    //2.从指定路径获取数据
> 		    val fileDS: DataStream[String] = env.readTextFile("input/data.log")
> 		 
> 		    //3.打印
> 		    fileDS.print()
> 		 
> 		    //4.执行
> 		    env.execute("sensor")
> 		 
> 		  }
> 		}
> 		/**
> 		 * 在读取文件时，文件路径可以是目录也可以是单一文件。如果采用相对文件路径，会从当前系统参数user.dir中获取路径
> 		 * System.getProperty("user.dir")
> 		 */
> 		/**
> 		 * 如果在IDEA中执行代码，那么系统参数user.dir自动指向项目根目录，
> 		 */ 

如果是standalone集群环境, 默认为集群节点根目录，  
当然除了相对路径以外，也可以将路径设置为分布式文件系统路径，如HDFS    
> 		val fileDS: DataStream[String] =
> 		env.readTextFile( "hdfs://hadoop02:9000/test/1.txt")  

###基于网络套接字的source（Socket-based-source）  

基于 Socket：监听主机的 host port，从 Socket 中获取数据
>     val source = env.socketTextStream("IP", PORT)

###基于自定义的Custom-Source   
除了预定义的Source外，我们还可以通过SourceFunction或者它的子类RichSourceFunction来自定义Source，  
然后通过StreamExecutionEnvironment.addSource(sourceFunction)添加进来。  

自定义的 source 常见的有 Apache kafka、RabbitMQ 等  

大多数的场景数据都是无界的，会源源不断的过来。  
比如去消费Kafka某个topic上的数据，这时候就需要用到这个addSource，可能因为用的比较多的原因吧，Flink 直接提供了 FlinkKafkaConsumer011 等类可供你直接使用

比如读取Kafka数据的Source:  
Flink 直接提供了 FlinkKafkaConsumer011 等类可供你直接使用  
所以，可以直接使用 addSource(new FlinkKafkaConsumer011<>(…)) 从 Apache Kafka 读取数据  


* 可以实现以下三个接口来自定义Source：  
	1. SourceFunction  
	2. ParallelSourceFunction  
	3. RichParallelSourceFunction    

* **自定义数据源-代码练习-案例一**  
	1. 示例:  
	自定义数据源, 每1秒钟随机生成一条订单信息(订单ID、用户ID、订单金额、时间戳)  
	2. 要求:     
		- 随机生成订单ID(UUID)    
		- 随机生成用户ID(0-2)    
		- 随机生成订单金额(0-100)    
		- 时间戳为当前系统时间      
	3. 开发步骤:  
		1. 创建订单样例类  
		2. 获取流处理环境  
		3. 创建自定义数据源  
		   - 循环1000次  
		   - 随机构建订单信息  
		   - 上下文收集数据  
		   - 每隔一秒执行一次循环    
		4. 打印数据   
		5. 执行任务  
	4. 代码实现    

		>     package cn.itcast.stream
		>     
		>     import java.util.UUID
		>     import java.util.concurrent.TimeUnit
		>     
		>     import org.apache.flink.configuration.Configuration
		>     import org.apache.flink.streaming.api.functions.source.{RichParallelSourceFunction, SourceFunction}
		>     import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
		>     
		>     import scala.util.Random
		>     
		>     object CustomerSourceOrderDemo {
		>       def main(args: Array[String]): Unit = {
		>     
		>     //1.准备环境
		>     val senv: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
		>     senv.setParallelism(1)
		>     
		>     //2.使用自定义获取数据
		>     import org.apache.flink.api.scala._
		>     val orderData: DataStream[Order] = senv.addSource(new RichParallelSourceFunction[Order] {
		>       var isRunning: Boolean = true
		>     
		>       override def open(parameters: Configuration): Unit = super.open(parameters)
		>     
		>       override def run(ctx: SourceFunction.SourceContext[Order]): Unit = {
		>     while (isRunning) {
		>       val id: String = UUID.randomUUID().toString.replaceAll("-", "") //订单id
		>       val userId: Int = Random.nextInt(3) //用户id
		>       val money: Int = Random.nextInt(101) //订单金额
		>       val createTime: Long = System.currentTimeMillis() //下单时间
		>       ctx.collect(Order(id, userId, money, createTime))
		>       TimeUnit.SECONDS.sleep(1)
		>     }
		>       }
		>     
		>       override def close(): Unit = super.close()
		>     
		>       override def cancel(): Unit = {
		>     isRunning = false
		>       }
		>     }).setParallelism(2)//Operator级别并行度优先级 env级别并行度
		>     
		>     //3.输出数据
		>     orderData.print()
		>     
		>     //4.启动执行
		>     senv.execute()
		>       }
		>       //订单样例类Order(订单ID、用户ID、订单金额、时间戳)
		>       case class Order(id: String, userId: Int, money: Long, createTime: Long)
		>     }
		
* **自定义数据源-代码练习-案例二**   
	1. 示例:  
上面我们已经使用了自定义数据源，那么接下来就模仿着写一个从 MySQL 中读取数据的 Source。    
	2. 代码实现 

			
		> 		package cn.itcast.stream
		> 		
		> 		import java.sql.{Connection, DriverManager, PreparedStatement, ResultSet}
		> 		import java.util.concurrent.TimeUnit
		> 		
		> 		import org.apache.flink.configuration.Configuration
		> 		import org.apache.flink.streaming.api.functions.source.{RichParallelSourceFunction, SourceFunction}
		> 		import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
		> 		
		> 		
		> 		object StreamMySQLSource {
		> 		  def main(args: Array[String]): Unit = {  
		> 		  
		> 		//1.准备环境
		> 		val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
		> 		import org.apache.flink.api.scala._
		> 		
		> 		//2.从自定义MySQL数据源读取数据
		> 		val mysqlData: DataStream[Student] = env.addSource(new MySQLSource).setParallelism(1)
		> 		
		> 		//3.输出数据
		> 		mysqlData.print()
		> 		
		> 		//4.启动执行
		> 		env.execute()
		> 		
		> 		  }
		> 		
		> 		//样例类对象
		> 		  case class Student(id: Int, name: String, age: Int)
		> 		  /**
		> 		* 自定义MySQL数据源
		> 		CREATE TABLE `t_student` (
		> 		`id` int(11) NOT NULL AUTO_INCREMENT,
		> 		`name` varchar(255) DEFAULT NULL,
		> 		`age` int(11) DEFAULT NULL,
		> 		PRIMARY KEY (`id`)
		> 		) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
		> 		
		> 		INSERT INTO `t_student` VALUES ('1', 'jack', '18');
		> 		INSERT INTO `t_student` VALUES ('2', 'tom', '19');
		> 		INSERT INTO `t_student` VALUES ('3', 'rose', '20');
		> 		INSERT INTO `t_student` VALUES ('4', 'tom', '19');
		> 		INSERT INTO `t_student` VALUES ('5', 'jack', '18');
		> 		INSERT INTO `t_student` VALUES ('6', 'rose', '20');
		> 		*/
		> 		  class MySQLSource extends RichParallelSourceFunction[Student]{
		> 		var conn:Connection = _
		> 		var ps:PreparedStatement = _
		> 		//var isRunning:Boolean = true
		> 		override def open(parameters: Configuration): Unit = {
		> 		  conn = DriverManager.getConnection( "jdbc:mysql://localhost:3306/bigdata", "root", "root")
		> 		  val sql:String = "select id,name,age from t_student"
		> 		  ps = conn.prepareStatement(sql)
		> 		}
		> 		
		> 		override def run(ctx: SourceFunction.SourceContext[Student]): Unit = {
		> 		  //while (isRunning){
		> 		val res: ResultSet = ps.executeQuery()
		> 		while (res.next()){
		> 		  val id = res.getInt("id")
		> 		  val name = res.getString("name")
		> 		  val age = res.getInt("age")
		> 		  val student = Student(id, name, age)
		> 		  ctx.collect(student)
		> 		}
		> 		//TimeUnit.SECONDS.sleep(1)
		> 		 // }
		> 		}
		> 		
		> 		override def cancel(): Unit = {
		> 		  //isRunning = false
		> 		}
		> 		
		> 		override def close(): Unit = {
		> 		  if (conn != null) conn.close()
		> 		  if (ps != null) ps.close()
		> 		}
		> 		  }
		> 		}
		 

* **自定义数据源-代码练习-案例三** 
	1. 基于kafka的source操作    
	Flink提供的Kafka连接器，用于向Kafka主题读取或写入数据。  
	Flink Kafka Consumer集成了Flink的检查点机制，可提供一次性处理语义。  
	为实现这一目标，Flink并不完全依赖kafka的消费者群体偏移跟踪，而是在内部跟踪和检查这些偏移。    
	2. 代码实现   

		>     package cn.itcast.stream
		>  
		>     import java.util.Properties
		>     
		>     import org.apache.flink.api.common.serialization.SimpleStringSchema
		>     import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
		>     import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer011
		>     import org.apache.kafka.clients.CommonClientConfigs
		>     
		>     
		>     object StreamKafkaSource {
		>       def main(args: Array[String]): Unit = {
		>     
		>     //1.准备环境
		>     val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
		>     env.enableCheckpointing(1000) // checkpoint every 1000 msecs
		>     
		>     //2.准备kafka连接参数
		>     val props = new Properties()
		>     props.setProperty(CommonClientConfigs.BOOTSTRAP_SERVERS_CONFIG,"node1:9092,node02:9092,node03:9092")
		>     props.setProperty("group.id", "flink")
		>     props.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
		>     props.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
		>     props.setProperty("auto.offset.reset", "latest")
		>     props.setProperty("flink.partition-discovery.interval-millis", "5000")//动态感知kafka主题分区的变化
		>     val topic = "flink_kafka"
		>     
		>     //3.创建kafka数据源
		>     //FlinkKafkaConsumer从kafka获取的每条消息都会通过DeserialzationSchema的T deserialize(byte[] message)反序列化处理
		>     //SimpleStringSchema可以将Kafka的字节消息反序列化为Flink的字符串对象
		>     //JSONDeserializationSchema(只反序列化value)/JSONKeyValueDeserializationSchema可以把序列化后的Json反序列化成ObjectNode，ObjectNode可以通过objectNode.get(“field”).as(Int/String/…)() 来访问指定的字段
		>     //TypeInformationSerializationSchema/TypeInformationKeyValueSerializationSchema基于Flink的TypeInformation来创建schema，这种反序列化对于读写均是Flink的场景会比其他通用的序列化方式带来更高的性能。
		>     val kafkaConsumerSource = new FlinkKafkaConsumer011[String](topic,new SimpleStringSchema(),props)
		>     
		>     //4.指定消费者参数
		>     kafkaConsumerSource.setCommitOffsetsOnCheckpoints(true)//默认为true
		>     kafkaConsumerSource.setStartFromGroupOffsets()
		>     //默认值，从当前消费组记录的偏移量接着上次的开始消费,如果没有找到，
		>     则使用consumer的properties的auto.offset.reset设置的策略
		>     //kafkaConsumerSource.setStartFromEarliest()//从最早的数据开始消费
		>     //kafkaConsumerSource.setStartFromLatest//从最新的数据开始消费
		>     //kafkaConsumerSource.setStartFromTimestamp(1568908800000L)//根据指定的时间戳消费数据
		>     /*val offsets = new util.HashMap[KafkaTopicPartition, java.lang.Long]()//key是KafkaTopicPartition(topic，分区id),value是偏移量
		>     offsets.put(new KafkaTopicPartition(topic, 0), 110L)
		>     offsets.put(new KafkaTopicPartition(topic, 1), 119L)
		>     offsets.put(new KafkaTopicPartition(topic, 2), 120L)*/
		>     //kafkaConsumerSource.setStartFromSpecificOffsets(offsets)//从指定的具体位置开始消费
		>     
		>     //5.从kafka数据源获取数据
		>     import org.apache.flink.api.scala._
		>     val kafkaData: DataStream[String] = env.addSource(kafkaConsumerSource)
		>     
		>     //6.处理输出数据
		>     kafkaData.print()
		>     
		>     //7.启动执行
		>     env.execute()
		>       }
		>     }
		
##数据处理 DataStream的Transformation   
Transformation操作参见官网：  
https://ci.apache.org/projects/flink/flink-docs-release-1.7/dev/stream/operators/index.html   

1. keyby
按照指定的key来进行分流，类似于批处理中的groupBy。  
可以按照索引名/字段名来指定分组的字段。  
	
	>     package cn.itcast.stream
	>     
	>     import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
	>     
	>     object Transformation_KeyBy {
	>       def main(args: Array[String]): Unit = {
	>       
	>     //1.准备环境
	>     val senv = StreamExecutionEnvironment.getExecutionEnvironment
	>     senv.setParallelism(3)
	>     
	>     //2.读取数据
	>     import org.apache.flink.api.scala._
	>     val stream = senv.socketTextStream("node01", 9999, '\n')
	>     
	>     //3.处理数据
	>     //val value: DataStream[(String, Int)] = stream.flatMap(_.split("\\s")).map((_,1))
	>     //val value2:KeyedStream[(String, Int), Tuple] = value.keyBy(0)
	>     val result: DataStream[(String, Int)] = stream.flatMap(_.split("\\s")).map((_,1))
	>       //逻辑上将一个流分成不相交的分区，每个分区包含相同键的元素。在内部是通过散列分区来实现的
	>       .keyBy(_._1)
	>       .sum(1)
	>       
	>     //4.输出数据
	>     result.print()
	>     
	>     //5.开启执行
	>     senv.execute()
	>       }
	>     }

2. connect  
Connect用来将两个DataStream组装成一个ConnectedStreams。  
ConnectedStreams有两个不同的泛型，即不要求两个dataStream的element是同一类型。这样我们就可以把不同的数据组装成同一个结构.   

	>     package cn.itcast.stream
	>     
	>     import java.util.concurrent.TimeUnit
	>     
	>     import org.apache.flink.streaming.api.functions.source.SourceFunction
	>     import org.apache.flink.streaming.api.functions.source.SourceFunction.SourceContext
	>     import org.apache.flink.streaming.api.scala.{ConnectedStreams, DataStream, StreamExecutionEnvironment}
	>     
	>     object Transformation_Connect {
	>       def main(args: Array[String]): Unit = {
	>     //1.准备环境
	>     val env = StreamExecutionEnvironment.getExecutionEnvironment
	>     //2.获取数据
	>     import org.apache.flink.api.scala._
	>     val text1: DataStream[Long] = env.addSource(new MyLongSourceScala)
	>     val text2: DataStream[String] = env.addSource(new MyStringSourceScala)
	>     //3.处理数据,使用connect
	>     val connectData: ConnectedStreams[Long, String] = text1.connect(text2)
	>     val result: DataStream[String] = connectData.map[String](x1 ="Long: " + x1, x2 ="String :" + x2)
	>     //4输出结果
	>     result.print().setParallelism(1)
	>     //5.启动执行
	>     env.execute()
	>       }
	>     
	>       /**
	>     * 自定义source实现从1开始产生递增数字
	>     */
	>       class MyLongSourceScala extends SourceFunction[Long] {
	>     var count = 1L
	>     var isRunning = true
	>     
	>     override def run(ctx: SourceContext[Long]) = {
	>       while (isRunning) {
	>     ctx.collect(count)
	>     count += 1
	>     TimeUnit.SECONDS.sleep(1)
	>       }
	>     }
	>     
	>     override def cancel() = {
	>       isRunning = false
	>     }
	>       }
	>     
	>       /**
	>     * 自定义source实现从1开始产生递增字符串
	>     */
	>       class MyStringSourceScala extends SourceFunction[String] {
	>     var count = 1L
	>     var isRunning = true
	>     
	>     override def run(ctx: SourceContext[String]) = {
	>       while (isRunning) {
	>     ctx.collect("str_" + count)
	>     count += 1
	>     TimeUnit.SECONDS.sleep(1)
	>       }
	>     }
	>     
	>     override def cancel() = {
	>       isRunning = false
	>     }
	>       }
	>     }

3. split和select  
split就是将一个DataStream分成多个流，用SplitStream来表示DataStream → SplitStream  
select就是获取分流后对应的数据，跟split搭配使用，从SplitStream中选择一个或多个流SplitStream → DataStream  
示例   
加载本地集合(1,2,3,4,5,6), 使用split进行数据分流,分为奇数和偶数. 并打印奇数结果  
	
	>     package cn.itcast.stream
	>     
	>     import org.apache.flink.streaming.api.scala.{DataStream, SplitStream, StreamExecutionEnvironment}
	>     
	>     object Transformation_SplitAndSelect {
	>       def main(args: Array[String]): Unit = {
	>       
	>     //1.准备环境
	>     val env = StreamExecutionEnvironment.getExecutionEnvironment
	>     env.setParallelism(1)
	>     
	>     //2.获取数据
	>     import org.apache.flink.api.scala._
	>     val data: DataStream[Int] = env.fromElements(1, 2, 3, 4, 5, 6)
	>     
	>     //3.处理数据,使用split分流将数据分为奇数和偶数
	>     val split_Stream: SplitStream[Int] = data.split(num ={
	>       val i: Int = num % 2
	>       i match {
	>     case 0 =List("even")
	>     case 1 =List("odd")
	>       }
	>     })
	>     
	>     //4.处理数据,使用select获取数据
	>     val even: DataStream[Int] = split_Stream.select("even")
	>     val odd: DataStream[Int] = split_Stream.select("odd")
	>     val all: DataStream[Int] = split_Stream.select("even", "odd")
	>     
	>     //5.数据数据
	>     odd.print()
	>     
	>     //6.启动执行
	>     env.execute()
	>       }
	>     }



##数据输出Data Sinks  

1. 将数据sink到本地文件(参考批处理)
2. Sink到本地集合(参考批处理)
3. Sink到HDFS(参考批处理)
4. Sink到MySQL


	>     package cn.itcast.stream
	>     
	>     import java.sql.{Connection, DriverManager, PreparedStatement}
	>     
	>     import org.apache.flink.configuration.Configuration
	>     import org.apache.flink.streaming.api.functions.sink.{RichSinkFunction, SinkFunction}
	>     import org.apache.flink.streaming.api.scala._
	>     
	>     object StreamMySQLSink {
	>       def main(args: Array[String]): Unit = {
	>     //1.准备环境
	>     val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
	>     //2.准备数据
	>     val studetStream: DataStream[Student] = env.fromElements(Student(0, "tony", 18))
	>     //3.使用自定义Sink输出数据
	>     studetStream.addSink(new MySinkToMySQL)
	>     //4.启动执行
	>     env.execute()
	>       }
	>     
	>       //样例类
	>       case class Student(id: Int, name: String, age: Int)
	>     
	>       /**
	>     * 自定义Sink
	>     */
	>       class MySinkToMySQL extends RichSinkFunction[Student] {
	>     var conn: Connection = null
	>     var ps: PreparedStatement = null
	>     
	>     override def open(parameters: Configuration): Unit = {
	>       conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bigdata", "root", "root")
	>       val sql = "insert into t_student(name, age) values(?,?)"
	>       ps = conn.prepareStatement(sql)
	>     }
	>     
	>     //在invoke方法中执行插入操作
	>     override def invoke(stu: Student, context: SinkFunction.Context[_]): Unit = {
	>       ps.setString(1, stu.name)
	>       ps.setInt(2, stu.age)
	>       ps.executeUpdate()
	>     }
	>     
	>     override def close(): Unit = {
	>       if (conn != null) conn.close()
	>       if (ps != null) ps.close()
	>     }
	>       }
	>     
	>     }


5. Sink到Kafka  
/export/servers/kafka/bin/kafka-console-consumer.sh --bootstrap-server node1:9092 --topic test --from-beginning   

	>     package cn.itcast.stream
	>     
	>     import java.util.Properties
	>     
	>     import org.apache.flink.api.common.serialization.SimpleStringSchema
	>     import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
	>     import org.apache.flink.streaming.connectors.kafka.FlinkKafkaProducer011
	>     
	>     /**
	>      * 将数据保存到kafka
	>      */
	>     object StreamKafkaSink {
	>       def main(args: Array[String]): Unit = {
	>     //1.准备环境
	>     val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
	>     //2.准备数据
	>     import org.apache.flink.api.scala._
	>     val data: DataStream[Student] = env.fromElements(Student(8, "tony", 18))
	>     //3.处理数据,将student转换成字符串
	>     val stream: DataStream[String] = data.map(stu =>stu.toString)
	>     stream.print()
	>     //4.准备kafka连接参数
	>     val topic = "flink_kafka"
	>     val prop = new Properties()
	>     prop.setProperty("bootstrap.servers", "node01:9092")
	>     //5.创建生产者
	>     val kafkaProducer: FlinkKafkaProducer011[String] = new FlinkKafkaProducer011[String](topic, new SimpleStringSchema(), prop)
	>     //6.使用kafka生产者将数据写入到kafka
	>     stream.addSink(kafkaProducer)
	>     //7.启动执行
	>     env.execute()
	>       }
	>       //样例类
	>       case class Student(id: Int, name: String, age: Int)
	>     }
	    
6. Sink到Redis  

	Flink 提供了专门操作redis 的RedisSink，使用起来更方便，而且不用我们考虑性能的问题  
	https://bahir.apache.org/docs/flink/current/flink-streaming-redis/  

	RedisSink 核心类是RedisMapper 是一个接口，使用时我们要编写自己的redis 操作类实现这个接口中的三个方法，如下所示    
	getCommandDescription() ： 设置使用的redis 数据结构类型，和key 的名称，通过RedisCommand 设置数据结构类型   
	String getKeyFromData(T data)：设置value 中的键值对key 的值  
	String getValueFromData(T data);设置value 中的键值对value 的值       

	
	>     package cn.itcast.stream
	>     
	>     import java.net.{InetAddress, InetSocketAddress}
	>     import java.util
	>     
	>     import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
	>     import org.apache.flink.streaming.connectors.redis.common.config.{FlinkJedisClusterConfig, FlinkJedisPoolConfig}
	>     import org.apache.flink.api.scala._
	>     import org.apache.flink.streaming.connectors.redis.RedisSink
	>     import org.apache.flink.streaming.connectors.redis.common.mapper.{RedisCommand, RedisCommandDescription, RedisMapper}
	>     //实现单词统计然后把结果写入redis中
	>     object StreamRedisSink_bak {
	>       def main(args: Array[String]): Unit = {
	>     //1.准备环境
	>     val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
	>     //2.接收数据
	>     val source: DataStream[String] = env.socketTextStream("node01", 9999)
	>     //3.处理数据
	>     val result: DataStream[(String, Int)] = source.flatMap(_.split("\\W+"))
	>       .map((_, 1))
	>       .keyBy(0)
	>       .sum(1)
	>     //4.配置redis
	>     //val config: FlinkJedisPoolConfig = new FlinkJedisPoolConfig.Builder().setHost("localhost").setPort(6379).build()
	>     val set = new util.HashSet[InetSocketAddress]()
	>     set.add(new InetSocketAddress(InetAddress.getByName("localhost"), 6379))
	>     val config: FlinkJedisClusterConfig = new FlinkJedisClusterConfig.Builder().setNodes(set).setMaxTotal(5).build()
	>     //5.数据写入redis
	>     result.addSink(new RedisSink(config, new MyRedisSink))
	>     //6.触发执行
	>     env.execute()
	>       }
	>       class MyRedisSink extends RedisMapper[(String, Int)] {
	>     //指定redis的数据类型
	>     override def getCommandDescription: RedisCommandDescription = {
	>       new RedisCommandDescription(RedisCommand.HSET, "RedisSink")
	>     }
	>     //redis key
	>     override def getKeyFromData(data: (String, Int)): String = {
	>       data._1
	>     }
	>     //redis value
	>     override def getValueFromData(data: (String, Int)): String = {
	>       data._2.toString
	>     }
	>       }
	>     }
	
