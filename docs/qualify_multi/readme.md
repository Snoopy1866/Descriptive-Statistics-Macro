## 简介

多组单个定性指标的分析，输出频数、构成比（率）指标。

## 语法

### 必选参数

- [INDATA](#indata)
- [VAR](#var)
- [GROUP](#group)

### 可选参数

- [GROUPBY](#groupby)
- [PATTERN](#pattern)
- [BY](#by)
- [OUTDATA](#outdata)
- [STAT_FORMAT](#stat_format)
- [LABEL](#label)
- [INDENT](#indent)

### 调试参数

- [DEL_TEMP_DATA](#del_temp_data)

## 参数说明

### INDATA

用法同 [INDATA](../qualify/readme.md#indata)。

---

### VAR

用法同 [VAR](../qualify/readme.md#var)。

---

### GROUP

**Syntax** :

- _variable_
- _variable_("_category-1_"<, "_category-2_", ...>)

指定分组变量，_`category`_ 表示需要统计的分组水平名称。

**Caution** :

1. 参数 `GROUP` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
2. 参数 `GROUP` 不允许指定数值型变量；

**Example** :

```sas
GROUP = ARM
GROUP = ARM("试验组", "对照组")
```

---

### GROUPBY

**Syntax** : _variable_<(ASC\<ENDING\>|DESC\<ENDING\>)>

指定分组变量的排序

**Default** : #AUTO

默认情况下，各个分组的输出结果根据分组水平名称在当前语言环境下的默认排列顺序排序（例如：gbk 环境下，按照水平名称的汉语拼音顺序）

**Caution** :

1. 参数 `GROUPBY` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
2. 参数 `GROUP` 若指定了分组变量的各水平名称，则各水平分组的统计结果将按照参数 `GROUP` 中各水平名称指定的顺序显示在输出数据集中，此时参数 `GROUPBY` 无效。

**Example** :

```sas
GROUPBY = ARMN
```

---

### OUTDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定统计结果输出的数据集，可包含数据集选项，用法同参数 [INDATA](#indata)。

输出数据集有 5(_m_ + 1) + 2 个变量，其中 _m_ 为参数 GROUP 指定的分组变量的水平数，具体如下：

| 变量名         | 含义                                                                   |
| -------------- | ---------------------------------------------------------------------- |
| SEQ            | 行号                                                                   |
| ITEM           | 指标名称                                                               |
| VALUE\__i_     | 统计量在 [PATTERN](#pattern) 指定的模式下的值（GROUP 的第 _i_ 个水平） |
| N\__i_         | 频数（GROUP 的第 _i_ 个水平）                                          |
| N\__i_\_FMT    | 频数格式化值（GROUP 的第 _i_ 个水平）                                  |
| RATE\__i_      | 频率（GROUP 的第 _i_ 个水平）                                          |
| RATE\__i_\_FMT | 频率格式化值（GROUP 的第 _i_ 个水平）                                  |
| VALUE_SUM      | 统计量在 [PATTERN](#pattern) 指定的模式下的值（GROUP 的所有水平合计）  |
| N_SUM          | 频数（GROUP 的所有水平合计）                                           |
| N_SUM_FMT      | 频数格式化值（GROUP 的所有水平合计）                                   |
| RATE_SUM       | 频率（GROUP 的所有水平合计）                                           |
| RATE_SUM_FMT   | 频率格式化值（GROUP 的所有水平合计）                                   |

其中，变量 `ITEM`、`VALUE_`_`i`_、`VALUE_SUM` 默认输出到 `OUTDATA` 指定的数据集中，其余变量默认隐藏。

⚠ 当 GROUP 的水平数量为 1 时，变量 `VALUE_SUM` 默认隐藏。

**Default** : RES\_&_VAR_

默认情况下，输出数据集的名称为 `RES_`_`var`_，其中 `var` 为参数 [VAR](#var) 指定的变量名。

**Tips** :

如需显示隐藏的变量，可使用数据集选项实现，例如：`OUTDATA = T1(KEEP = SEQ ITEM VALUE_1 VALUE_2 VALUE_SUM)`

**Example** :

```sas
OUTDATA = T1
OUTDATA = T1(KEEP = SEQ ITEM VALUE_1 VALUE_2 VALUE_SUM)
```

---

### PATTERN

用法同 [PATTERN](../qualify/readme.md#pattern)。

---

### BY

用法同 [BY](../qualify/readme.md#by)。

---

### STAT_FORMAT

用法同 [STAT_FORMAT](../qualify/readme.md#stat_format)。

---

### LABEL

用法同 [LABEL](../qualify/readme.md#label)。

---

### INDENT

用法同 [INDENT](../qualify/readme.md#indent)。

---

### DEL_TEMP_DATA

**Syntax** : TRUE|FALSE

指定是否删除宏程序运行过程生成的中间数据集。

**Default** : TRUE

默认情况下，宏程序会自动删除运行过程生成的中间数据集。

⚠ 此参数用于开发者调试，一般无需关注。

⚠ 本宏程序内部调用的依赖宏程序 `%qualify` 运行过程中生成的中间数据集无法通过此参数控制，在退出 `%qualify` 时，这些中间数据集默认被删除，如需单独调试宏程序 `%qualify`，请单独调用 `%qualify` 并指定 `DEL_TEMP_DATA = FALSE`。

---

## 例子

### 打开帮助文档

```sas
%qualify_multi();
%qualify_multi(help);
```

### 一般用法

```sas
%qualify_multi(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig, by = clsig., group = arm);
```

![](./assets/example-regular.png)

### 指定分组变量的水平名称

```sas
%qualify_multi(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig, by = clsig., group = arm("试验组"));
```

![](./assets/example-group-level.png)

### 指定分组变量的排序变量

```sas
%qualify_multi(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig, by = clsig., group = arm, groupby = armn);
```

![](./assets/example-groupby.png)
