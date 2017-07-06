## 从零开始构建语义化视频搜索引擎(二)、EFK+Jenkins可扩展的DevOps自动化运维部署及监控体系
#### 本章知识点
1. salt分组和OS自动化管理多种类型服务器
2. [全局统一规范化编码及日志格式约定](编码规范)
3. Kubernetes启动pod的yaml文件编写
4. 集成通用日志采集和监控平台EFK用于开发调试
5. 将EFK与Kubernetes集成实现服务器运行状态监控
6. Gitlab搭建本地代码库并触发自动集成CI
7. Jenkins实现多种编程语言自动部署CD及其替代方案
8. Jenkins插件SonarQube执行代码规范和安全性检查
9. 自动化测试框架解决方案
10. 实施敏捷开发必备的产品迭代工具：项目、bug、需求、优化、协作……集成管理平台
---
#### 开发支持系统架构
![通用日志采集和监控平台EFK架构图](../images/2-1-EFK.png)

6-10的项目管理->代码库->规范/安全检查->CI/CD->需求迭代采用[阿里云code]()进行管理,对于中小型项目还是很实用的,这里就无须重复造轮子了。
#### 升级代理服务器预下载安装插件所需要的镜像
- 部署镜像环境,由于minion新增了一台代理服务器,为避免误操作,所以本章开始强制按角色分组执行命令
```
alias salt='salt -N'
```
[操作目标参数](http://www.cnblogs.com/MacoLee/p/5750310.html):

-E，--pcre，通过正则表达式进行匹配:
```
salt -E '^SN2013.*' test.ping #探测SN2013开头的主机id名是否连通
salt '*.doam.net' test.ping--------匹配以*.doam.net的
salt '*.doam.*' test.ping----------匹配中间为doam的
salt 'web?.doam.*' test.ping-------一个问号表示统配一个，多个表示通赔多个
salt 'web[1-5]' test.ping----------1-5,通赔以web开头的1-5的id
salt 'web[1，3]' test.ping---------统配以web开头，1和3的id
salt 'web[x-z]' test.ping----------统配以web开头，x到z结尾的id
```
-L，--list，以主机id名列表的形式进行过滤，格式与Python的列表相似，即不同主机id名称使用逗号分离。
```
salt -L 'SN2013-08-021,SN2013-08-021' grains.item osfullname #获取主机id为：SN2013-08-021,SN2013-08-021完整操作系统发行版名称
```
-G，--grain,根据被控主机的grains信息进行匹配过滤，格式为：<grain value>:<grain expression>
```
salt -G 'osrelease:6.4' cmd.run 'python -V' #获取发行版本号为6.4的python版本号
```
-I,--pillar,根据被控主机的pillar信息进行匹配过滤，格式为："对象名称":"对象值"
```
salt -I 'nginx:root:/data' test.ping #探测具有'nginx:root:/data'信息的连通性。
```
#pillar属性配置文件如下：
nginx:
  root: /data

-N,--nodegroup,根据主控端master配置文件中的分组名称进行过滤。
```
#分组配置：【/etc/salt/master】
nodegroups:
web1group: 'L@wx,SN2013-08-21'
web2group: 'L@SN2013-08-22,SN2014'
#其中L@表示后面的主机id格式为列表，即主机id以逗号分隔：G@表示以grain格式描述：S@表示以IP子网或地址格式描述
salt -N web2group test.ping #探测web2group被控主机的连通性
```
-C,--compound,根据条件运算符not、and、or去匹配不同规则的主机信息
```
salt -C 'E@^SN2013.* and G@os:Centos' test.ping #探测SN2013开头并且操作系统版本为CentOS的主机的连通性
```
-S,--ipcidr,根据被控主机的IP地址或IP子网进行匹配
```
salt -S 192.168.0.0/16 test.ping
salt -S 192.168.1.10 test.ping
```
salt的nodegroup分组时可以用到的语法关键字：
字母|含义|例子
--|--|--
G  |Grains glob |G@os:CentOS
E  |PCRE Minions id |E@web\d+\.(dev|qa|prod)\.loc
P  |Grains PCRE  |P@os:(RedHat|Fedora|CentOS)
L  |Minions List  |L@minion1.example,minion2.example,dev*.example
I  |Pillar glob   |I@pdata:foobar
S  |IP  |S@192.168.1.0/24 or S@192.168.1.200
R  |Range cluster  |R@foo.bar
D  |Minions Data  |D@key:value

在top.sls中可以如下使用:
```
base:
  '*baidu-cn-guangzhou and G@os:CentOS or E@web-dc1-srv.*':
    – match: compound
    – k8s-cluster
```
使用'salt -N [GroupName] test.ping'测试,有新主机加入时minion id按照约定规则即可
- 配置不同角色服务器所要执行的命令
- 查看指定角色任务执行情况salt 'proxy' saltutil.running
docker 会自行检查并跳过已经拉取和推送过的镜像版本,如果有新镜像或版本会更新
- 使用pillar管理镜像和安装包版本,代理在软件和后面的爬虫中都有广泛应用
- 如果执行过程有配置或语法错误,使用"tail -n 50 /var/log/salt/master"跟踪日志
```
tee /srv/pillar/top.sls <<-EOF
base:
  '*':
    - env
    - proxy
EOF

# 代理变量
tee /srv/pillar/env.sls <<-EOF
appname: kubernetes
servers:
  master:
    cn-gz-baidu-xf-bcc-1: 172.16.0.2
    cn-gz-baidu-xf-bcc-2: 172.16.0.3
    cn-gz-baidu-xf-bcc-3: 172.16.0.5
registry:
  host: 182.61.57.29
  port: 5000
  username: YOUR_REGISTRY_USERNAME
  password: YOUR_REGISTRY_PASSWORD
proxy:
  host: 104.131.144.180
  port: 22
  username: YOUR_PROXY_USERNAME
  password: YOUR_PROXY_PASSWORD
etcd_prefix: http
etcd_endpoint_port: '2379'
etcd_node_port: '2380'
zabbix_master: 182.61.57.29
service_cidr: 10.254.0.0/16
cluster_cidr: 172.30.0.0/16
cluster_service_ip: 10.254.0.1
cluster_server_ip: 182.61.57.29
cluster_server_port: 6443
cluster_dns: 10.254.0.2
cluster_domain: cluster.local

packages:
  HTTP_SERVER: xf-repo.cdn.bcebos.com
  rpms:
    centos7:
      common:
        util-linux: 2.23-33
        httpd-tools: 2.4.6-45
      docker:
        docker-client: 1.12.6-32
        docker-common: 1.12.6-32
      salt:
        salt-master: 2016.11.5-3
        salt-minion: 2016.11.5-3
        salt-repo: latest-2
      kubernetes:
        kubelet: 1.6.6
        kubeadm: 1.6.6
        kubectl: 1.6.6
        kubernetes-cni: 0.5.1
  images:
    docker.io:
      calico:
        node: v1.3.0
        cni: v1.9.1
        typha: v0.2.2
      weaveworks:
        weave-kube: latest
        weave-npc: latest
    gcr.io:
      google_containers:
        kube-proxy-amd64: v1.6.6
        kube-controller-manager-amd64: v1.6.6
        kube-apiserver-amd64: v1.6.6
        kube-scheduler-amd64: v1.6.6
        kube-discovery-amd64: 1.0
        k8s-dns-sidecar-amd64: 1.14.2
        k8s-dns-kube-dns-amd64: 1.14.2
        k8s-dns-dnsmasq-nanny-amd64: 1.14.2
        etcd-amd64: 3.0.17
        pause-amd64: 3.0
        #
        kubernetes-dashboard-amd64: v1.6.1

        elasticsearch: v2.4.1-2
        kibana:v4.6.1-1
        event-exporter: v0.1.0-r2
        prometheus-to-sd: v0.1.2-r2
        ip-masq-agent-amd64: v2.0.2
        metadata-proxy: 0.1.2
        node-problem-detector: v0.4.1

        defaultbackend: 1.3
        heapster-amd64: v1.4.0-beta.0
        heapster-influxdb-amd64: v1.1.1
        heapster-grafana-amd64: v4.0.2
        addon-resizer: 1.7
        cluster-proportional-autoscaler-amd64: 1.1.2-r2

        etcd-empty-dir-cleanup: 3.0.14.0
    quay.io:
      coreos:
        flannel: v0.8.0-rc1-amd64
EOF
```
```
#!/usr/bin/env bash
registry='182.61.57.29:5000'
username=Your_Registry_Username
password=Your_Registry_Password
images={{ $pillar['packages']['images'] }}

docker login -u $username -p $password $registry
for image in ${images[@]} ; do
    imageName=${image##*/}
    docker pull $image
    docker tag $image $registry/$imageName
    docker push $registry/$imageName
done
```
#tee /srv/salt/usr/local/kubernetes/deploy-k8s.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/deploy-k8s.sh
      - name: /usr/local/kubernetes/deploy-k8s.sh
#EOF
[include对比扩展和 required or watch](http://ju.outofmemory.cn/entry/99067)
extend 语句的工作方式有别于 require 或者 watch ，它只是附加而不是替换必要的组件。
#### 编码规范
以Java最佳编程实践为范本,以利于自动化代码检查和测试
- java
- php
- nodejs
- go

#### 日志格式
以Linux系统日志为范本,便于接入ELK进行分析处理
```
通用格式: M d H:i:s hostname appname[processid]: information
内容格式: I/W/E/F{number} path/to/source/file:linenumber: content: stacktrace[...]

举例: Jun 27 18:47:28 instance-83trene1-3 kubelet[29319]: E0627 18:47:28.417917   29319 reflector.go:190] k8s.io/kubernetes/pkg/kubelet/kubelet.go:382: Failed to list *v1.Service: Get https://172.16.0.2:6443/api/v1/services?resourceVersion=0: dial tcp 172.16.0.2:6443: getsockopt: connection refused
```

#### kubernetes安装插件和应用

```
salt '*' state.sls usr.local.kubernetes.deploy-k8s
salt -E 'centos7-bcc[2,3].*' cmd.run 'bash /usr/local/kubernetes/deploy-k8s.sh replica'
salt -E 'centos7-bcc[2,3].*' cmd.run 'kubeadm join --token 849fab.ec34e21817d1c573 172.16.0.2:6443'

salt '*' state.sls usr.local.kubernetes.manifests
kubectl apply -f /usr/local/kubernetes/manifests/
# 检查etcd状态
etcdctl cluster-health
# 查看全部pods,services,rc
kubectl get all --all-namespaces -o wide
# 
# 查看子网分配
kubectl --namespace=kube-system get ep kubernetes-dashboard
#
kubectl describe services --all-namespaces
```
---
#### [章节目录](#本章知识点)
- [始、有一个改变世界的idea,就缺个程序员了](始、有一个改变世界的idea,就缺个程序员了.md)![image](http://progressed.io/bar/95?title=begin+architecture)
- [一、SaltStack搭建Kubernetes集群管理架构基础设施](一、SaltStack搭建Kubernetes集群管理架构基础设施.md)![image](http://progressed.io/bar/90?title=salt+kubernetes)
- **[二、EFK+Jenkins可扩展的DevOps自动化运维部署及监控体系](二、EFK+Jenkins可扩展的DevOps自动化运维部署及监控体系)**![image](http://progressed.io/bar/40?title=EFK+DevOps)
- [三、使用Python的Scrapy开发分布式爬虫进行数据采集](三、使用Python的Scrapy开发分布式爬虫进行数据采集.md)![image](http://progressed.io/bar/65?title=python+crawler)
- [四、VCA+go打造高性能语义化视频搜索引擎](四、VCA+go打造高性能语义化视频搜索引擎.md)![image](http://progressed.io/bar/30?title=VCA+go+engine)
- [五、Hadoop+Spark-Streaming+GraphX实现大数据的流式计算和可视化](五、Hadoop+Spark-Streaming+GraphX实现大数据的流式计算和可视化.md)![image](http://progressed.io/bar/20?title=hadoop+saprk)
- [六、ReactXP开发跨全平台的客户端程序](六、ReactXP开发跨全平台的客户端程序.md)![image](http://progressed.io/bar/5?title=react+nodejs)
- [七、将用户行为反馈接入机器学习框架TensorFlow进行算法调优](七、将用户行为反馈接入机器学习框架TensorFlow进行算法调优.md)![image](http://progressed.io/bar/10?title=tensorflow+DL+AI)
- [终、以终为始,不是终点的终点](终、以终为始,不是终点的终点.md)![image](http://progressed.io/bar/15?title=future+end)