#tee /srv/salt/usr/local/kubernetes/manifests/kubernetes-heapster.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/kubernetes-heapster.yaml
      - name: /usr/local/kubernetes/manifests/kubernetes-heapster.yaml
#EOF