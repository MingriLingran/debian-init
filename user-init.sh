#!/bin/bash
set -eE
USERNAME=$(whoami)
cd "$HOME" || exit 1
main(){
  check_os
  install_tools 
  echo "是否安装docker和nginx？(y/n): "
  echo "docker和nginx采用官方源安装"
  echo "中国建议手工安装docker和nginx，脚本安装可能会失败"
  read -rp "请选择[y/n]: " install_pack_choice
  if [[ "$install_pack_choice" =~ ^[Yy]$ ]]; then
    install_pack
  else
    echo "跳过安装docker和nginx"
  fi
}



install_tools(){
  install_zsh() {
    echo "正在安装zsh相关包..."
    sudo apt update
    sudo apt install -y \
    zsh \
    starship 
    echo "zsh安装完成"
    echo "正在配置zsh..."
    mkdir -p .config/zsh
    # 创建zshenv文件启用zsh/.zshenv
    if is_in_china; then
    git clone --depth=1 https://gh.llkk.cc/https://github.com/mattmc3/antidote.git ~/.config/zsh/.antidote
    else
    git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.config/zsh/.antidote
    fi
    cat > "/home/$USERNAME/.zshenv" << EOF
source \$HOME/.config/zsh/.zshenv
EOF

    # 定义环境
    cat > "/home/$USERNAME/.config/zsh/.zshenv" << EOF
export ZDOTDIR=\$HOME/.config/zsh
PATH="\$PATH:/opt/nvim-linux-x86_64/bin"
EOF

    # 配置zsh
    cat > "/home/$USERNAME/.config/zsh/.zshrc" << EOF
zstyle ':antidote:defer' bundle 'romkatv/zsh-defer'

zsh_plugins=\${ZDOTDIR:-\$HOME}/.zsh_plugins
if [[ ! \${zsh_plugins}.zsh -nt \${zsh_plugins}.txt ]]; then
  (
    source \${ZDOTDIR:-\$HOME}/.antidote/antidote.zsh
    
    antidote bundle <\${zsh_plugins}.txt >\${zsh_plugins}.zsh
  )
fi
source \${zsh_plugins}.zsh

# fastfetch

eval "\$(starship init zsh)"
EOF
    # 配置zsh插件
    cat > "/home/$USERNAME/.config/zsh/.zsh_plugins.txt" << EOF
ohmyzsh/ohmyzsh path:lib/key-bindings.zsh
ohmyzsh/ohmyzsh path:lib/history.zsh
ohmyzsh/ohmyzsh path:lib/clipboard.zsh
ohmyzsh/ohmyzsh path:plugins/sudo
ohmyzsh/ohmyzsh path:plugins/colored-man-pages

hlissner/zsh-autopair kind:defer

ohmyzsh/ohmyzsh path:lib/completion.zsh


zsh-users/zsh-syntax-highlighting
zsh-users/zsh-autosuggestions

ohmyzsh/ohmyzsh path:lib/theme-and-appearance.zsh
EOF

    # chsh -s /bin/zsh "$USERNAME"
    # echo "zsh已配置为默认shell"

    }
  install_neovim() {
    echo "正在安装neovim..."
    if is_in_china; then
      curl -LO https://gh.llkk.cc/https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
      git clone https://gh.llkk.cc/https://github.com/LazyVim/starter .config/nvim
    else
      curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
      git clone https://github.com/LazyVim/starter .config/nvim
    fi
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm nvim-linux-x86_64.tar.gz
    mkdir -p .config/nvim
    rm -rf .config/nvim/.git
    echo "neovim安装完成"
    }

install_zsh
install_neovim

}
install_pack(){
  docker() {
    echo "正在安装docker..."
    sudo apt update
    sudo apt install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      lsb-release
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose
    sudo usermod -aG docker "$USERNAME"
    echo "正在配置docker镜像源"
    sudo mkdir -p /etc/docker
    sudo echo tee /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://docker.1panel.live",
    "https://docker.1ms.run",
    "https://docker-0.unsee.tech",
    "https://lispy.org",
    "https://docker.xiaogenban1993.com",
    "https://proxy.vvvv.ee",
    "https://registry.cyou",
    "https://hub.docker.com"
  ]
}
EOF
  echo "正在重启docker服务"
  sudo systemctl daemon-reload
  sudo systemctl restart docker
  echo "docker安装完成" 
  } 
  nginx() {
    echo "正在安装nginx..."
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "验证下载的文件是否包含正确的密钥： "
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian \
  $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    sudo apt update
    sudo apt install -y nginx
    echo "nginx安装完成"
  }
  serveice() {
    sudo mkdir -p /opt/service
    sudo chown "$USERNAME":docker /opt/service
    sudo chmod 775 -R /opt/services
    sudo chmod g+s /opt/services
    sudo setfacl -d -m g::rwx /opt/services
    echo "/opt/service目录已创建，且用户$USERNAME 和docker组拥有该目录的读写权限"

  }
}
# ----------------------------------------工具

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

check_os(){
  if [ "$EUID" -eq 0 ]; then
    echo "请以普通用户（非root）运行此脚本："
    echo "bash user-init.sh"
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

error_and_exit() {
    error "$@"
    exit 1
}

# ----------------------------------------主
main