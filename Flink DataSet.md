#Flink DataSet开发

##Flink批处理程序一般流程 
flink和spark类似，也是一种一站式处理的框架；既可以进行批处理（DataSet），也可以进行实时处理（DataStream）  
开发流程：  
获得一个execution environment，  
加载/创建初始数据，  
指定这些数据的转换，  
指定将计算结果放在哪里，  
触发程序执行    


##简单示例   
实现思路：  
1. 通过eclipse或idea构建maven工程  
2. 编写flink代码  
3. 打包运行  

* 编写flink代码 
		
	>     package cn.itcast.hello
	>     
	>     import org.apache.flink.api.scala.{AggregateDataSet, DataSet, ExecutionEnvironment}
	>     
	>     object WordCount_bak {
	>       def main(args: Array[String]): Unit = {
	>     //1.获取ExecutionEnvironment
	>     val env: ExecutionEnvironment = ExecutionEnvironment.getExecutionEnvironment
	>     //2.加载数据
	>     import org.apache.flink.api.scala._
	>     val lines: DataSet[String] = env.fromElements("Apache Flink is an open source platform for distributed stream and batch data processing","Flink’s core is a streaming dataflow engine that provides data distribution")
	>     //3.处理数据 [\w]+和\w+没有区别，都是匹配数字和字母下划线的多个字符
	>     val words: DataSet[String] = lines.flatMap(_.split("\\W+"))//" "
	>     val wordAndOne: DataSet[(String, Int)] = words.map((_,1))
	>     //val value: GroupedDataSet[(String, Int)] = wordAndOne.groupBy(0)
	>     //val result: AggregateDataSet[(String, Int)] = wordAndOne.groupBy(_._1).sum(1)
	>     //Aggregate does not support grouping with KeySelector functions, yet.//聚合尚不支持使用键选择器函数进行分组
	>     //val result: AggregateDataSet[(String, Int)] = wordAndOne.groupBy("_1").sum(1)
	>     val result: AggregateDataSet[(String, Int)] = wordAndOne.groupBy(0).sum(1)
	>     //4.输出结果
	>     result.print()
	>     //5.触发执行
	>     //env.execute()
	>     // No new data sinks have been defined since the last execution. 
	>     //The last execution refers to the latest call to 'execute()', 'count()', 'collect()', or 'print()'.
	>       }
	>     }


* 打包运行  

	**在Yarn上运行**   
		注意  
		写入HDFS可能存在权限问题:  
		System.setProperty("HADOOP_USER_NAME", "root")  
		hadoop fs -chmod -R 777  /  

	* 修改代码
		>     package cn.itcast.hello  
		>     
		>     import org.apache.flink.api.scala.ExecutionEnvironment  
		>     
		>     object WordCount {  
		>       def main(args: Array[String]): Unit = { 
		>        
		>     //1.获取ExecutionEnvironment  
		>     val env: ExecutionEnvironment =   ExecutionEnvironment.getExecutionEnvironment  
		>     
		>     //2.加载数据  
		>     import org.apache.flink.api.scala._  
		>     val lines: DataSet[String] = env.fromElements("Apache Flink is an open source platform for distributed stream and batch data processing","Flink’s core is a streaming dataflow engine that provides data distribution")  
		>     
		>     //3.转换数据  
		>     val words: DataSet[String] = lines.flatMap(_.split("\\W+"))  
		>     val wordAndOne: DataSet[(String, Int)] = words.map((_,1))  
		>     val result: AggregateDataSet[(String, Int)] = wordAndOne.groupBy(0).sum(1)  
		>     
		>     //4.输出结果  
		>     result.setParallelism(1)  
		>     System.setProperty("HADOOP_USER_NAME", "root")  
		>     result.writeAsText("hdfs://node1:8020/wordcount/output")  
		>     
		>     //5.触发执行  
		>     env.execute()  
		>       }
		>     }
	

	* 打包
	* 改名上传
	* 执行  
	
		>     /export/servers/flink/bin/flink run -m yarn-cluster -yn 2 -yjm 1024 -ytm 1024 -c cn.itcast.batch.FlinkDemo01 /root/wc.jar 

	* 在Web页面可以观察到提交的程序：  
		http://node1:8088/cluster  
		http://node1:50070/explorer.html#/  
		或者在Standalone模式下使用web界面提交  


