#tee /srv/salt/usr/local/kubernetes/manifests/kube-efk/init.sls <<-EOF
include:
  - usr.local.kubernetes.manifests.kube-efk.es-controller
  - usr.local.kubernetes.manifests.kube-efk.fluentd-es-ds
  - usr.local.kubernetes.manifests.kube-efk.kibana-controller
/usr/local/kubernetes/manifests/kube-efk/es-clusterrole.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/es-clusterrole.yaml
/usr/local/kubernetes/manifests/kube-efk/es-clusterrolebinding.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/es-clusterrolebinding.yaml
/usr/local/kubernetes/manifests/kube-efk/es-service.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/es-service.yaml
/usr/local/kubernetes/manifests/kube-efk/es-serviceaccount.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/es-serviceaccount.yaml
/usr/local/kubernetes/manifests/kube-efk/fluentd-es-clusterrole.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/fluentd-es-clusterrole.yaml
/usr/local/kubernetes/manifests/kube-efk/fluentd-es-clusterrolebinding.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/fluentd-es-clusterrolebinding.yaml
/usr/local/kubernetes/manifests/kube-efk/fluentd-es-serviceaccount.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/fluentd-es-serviceaccount.yaml
/usr/local/kubernetes/manifests/kube-efk/kibana-service.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kube-efk/kibana-service.yaml
#EOF