# Debian 系统初始化脚本

这个脚本用于在新安装的 Debian 系统上进行基本配置和软件安装。
PS: 不保证通用性。

## 使用方法

一定一定使用root账户执行以下命令

``` bash
curl -fsSL https://github.com/MingriLingran/debain-init/raw/refs/heads/main/init.sh | bash
```

中国使用gh代理

```bash
curl -fsSL https://gh.llkk.cc/https://github.com/MingriLingran/debain-init/raw/refs/heads/main/init.sh | bash
```

## 预览效果使用docke

使用docker

```bash

docker pull linranqwq/debian-init:latest 
docker run -d debian-init 
docker exec -it debian-init zsh
```

## init.sh 功能

1. 自动设置ssh，默认22端口，（默认关闭密码登录）使用公钥登录
2. 自动设置hostname，自行填写
3. 创建用户账户，自行填写
4. 根据地区更该系统镜像源

## user-init.sh 功能

1. 安装zsh,使用[starship](https://github.com/starship/starship)美化终端,[antidote](https://github.com/mattmc3/antidote)管理插件,配置常见插件
2. 安装neovim,使用[lazyvim](https://github.com/LazyVim/LazyVim)配置nvim
3. 安装nginx,配置nginx源，
4. 安装docker,配置docker源，将用户加docker组允许用户管理
5. 在/opt/service/文件夹中设置权限允许用户直接访问（个人喜欢把第三方服务放在这个目录下，方便管理）
