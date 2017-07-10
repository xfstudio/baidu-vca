#tee /srv/salt/usr/local/kubernetes/manifests/efk/init.sls <<-EOF
include:
  - usr.local.kubernetes.manifests.efk.es-controller
  - usr.local.kubernetes.manifests.efk.fluentd-es-ds
  - usr.local.kubernetes.manifests.efk.kibana-controller
/usr/local/kubernetes/manifests/efk/es-rbac.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/efk/es-rbac.yaml
/usr/local/kubernetes/manifests/efk/fluentd-es-rbac.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/efk/fluentd-es-rbac.yaml
/usr/local/kubernetes/manifests/efk/es-service.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/efk/es-service.yaml
/usr/local/kubernetes/manifests/efk/kibana-service.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/efk/kibana-service.yaml
#EOF