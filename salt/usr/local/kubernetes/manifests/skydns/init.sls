#tee /srv/salt/usr/local/kubernetes/manifests/skydns/init.sls <<-EOF
include:
  - usr.local.kubernetes.manifests.skydns.skydns-rc
/usr/local/kubernetes/manifests/skydns/skydns-svc.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/skydns/skydns-svc.yaml
#EOF