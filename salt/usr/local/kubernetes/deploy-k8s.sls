#tee /srv/salt/usr/local/kubernetes/deploy-k8s.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/deploy-k8s.sh
      - name: /usr/local/kubernetes/deploy-k8s.sh
#EOF