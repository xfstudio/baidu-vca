#tee /srv/salt/usr/local/kubernetes/manifests/calico.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/calico.yaml
      - name: /usr/local/kubernetes/manifests/calico.yaml
#EOF