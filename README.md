# everbox_client - EverBox 命令行及调试工具

[![Build Status](https://secure.travis-ci.org/everbox/everbox-client-ruby.png?branch=master)](http://travis-ci.org/everbox/everbox-client-ruby)

## 安装

    $ gem install everbox_client

## 使用方法

### 列出全部可用命令

    $ everbox
    Usage: everbox [options] <command>

    Available commands:
       cat            cat file
       cd             change dir
       config         set config
       get            download file
       help           print help info
       info           show user info
       login          login
       ls             list files and directories
       lsdir          list directories
       mirror         download dir
       mkdir          make directory
       prepare_put    prepare put
       put            upload file
       pwd            print working dir
       rm             delete file or directory

### 显示单个命令的帮助

    $ everbox help login
    Usage:

      everbox login
      登录 everbox, 登录完成后的 token 保存在 $HOME/.everbox_client/config

### 环境变量

    http_proxy: 用于设置代理，比如 export http_proxy="http://192.168.2.1:3128"
