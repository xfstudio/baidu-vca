#tee /srv/salt/usr/local/kubernetes/environment.sls <<-EOF
kubernetes:
  file.managed:
    - template: jinja
    - default:
      appname: {{ pillar['appname'] }}
      custom_ssh_port: {{ pillar['servers']['custom_ssh_port'] }}
      repo_prefix: {{ pillar['registry']['host'] }}:{{ pillar['registry']['port'] }}
      cluster_master: {{ pillar['cluster']['master'] }}
      cluster_dns: {{ pillar['cluster']['dns'] }}
      cluster_cidr: {{ pillar['cluster']['cidr'] }}
      cluster_service_ip: {{ pillar['cluster']['service_ip'] }}
      cluster_service_cidr: {{ pillar['cluster']['service_cidr'] }}
      cluster_domain: {{ pillar['cluster']['domain'] }}
      cluster_servers: {{ pillar['servers']['master'] }}
      kube_version: {{ pillar['packages']['images']['gcr.io']['google_containers']['kube-apiserver-amd64'] }}
      pause_version: {{ pillar['packages']['images']['gcr.io']['google_containers']['pause-amd64'] }}
      etcd_version: {{ pillar['packages']['images']['gcr.io']['google_containers']['etcd-amd64'] }}
      images: {{ pillar['packages']['images'] }}
#EOF