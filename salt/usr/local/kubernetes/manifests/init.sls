#tee /srv/salt/usr/local/kubernetes/manifests/init.sls <<-EOF
manifests:
  '*':
    - usr.local.kubernetes.manifests.kubernetes-dashboard
    - usr.local.kubernetes.manifests.kubernetes-heapster
    - usr.local.kubernetes.manifests.nginx-ingress-controller
    - usr.local.kubernetes.manifests.calico
    - usr.local.kubernetes.manifests.kube-efk
#EOF