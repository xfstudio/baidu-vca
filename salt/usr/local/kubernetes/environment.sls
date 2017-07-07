#tee /srv/salt/usr/local/kubernetes/environment.sls <<-EOF
kubernetes:
  file.managed:
    - template: jinja
    - default:
      appname: {{ pillar['appname'] }}
      custom_ssh_port: {{ pillar['servers']['custom_ssh_port'] }}
      repo_prefix: {{ pillar['registry']['host'] }}:{{ pillar['registry']['port'] }}
      cluster: {{ pillar['cluster'] }}
      cluster_servers: {{ pillar['servers']['master'] }}
      images: {{ pillar['packages']['images'] }}
#EOF