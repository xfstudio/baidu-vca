#tee /srv/salt/usr/local/kubernetes/manifests/kubernetes-dashboard.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/kubernetes-dashboard.yaml
      - name: /usr/local/kubernetes/manifests/kubernetes-dashboard.yaml
#EOF