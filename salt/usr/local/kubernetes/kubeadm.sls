#tee /srv/salt/usr/local/kubernetes/kubeadm.sls <<-EOF
include:
  - usr.local.kubernetes.environment
extend:
  kubernetes:
    file.managed:
      - source: salt://usr/local/kubernetes/kubeadm.conf
      - name: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
#EOF