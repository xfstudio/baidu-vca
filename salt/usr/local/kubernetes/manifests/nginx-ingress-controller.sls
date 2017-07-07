#tee /srv/salt/usr/local/kubernetes/manifests/nginx-ingress-controller.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/manifests/nginx-ingress-controller.yaml
      - name: /usr/local/kubernetes/manifests/nginx-ingress-controller.yaml
#EOF