## 简介

多组单个定性指标的分析，输出频数、频率等指标，并进行卡方检验或 Fisher 精确检验。

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
- [PROCHTTP_PROXY](#prochttp_proxy)

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

用法同 [GROUP](../qualify_multi/readme.md#group)

---

### GROUPBY

用法同 [GROUPBY](../qualify_multi/readme.md#groupby)

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

用法同 [OUTDATA](../qualify_multi/readme.md#outdata)。

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

### CHISQ_NOTE

**Syntax** : _string_

指定输出结果中卡方检验方法显示的字符串，该字符串必须使用匹配的单（双）引号包围。

> [!NOTE]
>
> 该选项仅在使用卡方检验时生效。

**Default** : `"卡方检验"`

**Usage** :

```sas
CHISQ_NOTE = "χ\super 2 \nosupersub 检验"
```

### FISHER_NOTE

**Syntax** : _string_

指定输出结果中 Fisher 精确检验方法显示的字符串，该字符串必须使用匹配的单（双）引号包围。

> [!NOTE]
>
> 该选项仅在使用 Fisher 精确检验时生效。

**Default** : `"Fisher精确检验"`

**Usage** :

```sas
FISHER_NOTE = "Fisher"
```

### FISHER_STAT_PH

**Syntax** : _string_

指定输出结果中 Fisher 精确检验统计量显示的占位字符串，该字符串必须使用匹配的单（双）引号包围。

> [!NOTE]
>
> 该选项仅在使用 Fisher 精确检验时生效。

**Default** : `""`

**Usage** :

```sas
FISHER_STAT_PH = "-"
```

### PROCHTTP_PROXY

用法同 [PROCHTTP_PROXY](../qualify_multi/readme.md#prochttp_proxy)。

---

### DEL_TEMP_DATA

**Syntax** : TRUE | FALSE

指定是否删除宏程序运行过程生成的中间数据集。

**Default** : TRUE

默认情况下，宏程序会自动删除运行过程生成的中间数据集。

> [!NOTE]
>
> - 此参数用于开发者调试，一般无需关注。
> - 本宏程序内部调用的依赖宏程序 `%qualify_multi` 运行过程中生成的中间数据集无法通过此参数控制，在退出 `%qualify_multi` 时，这些中间数据集默认被删除，如需单独调试宏程序 `%qualify_multi`，请单独调用 `%qualify_multi` 并指定 `DEL_TEMP_DATA = FALSE`。

---

## 例子

### 打开帮助文档

```sas
%qualify_multi_test();
%qualify_multi_test(help);
```

### 一般用法

```sas
%qualify_multi_test(indata = adam.adsl(where = (fasfl = "Y")), var = sex, group = arm, groupby = armn);
```

![](./assets/example-regular.png)
