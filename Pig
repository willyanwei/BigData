# Pig
## 什么是Pig?  
Pig是一种数据流语言和运行环境，常用于检索和分析数据量较大的数据集。Pig包括两部分：一是用于描述数据流的语言，称为Pig Latin；二是用于运行Pig Latin程序的执行环境。  

## 为什么需要Pig？ 
MapReduce的程序写起来真麻烦。他们希望简化这个过程。这就好比你有了汇编语言，虽然你几乎什么都能干了，但是你还是觉得繁琐。  
你希望有个更高层更抽象的语言层来描述算法和数据处理流程。于是就有了Pig和Hive。  
Pig是接近脚本方式去描述MapReduce，Hive则用的是SQL。  
它们把脚本和SQL语言翻译成MapReduce程序，丢给计算引擎去计算，而你就从繁琐的MapReduce程序中解脱出来，用更简单更直观的语言去写程序了。

# Pig与Hive的区别？  
Pig与Hive作为一种高级数据语言，均运行于HDFS之上，是hadoop上层的衍生架构，用于简化hadoop任务，并对MapReduce进行一个更高层次的封装。Pig与Hive的区别如下：

Pig是一种面向过程的数据流语言；Hive是一种数据仓库语言，并提供了完整的sql查询功能。
Pig更轻量级，执行效率更快，适用于实时分析；Hive适用于离线数据分析。
Hive查询语言为Hql，支持分区；Pig查询语言为Pig Latin，不支持分区。
Hive支持JDBC/ODBC；Pig不支持JDBC/ODBC。
Pig适用于半结构化数据(如：日志文件)；Hive适用于结构化数据。
