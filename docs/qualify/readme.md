## 简介

单组单个定性指标的分析，输出频数、构成比（率）指标。

## 语法

### 必选参数

- [INDATA](#indata)
- [VAR](#var)

### 可选参数

- [PATTERN]()
- [BY]()
- [OUTDATA]()
- [STAT_FORMAT]()
- [LABEL]()
- [INDENT]()

## 参数说明

### INDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定用于定性分析的数据集，可包含数据集选项

_libname_: 数据集所在的逻辑库名称

_dataset_: 数据集名称

_dataset-options_: 数据集选项，兼容 SAS 系统支持的所有数据集选项

**Example** :

```sas
- INDATA = ADSL
- INDATA = SHKY.ADSL
- INDATA = SHKY.ADSL(where = (FAS = "Y"))
```

---

### VAR

**Syntax** :

- _variable_
- _variable_("_category-1_" <"_category-2_" ...>)
- _variable_("_category-1_" <= "_note-1_"> <"_category-2_" <= "_note-2_">>)

指定定性分析的变量，_`category`_ 表示需要统计的分类名称，_`note`_ 表示该分类在输出数据集中的展示名称（可以与分类名称不同）。

**Caution** :

1. 参数 `VAR` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
2. 参数 `VAR` 不允许指定数值型变量；

**Tips** :

1. 参数 `VAR` 可以指定空字符串作为一个分类，在这种情况下，宏程序将计算缺失分类的频数，例如：`VAR = SEX("" = "缺失" "男" "女")`；

**Example** :

```sas
VAR = SEX
VAR = SEX("男" "女")
VAR = SEX("" = "Missing" "男" = "Male" "女" = "Female")
```

---

### PATTERN

**Syntax** : <_string(s)_>#_statistic-keyword-1_<_string(s)_><#_statistic-keyword-2_<_string(s)_>>

指定需计算的统计量及统计量的输出模式，输出模式定义了统计量是如何进行组合的，以及统计量在输出数据集中的位置。

其中，_`statistic-keyword`_ 可以指定以下统计量：

| 统计量 | 含义         |
| ------ | ------------ |
| RATE   | 构成比（率） |
| N      | 频数         |

_`string(s)`_ 可以是任意字符（串），若字符串含有字符 `#`，则使用 `##` 进行转义。

**Default** : `%nrstr(#N(#RATE))`

**Example** :

```sas
PATTERN = #N
PATTERN = #N[#RATE]##
```

---

### BY

**Syntax** :

- #FREQ_MAX|#FREQ_MIN
- _variable_<(ASC\<ENDING\>|DESC\<ENDING\>)>

指定各分类在输出数据集中的排列顺序。

**Default** : `#FREQ_MAX`

默认情况下，各分类按照频数从大到小排列，频数较大的分类将显示在输出数据集中靠前的位置。

**Caution** :

1. 若参数 `VAR` 指定了分析变量的分类名称，则按照各分类在参数 `VAR` 中指定的顺序显示在输出数据集中，此时参数 `BY` 无效。

**Example** :

```sas
BY = SEXN
```

---

### OUTDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定统计结果输出的数据集，可包含数据集选项，用法同参数 [INDATA](#indata)。

输出数据集有 3 个变量，具体如下：

| 变量名 | 含义                                          |
| ------ | --------------------------------------------- |
| SEQ    | 行号                                          |
| ITEM   | 分类名称（展示名称）                          |
| VALUE  | 统计量在 [PATTERN](#pattern) 指定的模式下的值 |

其中，变量 `ITEM` 和 `VALUE` 默认输出到 `OUTDATA` 指定的数据集中，其余变量默认隐藏。

**Tips** :

如需显示隐藏的变量，可使用数据集选项实现，例如：`OUTDATA = T1(KEEP = SEQ ITEM VALUE)`

**Example** :

```sas
OUTDATA = T1
OUTDATA = T1(KEEP = KEEP = SEQ ITEM VALUE)
```

---

### STAT_FORMAT

**Syntax** : <(> #_statistic-keyword-1_ = _format-1_ <#_statistic-keyword-2_ = _format-2_> <...> <)>

指定输出结果中统计量的输出格式。

**Default** : (#N = BEST. #RATE = PERCENT9.2)

默认情况下，频数的输出格式为 `BEST.`，构成比（率）的输出格式为 `PERCENT9.2`，可通过参数 `STAT_FORMAT` 重新指定某个统计量的输出格式，_`statistic-keyword`_ 的用法详见 [PATTERN](#pattern)。

**Example** :

```sas
STAT_FORMAT = (#N = percent9.2 #RATE = 4.1)
```

---

### LABEL

**Syntax** : _string_

指定输出结果中第一行显示的标签。

**Default** : #AUTO

默认情况下，宏程序将自动获取变量 `VAR` 的标签，若标签为空，则使用变量 `VAR` 的变量名作为标签。

**Example** :

```sas
LABEL = %nrstr(性别, n(%%))
```

---

### INDENT

**Syntax** : _string_

指定输出结果各分类的缩进字符串。

**Default** : %bquote( )

默认情况下，各分类前使用 4 个英文空格作为缩进字符。

**Tips** :

1. 可以使用 RTF 控制符空值缩进，例如：五号字体下缩进 2 个中文字符，可指定参数 `INDENT = %str(\li420 )`

**Example** :

```sas
LABEL = %str(\li420 )
```

---

## 例子

### 打开帮助文档

```sas
%Qualify();
%Qualify(help);
```

### 一般用法

```sas
%Qualify(indata = adsl, var = sex);
```

![](./assets/example-1-1.png)

```sas
%Qualify(indata = adsl, var = sex("" = "Missing" "男" = "Male" "女" = "Female"));
```

![](./assets/example-1-2.png)

### 指定统计量的模式

```sas
%BinomialCI(indata = adeff(where = (CMPTFL = "Y")),
            cond_pos = %str(TSTP = "阳性" and TSTC = "阳性"),
            cond_neg = %str(TSTP ^= "阳性" and TSTC = "阳性"),
            stat_note = %str(阳性符合率),
            outdata = t1(keep = item n pos_n value));
```

![](./assets/example-2.png)

### 指定权重变量

```sas
data adeff;
    set temp.adeff;
    freq = _n_;
run;

%BinomialCI(indata = adeff(where = (CMPTFL = "Y")),
            cond_pos = %str(TSTP = "阳性" and TSTC = "阳性"),
            cond_neg = %str(TSTP ^= "阳性" and TSTC = "阳性"),
            stat_note = %str(阳性符合率),
            outdata = t1,
            weight = freq);
```

![](./assets/example-3.png)

### 指定校正置信区间的方法

```sas
%BinomialCI(indata = adeff(where = (CMPTFL = "Y")),
            cond_pos = %str(TSTP = "阳性" and TSTC = "阳性"),
            cond_neg = %str(TSTP ^= "阳性" and TSTC = "阳性"),
            stat_note = %str(阳性符合率),
            outdata = t1,
            adjust_method = cp);
```

![](./assets/example-4-1.png)

![](./assets/example-4-2.png)

上述例子中，使用参数 `ADJUST_METHOD` 指定了置信区间的校正方法为 Clopper-Pearson，由于未指定校正条件，默认当计算的阳性符合率大于或等于 0.9 时，使用 Clopper-Pearson 法对置信区间进行校正，并在日志中显示校正条件成立的信息。

### 指定校正置信区间的条件

```sas
%BinomialCI(indata = adeff(where = (CMPTFL = "Y")),
            cond_pos = %str(TSTP = "阳性" and TSTC = "阳性"),
            cond_neg = %str(TSTP ^= "阳性" and TSTC = "阳性"),
            stat_note = %str(阳性符合率),
            outdata = t1,
            adjust_method = cp,
            adjust_threshold = %str(#RATE >= 0.9 or #LCLM <= 0));
```

![](./assets/example-5-1.png)

![](./assets/example-5-2.png)

### 指定显著性水平

```sas
%BinomialCI(indata = adeff(where = (CMPTFL = "Y")),
            cond_pos = %str(TSTP = "阳性" and TSTC = "阳性"),
            cond_neg = %str(TSTP ^= "阳性" and TSTC = "阳性"),
            stat_note = %str(阳性符合率),
            outdata = t1,
            adjust_method = cp,
            adjust_threshold = %str(#RATE >= 0.9 or #LCLM <= 0),
            alpha = 0.1);
```

### 指定统计量输出格式

```sas
%BinomialCI(indata = adeff(where = (CMPTFL = "Y")),
            cond_pos = %str(TSTP = "阳性" and TSTC = "阳性"),
            cond_neg = %str(TSTP ^= "阳性" and TSTC = "阳性"),
            stat_note = %str(阳性符合率),
            outdata = t1,
            adjust_method = cp,
            adjust_threshold = %str(#RATE >= 0.9 or #LCLM <= 0),
            format = %str(#RATE = percentn11.4 #CLM = 5.3 #UCLM = dollar20.3));
```

![](./assets/example-6.png)

### 指定无法计算构成比（率）及置信区间时显示的字符（串）

```sas
%BinomialCI(indata = adeff(where = (CMPTFL = "Y")),
            cond_pos = %str(TSTP = "阳性" and TSTP = "阴性"),
            cond_neg = %str(TSTC = "阳性" and TSTC = "阴性"),
            stat_note = %str(阳性符合率),
            outdata = t1,
            adjust_method = cp,
            adjust_threshold = %str(#RATE >= 0.9 or #LCLM <= 0),
            format = %str(#RATE = percentn11.4 #CLM = 5.3 #UCLM = dollar20.3),
            placeholder = %str(%%%%));
```

![](./assets/example-7.png)
