---
title: 创建云硬盘（04）
date: 2021-10-11 18:16:19
tags:
  - cinder
  - openstack
categories:
  - openstack
---

**非概念型介绍，而是通过命令行或者 RESTful API 进行实际操作讲解。**

**本文主要介绍从云硬盘创建云硬盘。**

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
- --source: 云硬盘名称或者 ID
- --description: 描述信息
- --availability-zone: 目标 AZ
- --property: 设置云硬盘属性，可以使用多次 `--property` 进行多个设置

### 执行命令

```shell
$ source /etc/kolla/admin-openrc.sh
$ VOLUME_TYPE_NAME="__DEFAULT__"
$ VOLUME_NAME="vol01"
$ openstack volume create testvolume01 --size 10 --type ${VOLUME_TYPE_NAME} --source ${VOLUME_NAME} --description "test volume01" --availability-zone nova --property key01=value01 --property key02=value02
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2021-10-11T10:20:42.000000           |
| description         | test volume01                        |
| encrypted           | False                                |
| id                  | 02b154b6-2718-41ef-939c-4cd74fba869f |
| migration_status    | None                                 |
| multiattach         | False                                |
| name                | testvolume01                         |
| properties          | key01='value01', key02='value02'     |
| replication_status  | None                                 |
| size                | 10                                   |
| snapshot_id         | None                                 |
| source_volid        | 067ebd2b-2f41-46fc-aea8-c8ca3873c61f |
| status              | creating                             |
| type                | __DEFAULT__                          |
| updated_at          | None                                 |
| user_id             | 3961922174e34ba5ba0b899c676ebc30     |
+---------------------+--------------------------------------+
$ openstack volume show 02b154b6-2718-41ef-939c-4cd74fba869f -f json | jq
```
```json
{
  "attachments": [],
  "availability_zone": "nova",
  "bootable": "false",
  "consistencygroup_id": null,
  "created_at": "2021-10-11T10:20:42.000000",
  "description": "test volume01",
  "encrypted": false,
  "id": "02b154b6-2718-41ef-939c-4cd74fba869f",
  "migration_status": null,
  "multiattach": false,
  "name": "testvolume01",
  "os-vol-host-attr:host": "control@rbd-1#rbd-1",
  "os-vol-mig-status-attr:migstat": null,
  "os-vol-mig-status-attr:name_id": null,
  "os-vol-tenant-attr:tenant_id": "3b88159957c8455195d99d7558dff52a",
  "properties": {
    "key01": "value01",
    "key02": "value02"
  },
  "replication_status": null,
  "size": 10,
  "snapshot_id": null,
  "source_volid": "067ebd2b-2f41-46fc-aea8-c8ca3873c61f",
  "status": "available",
  "type": "__DEFAULT__",
  "updated_at": "2021-10-11T10:20:44.000000",
  "user_id": "3961922174e34ba5ba0b899c676ebc30"
}
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
        "source_volid": "",
        "description": "",
        "availability_zone": "",
        "metadata": {}
    }
}
```

### curl API

```shell
$ source /etc/kolla/admin-openrc.sh
$ VOLUME_TYPE_NAME="__DEFAULT__"
$ VOLUME_TYPE_ID=`openstack volume type show ${VOLUME_TYPE_NAME} -f value -c id`
$ VOLUME_NAME="vol01"
$ VOLUME_ID=`openstack volume show ${VOLUME_NAME} -f value -c id`
$ TOKEN=`openstack token issue -f value -c id`
$ PROJECT_ID=`openstack token issue -f value -c project_id`
$ CINDER_ENDPOINT="http://172.20.154.249:8776/v3/${PROJECT_ID}"
$ curl -X POST ${CINDER_ENDPOINT}/volumes \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "X-Auth-Token: ${TOKEN}" \
-d "
{
    \"volume\": {
        \"size\": 10,
        \"name\": \"testvolume02\",
        \"description\": \"test volume02\",
        \"volume_type\": \"${VOLUME_TYPE_ID}\",
        \"source_volid\": \"${VOLUME_ID}\",
        \"availability_zone\": \"nova\",
        \"metadata\": {
            \"key01\": \"value01\",
            \"key02\": \"value02\"
        }
    }
}" | jq
```
```json
{
  "volume": {
    "status": "creating",
    "migration_status": null,
    "user_id": "3961922174e34ba5ba0b899c676ebc30",
    "attachments": [],
    "links": [
      {
        "href": "http://172.20.154.249:8776/v3/3b88159957c8455195d99d7558dff52a/volumes/83ed85c6-cad2-4de2-b194-d2aa039f316c",
        "rel": "self"
      },
      {
        "href": "http://172.20.154.249:8776/3b88159957c8455195d99d7558dff52a/volumes/83ed85c6-cad2-4de2-b194-d2aa039f316c",
        "rel": "bookmark"
      }
    ],
    "availability_zone": "nova",
    "bootable": "false",
    "encrypted": false,
    "created_at": "2021-10-11T10:24:29.000000",
    "description": "test volume02",
    "updated_at": null,
    "volume_type": "__DEFAULT__",
    "name": "testvolume02",
    "replication_status": null,
    "consistencygroup_id": null,
    "source_volid": "067ebd2b-2f41-46fc-aea8-c8ca3873c61f",
    "snapshot_id": null,
    "multiattach": false,
    "metadata": {
      "key01": "value01",
      "key02": "value02"
    },
    "id": "83ed85c6-cad2-4de2-b194-d2aa039f316c",
    "size": 10
  }
}
```
```shell
$ openstack volume show 83ed85c6-cad2-4de2-b194-d2aa039f316c -f json | jq
```
```json
{
  "attachments": [],
  "availability_zone": "nova",
  "bootable": "false",
  "consistencygroup_id": null,
  "created_at": "2021-10-11T10:24:29.000000",
  "description": "test volume02",
  "encrypted": false,
  "id": "83ed85c6-cad2-4de2-b194-d2aa039f316c",
  "migration_status": null,
  "multiattach": false,
  "name": "testvolume02",
  "os-vol-host-attr:host": "control@rbd-1#rbd-1",
  "os-vol-mig-status-attr:migstat": null,
  "os-vol-mig-status-attr:name_id": null,
  "os-vol-tenant-attr:tenant_id": "3b88159957c8455195d99d7558dff52a",
  "properties": {
    "key01": "value01",
    "key02": "value02"
  },
  "replication_status": null,
  "size": 10,
  "snapshot_id": null,
  "source_volid": "067ebd2b-2f41-46fc-aea8-c8ca3873c61f",
  "status": "available",
  "type": "__DEFAULT__",
  "updated_at": "2021-10-11T10:24:31.000000",
  "user_id": "3961922174e34ba5ba0b899c676ebc30"
}
```
