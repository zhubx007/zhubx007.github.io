---
title: 获取某个 Bucket 下的分片信息
tags:
  - bucket
  - ceph
categories:
  - ceph
abbrlink: 22614
date: 2021-09-14 21:37:18
---

# 获取 bucket id

```console
$ BUCKET_NAME="bucket01"
$ BUCKET_ID=`radosgw-admin bucket stats --bucket=${BUCKET_NAME} | grep -w id | awk -F '"' '{print $4}'`
```

# 查看 bucket.index 中的 omap 信息

```console
$ INDEX_POOL="default.rgw.buckets.index"
$ OBJECT_MAP=".dir.${BUCKET_ID}"
$ rados -p ${INDEX_POOL} listomapkeys ${OBJECT_MAP}
_multipart_software/DingTalk_v4.5.5.18.exe.2~WG7XrXpvoUIfH9a1Sa8cChNsIfRMUNU.1
_multipart_software/DingTalk_v4.5.5.18.exe.2~WG7XrXpvoUIfH9a1Sa8cChNsIfRMUNU.2
_multipart_software/DingTalk_v4.5.5.18.exe.2~WG7XrXpvoUIfH9a1Sa8cChNsIfRMUNU.3
_multipart_software/DingTalk_v4.5.5.18.exe.2~WG7XrXpvoUIfH9a1Sa8cChNsIfRMUNU.4
_multipart_software/DingTalk_v4.5.5.18.exe.2~WG7XrXpvoUIfH9a1Sa8cChNsIfRMUNU.meta
```
