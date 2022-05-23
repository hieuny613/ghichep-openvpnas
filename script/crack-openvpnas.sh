#!/bin/bash
### Crack OpenVPN Access Server
### Version 1.0
### hieuny

function echo_red() {
  echo -e "\033[1;31m$1\033[0m"
}

function echo_green() {
  echo -e "\033[1;32m$1\033[0m"
}

function echo_yellow() {
  echo -e "\033[1;33m$1\033[0m"
}

function echo_done() {
  sleep 0.5
  echo "$(gettext 'complete')"
}

function echo_check() {
  echo -e "$1 \t [\033[32m √ \033[0m]"
}

function echo_failed() {
  echo_red "$(gettext 'fail')"
}

function log_success() {
  echo_green "[SUCCESS] $1"
}

function log_warn() {
  echo_yellow "[WARN] $1"
}

function log_error() {
  echo_red "[ERROR] $1"
}

function check_root() {
  if [[ "$(id -u)" != "0" ]]; then
    echo_red "Sử dụng tài khoản root để chạy"
    exit 1
  fi
}

function check_openvpnas() {
  if [[ ! -d /usr/local/openvpn_as ]]; then
    echo_red "Chưa cài đặt OpenVPN Access Server"
    exit 1
  fi
}

function install_soft {
  for i in unzip zip; do
     command -v $i &>/dev/null || dnf -q -y install $i > /dev/null
  done
}

function crack_openvpn() {
  echo_green "Bắt đầu crack OpenVPN Access Server"
  mkdir /tmp/crack-openvpn > /dev/null
  cd /tmp/crack-openvpn
  cp /usr/local/openvpn_as/lib/python/pyovpn-2.0-py3.6.egg /tmp/crack-openvpn > /dev/null
  unzip /tmp/crack-openvpn/pyovpn-2.0-py3.6.egg -d /tmp/crack-openvpn/ > /dev/null
  rm -rf /tmp/crack-openvpn/pyovpn-2.0-py3.6.egg > /dev/null
  mv /tmp/crack-openvpn/pyovpn/lic/uprop.pyc /tmp/crack-openvpn/pyovpn/lic/uprop2.pyc > /dev/null
  cat >> uprop.py << EOF
from pyovpn.lic import uprop2
old_figure = None

def new_figure(self, licdict):
    ret = old_figure(self, licdict)
    ret['concurrent_connections'] = 2048
    return ret


for x in dir(uprop2):
    if x[:2] == '__':
        continue
    if x == 'UsageProperties':
        exec('old_figure = uprop2.UsageProperties.figure')
        exec('uprop2.UsageProperties.figure = new_figure')
    exec('%s = uprop2.%s' % (x, x))
EOF
  python3 -O -m compileall uprop.py && mv __pycache__/uprop.cpython-36.opt-1.pyc /tmp/crack-openvpn/pyovpn/lic/uprop.pyc > /dev/null
  zip -r pyovpn-2.0-py3.6.egg.zip common EGG-INFO pyovpn > /dev/null
  mv pyovpn-2.0-py3.6.egg.zip pyovpn-2.0-py3.6.egg > /dev/null
  mv /usr/local/openvpn_as/lib/python/pyovpn-2.0-py3.6.egg /usr/local/openvpn_as/lib/python/pyovpn-2.0-py3.6.egg.bak > /dev/null
  mv /tmp/crack-openvpn/pyovpn-2.0-py3.6.egg /usr/local/openvpn_as/lib/python/ > /dev/null
  rm -rf /tmp/crack-openvpn/ > /dev/null
  cd
  echo_green "Khởi động lại service"
  service openvpnas restart
}

function main(){
  check_root
  check_openvpnas
  install_soft
  crack_openvpn
}

main
