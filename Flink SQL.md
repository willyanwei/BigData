#flink-SQL开发

## 背景  

Flink SQL是Flink实时计算为简化计算模型，降低用户使用实时计算门槛儿设计的一套符合标准SQL语义的开发语言。  

自 2015 年开始，阿里巴巴开始调研开源流计算引擎，最终决定基于 Flink 打造新一代计算引擎，针对 Flink 存在的不足进行优化和改进，并且在 2019 年初将最终代码开源，也就是我们熟知的 Blink。Blink 在原来的 Flink 基础上最显著的一个贡献就是 Flink SQL 的实现。  

Flink SQL 是面向用户的 API 层，在我们传统的流式计算领域，比如 Storm、Spark Streaming 都会提供一些 Function 或者 Datastream API，用户通过 Java 或 Scala 写业务逻辑，这种方式虽然灵活，但有一些不足，比如具备一定门槛且调优较难，随着版本的不断更新，API 也出现了很多不兼容的地方。  

在这个背景下，毫无疑问，SQL 就成了我们最佳选择，之所以选择将 SQL 作为核心 API，是因为其具有几个非常重要的特点：    
- SQL 属于设定式语言，用户只要表达清楚需求即可，不需要了解具体做法；  
- SQL 可优化，内置多种查询优化器，这些查询优化器可为 SQL 翻译出最优执行计划；  
- SQL 易于理解，不同行业和领域的人都懂，学习成本较低；  
- SQL 非常稳定，在数据库 30 多年的历史中，SQL 本身变化较少；  

流与批的统一，Flink 底层 Runtime 本身就是一个流与批统一的引擎，而 SQL 可以做到 API 层的流与批统一。   


##Flink常用算子  

1. SELECT  
	用于从 DataSet/DataStream 中选择数据，用于筛选出某些列。

	示例：  
	SELECT * FROM Table；// 取出表中的所有列  
	SELECT name，age FROM Table；// 取出表中 name 和 age 两列  
	与此同时 SELECT 语句中可以使用函数和别名，例如我们上面提到的 WordCount 中：  
	SELECT word, COUNT(word) FROM table GROUP BY word;   

2. WHERE  
	用于从数据集/流中过滤数据，与 SELECT 一起使用，用于根据某些条件对关系做水平分割，即选择符合条件的记录。

	示例：
	SELECT name，age FROM Table where name LIKE ‘% 小明 %’；  
	SELECT * FROM Table WHERE age = 20；  
	WHERE 是从原数据中进行过滤，那么在 WHERE 条件中，Flink SQL 同样支持 =、<、>、<>、>=、<=，以及 AND、OR 等表达式的组合，最终满足过滤条件的数据会被选择出来。并且 WHERE 可以结合 IN、NOT IN 联合使用。举个例子：  
	SELECT name, age  
	FROM Table  
	WHERE name IN (SELECT name FROM Table2)  

3. DISTINCT  
	用于从数据集/流中去重根据 SELECT 的结果进行去重。

	示例：
	SELECT DISTINCT name FROM Table;
	对于流式查询，计算查询结果所需的 State 可能会无限增长，用户需要自己控制查询的状态范围，以防止状态过大。

4. GROUP BY
	是对数据进行分组操作。例如我们需要计算成绩明细表中，每个学生的总分。

	示例：
	SELECT name, SUM(score) as TotalScore FROM Table GROUP BY name;

5. UNION和UNION ALL  
	UNION 用于将两个结果集合并起来，要求两个结果集字段完全一致，包括字段类型、字段顺序。不同于 UNION ALL 的是，UNION 会对结果数据去重。

	示例：
	SELECT * FROM T1 UNION (ALL) SELECT * FROM T2；

