#tee /srv/salt/top.sls <<-EOF
base:
  '*':
    - usr.local.kubernetes.manifests
  'os:CentOS':
    - usr.local.kubernetes.deploy-k8s
#EOF