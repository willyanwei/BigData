# MapReduce  
### 大数据学习线路图  
<img src="https://upload-images.jianshu.io/upload_images/22827736-ab17271698b9385a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" width="100%">
  
----------
###缩略词  
NN - NameNode  
SNN - Secondry NameNode  
DN - DataNode  
MR - MapReduce 


----------

###概念

MapReduce-大数据并行处理框架，分布式计算框架  
源自于google的MapReduce论文，发表于2004年12月，Hadoop MapReduce是google MapReduce 克隆版。
MapReduce是一种分布式计算模型，用以进行大数据量的计算。它屏蔽了分布式计算框架细节，将计算抽象成map和reduce两部分，
其中Map对数据集上的独立元素进行指定的操作，生成键-值对形式中间结果。Reduce则对中间结果中相同“键”的所有“值”进行规约，以得到最终结果。

* 为什么要有MapReduce？  
MR适合在大量计算机组成的分布式并行环境里进行数据处理  


----------
### 设计构思   

* 分而治之  
	* Map负责“分”  
	即把复杂的任务分解为若干个“简单的任务”来并行处理。可以进行拆分的前提是这些小任务可以并行计算，彼此之间几乎没有依赖关系  
	* Reduce负责“合”  
	即对Map阶段的结果进行全局汇总  


----------

###架构 
* 架构   
MapReduce运行在YARN集群，节点包括：ResourceManager,NodeManager  

* 进程  
	一个完整的MR程序在分布式运行时有三类实例进程：  
	* MRAppMaster-负责整个程序的调度以及状态协调  
	* MapTask-负责Map阶段的整个数据处理流程
	* ReduceTask-负责Reduce阶段的整个数据处理流程
 
 	<img src="https://upload-images.jianshu.io/upload_images/22827736-b10e328bd17840bd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" width="100%">  

* WordCount为例  


###优缺点
* 优点  
	* MapReduce是一个分布式运算程序的编程框架，核心功能是将用户编写的业务逻辑代码和自带默认组件整合成一个完整的分布式运算程序，并发运行在Hadoop集群上。
	* MapReduce设计并提供了统一的计算框架，为程序员隐藏了绝大多数系统层面的处理细节。 为程序员提供一个抽象和高层的编程接口和框架。程序员仅需要关心其应用层的具体计算问题，仅需编写少量的处理应用本身计算问题的程序代码。如何具体完成这个并行计算任务所相关的诸多系统层细节被隐藏起来,交给计算框架去处理：
	Map和Reduce为程序员提供了一个清晰的操作接口抽象描述。MapReduce中定义了如下的Map 和Reduce两个抽象的编程接口，由用户去编程实现.Map和Reduce,MapReduce处理的数据类型 是<key,value>键值对。
		* Map: (k1; v1) → [(k2; v2)]
		* Reduce:(k2; [v2]) → [(k3; v3)]

* 缺点  

	* 计算都必须要转化成Map和Reduce两个操作，但这并不适合所有的情况，难以描述复杂的数据处理过程
	* 磁盘IO开销大。每次执行时都需要从磁盘读取数据，并且在计算完成后需要将中间结果写入到磁盘中，IO开销较大
	* 一次计算可能需要分解成一系列按顺序执行的MapReduce任务，任务之间的衔接由于涉及到IO开销，会产生较高延迟。而且，在前一个任务执行完成之前，其他任务无法开始，难以胜任复杂、多阶段的计算任务。



----------


###运行机制

统计单词个数 word count为例：  
		<img src="https://upload-images.jianshu.io/upload_images/22827736-7998850010a324a2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" width="100%"> 

整体工作流程：  
		<img src="https://upload-images.jianshu.io/upload_images/22827736-737561904dcd7b68.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" width="100%"> 


