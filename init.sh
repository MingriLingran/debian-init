
# SSH密钥
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2A0zvOGzFHVmeOqijww+vz7VtSZNPuIA6tMIeTxXk0"
# 用户名(默认为linran)
USERNAME="linran"
# 主机名
HOSTNAME="home"
# SSH端口
SSH_PORT="22"
main() {
  check_root
  初始化系统

}
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本："
    echo "sudo "
    exit 1
  fi
}
# 初始化系统和软件包
初始化系统 () {

  init() {
    echo "正在更新系统..."
    apt update && apt upgrade -y

    apt install -y \
      curl \
      wget \
      git \
      zsh \
      docker-compose \

    get_name
  }

  # 覆盖默认用户名
  get_name() {
    read -p "请输入要创建的用户名 (默认: linran): " input_username
    USERNAME=${input_username:-linran}
    read -p "请输入主机名 (默认: home): " input_hostname
    HOSTNAME=${input_hostname:-home}
    # 执行
    config_hostname
    adduser
  }

  # 配置主机名
  config_hostname() {
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
      echo "请输入 $USERNAME 的密码:"
      passwd "$USERNAME"
    fi
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
      sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/sshd_config
    systemctl restart sshd
    echo "SSH配置完成"
  }
  安装用户常用工具
}

# ----------------------------------------
安装用户常用工具(){


  安装neovim() {
    echo "正在安装neovim..."
    bash << EOF
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
EOF
    echo "neovim安装完成"
    echo "正在配置neovim插件系统"
    mkdir -p /home/"$USERNAME"/.config/nvim
    git clone https://github.com/LazyVim/starter $USERNAME/.config/nvim
    rm -rf $USERNAME/.config/nvim/.git
  }

  安装zsh() {
    echo "正在安装zsh相关包..."
    apt update
    apt install -y \
    zsh \
    starship \
    echo "zsh安装完成"
    echo "正在配置zsh..."
    mkdir -p /home/"$USERNAME"/.config/zsh
    # 创建zshenv文件启用zsh/.zshenv
    cat > "/home/$USERNAME/.zshenv" << EOF
    source \$HOME/.config/zsh/.zshenv
EOF

    # 定义环境
    cat > "/home/$USERNAME/.config/zsh/.zshenv" << EOF
    export ZDOTDIR=$HOME/.config/zsh
    PATH="$PATH:/opt/nvim-linux-x86_64/bin"
EOF

    # 配置zsh
    cat > "/home/$USERNAME/.config/zsh/.zshrc" << EOF
    zstyle ':antidote:defer' bundle 'romkatv/zsh-defer'

    zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
    if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
      (
        source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh
        antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
      )
    fi
    source ${zsh_plugins}.zsh

    # fastfetch

    eval "$(starship init zsh)"
EOF

    chsh -s /bin/zsh "$USERNAME"
    echo "zsh已配置为默认shell"

}
  安装neovim
  安装zsh
  
}

main