## 简介

多组单个定性指标的分析，输出频数、构成比（率）指标。

## 语法

### 必选参数

- [INDATA](#indata)
- [VAR](#var)
- [GROUP](#group)

### 可选参数

- [GROUPBY](#groupby)
- [BY](#by)
- [UID](#uid)
- [PATTERN](#pattern)
- [MISSING](#missing)
- [MISSING_NOTE](#missing_note)
- [MISSING_POSITION](#missing_position)
- [OUTDATA](#outdata)
- [STAT_FORMAT](#stat_format)
- [LABEL](#label)
- [INDENT](#indent)
- [SUFFIX](#suffix)

### 调试参数

- [debug](#debug)

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

> [!WARNING]
>
> - 参数 `GROUP` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
> - 参数 `GROUP` 不允许指定数值型变量；

**Usage** :

```sas
GROUP = ARM
GROUP = ARM("试验组", "对照组")
```

[**Example**](#指定分组变量的水平名称)

---

### GROUPBY

**Syntax** :

- _variable_<(ASC\<ENDING\> | DESC\<ENDING\>)>
- _format_<(ASC\<ENDING\> | DESC\<ENDING\>)>

指定各分组在输出数据集中的排列顺序依据。

**Default** : #AUTO

默认情况下，各个分组的输出结果根据分组水平名称在当前语言环境下的默认排列顺序排序（例如：gbk 环境下，按照水平名称的汉语拼音顺序）

> [!IMPORTANT]
>
> - 若参数 `GROUPBY` 指定了基于某个输出格式进行排序，则该格式必须是 CATALOG-BASED，即在 `DICTIONARY.FORMATS` 表中，变量 `source` 的值应当是 `C`。
> - 当指定一个输出格式作为排序依据时，该输出格式应当使用 `VALUE` 语句生成，例如：
>
>   ```sas
>   proc format;
>       value armn
>           1 = "试验组"
>           2 = "对照组";
>   run;
>   ```
>
>   宏程序将根据格式化之前的数值对各分类进行排序。

**Usage** :

```sas
GROUPBY = ARMN(desc)
GROUPBY = ARMN.
```

[**Example**](#指定分组变量的排序变量)

---

### BY

用法同 [BY](../qualify/readme.md#by)。

---

### UID

用法同 [UID](../qualify/readme.md#uid)。

---

### PATTERN

用法同 [PATTERN](../qualify/readme.md#pattern)。

---

### MISSING

用法同 [MISSING](../qualify/readme.md#missing)。

---

### MISSING_NOTE

用法同 [MISSING_NOTE](../qualify/readme.md#missing_note)。

---

### MISSING_POSITION

用法同 [MISSING_POSITION](../qualify/readme.md#missing_position)。

---

### OUTDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定统计结果输出的数据集，可包含数据集选项，用法同参数 [INDATA](#indata)。

输出数据集有 9(_m_ + 1) + 2 个变量，其中 _m_ 为参数 GROUP 指定的分组变量的水平数，具体如下：

| 变量名                                         | 含义                                                                   |
| ---------------------------------------------- | ---------------------------------------------------------------------- |
| IDT                                            | 缩进标识（_indent identifier_）                                        |
| SEQ                                            | 行号                                                                   |
| ITEM                                           | 指标名称                                                               |
| VALUE\__i_                                     | 统计量在 [PATTERN](#pattern) 指定的模式下的值（GROUP 的第 _i_ 个水平） |
| FREQ\__i_                                      | 频数（GROUP 的第 _i_ 个水平）                                          |
| FREQ\__i_\_FMT                                 | 频数格式化值（GROUP 的第 _i_ 个水平）                                  |
| <font color=red>N\__i_<sup>1</sup></font>      | 频数（GROUP 的第 _i_ 个水平）                                          |
| <font color=red>N\__i_\_FMT<sup>1</sup></font> | 频数格式化值（GROUP 的第 _i_ 个水平）                                  |
| TIMES\__i_                                     | 频次（GROUP 的第 _i_ 个水平）                                          |
| TIMES\__i_\_FMT                                | 频次格式化值（GROUP 的第 _i_ 个水平）                                  |
| RATE\__i_                                      | 频率（GROUP 的第 _i_ 个水平）                                          |
| RATE\__i_\_FMT                                 | 频率格式化值（GROUP 的第 _i_ 个水平）                                  |
| VALUE_SUM                                      | 统计量在 [PATTERN](#pattern) 指定的模式下的值（GROUP 的所有水平合计）  |
| FREQ_SUM                                       | 频数（GROUP 的所有水平合计）                                           |
| FREQ_SUM_FMT                                   | 频数格式化值（GROUP 的所有水平合计）                                   |
| <font color=red>N_SUM<sup>1</sup></font>       | 频数（GROUP 的所有水平合计）                                           |
| <font color=red>N_SUM_FMT<sup>1</sup></font>   | 频数格式化值（GROUP 的所有水平合计）                                   |
| TIMES_SUM                                      | 频次（GROUP 的所有水平合计）                                           |
| TIMES_SUM_FMT                                  | 频次格式化值（GROUP 的所有水平合计）                                   |
| RATE_SUM                                       | 频率（GROUP 的所有水平合计）                                           |
| RATE_SUM_FMT                                   | 频率格式化值（GROUP 的所有水平合计）                                   |

> [!IMPORTANT]
>
> - <sup>1</sup> 建议改用 `FREQ_`_`i`_, `FREQ_`_`i`_`_FMT`, `FREQ_SUM`, `FREQ_SUM_FMT`，保留 `N_`_`i`_, `N_`_`i`_`_FMT`, `N_SUM`, `N_SUM_FMT` 仅为兼容旧版本程序，未来的版本 (_v1.5+_) 可能不受支持；

其中，变量 `ITEM`、`VALUE_`_`i`_、`VALUE_SUM` 默认输出到 `OUTDATA` 指定的数据集中，其余变量默认隐藏。

> [!NOTE]
>
> - 当 GROUP 的水平数量为 1 时，变量 `VALUE_SUM` 默认隐藏。

**Default** : RES\_&_VAR_

默认情况下，输出数据集的名称为 `RES_`_`var`_，其中 `var` 为参数 [VAR](#var) 指定的变量名。

> [!TIP]
>
> - 如需显示隐藏的变量，可使用数据集选项实现，例如：`OUTDATA = T1(KEEP = SEQ ITEM VALUE_1 VALUE_2 VALUE_SUM TIMES_1 TIMES_2 TIMES_SUM)`

**Usage** :

```sas
OUTDATA = T1
OUTDATA = T1(KEEP = SEQ ITEM VALUE_1 VALUE_2 VALUE_SUM TIMES_1 TIMES_2 TIMES_SUM)
```

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

### SUFFIX

用法同 [SUFFIX](../qualify/readme.md#suffix)。

---

### PROCHTTP_PROXY

**Syntax** : _host_:_port_

指定代理主机和端口。

本宏程序将自动检查前置依赖程序是否已经导入，若发现前置依赖程序未导入，则尝试从网络上下载最新版本程序文件，使用此参数可指定网络连接使用的代理主机和端口。

**Default** : 127.0.0.1:7890

---

### debug

**Syntax** : TRUE | FALSE

指定是否删除宏程序运行过程生成的中间数据集。

**Default** : TRUE

默认情况下，宏程序会自动删除运行过程生成的中间数据集。

> [!NOTE]
>
> - 此参数用于开发者调试，一般无需关注。
> - 本宏程序内部调用的依赖宏程序 `%qualify` 运行过程中生成的中间数据集无法通过此参数控制，在退出 `%qualify` 时，这些中间数据集默认被删除，如需单独调试宏程序 `%qualify`，请单独调用 `%qualify` 并指定 `debug = FALSE`。

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
