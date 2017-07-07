#tee /srv/salt/usr/local/kubernetes/proxy_download.sh <<-EOF
registry='{{ repo_prefix }}'
images=(
{% for sites in images %}{% for namespace in images[sites] %}{% for image in images[sites][namespace] %}    {{ sites }}/{{ namespace }}/{{ image }}:{{ images[sites][namespace][image] }}{% if not loop.last %}
{% endif %}{% endfor %}{% endfor %}{% endfor %}
)

docker login -u {{ pillar['registry']['username'] }} -p {{ pillar['registry']['password'] }} \$registry
for image in \${images[@]} ; do
    imageName=\${image##*/}
    docker pull \$image
    docker tag \$image \$registry/\$imageName
    docker push \$registry/\$imageName
done
#EOF