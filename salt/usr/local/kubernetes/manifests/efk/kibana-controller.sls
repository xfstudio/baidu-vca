#tee /srv/salt/usr/local/kubernetes/manifests/efk/kibana-controller.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/efk/kibana-controller.yaml
      - name: /usr/local/kubernetes/manifests/efk/kibana-controller.yaml
#EOF