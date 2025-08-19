#!/bin/bash
set -eE
USERNAME=$(whoami)
cd "$HOME" || exit 1
main(){
  check_os
  install_tools 
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
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    git clone https://github.com/LazyVim/starter .config/nvim
    fi
    suod tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm nvim-linux-x86_64.tar.gz
    mkdir -p .config/nvim
    rm -rf .config/nvim/.git
    echo "neovim安装完成"
    }

install_zsh
install_neovim
mv /root/user-init.sh /home/"$USERNAME"/user-init.sh
chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/user-init.sh
chmod +x /home/"$USERNAME"/user-init.sh
echo "=============================="
echo "不要关闭终端，请勿退出"
echo "验证公钥登录是否正常"
echo "=============================="
echo "请新开终端登录到"$USERNAME"用户"
echo "执行“bash user-init.sh”"
echo "=============================="
}