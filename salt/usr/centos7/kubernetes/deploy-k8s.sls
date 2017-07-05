kubernetes:
  file.managed:
    - source: salt://usr/centos7/kubernetes/deploy-k8s.sh
    - name: /usr/local/kubernetes/deploy-k8s.sh
    - template: jinja
    - include: environment
