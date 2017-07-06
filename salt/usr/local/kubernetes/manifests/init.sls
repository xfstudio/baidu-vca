#tee /srv/salt/usr/local/kubernetes/manifests/init.sls <<-EOF
/usr/local/kubernetes/manifests/kubernetes-dashboard.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/kubernetes-dashboard.yaml
    - template: jinja
    - default:
      dashboard_host: {{ pillar['registry']['host'] }}
      dashboard_port: 80
      repo_prefix: {{ pillar['registry']['host'] }}:{{ pillar['registry']['port'] }}
      kubernetes_dashboard_version: {{ pillar['packages']['images']['gcr.io']['google_containers']['kubernetes-dashboard-amd64'] }}
/usr/local/kubernetes/manifests/nginx-ingress-controller.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/nginx-ingress-controller.yaml
    - template: jinja
    - default:
      repo_prefix: {{ pillar['registry']['host'] }}:{{ pillar['registry']['port'] }}
      defaultbackend_version: {{ pillar['packages']['images']['gcr.io']['google_containers']['defaultbackend'] }}
      nginx_ingress_controller_version: {{ pillar['packages']['images']['gcr.io']['google_containers']['nginx-ingress-controller'] }}
/usr/local/kubernetes/manifests/calico.yaml:
  file.managed:
    - source: salt://usr/local/kubernetes/manifests/calico.yaml
    - template: jinja
    - default:
      repo_prefix: {{ pillar['registry']['host'] }}:{{ pillar['registry']['port'] }}
      cluster_etcd_endponits: {% for server in pillar['servers']['master'] %}{% if loop.first %}{{ pillar['etcd']['prefix'] }}://{% endif %}{{ pillar['servers']['master'][server] }}:{{ pillar['etcd']['endpoint_port'] }}{% if not loop.last %},{{pillar['etcd']['prefix'] }}://{% endif %}{% endfor %}
      kube_policy_controller_version: {{ pillar['packages']['images']['quay.io']['calico']['kube-policy-controller'] }}
      node_version: {{ pillar['packages']['images']['quay.io']['calico']['node'] }}
      cni_version: {{ pillar['packages']['images']['quay.io']['calico']['cni'] }}
#EOF