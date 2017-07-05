images=(
    kube-proxy-amd64:{{ kube_version }}
    kube-controller-manager-amd64:{{ kube_version }}
    kube-apiserver-amd64:{{ kube_version }}
    kube-scheduler-amd64:{{ kube_version }}
    kubernetes-dashboard-amd64:{{ k8s_dashboard_version }}
    k8s-dns-sidecar-amd64:{{ k8s_dns_version }}
    k8s-dns-kube-dns-amd64:{{ k8s_dns_version }}
    k8s-dns-dnsmasq-nanny-amd64:{{ k8s_dns_version }}
    etcd-amd64:{{ etcd_version }}
    pause-amd64:{{ pause_version }}
    flannel:{{ flannel_version }}
    etcd-empty-dir-cleanup:3.0.14.0
    elasticsearch:v2.4.1-2
    fluentd-elasticsearch:1.23
    kibana:v4.6.1-1
    event-exporter:v0.1.0-r2
    prometheus-to-sd:v0.1.2-r2
    fluentd-gcp:2.0.7
    ip-masq-agent-amd64:v2.0.2
    metadata-proxy:0.1.2
    node-problem-detector:v0.4.1
    node:v1.3.0
    cni:v1.9.1
    typha:v0.2.2
    defaultbackend:1.3
    heapster-amd64:v1.4.0-beta.0
    heapster-influxdb-amd64:v1.1.1
    heapster-grafana-amd64:v4.0.2
    addon-resizer:1.7
    cluster-proportional-autoscaler-amd64:1.1.2-r2
)
# 此处使用私有镜像库配置的账号密码
salt '*' cmd.run 'docker login -u Your_Username -p Your_Password -e Your_Email {{ repo_prefix }}'

for imageName in ${images[@]} ; do
    docker pull {{ repo_prefix }}/$imageName
done
export KUBE_REPO_PREFIX="{{ repo_prefix }}"
export KUBE_ETCD_IMAGE="{{ repo_prefix }}/etcd-amd64:{{ etcd_version }}"
#source /usr/local/environment.sh
ip addr add {{ cluster_cidr }} dev eth0
kubeadm init --apiserver-advertise-address={{ cluster_server_ip }} --kubernetes-version={{ kube_version }} --pod-network-cidr={{ cluster_cidr }} --service-dns-domain={{ cluster_domain }} --apiserver-bind-port={{ cluster_server_port }} --service-cidr={{ service_cidr }}
mkdir -p ~/.kube
alias cp='cp'
cp /etc/kubernetes/admin.conf ~/.kube/config
alias cp='cp -i'
#chown 0:0 ~/.kube/config
#export KUBECONFIG=~/.kube/config
#kubectl taint nodes --all node-role.kubernetes.io/master-
