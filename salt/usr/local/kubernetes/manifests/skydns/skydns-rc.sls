#tee /srv/salt/usr/local/kubernetes/manifests/skydns/skydns-rc.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/skydns/skydns-rc.yaml
      - name: /usr/local/kubernetes/manifests/skydns/skydns-rc.yaml
#EOF