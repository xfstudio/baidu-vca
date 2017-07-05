#!/usr/bin/env bash
registry='182.61.57.29:5000'
docker login http://$registry
images=(
    kube-proxy-amd64:v1.6.6
    kube-controller-manager-amd64:v1.6.6
    kube-apiserver-amd64:v1.6.6
    kube-scheduler-amd64:v1.6.6
    kubernetes-dashboard-amd64:v1.6.0
    k8s-dns-sidecar-amd64:1.14.1
    k8s-dns-kube-dns-amd64:1.14.1
    k8s-dns-dnsmasq-nanny-amd64:1.14.1
    etcd-amd64:3.2.1
    pause-amd64:3.0
    flannel:v0.8.0-rc1-amd64
)

for imageName in ${images[@]} ; do
    docker pull $registry/$imageName
done

