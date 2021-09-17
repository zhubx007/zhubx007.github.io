---
title: 创建云硬盘（01）
abbrlink: 24690
date: 2021-09-16 20:59:34
tags:
- cinder
- openstack
categories:
- openstack
---

**非概念型介绍，而是通过命令行或者 RESTful API 进行实际操作讲解。**

**本文主要介绍创建一块空的云硬盘。**

## OpenStack 环境

安装可以参考官方文档进行搭建：

- 通过 `kolla-ansible` 进行容器化部署：https://docs.openstack.org/kolla-ansible/latest/
- 通过 `devstack` 进行开发式部署：https://docs.openstack.org/devstack/latest/

命令行工具，通过 `pip` 进行安装：

```shell
$ pip install python-openstackclient
$ openstack --version
openstack 5.6.0
```

## 命令行方式

### 使用 help 命令查看参数

```shell
$ openstack help volume create
```

![openstack help volume create](https://zbx-pic.oss-cn-shanghai.aliyuncs.com/iseeyou/2021-09-16_182117.png)

### 参数详解

- \<name\>: 云硬盘名称
- --size: 设置云硬盘的大小，单位为 GiB
- --type: 设置云硬盘的类型
- --description: 描述信息
- --availability-zone: 目标 AZ
- --property: 设置云硬盘属性，可以使用多次 `--property` 进行多个设置

### 执行命令

```shell
$ # 首先 source <openrc-file>
$ openstack volume create <name> --size <size> --type <volume-type> --description <description> --availability-zone <availability-zone> --property <key01>=<value01> --property <key02>=<value02>
```

## RESTful API 方式

### API 详解

API doc: https://docs.openstack.org/api-ref/block-storage/v3/index.html#create-a-volume

API: `/v3/{project_id}/volumes`

Request Body:

```json
{
    "volume": {
        "name": "",
        "size": 10,
        "volume_type": "",
        "description": "",
        "availability_zone": "",
        "metadata": {}
    }
}
```

### curl API

```shell
$ # 首先 source <openrc-file>
$ TOKEN=`openstack token issue -f value -c id`
$ curl -g -i -X POST <cinder-endpoint>/v3/<project-id>/volumes \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: ${TOKEN}" \
-d '
{
    "volume": {
        "size": 10,
        "name": "testvol",
        "description": "testvol",
        "volume_type": "__DEFAULT__",
        "availability_zone": "nova",
        "metadata": {
            "key01": "value01",
            "key02": "value02"
        }
    }
}'
```
