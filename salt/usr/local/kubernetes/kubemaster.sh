images=(
{% for sites in images %}{% for namespace in images[sites] %}{% for image in images[sites][namespace] %}    {{ image }}:{{ images[sites][namespace][image] }}{% if not loop.last %}
{% endif %}{% endfor %}{% endfor %}{% endfor %}
)
# 此处使用私有镜像库配置的账号密码
salt '*' cmd.run 'docker login -u Your_Username -p Your_Password -e Your_Email {{ repo_prefix }}'

for imageName in ${images[@]} ; do
    docker pull {{ repo_prefix }}/$imageName
done
export KUBE_REPO_PREFIX="{{ repo_prefix }}"
export KUBE_ETCD_IMAGE="{{ repo_prefix }}/etcd-amd64:{{ images['gcr.io']['google_containers']['etcd-amd64'] }}"
#source /usr/local/environment.sh
ip addr add {{ cluster['cidr'] }} dev eth0
kubeadm init --apiserver-advertise-address={{ cluster_server_ip }} --kubernetes-version={{ images['gcr.io']['google_containers']['kube-apiserver-amd64'] }} --pod-network-cidr={{ cluster['cidr'] }} --service-dns-domain={{ cluster['domain'] }} --apiserver-bind-port={{ cluster_server_port }} --service-cidr={{ service_cidr }}
mkdir -p ~/.kube
alias cp='cp'
cp /etc/kubernetes/admin.conf ~/.kube/config
alias cp='cp -i'
#chown 0:0 ~/.kube/config
#export KUBECONFIG=~/.kube/config
#kubectl taint nodes --all node-role.kubernetes.io/master-
