{%- from 'graphite/map.jinja' import graphite with context %}

/etc/init.d/carbon-cache:
  file.absent

carbon_cache_service:
  # file.managed:
  #   - name: /etc/init.d/carbon-cache
  #   - source: salt://graphite/carbon/files/carbon-cache.init.j2
  #   - template: jinja
  #   - mode: 755
  #   - context:
  #       graphite: {{ graphite }}
  file.managed:
    - name: {{ graphite.carbon.paths.servicefile }}
    - source: salt://graphite/carbon/files/carbon-cache.service.j2
    - template: jinja
    - mode: 755
    - context:
        graphite: {{ graphite }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: carbon_cache_service
  service.running:
    - name: carbon-cache
    - enable: True
    - watch:
      - file: carbon_cache_service


graphite_pkg_carbon:
  pip.installed:
    - pkgs:
      - git+https://github.com/graphite-project/whisper.git
      - git+https://github.com/graphite-project/carbon.git
    - bin_env: /srv/graphite
    - install_options:
      - --prefix=/srv/graphite
      - --install-lib=/srv/graphite/lib
    - require:
      - virtualenv: graphite_virtualenv


/srv/graphite/conf/storage-schemas.conf:
  file.managed:
    - source: salt://graphite/carbon/files/storage-schemas.conf
    - template: jinja
    - context:
        graphite: {{ graphite }}


/srv/graphite/conf/storage-aggregation.conf:
  file.managed:
    - source: salt://graphite/carbon/files/storage-aggregation.conf


/srv/graphite/conf/carbon.conf:
  file.managed:
    - source: salt://graphite/carbon/files/carbon.conf.j2
    - template: jinja
    - context:
        graphite: {{ graphite }}


local-dirs:
  file.directory:
    - user: {{ graphite.user }}
    - group: {{ graphite.group }}
    - names:
      - {{ graphite.carbon.paths.pid }}
      - {{ graphite.carbon.paths.logs }}
