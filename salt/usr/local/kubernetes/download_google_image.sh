#!/usr/bin/env bash
registry='182.61.57.29:5000'
username=root
password=Xfstudio2017@Baidu
images=(
    gcr.io/google_containers/kube-proxy-amd64:v1.6.6
    gcr.io/google_containers/kube-controller-manager-amd64:v1.6.6
    gcr.io/google_containers/kube-apiserver-amd64:v1.6.6
    gcr.io/google_containers/kube-scheduler-amd64:v1.6.6
    gcr.io/google_containers/kube-discovery-amd64:1.0
    gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.1
    gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.2
    gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.2
    gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.2
    gcr.io/google_containers/etcd-amd64:3.0.17
    gcr.io/google-containers/etcd-empty-dir-cleanup:3.0.14.0
    gcr.io/google_containers/pause-amd64:3.0
    quay.io/coreos/flannel:v0.8.0-rc1-amd64
    gcr.io/google_containers/elasticsearch:v2.4.1-2
    gcr.io/google_containers/fluentd-elasticsearch:1.23
    gcr.io/google_containers/kibana:v4.6.1-1
    gcr.io/google-containers/event-exporter:v0.1.0-r2
    gcr.io/google-containers/prometheus-to-sd:v0.1.2-r2
    gcr.io/google-containers/fluentd-gcp:2.0.7
    gcr.io/google-containers/prometheus-to-sd:v0.1.0
    gcr.io/google-containers/ip-masq-agent-amd64:v2.0.2
    gcr.io/google-containers/metadata-proxy:0.1.2
    gcr.io/google_containers/node-problem-detector:v0.4.1
    calico/node:v1.3.0
    calico/cni:v1.9.1
    calico/typha:v0.2.2
    calico/kube-policy-controller:v0.6.0
    gcr.io/google_containers/defaultbackend:1.3
    gcr.io/google_containers/heapster-amd64:v1.4.0-beta.0
    gcr.io/google_containers/heapster-influxdb-amd64:v1.1.1
    gcr.io/google_containers/heapster-grafana-amd64:v4.0.2
    gcr.io/google_containers/addon-resizer:1.7
    gcr.io/google_containers/cluster-proportional-autoscaler-amd64:1.1.2-r2
    weaveworks/weave-kube:2.0.1
    weaveworks/weave-npc
)

docker login -u $username -p $password $registry
for image in ${images[@]} ; do
    imageName=${image##*/}
    docker pull $image
    docker tag $image $registry/$imageName
    docker push $registry/$imageName
done