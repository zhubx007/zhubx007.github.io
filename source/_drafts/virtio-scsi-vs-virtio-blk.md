---
title:  Virtio-SCSI VS Virtio-BLK
tags:
---

## Virtio-SCSI

### 简介

Virtio-SCSI 是一种新的半虚拟化 SCSI 控制器。它是 KVM 虚拟机存储堆栈替代 Virtio-BLK 并改进其功能的替代方案。它提供与 Virtio-SCSI 相同的性能，并增加了一下的优势：

- 改进扩展性：虚拟机可以连接到更多的存储设备（Virtio-SCSI 可以处理每个虚拟 SCSI 适配器的多个设备）。
- 标准指令集：Virtio-SCSI 使用标准 SCSI 命令集，简化了新功能的添加。
- 标准设备名：Virtio-SCSI 磁盘使用与裸机系统相同的路径。简化了物理机到虚拟机和虚拟机到虚拟机的迁移。
- SCSI 设备直通：Virtio-SCSI 可以将物理存储设备直接呈现给 Guest。


## Virtio-BLK

### 简介

## 


参考文献：

- https://www.ovirt.org/develop/release-management/features/storage/virtio-scsi.html
- https://www.qemu.org/2021/01/19/virtio-blk-scsi-configuration/
