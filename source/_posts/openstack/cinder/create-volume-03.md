---
title: 创建云硬盘（03）
tags:
  - cinder
  - openstack
categories:
  - openstack
abbrlink: 476
date: 2021-09-24 13:45:07
---

**非概念型介绍，而是通过命令行或者 RESTful API 进行实际操作讲解。**

**本文主要介绍从云硬盘快照创建云硬盘。**

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
- --snapshot: 云硬盘快照名称或者 ID
- --description: 描述信息
- --availability-zone: 目标 AZ
- --property: 设置云硬盘属性，可以使用多次 `--property` 进行多个设置

### 执行命令

```shell
$ source /etc/kolla/admin-openrc.sh
$ VOLUME_TYPE_NAME="__DEFAULT__"
$ SNAPSHOT_NAME="vol01-snapshot"
$ openstack volume create testvolume01 --size 10 --type ${VOLUME_TYPE_NAME} --snapshot ${SNAPSHOT_NAME} --description "test volume01" --availability-zone nova --property key01=value01 --property key02=value02
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2021-09-24T05:51:06.000000           |
| description         | test volume01                        |
| encrypted           | False                                |
| id                  | 07f06cb4-f558-450f-b019-89c7fa2b35d5 |
| migration_status    | None                                 |
| multiattach         | False                                |
| name                | testvolume01                         |
| properties          | key01='value01', key02='value02'     |
| replication_status  | None                                 |
| size                | 10                                   |
| snapshot_id         | 09e4c5ae-34b5-473d-9c00-c0c8a2487f95 |
| source_volid        | None                                 |
| status              | creating                             |
| type                | __DEFAULT__                          |
| updated_at          | None                                 |
| user_id             | 7ef3adefeecc45868a7f84fbd1a82f22     |
+---------------------+--------------------------------------+
$ openstack volume show 07f06cb4-f558-450f-b019-89c7fa2b35d5 -f json | jq
```
```json
{
  "attachments": [],
  "availability_zone": "nova",
  "bootable": "false",
  "consistencygroup_id": null,
  "created_at": "2021-09-24T05:51:06.000000",
  "description": "test volume01",
  "encrypted": false,
  "id": "07f06cb4-f558-450f-b019-89c7fa2b35d5",
  "migration_status": null,
  "multiattach": false,
  "name": "testvolume01",
  "os-vol-host-attr:host": "control@rbd-1#rbd-1",
  "os-vol-mig-status-attr:migstat": null,
  "os-vol-mig-status-attr:name_id": null,
  "os-vol-tenant-attr:tenant_id": "d29306a672de404dbcd8731065b521a1",
  "properties": {
    "key01": "value01",
    "key02": "value02"
  },
  "replication_status": null,
  "size": 10,
  "snapshot_id": "09e4c5ae-34b5-473d-9c00-c0c8a2487f95",
  "source_volid": null,
  "status": "available",
  "type": "__DEFAULT__",
  "updated_at": "2021-09-24T05:51:07.000000",
  "user_id": "7ef3adefeecc45868a7f84fbd1a82f22"
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
        "snapshot_id": "",
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
$ SNAPSHOT_NAME="vol01-snapshot"
$ SNAPSHOT_ID=`openstack volume snapshot show ${SNAPSHOT_NAME} -f value -c id`
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
        \"snapshot_id\": \"${SNAPSHOT_ID}\",
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
    "user_id": "7ef3adefeecc45868a7f84fbd1a82f22",
    "attachments": [],
    "links": [
      {
        "href": "http://172.20.154.249:8776/v3/d29306a672de404dbcd8731065b521a1/volumes/07d20984-5652-437e-89e1-c4df6956c634",
        "rel": "self"
      },
      {
        "href": "http://172.20.154.249:8776/d29306a672de404dbcd8731065b521a1/volumes/07d20984-5652-437e-89e1-c4df6956c634",
        "rel": "bookmark"
      }
    ],
    "availability_zone": "nova",
    "bootable": "false",
    "encrypted": false,
    "created_at": "2021-09-24T05:56:38.000000",
    "description": "test volume02",
    "updated_at": null,
    "volume_type": "__DEFAULT__",
    "name": "testvolume02",
    "replication_status": null,
    "consistencygroup_id": null,
    "source_volid": null,
    "snapshot_id": "09e4c5ae-34b5-473d-9c00-c0c8a2487f95",
    "multiattach": false,
    "metadata": {
      "key01": "value01",
      "key02": "value02"
    },
    "id": "07d20984-5652-437e-89e1-c4df6956c634",
    "size": 10
  }
}
```
```shell
$ openstack volume show 07d20984-5652-437e-89e1-c4df6956c634 -f json | jq
```
```json
{
  "attachments": [],
  "availability_zone": "nova",
  "bootable": "false",
  "consistencygroup_id": null,
  "created_at": "2021-09-24T05:56:38.000000",
  "description": "test volume02",
  "encrypted": false,
  "id": "07d20984-5652-437e-89e1-c4df6956c634",
  "migration_status": null,
  "multiattach": false,
  "name": "testvolume02",
  "os-vol-host-attr:host": "control@rbd-1#rbd-1",
  "os-vol-mig-status-attr:migstat": null,
  "os-vol-mig-status-attr:name_id": null,
  "os-vol-tenant-attr:tenant_id": "d29306a672de404dbcd8731065b521a1",
  "properties": {
    "key01": "value01",
    "key02": "value02"
  },
  "replication_status": null,
  "size": 10,
  "snapshot_id": "09e4c5ae-34b5-473d-9c00-c0c8a2487f95",
  "source_volid": null,
  "status": "available",
  "type": "__DEFAULT__",
  "updated_at": "2021-09-24T05:56:39.000000",
  "user_id": "7ef3adefeecc45868a7f84fbd1a82f22"
}
```
