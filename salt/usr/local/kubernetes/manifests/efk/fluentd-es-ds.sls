#tee /srv/salt/usr/local/kubernetes/manifests/efk/fluentd-es-ds.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/efk/fluentd-es-ds.yaml
      - name: /usr/local/kubernetes/manifests/efk/fluentd-es-ds.yaml
#EOF