## 输入数据集DataSources 
Flink在批处理中常见的Source主要由两大类：   
基于本地集合的Source（collection-base-source）  
基于文件的Source（File-based-sourcec）  

1. 基于本地集合  
	基于集合创建DataSet的方式有三种：  
	* 使用env.fromElements()支持Tuple，自定义对象等复合形式  
	* 使用env.fromCollection（）支持多种Collection的具体类型
	* 使用env.generateSequence()支持创建基于Sequence的DataSet  

		>     package cn.itcast.batch
		>     
		>     import org.apache.flink.api.scala.ExecutionEnvironment
		>     import scala.collection.mutable
		>     import scala.collection.mutable.{ArrayBuffer, ListBuffer}
		>     
		>     /**
		>       * 读取集合中的批次数据
		>       */
		>     object BatchFromCollection {
		>       def main(args: Array[String]): Unit = {
		>     //获取env
		>     val env = ExecutionEnvironment.getExecutionEnvironment
		>     import org.apache.flink.api.scala._
		>     
		>     //0.用element创建DataSet(fromElements)
		>     val ds0: DataSet[String] = env.fromElements("spark", "flink")
		>     ds0.print()
		>     
		>     //1.用Tuple创建DataSet(fromElements)
		>     val ds1: DataSet[(Int, String)] = env.fromElements((1, "spark"), (2, "flink"))
		>     ds1.print()
		>     
		>     //2.用Array创建DataSet
		>     val ds2: DataSet[String] = env.fromCollection(Array("spark", "flink"))
		>     ds2.print()
		>     
		>     //3.用ArrayBuffer创建DataSet
		>     val ds3: DataSet[String] = env.fromCollection(ArrayBuffer("spark", "flink"))
		>     ds3.print()
		>     
		>     //4.用List创建DataSet
		>     val ds4: DataSet[String] = env.fromCollection(List("spark", "flink"))
		>     ds4.print()
		>     
		>     //5.用ListBuffer创建DataSet
		>     val ds5: DataSet[String] = env.fromCollection(ListBuffer("spark", "flink"))
		>     ds5.print()
		>     
		>     //6.用Vector创建DataSet
		>     val ds6: DataSet[String] = env.fromCollection(Vector("spark", "flink"))
		>     ds6.print()
		>     
		>     //7.用Queue创建DataSet
		>     val ds7: DataSet[String] = env.fromCollection(mutable.Queue("spark", "flink"))
		>     ds7.print()
		>     
		>     //8.用Stack创建DataSet
		>     val ds8: DataSet[String] = env.fromCollection(mutable.Stack("spark", "flink"))
		>     ds8.print()
		>     
		>     //9.用Stream创建DataSet(Stream相当于lazy List，避免在中间过程中生成不必要的集合)
		>     val ds9: DataSet[String] = env.fromCollection(Stream("spark", "flink"))
		>     ds9.print()
		>     
		>     //10.用Seq创建DataSet
		>     val ds10: DataSet[String] = env.fromCollection(Seq("spark", "flink"))
		>     ds10.print()
		>     
		>     //11.用Set创建DataSet
		>     val ds11: DataSet[String] = env.fromCollection(Set("spark", "flink"))
		>     ds11.print()
		>     
		>     //12.用Iterable创建DataSet
		>     val ds12: DataSet[String] = env.fromCollection(Iterable("spark", "flink"))
		>     ds12.print()
		>     
		>     //13.用ArraySeq创建DataSet
		>     val ds13: DataSet[String] = env.fromCollection(mutable.ArraySeq("spark", "flink"))
		>     ds13.print()
		>     
		>     //14.用ArrayStack创建DataSet
		>     val ds14: DataSet[String] = env.fromCollection(mutable.ArrayStack("spark", "flink"))
		>     ds14.print()
		>     
		>     //15.用Map创建DataSet
		>     val ds15: DataSet[(Int, String)] = env.fromCollection(Map(1 -"spark", 2 -"flink"))
		>     ds15.print()
		>     
		>     //16.用Range创建DataSet
		>     val ds16: DataSet[Int] = env.fromCollection(Range(1, 9))
		>     ds16.print()
		>     
		>     //17.用fromElements创建DataSet
		>     val ds17: DataSet[Long] = env.generateSequence(1, 9)
		>     ds17.print()
		>       }
		>     }  


