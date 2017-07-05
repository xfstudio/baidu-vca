defaults:
      appname: {{ pillar['appname'] }}
      repo_prefix: {{ pillar['registry']['host'] }}:{{ pillar['registry']['port'] }}
      cluster_dns: {{ pillar['cluster_dns'] }}
      cluster_cidr: {{ pillar['cluster_cidr'] }}
      service_cidr: {{ pillar['service_cidr'] }}
      cluster_server_ip: {{ pillar['cluster_server_ip'] }}
      cluster_domain: {{ pillar['cluster_domain'] }}
      packages: {{ pillar['packages'] }}
