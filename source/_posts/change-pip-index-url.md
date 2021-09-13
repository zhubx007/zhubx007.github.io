---
title: 配置 pip 国内源
tags:
  - pip
categories:
  - linux
abbrlink: 39470
date: 2021-09-12 15:56:05
---

# Linux

 1. 创建.pip目录

```console
$ mkdir -p $HOME/.pip
```

 2. 写入pip.conf配置文件

```console
$ echo "[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >$HOME/.pip/pip.conf
```

# Windows

 1. 在用户目录下，创建pip目录，例如C:\Users\Administrator\pip
 2. 写入pip.ini配置文件，内容如下：

```text
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
```

# 推荐国内源

| 源 | 地址  |
| -- | -- |
| 清华大学 | https://pypi.tuna.tsinghua.edu.cn/simple |
| 阿里云 | http://mirrors.aliyun.com/pypi/simple |
| 豆瓣 | http://pypi.douban.com/simple |

