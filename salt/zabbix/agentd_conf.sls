zabbix:
   file.managed:
     - source: salt://zabbix/zabbix_agentd.conf
     - name: /usr/local/zabbix/conf/zabbix_agentd.conf
     - template: jinja
     - defaults:
      zabbix_master: {{ pillar['zabbix_master'] }}
      ip: {{ pillar['ip'] }}
