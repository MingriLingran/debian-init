#!/bin/bash
set -eE
# SSH密钥
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2A0zvOGzFHVmeOqijww+vz7VtSZNPuIA6tMIeTxXk0"
# 用户名(默认为linran)
USERNAME="linran"
# 主机名
HOSTNAME="home"
# SSH端口
SSH_PORT="22"
main() {
  check_os
  init-system

}
check_os() {
  if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本："
    echo "sudo "
    exit 1
  fi
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [ "$ID" != "debian" ]; then
      echo "此脚本仅支持Debian 13 (trixie)"
      exit 1
    elif [ "$VERSION_ID" != "13" ]; then
      echo "此脚本仅支持Debian 13 (trixie)"
      exit 1
    fi
  fi
}
# 初始化系统和软件包
init-system() {
  init() {
    echo "正在初始化系统..."
    if is_in_china; then
      rm -f /etc/apt/sources.list
      echo "正在配置国内镜像源..."
      cat > /etc/apt/sources.list.d/debian.sources << EOF
Types: deb deb-src
URIs: http://mirrors.tuna.tsinghua.edu.cn/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: http://mirrors.tuna.tsinghua.edu.cn/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    else
      echo "当前不在国内，使用默认源"
    fi
    echo "正在更新镜像源..."
    apt update && apt upgrade -y
    echo "正在安装必要的工具..."
    apt install -y \
      curl \
      git \
      sudo \
      systemd
    get_name
  }

  # 覆盖默认用户名
  get_name() {
    read -p "请输入要创建的用户名 (默认: linran): " input_username
    USERNAME=${input_username:-linran}
    read -p "请输入主机名 (默认: home): " input_hostname
    HOSTNAME=${input_hostname:-home}
    # 执行
    # config_hostname
    adduser
  }

  # 配置主机名
  config_hostname() {
    cat > /etc/hosts << EOF
127.0.0.1 $HOSTNAME
::1       $HOSTNAME ip6-localhost ip6-loopback
EOF
    echo "$HOSTNAME" > /etc/hostname
    hostnamectl set-hostname "$HOSTNAME"
  }

  # 添加用户
  adduser() {
    if id "$USERNAME" &>/dev/null; then
      echo "用户 $USERNAME 已存在"
    else
      echo "正在创建用户 $USERNAME..."
      useradd -m -s /bin/bash "$USERNAME"
      echo "$USERNAME:123456" | chpasswd
      echo "用户 $USERNAME 已创建，默认密码: 123456"
    fi
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
    chmod 440 "/etc/sudoers.d/$USERNAME"
    config_ssh_login
  }

  # 配置SSH
  config_ssh_login() {
    mkdir -p /home/"$USERNAME"/.ssh
    echo "$PUBLIC_KEY" > /home/"$USERNAME"/.ssh/authorized_keys
    chmod 700 /home/"$USERNAME"/.ssh
    chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
    chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh

    config_ssh
  }


  # 配置SSH
  config_ssh() {
    read -p "请输入SSH端口 (默认: 22): " input_ssh_port 
    SSH_PORT=${input_ssh_port:-22}
    read -p "是否开启密码登录？(true/false) [默认false]: " input
    enable_pwd=${input:-false}
    echo "正在配置SSH..."
    sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    # 设置密码登录
    if [ "$enable_pwd" = "true" ]; then
      sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
    else
      sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
    fi
    systemctl restart sshd
    echo "SSH配置完成"
  }
  init
  install_tools
}

# ----------------------------------------

is_in_china() {
    [ "$force_cn" = 1 ] && return 0
    if ! command -v curl &> /dev/null; then
        echo "curl命令不存在，默认设置为中国镜像源" >&2
        _loc=CN
    
    elif [ -z "$_loc" ]; then
        if ! _loc=$(curl -L http://www.qualcomm.cn/cdn-cgi/trace | grep '^loc=' | cut -d= -f2 | grep .); then
            error_and_exit "Can not get location."
        fi
        echo "Location: $_loc" >&2
    fi
    [ "$_loc" = CN ]
}
error_and_exit() {
    error "$@"
    exit 1
}
main
