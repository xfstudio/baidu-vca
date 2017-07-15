## 从零开始构建语义化视频搜索引擎(三)、使用Python的Scrapy开发分布式爬虫进行数据采集
#### 本章知识点
1. 使用Docker快速创建本地开发和单元测试环境
2. 线上环境的自动测试与部署
3. Python scrapy开发多线程高可用网络爬虫
4. 使用Kubernetes搭建Redis集群提升性能
5. Mongodb集群存储非结构化数据
6. 常见反爬虫技术及其应对方案
---
经过前两章的基础设施和开发支持体系建设,要开始进入越来越有意思的部分了

在下面的过程中,你会真切地感受到,在完善的基础设施上撸码是种多有快感的体验,

#### 分布式爬虫系统架构

- [ ] 首先git上创建创建项目
- 
---
#### [章节目录](#本章知识点)
- [始、有一个改变世界的idea,就缺个程序员了](始、有一个改变世界的idea,就缺个程序员了.md)![image](http://progressed.io/bar/95?title=begin+architecture)
- [一、SaltStack搭建Kubernetes集群管理架构基础设施](一、SaltStack搭建Kubernetes集群管理架构基础设施.md)![image](http://progressed.io/bar/90?title=salt+kubernetes)
- [二、EFK+Prometheus可扩展的DevOps自动化运维部署及监控体系](二、EFK+Prometheus可扩展的DevOps自动化运维部署及监控体系)**![image](http://progressed.io/bar/60?title=EFK+DevOps)
- **[三、使用Python的Scrapy开发分布式爬虫进行数据采集](三、使用Python的Scrapy开发分布式爬虫进行数据采集)**![image](http://progressed.io/bar/65?title=python+crawler)
- [四、VCA+go打造高性能语义化视频搜索引擎](四、VCA+go打造高性能语义化视频搜索引擎.md)![image](http://progressed.io/bar/30?title=VCA+go+engine)
- [五、Hadoop+Spark-Streaming+GraphX实现大数据的流式计算和可视化](五、Hadoop+Spark-Streaming+GraphX实现大数据的流式计算和可视化.md)![image](http://progressed.io/bar/20?title=hadoop+saprk)
- [六、ReactXP开发跨全平台的客户端程序](六、ReactXP开发跨全平台的客户端程序.md)![image](http://progressed.io/bar/5?title=react+nodejs)
- [七、将用户行为反馈接入机器学习框架TensorFlow进行算法调优](七、将用户行为反馈接入机器学习框架TensorFlow进行算法调优.md)![image](http://progressed.io/bar/10?title=tensorflow+DL+AI)
- [终、以终为始,不是终点的终点](终、以终为始,不是终点的终点.md)![image](http://progressed.io/bar/15?title=future+end)