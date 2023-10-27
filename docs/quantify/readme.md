## 简介

单组单个定量指标的分析，输出均值、中位数、标准差、最大值、最小值、Q1、Q3 等指标。

## 语法

### 必选参数

- [INDATA](#indata)
- [VAR](#var)

### 可选参数

- [PATTERN](#pattern)
- [OUTDATA](#outdata)
- [STAT_FORMAT](#stat_format)
- [STAT_NOTE](#stat_note)
- [LABEL](#label)
- [INDENT](#indent)

## 参数说明

### INDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定用于定量分析的数据集，可包含数据集选项

_libname_: 数据集所在的逻辑库名称

_dataset_: 数据集名称

_dataset-options_: 数据集选项，兼容 SAS 系统支持的所有数据集选项

**Example** :

```sas
INDATA = ADSL
INDATA = SHKY.ADSL
INDATA = SHKY.ADSL(where = (FAS = "Y"))
```

---

### VAR

**Syntax** : _variable_

指定定量分析的变量。

**Caution** :

1. 参数 `VAR` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
2. 参数 `VAR` 不允许指定字符型变量；

**Example** :

```sas
VAR = AGE
```

---

### PATTERN

**Syntax** : _row-1-specification_<|_row-2-specification_<|...>>

指定需计算的统计量及统计量的输出模式，输出模式定义了统计量是如何进行组合的，以及统计量在输出数据集中的位置。

_`row-i-specification`_ 表示输出数据集中第 `i+1` 行（第 1 行固定为分析变量的标签）的统计量结果展示模式，输出数据集中的每一行均用一个 _`row-i-specification`_ 进行定义，不同行的定义之间使用字符 `|` 隔开，其中 _`row-i-specification`_ 的语法如下：

- _string(s)_
- #_statistic-keyword_
- <_string(s)_>#_statistic-keyword_<_string(s)_>
- <_string(s)_>#_statistic-keyword-1_<_string(s)_><#_statistic-keyword-2_><_string(s)_><...>

_`statistic-keyword`_ 可以指定以下统计量：

| 统计量   | 简写 | 含义               |
| -------- | ---- | ------------------ |
| N        |      | 例数               |
| NMISS    |      | 缺失               |
| MEAN     |      | 均值               |
| VAR      |      | 方差               |
| STDDVE   | STD  | 标准差             |
| STDERR   |      | 标准误             |
| RANGE    |      | 极差               |
| MEDIAN   |      | 中位数             |
| MODE     |      | 众数               |
| Q1       |      | 下四分位数         |
| Q3       |      | 上四分位数         |
| QRANGE   |      | 四分位间距         |
| MIN      |      | 最小值             |
| MAX      |      | 最大值             |
| CV       |      | 变异系数           |
| KURTOSIS | KURT | 峰度               |
| SKEWNESS | SKEW | 偏度               |
| LCLM     |      | 均值的 95%置信下限 |
| UCLM     |      | 均值的 95%置信上限 |
| SUM      |      | 总和               |
| USS      |      | 未校正平方和       |
| CSS      |      | 校正平方和         |
| P1       |      | 第 1 百分位数      |
| P5       |      | 第 5 百分位数      |
| P10      |      | 第 10 百分位数     |
| P20      |      | 第 20 百分位数     |
| P25      |      | 第 25 百分位数     |
| P30      |      | 第 30 百分位数     |
| P40      |      | 第 40 百分位数     |
| P50      |      | 第 50 百分位数     |
| P60      |      | 第 60 百分位数     |
| P70      |      | 第 70 百分位数     |
| P75      |      | 第 75 百分位数     |
| P80      |      | 第 80 百分位数     |
| P90      |      | 第 90 百分位数     |
| P95      |      | 第 95 百分位数     |
| P99      |      | 第 99 百分位数     |

_`string(s)`_ 可以是任意字符（串），若字符串含有字符 `|`，则使用 `#|` 进行转义，若字符串含有字符 `#`，则使用 `##` 进行转义。

**Default** : `%nrstr(#N(#NMISS)|#MEAN(#STD)|#MEDIAN(#Q1, #Q3)|#MIN, #MAX)`

**Caution** :

1. 若紧跟在 _statistic-keyword_ 之后的 _string(s)_ 的部分字符与 _statistic-keyword_ 可以组合成另一个 _statistic-keyword_，为了避免混淆，应当在 _statistic-keyword_ 后添加一个 `.`，然后再添加 _string(s)_。例如：`PATTERN = #N(#N.MISS)|#MEAN(#STD)`，其中 `#N.MISS` 代表将计算例数与字符串 `MISS` 进行连接；
2. 若 _statistic-keyword_ 之后的第一个字符是 `.`，则需要使用 `..` 才能正确表示。例如：`PATTERN = #N(#N..MISS)|#MEAN(#STD)`；
3. 若未指定任何 _statistic-keyword_，则会直接输出原始字符串，而不进行任何统计量的计算。

**Example** :

```sas
PATTERN = #N(#NMISS)|#MEAN±#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX
PATTERN = #N(#NMISS)|#MEAN(###STD)|#MEDIAN(#Q1, #Q3)|#MIN#|#|#max|#KURTOSIS, #SKEWNESS|(#LCLM, #UCLM)
```

---

### OUTDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定统计结果输出的数据集，可包含数据集选项，用法同参数 [INDATA](#indata)。

输出数据集有 3 个变量，具体如下：

| 变量名 | 含义                                          |
| ------ | --------------------------------------------- |
| SEQ    | 行号                                          |
| ITEM   | 指标名称                                      |
| VALUE  | 统计量在 [PATTERN](#pattern) 指定的模式下的值 |

其中，变量 `ITEM` 和 `VALUE` 默认输出到 `OUTDATA` 指定的数据集中，其余变量默认隐藏。

**Default** : RES\_&_VAR_

默认情况下，输出数据集的名称为 `RES_xxx`，其中 `xxx` 为参数 [VAR](#var) 指定的变量名。

**Tips** :

如需显示隐藏的变量，可使用数据集选项实现，例如：`OUTDATA = T1(KEEP = SEQ ITEM VALUE)`

**Example** :

```sas
OUTDATA = T1
OUTDATA = T1(KEEP = (SEQ ITEM VALUE))
```

---

### STAT_FORMAT

**Syntax** : <(> #_statistic-keyword-1_ = _format-1_ <#_statistic-keyword-2_ = _format-2_> <...> <)>

指定输出结果中统计量的输出格式。

**Default** : #NULL

默认情况下，频数的输出格式为 `BEST.`，可通过参数 `STAT_FORMAT` 重新指定某个统计量的输出格式，_`statistic-keyword`_ 的用法详见 [PATTERN](#pattern)。

**Example** :

```sas
STAT_FORMAT = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1)
```

---

### STAT_NOTE

**Syntax** : <(> #_statisic-keyword-1_ = _string-1_ <#_statistic-keyword-2_ = _string-2_ <...>> <)>

指定输出结果中统计量的说明文字，该说明文字将会出现在输出数据集的 `ITEM` 列中。

**Default** : #NULL

默认情况下，绝大部分统计量的说明文字与参数 [PATTERN](#pattern) 中对 _statistic-keyword_ 描述的含义一致，Q1 和 Q3 是例外，具体各统计量的说明文字如下：

| 统计量   | 简写 | 说明文字           |
| -------- | ---- | ------------------ |
| N        |      | 例数               |
| NMISS    |      | 缺失               |
| MEAN     |      | 均值               |
| VAR      |      | 方差               |
| STDDEV   | STD  | 标准差             |
| STDERR   |      | 标准误             |
| RANGE    |      | 极差               |
| MEDIAN   |      | 中位数             |
| MODE     |      | 众数               |
| Q1       |      | Q1                 |
| Q3       |      | Q3                 |
| QRANGE   |      | 四分位间距         |
| MIN      |      | 最小值             |
| MAX      |      | 最大值             |
| CV       |      | 变异系数           |
| KURTOSIS | KURT | 峰度               |
| SKEWNESS | SKEW | 偏度               |
| LCLM     |      | 均值的 95%置信下限 |
| UCLM     |      | 均值的 95%置信上限 |
| SUM      |      | 总和               |
| USS      |      | 未校正平方和       |
| CSS      |      | 校正平方和         |
| P1       |      | 第 1 百分位数      |
| P5       |      | 第 5 百分位数      |
| P10      |      | 第 10 百分位数     |
| P20      |      | 第 20 百分位数     |
| P30      |      | 第 30 百分位数     |
| P40      |      | 第 40 百分位数     |
| P50      |      | 第 50 百分位数     |
| P60      |      | 第 60 百分位数     |
| P70      |      | 第 70 百分位数     |
| P75      |      | 第 75 百分位数     |
| P80      |      | 第 80 百分位数     |
| P90      |      | 第 90 百分位数     |
| P95      |      | 第 95 百分位数     |
| P99      |      | 第 99 百分位数     |

---

**Example** :

```sas
STAT_NOTE = (#N = "靶区数" #MEAN = "平均值")
```

### LABEL

**Syntax** : _string_

指定输出结果中第一行显示的标签。

**Default** : #AUTO

默认情况下，宏程序将自动获取变量 `VAR` 的标签，若标签为空，则使用变量 `VAR` 的变量名作为标签。

**Example** :

```sas
LABEL = 年龄（岁）
```

---

### INDENT

**Syntax** : _string_

指定输出结果各分类的缩进字符串。

**Default** : %bquote( )

默认情况下，各分类前使用 4 个英文空格作为缩进字符。

**Tips** :

1. 可以使用 RTF 控制符控制缩进，例如：五号字体下缩进 2 个中文字符，可指定参数 `INDENT = %str(\li420 )`

**Example** :

```sas
INDENT = %str(\li420 )
```

---

## 例子

### 打开帮助文档

```sas
%quantify();
%quantify(help);
```

### 一般用法

```sas
%quantify(indata = adsl, var = age);
```

![](./assets/example-1.png)

### 指定统计量的模式

```sas
%quantify(indata = adsl, var = age,
          pattern = %nrstr(#N(#NMISS)#Q1|#MEAN(###STD)|#MEDIAN(#Q1, #Q3)|#MIN#|#|#max));
```

![](./assets/example-2.png)

上述例子中，使用参数 `PATTERN` 改变了默认的统计量输出模式，第二行额外输出了统计量 `Q1`，第三行使用 `##` 对 `#` 进行转义，最后一行最小值和最大值使用 `||` 进行分隔，同样使用 `#|` 对 `|` 进行转义。

### 指定需要保留的变量

```sas
%quantify(indata = adsl, var = age, outdata = t1(keep = seq item value));
```

![](./assets/example-3.png)

### 指定统计量的输出格式

```sas
%quantify(indata = adsl, var = age,
          stat_format = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1));
```

![](./assets/example-4.png)

### 指定统计量的说明文字

```sas
%quantify(indata = adsl, var = age,
          stat_note = (#N = "靶区数" #MEAN = "平均值" #Q1 = "下四分位数" #Q3 = "上四分位数"));
```

![](./assets/example-5.png)

### 指定分析变量的标签

```sas
%quantify(indata = adsl, var = age,
          stat_format = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1), label = 年龄(岁));
```

![](./assets/example-6.png)

### 指定缩进字符串

```sas
%quantify(indata = adsl, var = age,
          stat_format = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1), indent = %str(\li420 ));
```

上述例子中，使用参数 `INDENT` 指定了缩进字符串，如需使 RTF 控制符生效，需要在传送至 ODS 的同时，指定相关元素的 `PROTECTSPECIALCHAR` 属性值为 `OFF`。