2. 基于文件  
	基于文件创建DataSet的方式有5种：  
	1. 读取本地文件数据 readTextFile
	1. 读取HDFS文件数据
	1. 读取CSV文件数据
	1. 读取压缩文件
	1. 遍历目录 
	> 遍历目录  
	flink支持对一个文件目录内的所有文件，包括所有子目录中的所有文件的遍历访问方式。
	对于从文件中读取数据，当读取的数个文件夹的时候，嵌套的文件默认是不会被读取的，
	所以我们需要使用recursive.file.enumeration进行递归读取  
 
	实现：   

	>     package cn.itcast.batch
	>     
	>     import org.apache.flink.api.scala.{DataSet, ExecutionEnvironment}
	>     import org.apache.flink.configuration.Configuration
	>     
	>     /**
	>       * 读取文件中的批次数据
	>       */
	>     object BatchFromFile {
	>       def main(args: Array[String]): Unit = {
	>     //获取env
	>     val env: ExecutionEnvironment = ExecutionEnvironment.getExecutionEnvironment
	>     
	>     //1.读取本地文件
	>     val ds1: DataSet[String] = env.readTextFile("D:\\data\\words.txt")
	>     ds1.print()
	>     
	>     //2.读取HDFS文件
	>     val ds2: DataSet[String] = env.readTextFile("hdfs://node01:8020/wordcount/input/words.txt")
	>     ds2.print()
	>     
	>     //3.读取CSV文件
	>     case class Student(id:Int, name:String)
	>     import org.apache.flink.api.scala._
	>     val ds3: DataSet[Student] = env.readCsvFile[Student]("D:\\data\\subject.csv")
	>     ds3.print()
	>     
	>     //4.读取压缩文件
	>     val ds4 = env.readTextFile("D:\\data\\wordcount.txt.gz")
	>     ds4.print()
	>     
	>     //5.读取文件夹
	>     val parameters = new Configuration
	>     parameters.setBoolean("recursive.file.enumeration", true)
	>     val ds5 = env.readTextFile("D:\\data\\wc").withParameters(parameters)
	>     ds5.print()
	>     
	>       }
	>     }  

##数据处理 DataSet的4.3.Operator/Transformation  

https://ci.apache.org/projects/flink/flink-docs-release-1.9/dev/batch/     


##数据输出Data Sinks  

* 基于集合  
	* 基于本地集合的sink(Collection-based-sink)
	可以sink到标准输出,error输出,collect()到本地集合
* 基于文件  
	* 基于文件的sink(File-based-sink)  
	可以sink到本地文件,hdfs文件(支持多种文件的存储格式，包括text文件，CSV文件等)
	writeAsText()：TextOuputFormat - 将元素作为字符串写入行。字符串是通过调用每个元素的toString()方法获得的。


		>     package cn.itcast.batch
		>     
		>     import org.apache.flink.api.scala.{DataSet, ExecutionEnvironment}
		>     import org.apache.flink.core.fs.FileSystem.WriteMode
		>     import org.apache.flink.api.scala._
		>     
		>     object BatchSink {
		>       def main(args: Array[String]): Unit = {
		>     val env = ExecutionEnvironment.getExecutionEnvironment
		>     
		>     val ds: DataSet[Map[Int, String]] = env.fromElements(Map(1 -"spark", 2 -"flink"))
		>     //sink到标准输出
		>     ds.print
		>     
		>     //sink到标准error输出
		>     ds.printToErr()
		>     
		>     //sink到本地Collection
		>     print(ds.collect())
		>     
		>     //sink到本地文件
		>     ds.setParallelism(1).writeAsText("D:\\data\\output", WriteMode.OVERWRITE)
		>     
		>     //sink到hdfs
		>     ds.setParallelism(1).writeAsText("hdfs://node01:8020/wordcount/output", WriteMode.OVERWRITE)
		>     
		>     env.execute()
		>     //主意：不论是本地还是hdfs.
		>     //如果Parallelism>1将把path当成目录名称，
		>     //如果Parallelism=1将把path当成文件名。
		>     //OVERWRITE模式下如果文件已经存在，则覆盖
		>       }
		>     }