6. JOIN  
	JOIN 用于把来自两个表的数据联合起来形成结果表，Flink 支持的 JOIN 类型包括：

	JOIN - INNER JOIN  
	LEFT JOIN - LEFT OUTER JOIN  
	RIGHT JOIN - RIGHT OUTER JOIN  
	FULL JOIN - FULL OUTER JOIN	  
	这里的 JOIN 的语义和我们在关系型数据库中使用的 JOIN 语义一致。

	示例：
	JOIN（将订单表数据和商品表进行关联）
	SELECT * FROM Orders INNER JOIN Product ON Orders.productId = Product.id

	LEFT JOIN 与 JOIN 的区别是当右表没有与左边相 JOIN 的数据时候，右边对应的字段补 NULL 输出，RIGHT JOIN 相当于 LEFT JOIN 左右两个表交互一下位置。FULL JOIN 相当于 RIGHT JOIN 和 LEFT JOIN 之后进行 UNION ALL 操作。

	示例：
	SELECT * FROM Orders LEFT JOIN Product ON Orders.productId = Product.id  
	SELECT * FROM Orders RIGHT JOIN Product ON Orders.productId = Product.id  
	SELECT * FROM Orders FULL OUTER JOIN Product ON Orders.productId = Product.id   

7. Group Window  

	根据窗口数据划分的不同，目前 Apache Flink 有如下 3 种 Bounded Window：  
	* Tumble 滚动窗口     
	滚动窗口有固定大小，窗口数据无叠加，不重叠：
	滚动窗口对应的语法：  
		> 	SELECT   
		>     [gk],  
		>     [TUMBLE_START(timeCol, size)],   
		>     [TUMBLE_END(timeCol, size)],   
		>     agg1(col1), 
		>     ... 
		>     aggn(colN)  
		> 	FROM Tab1  
		> 	GROUP BY [gk], TUMBLE(timeCol, size)  
	
	其中：
	[gk] 决定了是否需要按照字段进行聚合；
	TUMBLE_START 代表窗口开始时间；
	TUMBLE_END 代表窗口结束时间；
	timeCol 是流表中表示时间字段；
	size 表示窗口的大小，如 秒、分钟、小时、天。  

	举个例子，假如我们要计算每个人每天的订单量，按照 user 进行聚合分组：  
	SELECT user,   
	TUMBLE_START(rowtime, INTERVAL ‘1’ DAY) as wStart, 
	SUM(amount) FROM Orders 
	GROUP BY TUMBLE(rowtime, INTERVAL ‘1’ DAY), user;

	* Hop 滑动窗口  
	窗口数据有固定大小，并且有固定的窗口重建频率，窗口数据有叠加；  
	与滚动窗口不同的是，滑动窗口可以通过slide参数控制滑动窗口的新建频率。  
	当slide值小于窗口size的值的时候，多个滑动窗口会重叠，具体语义如下：  

		
		>     SELECT 
		>     [gk], 
		>     [HOP_START(timeCol, slide, size)] ,  
		>     [HOP_END(timeCol, slide, size)],
		>     agg1(col1), 
		>     ... 
		>     aggN(colN) 
		>     FROM Tab1
		>     GROUP BY [gk], HOP(timeCol, slide, size)
		


		字段的意思和 Tumble 窗口类似：  
		[gk] 决定了是否需要按照字段进行聚合；  
		HOP_START 表示窗口开始时间；  
		HOP_END 表示窗口结束时间；  
		timeCol 表示流表中表示时间字段；  
		slide 表示每次窗口滑动的大小；  
		size 表示整个窗口的大小，如 秒、分钟、小时、天。  

		举例说明，我们要每过一小时计算一次过去 24 小时内每个商品的销量：  
		>     SELECT   
		>     	product,   
		>     	SUM(amount)   
		>     FROM Orders   
		>     GROUP BY HOP(rowtime, INTERVAL '1' HOUR, INTERVAL '1' DAY), product

	* Session会话窗口  
	窗口数据没有固定的大小，根据窗口数据活跃程度划分窗口，窗口数据无叠加。      
	会话时间没有固定的持续时间，他们的接线由interval不活动时间定义，即如果在定义的间隙时间内没有出现事件，则会话窗口会关闭  
	
		Seeeion 会话窗口对应语法如下：  
		> 	SELECT   
		> 	    [gk],   
		> 	    SESSION_START(timeCol, gap) AS winStart,
		> 	    SESSION_END(timeCol, gap) AS winEnd,  
		> 	    agg1(col1),  
		>  	    ...   
		> 	    aggn(colN)  
		> 	FROM Tab1  
		> 	GROUP BY [gk], SESSION(timeCol, gap)  

		[gk] 决定了是否需要按照字段进行聚合；  
		SESSION_START 表示窗口开始时间；  
		SESSION_END 表示窗口结束时间；  
		timeCol 表示流表中表示时间字段；  
		gap 表示窗口数据非活跃周期的时长。  

		例如，我们需要计算每个用户访问时间 12 小时内的订单量：
		> 	SELECT   
		> 		user,   
		> 		SESSION_START(rowtime, INTERVAL ‘12’ HOUR) AS sStart,   
		> 		SESSION_ROWTIME(rowtime, INTERVAL ‘12’ HOUR) AS sEnd,   
		> 		SUM(amount)   
		> 	FROM Orders   
		> 	GROUP BY SESSION(rowtime, INTERVAL ‘12’ HOUR), user
		>  

		Table API和SQL捆绑在flink-table Maven工件中。必须将以下依赖项添加到你的项目才能使用Table API和SQL：    
		> 		<dependency 
		>     		<groupId>org.apache.flink</groupId  
		>     		<artifactId>flink-table_2.11</artifactId 
		>     		<version>${flink.version}</version 
		> 		</dependency 


		另外，你需要为Flink的Scala批处理或流式API添加依赖项。对于批量查询，您需要添加：

		> 		<dependency   
		>   			<groupId>org.apache.flink</groupId   
		> 			<artifactId>flink-scala_2.11</artifactId 
		>  			<version>1.7.0</version 
		> 		</dependency 



