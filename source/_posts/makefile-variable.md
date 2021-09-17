---
title: Makefile 中的 Shell 变量设置
tags:
  - linux
  - makefile
categories:
  - linux
abbrlink: 48427
date: 2021-09-17 14:18:34
---

## 错误方式

- 新建一个名为 `Makefile` 的文件，内容如下：

```make
.PHONY: example
example:
	key=1
	echo $$key
```

- 执行命令 `make example`，输出结果如下：

```text
key=1
echo $key

```

- 从上面发现，定义的变量 `key`，在使用 `echo` 输出时，并没有按预期给出值 `1`，这是为什么呢？

**原因：`Makefile` 文件中的 `shell` 定义的变量不支持跨行传递，也就是上面行定义的变量，在换行之后，无法读取。**

> 既然原因找到了，那么正确的方式应该如何呢？参考下面的章节。

## 正确方式

- 将原先 `Makefile` 文件中的内容，修改为如下：

```make
.PHONY: example
example:
	key=1; \
	echo $$key
```

- 执行命令 `make example`，输出结果如下：

```text
key=1;\
echo $key
1
```

- 当然上述也可以将 `shell` 中的放在一行，例如：`key=1; echo $key` 即可
