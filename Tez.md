# Tez
## Tez概述
官网：https://tez.apache.org/
Tez是支持DAG作业的开源计算框架，它可以将多个有依赖的作业转换为一个作业从而大幅提升DAG 作业的性能。
Tez源于MapReduce框架，核心思想是将Map和Reduce两个操作进一步拆分，即Map被拆分成Input、Processor、Sort、Merge和Output， Reduce被拆分成Input、Shuffle、Sort、Merge、Processor和Output等，这样，这些分解后的元操作可以灵活组合，产生新的操作，这些操作经过一些控制程序组装后，可形成一个大的DAG作业。

## 为什么需要Tez
提升计算性能

## 设计思想

两个组成部分：

1.数据处理管道引擎，其中一个引擎可以插入输入，处理和输出实现以执行任意数据处理
2.数据处理应用程序的主机，通过它可以将上述任意数据处理“任务”组合到任务 DAG 中，以根据需要处理数据。

<img src="https://upload-images.jianshu.io/upload_images/22827736-f1f514b07210270c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" width="50%">

<img src="https://upload-images.jianshu.io/upload_images/22827736-d5bf70e8d5a072df.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" width="50%">


通过允许诸如Apache Hive和Apache Pig之类的项目运行复杂的 DAG（运行计算的有向无环图）任务，Tez 可以用于处理数据，该数据以前需要执行多个MR作业，而现在在单个Tez作业中。  
第一个图表展示的流程包含多个MR任务，每个任务都将中间结果存储到HDFS上——前一个步骤中的reducer为下一个步骤中的mapper提供数据。  、
第二个图表展示了使用Tez时的流程，仅在一个任务中就能完成同样的处理过程，任务之间不需要访问HDFS。
