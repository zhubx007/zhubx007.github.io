---
title: CentOS 中使用 kolla-ansible 快速部署 OpenStack All-In-One
date: 2021-09-15 22:44:34
tags:
- centos
- kolla-ansible
- openstack
categories:
- openstack
---

## 准备
___

- 系统：CentOS 7
- 两块网卡：
    - eth0：172.16.140.15   管理网
    - eth1：192.168.1.16    业务网/存储网
- CPU：8C
- 内存：16G
- 系统盘：50G
- Ceph OSD 盘：100G

## 安装
___

`NOTE：整个安装过程，并没有使用 python 虚拟环境。`

### 安装依赖

1. 安装 `python` 构建依赖

    ```shell
    $ sudo yum install python-devel libffi-devel gcc openssl-devel libselinux-python -y
    ```

2. 安装 `pip`

    ```shell
    $ sudo easy_install pip
    $ pip install -U pip
    ```

3. 安装 `ansible >=2.8`

    ```shell
    $ sudo yum install epel-release -y
    $ sudo yum install ansible -y
    ```

### 安装 kolla-ansible

1. 使用 `pip` 安装 `kolla-ansible`

    ```shell
    $ sudo pip install kolla-ansible
    ```

    **如果出现以下情况**

    ![安装kolla-ansible失败](https://zbx-pic.oss-cn-shanghai.aliyuncs.com/iseeyou/20200205200301456.png)

    则需要使用命令 `sudo pip install kolla-ansible -I`

2. 创建 `/etc/kolla` 目录

    ```shell
    $ sudo mkdir -p /etc/kolla
    $ sudo chown $USER:$USER /etc/kolla
    ```

3. 拷贝 `globals.yml` 和 `passwords.yml` 到 `/etc/kolla` 目录下

    ```shell
    $ cp -r /usr/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
    ```

4. 拷贝 `all-in-one` 和 `multinode` 文件到当前目录下

    ```shell
    $ cp /usr/share/kolla-ansible/ansible/inventory/* .
    ```

### 配置 ansible

修改配置文件 **/etc/ansible/ansible.cfg** ，在 **defaults** 段中增加如下内容

```text
[defaults]
host_key_checking=False
pipelining=True
forks=100
```

### 准备初始化配置

`由于安装的All-In-One模式，所以直接使用文件all-in-one即可。`

1. 检查使用文件 `all-in-one` 时，执行 `ansible` 的连通性

    ```shell
    $ ansible -i all-in-one all -m ping
    ```

2. 生成密码

    ```shell
    $ kolla-genpwd
    ```

3. 修改 `/etc/kolla/globals.yml` 配置文件，修改内容如下

    ```text
    kolla_base_distro: "centos"
    kolla_install_type: "binary"
    openstack_release: "train"
    network_interface: "eth0"
    neutron_external_interface: "eth1"
    kolla_internal_vip_address: "172.16.140.15"
    enable_haproxy: "no"
    enable_cinder: "yes"
    enable_ceph: "yes"
    ```

4. 由于使用 `ceph` 作为后端存储，所以在准备阶段，需要额外准备一块磁盘作为 `OSD` ，以下命令是为了在执行 `ansible` 脚本时，能识别此分区作为 `OSD`

    ```shell
    $ DISK=/dev/vdb
    $ parted $DISK -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP_BS 1 -1
    ```

    因为只有一台服务器作为 `All-In-One` 部署，所以对于 `ceph` 的配置需要先做预处理，将 `pool` 的 `size` 置为 1。新建目录 `/etc/kolla/config` ，然后在目录下创建配置文件 `ceph.conf` ，内容如下

    ```text
    [global]
    osd pool default size = 1
    osd pool default min size = 1
    ```

### 开始部署

1. 完成带有 `kolla` 部署依赖的引导服务准备

    ```shell
    $ kolla-ansible -i ./all-in-one bootstrap-servers
    ```

2. 部署前的预检测

    ```shell
    $ kolla-ansible -i ./all-in-one prechecks
    ```

3. 开始部署

    ```shell
    $ kolla-ansible -i ./all-in-one deploy
    ```

## 验证
___

1. 安装 `OpenStack CLI` 客户端

    ```shell
    $ pip install python-openstackclient
    ```

2. 生成 `admin-openrc.sh` 文件

    ```shell
    >> kolla-ansible post-deploy
    ```

    启用环境变量

    ```shell
    $ . /etc/kolla/admin-openrc.sh
    ```

3. 获取 `cirros` 镜像

    ```shell
    $ wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
    ```

    如果没有 `wget` 工具，使用一下命令安装

    ```shell
    $ sudo yum install wget -y
    ```

4. 上传 `cirros` 镜像

    ```shell
    $ openstack image create cirros-0.4.0-x86_64-disk.img --container-format bare --disk-format qcow2 --file cirros-0.4.0-x86_64-disk.img
    ```

    查看上传的镜像

    ```shell
    $ openstack image list
    ```

    ![images列表](https://zbx-pic.oss-cn-shanghai.aliyuncs.com/iseeyou/20200206091856874.png)

5. 创建 `private` 网络

    ```shell
    $ openstack network create private
    $ openstack subnet create net --subnet-range 10.0.0.0/24 --gateway 10.0.0.1 --network 2c428b82-023e-4788-b37a-077e0effd2cc
    ```

6. 创建 `flavor`

    ```shell
    $ openstack flavor create 1C1G10G --id 1 --ram 1024 --disk 10 --vcpus 1
    ```

7. 创建虚拟机

    准备工作完成

    ![ready](https://zbx-pic.oss-cn-shanghai.aliyuncs.com/iseeyou/20200206093551617.png)

    ```shell
    $ openstack server create vm01 --image 46c1d789-f213-4fbd-bc8c-540a4194fab0 --flavor 1 --network 2c428b82-023e-4788-b37a-077e0effd2cc
    ```

    ![servers 列表](https://zbx-pic.oss-cn-shanghai.aliyuncs.com/iseeyou/2020020609392174.png)

    ![虚拟机 console](https://zbx-pic.oss-cn-shanghai.aliyuncs.com/iseeyou/20200206094121956.png)
