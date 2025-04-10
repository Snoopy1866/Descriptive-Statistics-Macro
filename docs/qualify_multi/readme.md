## 简介

多组单个定性指标的分析，输出频数、构成比（率）指标。

## 语法

### 必选参数

- [indata](#indata)
- [var](#var)
- [group](#group)

### 可选参数

- [groupby](#groupby)
- [by](#by)
- [uid](#uid)
- [pattern](#pattern)
- [missing](#missing)
- [missing_note](#missing_note)
- [missing_position](#missing_position)
- [outdata](#outdata)
- [stat_format](#stat_format)
- [label](#label)
- [indent](#indent)
- [suffix](#suffix)

### 调试参数

- [debug](#debug)

## 参数说明

### indata

用法同 [indata](../qualify/readme.md#indata)。

---

### var

用法同 [var](../qualify/readme.md#var)。

---

### group

**Syntax** :

- _variable_
- _variable_("_category-1_"<, "_category-2_", ...>)

指定分组变量，_`category`_ 表示需要统计的分组水平名称。

> [!WARNING]
>
> - 参数 `group` 不允许指定不存在于参数 [indata](#indata) 指定的数据集中的变量；
> - 参数 `group` 不允许指定数值型变量；

**Usage** :

```sas
group = arm
group = arm("试验组", "对照组")
```

[**Example**](#指定分组变量的水平名称)

---

### groupby

**Syntax** :

- _variable_<(asc\<ending\> | desc\<ending\>)>
- _format_<(asc\<ending\> | desc\<ending\>)>

指定各分组在输出数据集中的排列顺序依据。

**Default** : `#auto`

默认情况下，各个分组的输出结果根据分组水平名称在当前语言环境下的默认排列顺序排序（例如：gbk 环境下，按照水平名称的汉语拼音顺序）

> [!IMPORTANT]
>
> - 若参数 `groupby` 指定了基于某个输出格式进行排序，则该格式必须是 `catalog-based`，即在 `dictionary.formats` 表中，变量 `source` 的值应当是 `C`。
> - 当指定一个输出格式作为排序依据时，该输出格式应当使用 `value` 语句生成，例如：
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
groupby = armn(desc)
groupby = armn.
```

[**Example**](#指定分组变量的排序变量)

---

### by

用法同 [by](../qualify/readme.md#by)。

---

### uid

用法同 [uid](../qualify/readme.md#uid)。

---

### pattern

用法同 [pattern](../qualify/readme.md#pattern)。

---

### missing

用法同 [missing](../qualify/readme.md#missing)。

---

### missing_note

用法同 [missing_note](../qualify/readme.md#missing_note)。

---

### missing_position

用法同 [missing_position](../qualify/readme.md#missing_position)。

---

### outdata

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定统计结果输出的数据集，可包含数据集选项，用法同参数 [indata](#indata)。

输出数据集有 $9(m + 1) + 2$ 个变量，其中 $m$ 为参数 [group](#group) 指定的分组变量的水平数，具体如下：

| 变量名              | 含义                                                                         |
| ------------------- | ---------------------------------------------------------------------------- |
| `idt`               | 缩进标识（_indent identifier_）                                              |
| `seq`               | 行号                                                                         |
| `item`              | 指标名称                                                                     |
| `value_`_`i`_       | `group` 的第 _i_ 个水平的统计量在 [pattern](#pattern) 指定的模式下的格式化值 |
| `freq_`_`i`_        | `group` 的第 _i_ 个水平的频数                                                |
| `freq_`_`i`_`_fmt`  | `group` 的第 _i_ 个水平的频数格式化值                                        |
| `times_`_`i`_       | `group` 的第 _i_ 个水平的频次                                                |
| `times_`_`i`_`_fmt` | `group` 的第 _i_ 个水平的频次格式化值                                        |
| `rate_`_`i`_        | `group` 的第 _i_ 个水平的频率                                                |
| `rate_`_`i`_`_fmt`  | `group` 的第 _i_ 个水平的频率格式化值                                        |
| `value_sum`         | `group` 的所有水平合计的统计量在 [pattern](#pattern) 指定的模式下的格式化值  |
| `freq_sum`          | `group` 的所有水平合计的频数                                                 |
| `freq_sum_fmt`      | `group` 的所有水平合计的频数格式化值                                         |
| `times_sum`         | `group` 的所有水平合计的频次                                                 |
| `times_sum_fmt`     | `group` 的所有水平合计的频次格式化值                                         |
| `rate_sum`          | `group` 的所有水平合计的频率                                                 |
| `rate_sum_fmt`      | `group` 的所有水平合计的频率格式化值                                         |

其中，变量 `item`、`value_`_`i`_、`value_sum` 默认输出到 `outdata` 指定的数据集中，其余变量默认隐藏。

> [!NOTE]
>
> - 当 `group` 的水平数量为 1 时，变量 `value_sum` 默认隐藏。

**Default** : `res_`_`var`_

默认情况下，输出数据集的名称为 `res_`_`var`_，其中 `var` 为参数 [var](#var) 指定的变量名。

> [!TIP]
>
> - 如需显示隐藏的变量，可使用数据集选项实现，例如：`outdata = t1(keep = seq item value_1 value_2 value_sum times_1 times_2 times_sum)`

**Usage** :

```sas
outdata = t1
outdata = t1(keep = seq item value_1 value_2 value_sum times_1 times_2 times_sum)
```

---

### stat_format

用法同 [stat_format](../qualify/readme.md#stat_format)。

---

### label

用法同 [label](../qualify/readme.md#label)。

---

### indent

用法同 [indent](../qualify/readme.md#indent)。

---

### suffix

用法同 [suffix](../qualify/readme.md#suffix)。

---

### debug

**Syntax** : `true` | `false`

指定是否删除宏程序运行过程生成的中间数据集。

**Default** : `false`

默认情况下，宏程序会自动删除运行过程生成的中间数据集。

> [!NOTE]
>
> - 此参数用于开发者调试，一般无需关注。
> - 本宏程序内部调用的依赖宏程序 `%qualify` 运行过程中生成的中间数据集无法通过此参数控制，在退出 `%qualify` 时，这些中间数据集默认被删除，如需单独调试宏程序 `%qualify`，请单独调用 `%qualify` 并指定 `debug = true`。

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
