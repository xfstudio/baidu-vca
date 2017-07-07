# vim deploy-k8s.sh
#!/bin/bash
set -x
set -e

HTTP_SERVER=xf-repo.cdn.bcebos.com

SSH_PORT={{ custom_ssh_port }}
KUBE_HA=true
KUBE_REPO_MIRRORS=http://hub-mirror.c.163.com
KUBE_REPO_PREFIX={{ repo_prefix }}
KUBE_REPO_USERNAME=Your_Registry_Username
KUBE_REPO_PASSWORD=Your_Registry_Password
KUBE_CLUSTER_CIDR={{ cluster['cidr'] }}
KUBE_CLUSTER_SERVICE_CIDR={{ cluster['service_cidr'] }}
KUBE_VERSION={{ images['gcr.io']['google_containers']['kube-apiserver-amd64'] }}
KUBE_MASTER={{ cluster['master'] }}
KUBE_ETCD_VERSION={{ images['gcr.io']['google_containers']['etcd-amd64'] }}
KUBE_ETCD_ENDPOINTS={% for server in cluster_servers %}{% if loop.first %}{{ pillar['etcd']['prefix'] }}://{% endif %}{{ cluster_servers[server] }}:{{ pillar['etcd']['endpoint_port'] }}{% if not loop.last %},{{pillar['etcd']['prefix'] }}://{% endif %}{% endfor %}
KUBE_CONFIG=kubeadm-config.yaml
tee $KUBE_CONFIG <<-EOF
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
networking:
  podSubnet: {{ cluster['service_cidr'] }}
api:
  advertiseAddress: $KUBE_MASTER
etcd:
  endpoints:
{% for server in cluster_servers %}    - {{ cluster_servers[server] }}:{{ pillar['etcd']['endpoint_port'] }}{% if not loop.last %}
{% endif %}{% endfor %}
kubernetesVersion: $KUBE_VERSION
EOF
KUER_CLUSTER_PARAMETER="--config $KUBE_CONFIG"

KUBE_IMAGES=(
{% for sites in images %}{% for namespace in images[sites] %}{% for image in images[sites][namespace] %}    {{ image }}:{{ images[sites][namespace][image] }}{% if not loop.last %}
{% endif %}{% endfor %}{% endfor %}{% endfor %}
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
  KUBE_VIP=$(echo ${KUBE_MASTER} |awk -F= '{print $2}')
  VIP_PREFIX=$(echo ${KUBE_VIP} | cut -d . -f 1,2,3)
  VIP_INTERFACE=$(ip addr show | grep ${VIP_PREFIX} | awk -F 'dynamic' '{print $2}' | head -1)
  [ -z ${VIP_INTERFACE} ] && VIP_INTERFACE=$(ip addr show | grep ${VIP_PREFIX} | awk -F 'global' '{print $2}' | head -1)
  ###
  LOCAL_IP=$(ip addr show | grep ${VIP_PREFIX} | awk -F / '{print $1}' | awk -F ' ' '{print $2}' | head -1)
  MASTER_NODES=$(echo $KUBE_ETCD_ENDPOINTS | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
  MASTER_NODES_NO_LOCAL_IP=$(echo "${MASTER_NODES}" | sed -e 's/"${LOCAL_IP}"//g')
}

kube::install_keepalived()
{
    kube::get_env $@
    set +e
    which keepalived > /dev/null 2>&1
    i=$?
    set -e
    if [ $i -ne 0 ]; then
        yum install -y keepalived
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

vrrp_script CheckKubernetesMaster {
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
        CheckKubernetesMaster
    }
}

EOF
  modprobe ip_vs
  systemctl daemon-reload && systemctl restart keepalived.service
}

kube::save_master_ip()
{
    set +e
    [ ${KUBE_HA} == true ] && etcdctl mk ha_master ${LOCAL_IP}
    set -e
}

kube::copy_master_config()
{
    local master_ip=$(etcdctl get ha_master)
    mkdir -p /etc/kubernetes
    scp -P $SSH_PORT -r root@${master_ip}:/etc/kubernetes/* /etc/kubernetes/
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
    kube::save_master_ip

    kubeadm init --kubernetes-version=$KUBE_VERSION --apiserver-advertise-address=$KUBE_MASTER --pod-network-cidr=$KUBE_CLUSTER_SERVICE_CIDR $@

    mkdir -p ~/.kube
    alias cp='cp'
    cp /etc/kubernetes/admin.conf ~/.kube/config
    alias cp='cp -i'
    kubectl taint nodes --all dedicated-

    echo -e "\033[32m record thetoken, OR use 'kubectl token list' \033[0m"

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
    export KUBE_REPO_PREFIX="$KUBE_REPO_PREFIX"
    export KUBE_ETCD_IMAGE="$KUBE_REPO_PREFIX/etcd-amd64:$KUBE_ETCD_VERSION"
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