## 简介

多组单个定量指标的分析，输出均值、中位数、标准差、最大值、最小值、Q1、Q3 等指标。

## 语法

### 必选参数

- [INDATA](#indata)
- [VAR](#var)
- [GROUP](#group)

### 可选参数

- [GROUPBY](#groupby)
- [PATTERN](#pattern)
- [OUTDATA](#outdata)
- [STAT_FORMAT](#stat_format)
- [STAT_NOTE](#stat_note)
- [LABEL](#label)
- [INDENT](#indent)
- [PROCHTTP_PROXY](#prochttp_proxy)

### 调试参数

- [DEL_TEMP_DATA](#del_temp_data)

## 参数说明

### INDATA

用法同 [INDATA](../quantify/readme.md#indata)。

---

### VAR

用法同 [VAR](../quantify/readme.md#var)。

---

### GROUP

**Syntax** :

- _variable_
- _variable_("_category-1_"<, "_category-2_", ...>)

指定分组变量，_`category`_ 表示需要统计的分组水平名称。

**Caution** :

1. 参数 `GROUP` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
2. 参数 `GROUP` 不允许指定数值型变量；

**Usage** :

```sas
GROUP = ARM
GROUP = ARM("试验组", "对照组")
```

[**Example**](#指定分组变量的水平名称)

---

### GROUPBY

**Syntax** : _variable_<(ASC\<ENDING\>|DESC\<ENDING\>)>

指定分组变量的排序

**Default** : #AUTO

默认情况下，各个分组的输出结果根据分组水平名称在当前语言环境下的默认排列顺序排序（例如：gbk 环境下，按照水平名称的汉语拼音顺序）

**Caution** :

1. 参数 `GROUPBY` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
2. 参数 `GROUP` 若指定了分组变量的各水平名称，则各水平分组的统计结果将按照参数 `GROUP` 中各水平名称指定的顺序显示在输出数据集中，此时参数 `GROUPBY` 无效。

**Usage** :

```sas
GROUPBY = ARMN
```

[**Example**](#指定分组变量的排序变量)

---

### OUTDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定统计结果输出的数据集，可包含数据集选项，用法同参数 [INDATA](#indata)。

输出数据集有 _m_ + 3 个变量，其中 _m_ 为参数 GROUP 指定的分组变量的水平数，具体如下：

| 变量名     | 含义                                                                   |
| ---------- | ---------------------------------------------------------------------- |
| SEQ        | 行号                                                                   |
| ITEM       | 指标名称                                                               |
| VALUE\__i_ | 统计量在 [PATTERN](#pattern) 指定的模式下的值（GROUP 的第 _i_ 个水平） |
| VALUE_SUM  | 统计量在 [PATTERN](#pattern) 指定的模式下的值（GROUP 的所有水平合计）  |

其中，变量 `ITEM`、`VALUE_`_`i`_、`VALUE_SUM` 默认输出到 `OUTDATA` 指定的数据集中，其余变量默认隐藏。

⚠ 当 GROUP 的水平数量为 1 时，变量 VALUE_SUM 默认隐藏。

**Default** : RES\_&_VAR_

默认情况下，输出数据集的名称为 `RES_`_`var`_，其中 `var` 为参数 [VAR](#var) 指定的变量名。

**Tips** :

如需显示隐藏的变量，可使用数据集选项实现，例如：`OUTDATA = T1(KEEP = SEQ ITEM VALUE_1 VALUE_2 VALUE_SUM)`

**Usage** :

```sas
OUTDATA = T1
OUTDATA = T1(KEEP = SEQ ITEM VALUE_1 VALUE_2 VALUE_SUM)
```

---

### PATTERN

用法同 [PATTERN](../quantify/readme.md#pattern)。

---

### STAT_FORMAT

用法同 [STAT_FORMAT](../quantify/readme.md#stat_format)。

---

### STAT_NOTE

用法同 [STAT_NOTE](../quantify/readme.md#stat_note)。

---

### LABEL

用法同 [LABEL](../quantify/readme.md#label)。

---

### INDENT

用法同 [INDENT](../quantify/readme.md#indent)。

---

### PROCHTTP_PROXY

**Syntax** : _host_:_port_

指定代理主机和端口。

本宏程序将自动检查前置依赖程序是否已经导入，若发现前置依赖程序未导入，则尝试从网络上下载最新版本程序文件，使用此参数可指定网络连接使用的代理主机和端口。

**Default** : 127.0.0.1:7890

---

### DEL_TEMP_DATA

**Syntax** : TRUE|FALSE

指定是否删除宏程序运行过程生成的中间数据集。

**Default** : TRUE

默认情况下，宏程序会自动删除运行过程生成的中间数据集。

⚠ 此参数用于开发者调试，一般无需关注。

⚠ 本宏程序内部调用的依赖宏程序 `%quantify` 运行过程中生成的中间数据集无法通过此参数控制，在退出 `%quantify` 时，这些中间数据集默认被删除，如需单独调试宏程序 `%quantify`，请单独调用 `%quantify` 并指定 `DEL_TEMP_DATA = FALSE`。

---

## 例子

### 打开帮助文档

```sas
%quantify_multi();
%quantify_multi(help);
```

### 一般用法

```sas
%quantify_multi(indata = adam.adsl(where = (FASFL = "Y")), var = age, group = arm);
```

![](./assets/example-regular.png)

### 指定分组变量的水平名称

```sas
%quantify_multi(indata = adam.adsl(where = (FASFL = "Y")), var = age, group = arm("对照组"));
```

![](./assets/example-group-level.png)

### 指定分组变量的排序变量

```sas
%quantify_multi(indata = adam.adsl(where = (FASFL = "Y")), var = age, group = arm, groupby = armn);
```

![](./assets/example-groupby.png)