* MapTask工作机制   
 简单概述：inputFile通过split被逻辑切分为多个split文件，通过Record按行读取内容给 map（用户自己实现的）进行处理，数据被map处理结束之后交给OutputCollector收集器，对 其结果key进行分区（默认使用hash分区），然后写入buwer，每个map task都有一个内存缓冲 区，存储着map的输出结果，当缓冲区快满的时候需要将缓冲区的数据以一个临时文件的方 式存放到磁盘，当整个map task结束后再对磁盘中这个map task产生的所有临时文件做合并， 生成最终的正式输出文件，然后等待reduce task来拉数据

	* 读取数据组件 InputFormat (默认 TextInputFormat) 会通过 getSplits 方法对输入目录 中文件进行逻辑切片规划得到 block , 有多少个 block 就对应启动多少个 MapTask
	* 将输入文件切分为 block 之后, 由 RecordReader 对象 (默认是LineRecordReader) 进 行读取, 以 \n 作为分隔符, 读取一行数据, 返回 <key，value> . Key 表示每行首字符偏 移值, Value 表示这一行文本内容
	* 读取 block 返回 <key,value> , 进入用户自己继承的 Mapper 类中，执行用户重写 的 map 函数, RecordReader 读取一行这里调用一次
	* Mapper 逻辑结束之后, 将 Mapper 的每条结果通过 context.write 集. 在 collect 中, 会先对其进行分区处理，默认使用 HashPartitioner 
		* MapReduce 提供 Partitioner 接口, 它的作用就是根据 Key 或 Value 及 Reducer 的数量来决定当前的这对输出数据最终应该交由哪个 Reduce task 处理, 默认对 Key Hash 后再以 Reducer 数量取模. 默认的取模方式只是为 了平均 Reducer 的处理能力, 如果用户自己对 Partitioner 有需求, 可以订制并设置 到 Job 上 
	* 接下来, 会将数据写入内存, 内存中这片区域叫做环形缓冲区, 缓冲区的作用是批量收集 Mapper 结果, 减少磁盘 IO 的影响. 我们的 Key/Value 对以及 Partition 的结果都会被写入 缓冲区. 当然, 写入之前，Key 与 Value 值都会被序列化成字节数组

		* 环形缓冲区其实是一个数组, 数组中存放着 Key, Value 的序列化数据和 Key, Value 的元数据信息, 包括 Partition, Key 的起始位置, Value 的起始位置以及 Value 的长度. 环形结构是一个抽象概念 
		* 缓冲区是有大小限制, 默认是 100MB. 当 Mapper 的输出结果很多时, 就可能会撑 爆内存, 所以需要在一定条件下将缓冲区中的数据临时写入磁盘, 然后重新利用 这块缓冲区. 这个从内存往磁盘写数据的过程被称为 Spill, 中文可译为溢写. 这个 溢写是由单独线程来完成, 不影响往缓冲区写 Mapper 结果的线程. 溢写线程启动 时不应该阻止 Mapper 的结果输出, 所以整个缓冲区有个溢写的比例 spill.percent . 这个比例默认是 0.8, 也就是当缓冲区的数据已经达到阈值 buffer size * spill percent = 100MB * 0.8 = 80MB , 溢写线程启动, 锁定这 80MB 的内存, 执行溢写过程. Mapper 的输出结果还可以往剩下的 20MB 内存中写, 互不影响

	* 当溢写线程启动后, 需要对这 80MB 空间内的 Key 做排序 (Sort). 排序是 MapReduce 模型 默认的行为, 这里的排序也是对序列化的字节做的排序 
		* 如果 Job 设置过 Combiner, 那么现在就是使用 Combiner 的时候了. 将有相同 Key 的 Key/Value 对的 Value 加起来, 减少溢写到磁盘的数据量. Combiner 会优化 MapReduce 的中间结果, 所以它在整个模型中会多次使用
 
		* 那哪些场景才能使用 Combiner 呢? 从这里分析, Combiner 的输出是 Reducer 的 输入, Combiner 绝不能改变最终的计算结果. Combiner 只应该用于那种 Reduce 的输入 Key/Value 与输出 Key/Value 类型完全一致, 且不影响最终结果的场景. 比 如累加, 最大值等. Combiner 的使用一定得慎重, 如果用好, 它对 Job 执行效率有 帮助, 反之会影响 Reducer 的最终结果
	* 合并溢写文件, 每次溢写会在磁盘上生成一个临时文件 (写之前判断是否有 Combiner), 如 果 Mapper 的输出结果真的很大, 有多次这样的溢写发生, 磁盘上相应的就会有多个临时文 件存在. 当整个数据处理结束之后开始对磁盘中的临时文件进行 Merge 合并, 因为最终的 文件只有一个, 写入磁盘, 并且为这个文件提供了一个索引文件, 以记录每个reduce对应数据的偏移量