##Flink实战应用  
###批数据处理  
* 课题  
	使用Flink SQL统计用户消费订单的总金额、最大金额、最小金额、订单总数。  

* 实现思路  

	1. 构建table运行环境  
	2. 将dataset注册为一张表  
	3. 使用table运行环境的SQLQuery方法来执行SQL语句  

* 步骤    
	1. 获取一个批处理运行环境
	2. 获取一个Table运行环境
	3. 创建一个样例类 Order 用来映射数据（订单名、用户名、订单日期、订单金额）
	4. 基于本地 Order 集合创建一个DataSet source
	5. 使用Table运行环境将DataSet注册为一张表
	6. 使用SQL语句来操作数据（统计用户消费订单的总金额、最大金额、最小金额、订单总数）
	7. 使用TableEnv.toDataSet将Table转换为DataSet
	8. 打印测试  


	>     
	>     package cn.itcast.table
	>     
	>     import org.apache.flink.api.scala.ExecutionEnvironment
	>     import org.apache.flink.table.api.{Table, TableEnvironment}
	>     import org.apache.flink.table.api.scala.BatchTableEnvironment
	>     import org.apache.flink.api.scala._
	>     import org.apache.flink.types.Row


	>     /**
	>      * 使用Flink SQL统计用户消费订单的总金额、最大金额、最小金额、订单总数。
	>      */
	>      
	>     object BatchFlinkSqlDemo {  
	>     
	>       //创建一个样例类 Order 用来映射数据（订单名、用户名、订单日期、订单金额）
	>       case class Order(id:Int, userName:String, createTime:String, money:Double)
	>     
	>       def main(args: Array[String]): Unit = {
	>     /**
	>      * 实现思路：
	>      */  
	>      
	>     //1. 获取一个批处理运行环境
	>     val env: ExecutionEnvironment = ExecutionEnvironment.getExecutionEnvironment
	>     
	>     //2. 获取一个Table运行环境
	>     val tabEnv: BatchTableEnvironment = TableEnvironment.getTableEnvironment(env)
	>     
	>     //4. 基于本地 Order 集合创建一个DataSet source
	>     val orderDataSet: DataSet[Order] = env.fromElements(
	>       Order(1, "zhangsan", "2018-10-20 15:30", 358.5),
	>       Order(2, "zhangsan", "2018-10-20 16:30", 131.5),
	>       Order(3, "lisi", "2018-10-20 16:30", 127.5),
	>       Order(4, "lisi", "2018-10-20 16:30", 328.5),
	>       Order(5, "lisi", "2018-10-20 16:30", 432.5),
	>       Order(6, "zhaoliu", "2018-10-20 22:30", 451.0),
	>       Order(7, "zhaoliu", "2018-10-20 22:30", 362.0),
	>       Order(8, "zhaoliu", "2018-10-20 22:30", 364.0),
	>       Order(9, "zhaoliu", "2018-10-20 22:30", 341.0)
	>     )
	>     
	>     //5. 使用Table运行环境将DataSet注册为一张表
	>     tabEnv.registerDataSet("t_order", orderDataSet)
	>     
	>     //6. 使用SQL语句来操作数据（统计用户消费订单的总金额、最大金额、最小金额、订单总数）
	>     //用户消费订单的总金额、最大金额、最小金额、订单总数。
	>     val sql =
	>       """
	>     | select
	>     |   userName,
	>     |   sum(money) totalMoney,
	>     |   max(money) maxMoney,
	>     |   min(money) minMoney,
	>     |   count(1) totalCount
	>     |  from t_order
	>     |  group by userName
	>     |""".stripMargin  //在scala中stripMargin默认是“|”作为多行连接符
	>     
	>     //7. 使用TableEnv.toDataSet将Table转换为DataSet
	>     val table: Table = tabEnv.sqlQuery(sql)
	>     
	>     table.printSchema()
	>     
	>     tabEnv.toDataSet[Row](table).print()
	>       }
	>     }



