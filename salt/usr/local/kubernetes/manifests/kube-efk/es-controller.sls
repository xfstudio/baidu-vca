#tee /srv/salt/usr/local/kubernetes/manifests/kube-efk/es-controller.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/kube-efk/es-controller.yaml
      - name: /usr/local/kubernetes/manifests/kube-efk/es-controller.yaml
#EOF