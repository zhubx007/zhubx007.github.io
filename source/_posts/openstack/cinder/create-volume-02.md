---
title: 创建云硬盘（02）
date: 2021-09-18 17:30:15
tags:
- cinder
- openstack
categories:
- openstack
---

**非概念型介绍，而是通过命令行或者 RESTful API 进行实际操作讲解。**

**本文主要介绍从镜像创建云硬盘。**

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
- --image: 镜像名称或者 ID
- --description: 描述信息
- --availability-zone: 目标 AZ
- --property: 设置云硬盘属性，可以使用多次 `--property` 进行多个设置

### 执行命令

```shell
$ source /etc/kolla/admin-openrc.sh
$ VOLUME_TYPE_NAME="__DEFAULT__"
$ IMAGE_NAME="cirros"
$ openstack volume create testvolume01 --size 10 --type ${VOLUME_TYPE_NAME} --image ${IMAGE_NAME} --description "test volume01" --availability-zone nova --property key01=value01 --property key02=value02
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| attachments         | []                                   |
| availability_zone   | nova                                 |
| bootable            | false                                |
| consistencygroup_id | None                                 |
| created_at          | 2021-09-18T10:09:02.000000           |
| description         | test volume01                        |
| encrypted           | False                                |
| id                  | 33461e06-28d1-4a8f-8c6b-09b6e1ade56f |
| migration_status    | None                                 |
| multiattach         | False                                |
| name                | testvolume01                         |
| properties          | key01='value01', key02='value02'     |
| replication_status  | None                                 |
| size                | 10                                   |
| snapshot_id         | None                                 |
| source_volid        | None                                 |
| status              | creating                             |
| type                | __DEFAULT__                          |
| updated_at          | None                                 |
| user_id             | 25a3a9d49b914af087aee7b56e2b9d37     |
+---------------------+--------------------------------------+
$ openstack volume show 33461e06-28d1-4a8f-8c6b-09b6e1ade56f -f json | jq
```
```json
{
  "attachments": [],
  "availability_zone": "nova",
  "bootable": "true",
  "consistencygroup_id": null,
  "created_at": "2021-09-18T10:09:02.000000",
  "description": "test volume01",
  "encrypted": false,
  "id": "33461e06-28d1-4a8f-8c6b-09b6e1ade56f",
  "migration_status": null,
  "multiattach": false,
  "name": "testvolume01",
  "os-vol-host-attr:host": "control@rbd-1#rbd-1",
  "os-vol-mig-status-attr:migstat": null,
  "os-vol-mig-status-attr:name_id": null,
  "os-vol-tenant-attr:tenant_id": "3413e9d2302b44058f264258ea0ec41e",
  "properties": {
    "key01": "value01",
    "key02": "value02"
  },
  "replication_status": null,
  "size": 10,
  "snapshot_id": null,
  "source_volid": null,
  "status": "available",
  "type": "__DEFAULT__",
  "updated_at": "2021-09-18T10:09:04.000000",
  "user_id": "25a3a9d49b914af087aee7b56e2b9d37",
  "volume_image_metadata": {
    "container_format": "bare",
    "hw_qemu_guest_agent": "no",
    "owner_specified.openstack.sha256": "63c6e014a024dcc20ec66d11ecbd6c36dd609ff3b6dfaa05cf7d4502614a6923",
    "image_name": "cirros",
    "image_id": "4dea6e72-1abf-44a5-87f9-64d3b4172bef",
    "min_disk": "0",
    "usage_type": "common",
    "size": "41126400",
    "os_distro": "others",
    "image_type": "image",
    "checksum": "56730d3091a764d5f8b38feeef0bfcef",
    "disk_format": "raw",
    "os_admin_user": "root",
    "owner_specified.openstack.md5": "56730d3091a764d5f8b38feeef0bfcef",
    "owner_specified.openstack.object": "images/cirros",
    "min_ram": "0"
  }
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
        "imageRef": "",
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
$ IMAGE_NAME="cirros"
$ IMAGE_ID=`openstack image show ${IMAGE_NAME} -f value -c id`
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
        \"imageRef\": \"${IMAGE_ID}\",
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
    "user_id": "25a3a9d49b914af087aee7b56e2b9d37",
    "attachments": [],
    "links": [
      {
        "href": "http://172.20.154.249:8776/v3/3413e9d2302b44058f264258ea0ec41e/volumes/c9ad8365-fa2a-4dbc-9f1c-6ffad2a58550",
        "rel": "self"
      },
      {
        "href": "http://172.20.154.249:8776/3413e9d2302b44058f264258ea0ec41e/volumes/c9ad8365-fa2a-4dbc-9f1c-6ffad2a58550",
        "rel": "bookmark"
      }
    ],
    "availability_zone": "nova",
    "bootable": "false",
    "encrypted": false,
    "created_at": "2021-09-18T10:11:01.000000",
    "description": "test volume02",
    "updated_at": null,
    "volume_type": "__DEFAULT__",
    "name": "testvolume02",
    "replication_status": null,
    "consistencygroup_id": null,
    "source_volid": null,
    "snapshot_id": null,
    "multiattach": false,
    "metadata": {
      "key01": "value01",
      "key02": "value02"
    },
    "id": "c9ad8365-fa2a-4dbc-9f1c-6ffad2a58550",
    "size": 10
  }
}
```
```shell
$ openstack volume show c9ad8365-fa2a-4dbc-9f1c-6ffad2a58550 -f json | jq
```
```json
{
  "attachments": [],
  "availability_zone": "nova",
  "bootable": "true",
  "consistencygroup_id": null,
  "created_at": "2021-09-18T10:11:01.000000",
  "description": "test volume02",
  "encrypted": false,
  "id": "c9ad8365-fa2a-4dbc-9f1c-6ffad2a58550",
  "migration_status": null,
  "multiattach": false,
  "name": "testvolume02",
  "os-vol-host-attr:host": "control@rbd-1#rbd-1",
  "os-vol-mig-status-attr:migstat": null,
  "os-vol-mig-status-attr:name_id": null,
  "os-vol-tenant-attr:tenant_id": "3413e9d2302b44058f264258ea0ec41e",
  "properties": {
    "key01": "value01",
    "key02": "value02"
  },
  "replication_status": null,
  "size": 10,
  "snapshot_id": null,
  "source_volid": null,
  "status": "available",
  "type": "__DEFAULT__",
  "updated_at": "2021-09-18T10:11:02.000000",
  "user_id": "25a3a9d49b914af087aee7b56e2b9d37",
  "volume_image_metadata": {
    "container_format": "bare",
    "hw_qemu_guest_agent": "no",
    "owner_specified.openstack.sha256": "63c6e014a024dcc20ec66d11ecbd6c36dd609ff3b6dfaa05cf7d4502614a6923",
    "image_name": "cirros",
    "image_id": "4dea6e72-1abf-44a5-87f9-64d3b4172bef",
    "min_disk": "0",
    "usage_type": "common",
    "size": "41126400",
    "os_distro": "others",
    "image_type": "image",
    "checksum": "56730d3091a764d5f8b38feeef0bfcef",
    "disk_format": "raw",
    "os_admin_user": "root",
    "owner_specified.openstack.md5": "56730d3091a764d5f8b38feeef0bfcef",
    "owner_specified.openstack.object": "images/cirros",
    "min_ram": "0"
  }
}
```
