# vim deploy-k8s-v1.6.6.sh
# usage:
#!/bin/bash
set -x
set -e

HTTP_SERVER=xf-repo.cdn.bcebos.com

SSH_PORT=51222
KUBE_HA=true
KUBE_REPO_MIRRORS=http://hub-mirror.c.163.com
KUBE_REPO_PREFIX=182.61.57.29:5000
KUBE_REPO_USERNAME=Your_Registry_Username
KUBE_REPO_PASSWORD=Your_Registry_Password

# 1.6以后使用configfile配置--apiserver-advertise-address=--api-advertise-addresses
KUER_CLUSTER_PARAMETER="--api-advertise-addresses=172.16.0.2 --external-etcd-endpoints=http://172.16.0.3:2379,http://172.16.0.2:2379,http://172.16.0.5:2379"
KUBE_cluster['cidr']=10.244.0.0/16
KUBE-version=v1.6.6
KUBE_IMAGES=(
    #docker.io:
    #  calico:
        node:v1.3.0
        cni:v1.9.1
        typha:v0.2.2
    #  weaveworks:
        weave-kube:latest
        weave-npc:latest
    #gcr.io:
    #  google_containers:
        kube-proxy-amd64:v1.6.6
        kube-controller-manager-amd64:v1.6.6
        kube-apiserver-amd64:v1.6.6
        kube-scheduler-amd64:v1.6.6
        kube-discovery-amd64:1.0
        k8s-dns-sidecar-amd64:1.14.2
        k8s-dns-kube-dns-amd64:1.14.2
        k8s-dns-dnsmasq-nanny-amd64:1.14.2
        etcd-amd64:3.0.17
        pause-amd64:3.0
        kubernetes-dashboard-amd64:v1.6.1
        elasticsearch:v2.4.1-2
        kibana:v4.6.1-1
        event-exporter:v0.1.0-r2
        prometheus-to-sd:v0.1.2-r2
        ip-masq-agent-amd64:v2.0.2
        metadata-proxy:0.1.2
        node-problem-detector:v0.4.1
        defaultbackend:1.3
        heapster-amd64:v1.4.0-beta.0
        heapster-influxdb-amd64:v1.1.1
        heapster-grafana-amd64:v4.0.2
        addon-resizer:1.7
        cluster-proportional-autoscaler-amd64:1.1.2-r2
        etcd-empty-dir-cleanup:3.0.14.0
    #quay.io:
    #  coreos:
        flannel:v0.8.0-rc1-amd64
    )

root=$(id -u)
if [ "$root" -ne 0 ] ;then
    echo must run as root
    exit 1
fi

