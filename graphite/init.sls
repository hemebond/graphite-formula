{%- from "graphite/map.jinja" import graphite with context %}

include:
  - .carbon



graphite_dependencies:
  pkg.installed:
    - pkgs:
      - virtualenv
      - git
      - python-dev
      - python-cairocffi
      - libcairo2-dev
      - libffi-dev
      - build-essential



graphite_virtualenv:
  virtualenv.managed:
    - name: /srv/graphite
    - system_site_packages: True
    - python: python2
    - require:
      - pkg: graphite_dependencies







graphite_pkg_graphite_web:
  pip.installed:
    - name: git+https://github.com/graphite-project/graphite-web.git
    - bin_env: /srv/graphite
    - install_options:
      - --prefix=/srv/graphite
      - --install-lib=/srv/graphite/webapp
    - require:
      - virtualenv: graphite_virtualenv



graphite_group:
  group.present:
    - name: {{ graphite.group }}

graphite_user:
  user.present:
    - name: {{ graphite.user }}
    - shell: /bin/false
    - createhome: False
    - groups:
      - {{ graphite.group }}
    - require:
      - group: graphite_group



{{ graphite.paths.local_settings }}:
  file.managed:
    - source: salt://graphite/files/local_settings.py
    - template: jinja
    - context:
        graphite: {{ graphite }}


/srv/graphite/conf/graphite.ini:
  file.managed:
    - source: salt://graphite/files/graphite.ini
    - template: jinja
    - context:
        graphite: {{ graphite }}


graphite_database_initialisation:
  cmd.run:
    - name: /srv/graphite/bin/django-admin.py migrate --settings=graphite.settings --run-syncdb
    - env:
        PYTHONPATH: {{ graphite.paths.pythonpath }}
{%- if graphite.database.type == 'sqlite3' %}
    - creates: {{ graphite.database.name }}
{%- endif %}


graphite_storage_directory_permissions:
  file.directory:
    - name: {{ graphite.paths.storage }}
    - user: {{ graphite.user }}
    - group: {{ graphite.group }}
    - recurse:
      - user
      - group



graphite_collectstatic:
  cmd.run:
    - name: /srv/graphite/bin/django-admin.py collectstatic --noinput --settings=graphite.settings
    - env:
        PYTHONPATH: {{ graphite.paths.pythonpath }}
    - creates: {{ graphite.paths.root }}/static



graphite_service:
  file.managed:
    - name: /etc/systemd/system/graphite.service
    - source: salt://graphite/files/graphite.service.j2
    - template: jinja
    - mode: 755
    - context:
        graphite: {{ graphite }}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: graphite_service
  service.running:
    - name: graphite
    - enable: True
    - watch:
      - file: graphite_service
