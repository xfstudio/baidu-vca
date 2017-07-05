kubernetes:
  file.managed:
    - source: salt://usr/local/kubelet/kubemaster.sh
    - name: /usr/local/kubelet/kubemaster.sh
    - template: jinja
    include: 
      environment