##执行模式  
1. 本地环境
2. 集群环境  

###本地执行  
Flink支持两种不同的本地执行：    

- **local环境**  
LocalEnvironment是Flink程序本地执行的句柄。可使用它独立或嵌入其他程序在本地 JVM 中运行Flink程序。  
LocalExecutionEnvironment 是启动完整的Flink运行时(Flink Runtime)，包括 JobManager 和 TaskManager。     
这种方式包括内存管理和在集群模式下执行的所有内部算法。  
本地环境通过该方法实例化ExecutionEnvironment.createLocalEnvironment()。
默认情况下，启动的本地线程数与计算机的CPU个数相同。也可以指定所需的并行性。  
本地环境可以配置为使用enableLogging()/ 登录到控制台disableLogging()。
在大多数情况下，ExecutionEnvironment.getExecutionEnvironment()是更好的方式。
LocalEnvironment当程序在本地启动时(命令行界面外)，该方法会返回一个程序，并且当程序由命令行界面调用时，它会返回一个预配置的群集执行环境。
注意：本地执行环境不启动任何Web前端来监视执行。

- **集合环境**  
CollectionEnvironment 是在 Java 集合(Java Collections)上执行 Flink 程序。   
此模式不会启动完整的Flink运行时(Flink Runtime)，因此执行的开销非常低并且轻量化。   
例如一个DataSet.map()变换，会对Java list中所有元素应用 map() 函数。  
使用CollectionEnvironment是执行Flink程序的低开销方法。这种模式的典型用例是自动化测试，调试。  
用户也可以使用为批处理实施的算法，以便更具交互性的案例
请注意，基于集合的Flink程序的执行仅适用于适合JVM堆的小数据。集合上的执行不是多线程的，只使用一个线程   

	>     package cn.itcast.batch.transformation
	>     
	>     import java.util.Date
	>     
	>     import org.apache.flink.api.scala.{DataSet, ExecutionEnvironment}
	>     import org.apache.flink.api.scala._
	>     object MultiEnvDemo {
	>       def main(args: Array[String]): Unit = {
	>     var start_time =new Date().getTime
	>     
	>     //val env = ExecutionEnvironment.createLocalEnvironment()//4635
	>     //val env = ExecutionEnvironment.createCollectionsEnvironment//448
	>     val env = ExecutionEnvironment.getExecutionEnvironment//4651
	>     val list: DataSet[String] = env.fromCollection(List("1","2"))//
	>     list.print()
	>     
	>     var end_time =new Date().getTime
	>     
	>     println(end_time-start_time) //单位毫秒
	>       }
	>     }   

###集群执行  

Flink程序可以在许多机器的集群上分布运行。  
有两种方法可将程序发送到群集以供执行：


- 命令行界面：  
>     /export/servers/flink/bin/flink run  /export/servers/flink/examples/batch/WordCount.jar --input hdfs://node01:8020/wordcount/input/words.txt --output hdfs://node01:8020/wordcount/output/result.txt



- 远程环境提交
远程环境允许直接在群集上执行Flink程序。远程环境指向要在其上执行程序的群集


>     package cn.itcast.batch
>     
>     import org.apache.flink.api.scala.{DataSet, ExecutionEnvironment}
>     
>     object BatchRemoteEven {
>       def main(args: Array[String]): Unit = {
>     // 1. 创建远程执行环境
>     val env: ExecutionEnvironment = ExecutionEnvironment
>       .createRemoteEnvironment("node02", 8081, "C:\\develop\\code\\idea\\FlinkDemo\\target\\FlinkDemo-1.0-SNAPSHOT.jar")
>     // 2. 读取远程CSV文件,转换为元组类型
>     val scoreDatSet: DataSet[String] =env.readTextFile("hdfs://node01:8020//wordcount/input/words.txt")
>     // 4. 打印结果
>     scoreDatSet.print()
>       }
>     }  


