kubernetes:
  file.managed:
    - source: salt://usr/local/kubelet/kubeadm.conf
    - name: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    - template: jinja
    - defaults:
      repo_prefix: {{ pillar['repo']['host'] }}:{{ pillar['repo']['port'] }}
      cluster_dns: {{ pillar['cluster_dns'] }}
      cluster_server_ip: {{ pillar['cluster_server_ip'] }}
      cluster_cidr: {{ pillar['cluster_cidr'] }}
      cluster_domain: {{ pillar['cluster_domain'] }}
      cluster_etcd_endponits: {% for server in pillar['cluster_servers']['master'] %}{% if loop.first %}{{ pillar['etcd_prefix'] }}://{% endif %}{{ server }}:{{ pillar['etcd_endpoint_port'] }}{% if not loop.last %},{{pillar['etcd_prefix'] }}://{% endif %}{% endfor %}
      pause_version: {{ pillar['pause_version'] }}