kube::install_docker()
{
    set +e
    docker info> /dev/null 2>&1
    i=$?
    set -e
    if [ $i -ne 0 ]; then
        curl -L http://$HTTP_SERVER/rpms/docker.tar.gz > /tmp/docker.tar.gz
        tar zxf /tmp/docker.tar.gz -C /tmp
        yum localinstall -y /tmp/docker/*.rpm
        systemctl enable docker.service && systemctl start docker.service
        kube::config_docker
    fi
    echo docker has been installed
    rm -rf /tmp/docker /tmp/docker.tar.gz
}

kube::config_docker()
{
    setenforce 0 > /dev/null 2>&1 && sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

    sysctl -w net.bridge.bridge-nf-call-iptables=1
    sysctl -w net.bridge.bridge-nf-call-ip6tables=1
cat <<EOF >>/etc/sysctl.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
EOF

cat <<EOF >>/etc/docker/daemon.json
{
   "registry-mirrors": ["$KUBE_REPO_MIRRORS"],
   "insecure-registries":["$KUBE_REPO_PREFIX"]
}
EOF

    mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF >/etc/systemd/system/docker.service.d/10-docker.conf
[Service]
    ExecStart=
    ExecStart=/usr/bin/dockerd -s overlay --selinux-enabled=false
EOF

    systemctl daemon-reload && systemctl restart docker.service
}

kube::load_images()
{
    docker login -u $KUBE_REPO_USERNAME -p $KUBE_REPO_PASSWORD $KUBE_REPO_PREFIX
    for imageName in ${KUBE_IMAGES[@]} ; do
        docker pull $KUBE_REPO_PREFIX/$imageName
    done
}
kube::load_images_http()
{
    mkdir -p /tmp/kubernetes

    images=$KUBE_IMAGES

    for i in "${!images[@]}"; do
        ret=$(docker images | awk 'NR!=1{print $1"_"$2}'| grep $KUBE_REPO_PREFIX/${images[$i]} | wc -l)
        if [ $ret -lt 1 ];then
            curl -L http://$HTTP_SERVER/images/${images[$i]}.tar o /tmp/kubernetes/${images[$i]}.tar
            docker load -i /tmp/kubernetes/${images[$i]}.tar
        fi
    done

    rm /tmp/kubernetes* -rf
}

kube::install_bin()
{
    set +e
    which kubeadm > /dev/null 2>&1
    i=$?
    set -e
    if [ $i -ne 0 ]; then
        curl -L http://$HTTP_SERVER/rpms/kubernetes.tar.gz > /tmp/kubernetes.tar.gz
        tar zxf /tmp/kubernetes.tar.gz -C /tmp
        yum localinstall -y  /tmp/kubernetes/*.rpm
        rm -rf /tmp/kubernetes*
        systemctl enable kubelet.service && systemctl start kubelet.service && rm -rf /etc/kubernetes
    fi
}

kube::wait_apiserver()
{
    until curl http://127.0.0.1:8080; do sleep 1; done
}

kube::disable_static_pod()
{
    # remove the waring log in kubelet
    sed -i 's/--pod-manifest-path=\/etc\/kubernetes\/manifests//g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    systemctl daemon-reload && systemctl restart kubelet.service
}

kube::get_env()
{
  HA_STATE=$1
  [ $HA_STATE == "MASTER" ] && HA_PRIORITY=200 || HA_PRIORITY=`expr 200 - ${RANDOM} / 1000 + 1`
  KUBE_VIP=$(echo $2 |awk -F= '{print $2}')
  VIP_PREFIX=$(echo ${KUBE_VIP} | cut -d . -f 1,2,3)
  #dhcp和static地址的不同取法
  VIP_INTERFACE=$(ip addr show | grep ${VIP_PREFIX} | awk -F 'dynamic' '{print $2}' | head -1)
  [ -z ${VIP_INTERFACE} ] && VIP_INTERFACE=$(ip addr show | grep ${VIP_PREFIX} | awk -F 'global' '{print $2}' | head -1)
  ###
  LOCAL_IP=$(ip addr show | grep ${VIP_PREFIX} | awk -F / '{print $1}' | awk -F ' ' '{print $2}' | head -1)
  MASTER_NODES=$(echo $3 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
  MASTER_NODES_NO_LOCAL_IP=$(echo "${MASTER_NODES}" | sed -e 's/'${LOCAL_IP}'//g')
}

kube::install_keepalived()
{
    kube::get_env $@
    set +e
    which keepalived > /dev/null 2>&1
    i=$?
    set -e
    if [ $i -ne 0 ]; then
        ip addr add ${KUBE_VIP}/32 dev ${VIP_INTERFACE}
        curl -L http://$HTTP_SERVER/rpms/keepalived.tar.gz > /tmp/keepalived.tar.gz
        tar zxf /tmp/keepalived.tar.gz -C /tmp
        yum localinstall -y  /tmp/keepalived/*.rpm
        rm -rf /tmp/keepalived*
        systemctl enable keepalived.service && systemctl start keepalived.service
        kube::config_keepalived
    fi
}

kube::config_keepalived()
{
  echo "gen keepalived configuration"
cat <<EOF >/etc/keepalived/keepalived.conf
global_defs {
   router_id LVS_kubernetes
}

vrrp_script CheckkubernetesMaster {
    script "curl http://127.0.0.1:8080"
    interval 3
    timeout 9
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state ${HA_STATE}
    interface ${VIP_INTERFACE}
    virtual_router_id 61
    priority ${HA_PRIORITY}
    advert_int 1
    mcast_src_ip ${LOCAL_IP}
    nopreempt
    authentication {
        auth_type PASS
        auth_pass 378378
    }
    unicast_peer {
        ${MASTER_NODES_NO_LOCAL_IP}
    }
    virtual_ipaddress {
        ${KUBE_VIP}
    }
    track_script {
        CheckkubernetesMaster
    }
}

EOF
  modprobe ip_vs
  systemctl daemon-reload && systemctl restart keepalived.service
}

kube::save_master_ip()
{
    set +e
    # 应该从$2里拿到etcd集群的 --endpoints, 这里默认走的127.0.0.1:2379
    [ ${KUBE_HA} == true ] && etcdctl mk ha_master ${LOCAL_IP}
    set -e
}

kube::copy_master_config()
{
    local master_ip=$(etcdctl get ha_master)
    mkdir -p /etc/kubernetes
    scp -p $SSH_PORT -r root@${master_ip}:/etc/kubernetes/* /etc/kubernetes/
    systemctl start kubelet
}

kube::set_label()
{
  until kubectl get no | grep `hostname`; do sleep 1; done
  kubectl label node `hostname` kubeadm.alpha.kubernetes.io/role=master
}

kube::master_up()
{
    shift

    kube::install_docker

    kube::load_images

    kube::install_bin

    [ ${KUBE_HA} == true ] && kube::install_keepalived "MASTER" $@

    # 存储master_ip，master02和master03需要用这个信息来copy配置
    kube::save_master_ip

    # 这里一定要带上--pod-network-cidr参数，不然后面的flannel网络会出问题 1.6以后--kubernetes-version=--use-kubernetes-version
    kubeadm init --use-kubernetes-version=$KUBE-version --pod-network-cidr=$KUBE_cluster['cidr'] $@

    # 使master节点可以被调度
    kubectl taint nodes --all dedicated-

    echo -e "\033[32m 注意记录下token信息，node加入集群时需要使用！\033[0m"

    # install flannel network
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml --namespace=kube-system
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --namespace=kube-system

    # show pods
    kubectl get all --all-namespaces
}

kube::replica_up()
{
    shift

    kube::install_docker

    kube::load_images

    kube::install_bin

    kube::install_keepalived "BACKUP" $@

    kube::copy_master_config

    kube::set_label

}

kube::node_up()
{
    kube::install_docker

    kube::load_images

    kube::install_bin

    kube::disable_static_pod

    kubeadm join $@
}

kube::tear_down()
{
    systemctl stop kubelet.service
    docker ps -aq|xargs -I '{}' docker stop {}
    docker ps -aq|xargs -I '{}' docker rm {}
    df |grep /var/lib/kubelet|awk '{ print $6 }'|xargs -I '{}' umount {}
    rm -rf /var/lib/kubelet && rm -rf /etc/kubernetes/ && rm -rf /var/lib/etcd
    yum remove -y kubectl kubeadm kubelet kubernetes-cni
    if [ ${KUBE_HA} == true ]
    then
      yum remove -y keepalived
      rm -rf /etc/keepalived/keepalived.conf
    fi
    rm -rf /var/lib/cni
    ip link del cni0
}

main()
{
    case $1 in
    "m" | "master" )
        kube::master_up $@
        ;;
    "r" | "replica" )
        kube::replica_up $@
        ;;
    "j" | "join" )
        shift
        kube::node_up $@
        ;;
    "d" | "down" )
        kube::tear_down
        ;;
    *)
        echo "usage:$0 m[master] | r[replica] | j[join] token | d[down] "
        echo "       $0 master to setup master "
        echo "       $0 replica to setup replica master "
        echo "       $0 join   to join master with token "
        echo "       $0 down   to tear all down ,inlude all data! so becarefull"
        echo "       unkown command $0 $@"
        ;;
    esac
}

main $@ $KUER_CLUSTER_PARAMETER