###流数据SQL   

* 流数据也可以支持SQL，但是需要注意一下几点:  
	1. 要使用流处理的SQL，必须添加水印时间 
	2. 使用RegisterDataStream注册表时，使用‘来指定字段
	3. 注册表时，必须指定一个rowtime，否则无法在SQL中使用窗口
	4. 必须导入import org.apache.flink.table.api.scala._  
	5. SQL中使用trumble（时间列名，interval‘时间’ second）来进行窗口定义  

* 课题  
使用Flink SQL来统计5秒内用户的订单总数，订单最大金额，订单的最小金额  

* 步骤  
	1. 获取流处理运行环境
	2. 获取Table运行环境
	3. 设置处理时间为 EventTime
	4. 创建一个订单样例类 Order ，包含四个字段（订单ID、用户ID、订单金额、时间戳）
	5. 创建一个自定义数据源  
		a.使用for循环生成1000个订单  
		b.随机生成订单ID（UUID）  
		c.随机生成用户ID（0-2）  
		d.随机生成订单金额（0-100）  
		e.时间戳为当前系统时间  
		f.每隔1秒生成一个订单    
	6. 添加水印，允许延迟2秒  
	7. 导入 import org.apache.flink.table.api.scala._ 隐式参数  
	8. 使用 registerDataStream 注册表，并分别指定字段，还要指定rowtime字段  
	9. 编写SQL语句统计用户订单总数、最大金额、最小金额  
		分组时要使用 tumble(时间列, interval '窗口时间' second) 来创建窗口
	10. 使用 tableEnv.sqlQuery 执行sql语句  
	11. 将SQL的执行结果转换成DataStream再打印出来  
	12. 启动流处理程序  
	
	
	>     package cn.itcast.table
	>     
	>     import java.util.UUID
	>     import java.util.concurrent.TimeUnit
	>     
	>     import org.apache.flink.streaming.api.TimeCharacteristic
	>     import org.apache.flink.streaming.api.functions.source.{RichSourceFunction, SourceFunction}
	>     import org.apache.flink.streaming.api.scala.{DataStream, StreamExecutionEnvironment}
	>     import org.apache.flink.table.api.{Table, TableEnvironment}
	>     import org.apache.flink.api.scala._
	>     import org.apache.flink.streaming.api.functions.AssignerWithPeriodicWatermarks
	>     import org.apache.flink.streaming.api.functions.timestamps.BoundedOutOfOrdernessTimestampExtractor
	>     import org.apache.flink.streaming.api.watermark.Watermark
	>     import org.apache.flink.streaming.api.windowing.time.Time
	>     import org.apache.flink.types.Row
	>     
	>     import scala.util.Random
	>     /**
	>      * 需求：
	>      *  使用Flink SQL来统计5秒内 用户的 订单总数、订单的最大金额、订单的最小金额
	>      *
	>      *  timestamp是关键字不能作为字段的名字（关键字不能作为字段名字）
	>      */
	>     object StreamFlinkSqlDemo {
	>     
	>     // 创建一个订单样例类`Order`，包含四个字段（订单ID、用户ID、订单金额、时间戳）
	>     case class Order(orderId:String, userId:Int, money:Long, createTime:Long)
	>     
	>     def main(args: Array[String]): Unit = {
	>     
	>       // 1. 创建流处理运行环境
	>       val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
	>     
	>       // 2. 设置处理时间为`EventTime`
	>       env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
	>     
	>       //获取table的运行环境
	>       val tableEnv = TableEnvironment.getTableEnvironment(env)
	>     
	>       // 4. 创建一个自定义数据源
	>       val orderDataStream = env.addSource(new RichSourceFunction[Order] {
	>     var isRunning = true
	>     override def run(ctx: SourceFunction.SourceContext[Order]): Unit = {
	>       // - 随机生成订单ID（UUID）
	>       // - 随机生成用户ID（0-2）
	>       // - 随机生成订单金额（0-100）
	>       // - 时间戳为当前系统时间
	>       // - 每隔1秒生成一个订单
	>       for (i <- 0 until 1000 if isRunning) {
	>     val order = Order(UUID.randomUUID().toString, Random.nextInt(3), Random.nextInt(101),
	>       System.currentTimeMillis())
	>     TimeUnit.SECONDS.sleep(1)
	>     ctx.collect(order)
	>       }
	>     }
	>     override def cancel(): Unit = { isRunning = false }
	>       })
	>     
	>       // 5. 添加水印，允许延迟2秒
	>       val watermarkDataStream = orderDataStream.assignTimestampsAndWatermarks(
	>     new BoundedOutOfOrdernessTimestampExtractor[Order](Time.seconds(2)) {
	>       override def extractTimestamp(element: Order): Long = {
	>     val eventTime = element.createTime
	>     eventTime
	>       }
	>     }
	>       )
	>     
	>       // 6. 导入`import org.apache.flink.table.api.scala._`隐式参数
	>       // 7. 使用`registerDataStream`注册表，并分别指定字段，还要指定rowtime字段
	>       import org.apache.flink.table.api.scala._
	>       tableEnv.registerDataStream("t_order", watermarkDataStream, 'orderId, 'userId, 'money,'createTime.rowtime)
	>     
	>       // 8. 编写SQL语句统计用户订单总数、最大金额、最小金额
	>       // - 分组时要使用`tumble(时间列, interval '窗口时间' second)`来创建窗口
	>       val sql =
	>       """
	>     |select
	>     | userId,
	>     | count(1) as totalCount,
	>     | max(money) as maxMoney,
	>     | min(money) as minMoney
	>     | from
	>     | t_order
	>     | group by
	>     | tumble(createTime, interval '5' second),
	>     | userId
	>       """.stripMargin
	>       // 9. 使用`tableEnv.sqlQuery`执行sql语句
	>       val table: Table = tableEnv.sqlQuery(sql)
	>     
	>       // 10. 将SQL的执行结果转换成DataStream再打印出来
	>       table.toRetractStream[Row].print()
	>       env.execute("StreamSQLApp")
	>     }
	>     }
	
