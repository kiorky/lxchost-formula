{% from 'lxchost/map.jinja' import lxchost -%}

lxc_pkgs:
  pkg.installed:
    - pkgs:
      - bridge-utils
      - dnsmasq
      - iptables
      - lxc
    - install_recommends: False
    - reload_modules: True

disable_dnsmasq:
  service.dead:
    - name: dnsmasq
    - enable: False

{% if 'sysctl' in salt -%}
conf_sysctl:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
{%- endif %}

etclxc:
  file.directory:
    - name: /etc/lxc

default:
  file.managed:
    - name: /etc/lxc/default.conf
    - source: salt://lxchost/lxc.conf
    - template: jinja

conf_lxc_dnsmasq:
  file.managed:
    - name: /etc/lxc/dnsmasq.conf
    - source: salt://lxchost/dnsmasq.conf
    - template: jinja

interfaces-d:
  file.directory:
    - name: /etc/network/interfaces.d
    - mode: 0755

source-interfaces-d:
  file.append:
    - name: /etc/network/interfaces
    - text: source-directory interfaces.d

interface-file:
  file.managed:
    - name: /etc/network/interfaces.d/lxchost
    - source: salt://lxchost/interfaces
    - template: jinja
    - mode: 0644

down_{{ lxchost.iface }}:
  cmd.wait:
    - name: ifdown {{ lxchost.iface }}
    - watch:
      - file: interface-file
    - onlyif: test -f /sys/devices/virtual/net/{{ lxchost.iface }}/bridge/bridge_id

up_{{ lxchost.iface }}:
  cmd.wait:
    - name: ifup {{ lxchost.iface }}
    - watch:
      - file: interface-file

resolvconf_update:
  cmd.run:
    - name: resolvconf -u
    - onlyif: which resolvconf

wait_network:
  cmd.run:
    - name: curl --silent --show-error --retry 300 --retry-delay 1 --fail -I {{ lxchost.test_url }}