----------

* ReduceTask工作机制  
Reduce 大致分为 copy、sort、reduce 三个阶段，重点在前两个阶段。copy 阶段包含一个 eventFetcher 来获取已完成的 map 列表，由 Fetcher 线程去 copy 数据，在此过程中会启动两 个 merge 线程，分别为 inMemoryMerger 和 onDiskMerger，分别将内存中的数据 merge 到磁 盘和将磁盘中的数据进行 merge。待数据 copy 完成之后，copy 阶段就完成了，开始进行 sort阶段，sort 阶段主要是执行 finalMerge 操作，纯粹的 sort 阶段，完成之后就是 reduce 阶段， 调用用户定义的 reduce 函数进行处理。  



	* Copy阶段,简单地拉取数据。Reduce进程启动一些数据copy线程(Fetcher)，通过HTTP 方式请求maptask获取属于自己的文件。
 
	* Merge阶段 。这里的merge如map端的merge动作，只是数组中存放的是不同map端 copy来的数值。Copy过来的数据会先放入内存缓冲区中，这里的缓冲区大小要比map端 的更为灵活。merge有三种形式：内存到内存；内存到磁盘；磁盘到磁盘。默认情况下第 一种形式不启用。当内存中的数据量到达一定阈值，就启动内存到磁盘的merge。与map 端类似，这也是溢写的过程，这个过程中如果你设置有Combiner，也是会启用的，然后 在磁盘中生成了众多的溢写文件。第二种merge方式一直在运行，直到没有map端的数据 时才结束，然后启动第三种磁盘到磁盘的merge方式生成最终的文件。
 
	* 合并排序 。把分散的数据合并成一个大的数据后，还会再对合并后的数据排序。
 
	* 对排序后的键值对调用reduce方法，键相等的键值对调用一次reduce方法，每次调用会产生零个或者多个键值对，最后把这些输出的键值对写入到HDFS文件中。


----------

* Shuffle过程
	* 	Map阶段处理的数据如何传递给Reduce阶段，是MapReduce框架中最关键的一个流程，这个流程叫shuffle：洗牌/发牌 
	* 	Shuffle分布在MR的Map阶段和Reduce阶段，一般把从Map产生输出开始到Reduce取得数据作为输出之前的过程称为Shuffle   
	* 	核心机制：数据分区/排序/分组/规约/合并等过程  
		*  Collect阶段，将 MapTask 的结果输出到默认大小为 100M 的环形缓冲区，保存的是 key/value，Partition 分区信息等。
		*  Spill阶段 ：当内存中的数据量达到一定的阀值的时候，就会将数据写入本地磁盘， 在将数据写入磁盘之前需要对数据进行一次排序的操作，如果配置了 combiner，还会将 有相同分区号和 key 的数据进行排序。
		*  Merge阶段 ：把所有溢出的临时文件进行一次合并操作，以确保一个 MapTask 最终只产生一个中间数据文件。
		*  Copy阶段 ：ReduceTask 启动 Fetcher 线程到已经完成 MapTask 的节点上复制一份属于 自己的数据，这些数据默认会保存在内存的缓冲区中，当内存的缓冲区达到一定的阀值 的时候，就会将数据写到磁盘之上。
		*  Merge阶段 ：在 ReduceTask 远程复制数据的同时，会在后台开启两个线程对内存到本地的数据文件进行合并操作。
		*  Sort阶段 ：在对数据进行合并的同时，会进行排序操作，由于 MapTask 阶段已经对数 据进行了局部的排序，ReduceTask 只需保证 Copy 的数据的最终整体有效性即可。 Shuwle 中的缓冲区大小会影响到 mapreduce 程序的执行效率，原则上说，缓冲区越大， 磁盘io的次数越少，执行速度就越快 缓冲区的大小可以通过参数调整, 参数：mapreduce.task.io.sort.mb 默认100M

	