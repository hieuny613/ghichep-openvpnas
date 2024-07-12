#!/bin/bash
### Crack OpenVPN Access Server
### Version 1.1
### hieuny

# Function to print red text
function echo_red() {
  echo -e "\033[1;31m$1\033[0m"
}

# Function to print green text
function echo_green() {
  echo -e "\033[1;32m$1\033[0m"
}

# Function to print yellow text
function echo_yellow() {
  echo -e "\033[1;33m$1\033[0m"
}

# Function to indicate completion
function echo_done() {
  sleep 0.5
  echo "$(gettext 'complete')"
}

# Function to print a checkmark
function echo_check() {
  echo -e "$1 \t [\033[32m √ \033[0m]"
}

# Function to indicate failure
function echo_failed() {
  echo_red "$(gettext 'fail')"
}

# Function to log success messages
function log_success() {
  echo_green "[SUCCESS] $1"
}

# Function to log warnings
function log_warn() {
  echo_yellow "[WARN] $1"
}

# Function to log errors
function log_error() {
  echo_red "[ERROR] $1"
}

# Function to check if the script is run as root
function check_root() {
  if [[ "$(id -u)" != "0" ]]; then
    echo_red "Use root account to run"
    exit 1
  fi
}

# Function to check if OpenVPN Access Server is installed
function check_openvpnas() {
  if [[ ! -d /usr/local/openvpn_as ]]; then
    echo_red "OpenVPN Access Server is not installed"
    exit 1
  fi
}

# Function to install software packages
function install_soft() {
  local package=$1
  if command -v dnf > /dev/null; then
    dnf -q -y install "$package"
  elif command -v yum > /dev/null; then
    yum -q -y install "$package"
  elif command -v apt > /dev/null; then
    apt-get -qqy install "$package"
  elif command -v zypper > /dev/null; then
    zypper -q -n install "$package"
  else
    echo_red "$package command not found, Please install it first"
    exit 1
  fi
}

# Function to prepare and install necessary packages
function prepare_install() {
  echo_yellow "Installing packages ..."
  local packages=(vim curl wget net-tools telnet unzip zip)
  for package in "${packages[@]}"; do
    command -v "$package" &>/dev/null || install_soft "$package"
  done
}

# Function to crack OpenVPN Access Server
function crack_openvpn() {
  echo_green "Starting to crack OpenVPN Access Server"
  local temp_dir=/tmp/crack-openvpn
  local pyovpn_version

  mkdir "$temp_dir"
  cd "$temp_dir" || exit

  pyovpn_version=$(ls /usr/local/openvpn_as/lib/python/pyovpn-2.0-py*.egg | cut -d / -f7)
  cp /usr/local/openvpn_as/lib/python/"${pyovpn_version}" "$temp_dir"
  unzip "${pyovpn_version}" -d "$temp_dir"
  rm -f "${pyovpn_version}"
  mv pyovpn/lic/uprop.pyc pyovpn/lic/uprop2.pyc

  cat > uprop.py << EOF
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

  python3 -O -m compileall uprop.py
  mv __pycache__/uprop.cpython-*.pyc pyovpn/lic/uprop.pyc
  zip -r "${pyovpn_version}.zip" common EGG-INFO pyovpn
  mv "${pyovpn_version}.zip" "${pyovpn_version}"
  mv /usr/local/openvpn_as/lib/python/"${pyovpn_version}" /usr/local/openvpn_as/lib/python/"${pyovpn_version}".bak
  mv "${pyovpn_version}" /usr/local/openvpn_as/lib/python/
  rm -rf "$temp_dir"

  echo_green "Restarting OpenVPN Access Server service"
  service openvpnas restart
}

# Main function to orchestrate the cracking process
function main() {
  check_root
  check_openvpnas
  prepare_install
  crack_openvpn
}

main
