---
title: 搭建 pip 本地源
abbrlink: 30029
date: 2021-09-19 21:19:00
tags:
  - pip
categories:
  - linux
---

## 安装 pip 命令
```shell
$ yum install epel-release -y
$ yum makecache
$ yum install python-pip -y
```

## 使用 `pip download` 命令下载包以及相关依赖包
```shell
$ cd /opt
$ pip download <pkgs>
```

## 将所有的包，放置到一个目录下，例如 `/opt/pypi` 下
```shell
$ mkdir -p /opt/pypi
$ mv * /opt/pypi
```

## 安装 pip2pi
```shell
$ pip install pip2pi
```

## 制作本地源
```shell
$ cd /opt
$ dir2pi pypi
```

## 配置 pip.conf
```shell
$ mkdir -p /root/.pip
$ cat >/root/.pip/pip.conf <<END
[global]
index-url = file:///opt/pypi/simple
END
```

## 验证
```shell
$ pip install <pkgs>
```
