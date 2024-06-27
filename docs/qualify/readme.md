## 简介

单组单个定性指标的分析，输出频数、构成比（率）指标。

## 语法

### 必选参数

- [INDATA](#indata)
- [VAR](#var)

### 可选参数

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
- [TOTAL](#total)

### 调试参数

- [DEL_TEMP_DATA](#del_temp_data)

## 参数说明

### INDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定用于定性分析的数据集，可包含数据集选项

_libname_: 数据集所在的逻辑库名称

_dataset_: 数据集名称

_dataset-options_: 数据集选项，兼容 SAS 系统支持的所有数据集选项

**Usage** :

```sas
INDATA = ADSL
INDATA = SHKY.ADSL
INDATA = SHKY.ADSL(where = (FAS = "Y"))
```

[**Example**](#一般用法)

---

### VAR

**Syntax** :

- _variable_
- _variable_("_category-1_" = "_note-1_" <, "_category-2_" ="_note-2_", ...>)

指定定性分析的变量。

_`category`_ 表示重命名前的分类名称，_`note`_ 表示重命名后的分类名称。重命名后的分类名称仅作为输出数据集中该分类显示的名称，实际输出的统计量结果仍然是按照重命名前的分类名称进行计算的。例如：

```sas
VAR = SEX("男" = "Male", "女" = "Female")
```

> [!WARNING]
>
> - 参数 `VAR` 不允许指定不存在于参数 `INDATA` 指定的数据集中的变量；
> - 参数 `VAR` 不允许指定数值型变量；

**Usage** :

```sas
VAR = SEX
```

[**Example**](#一般用法)

---

### BY

**Syntax** :

- #FREQ<(ASC\<ENDING\> | DESC\<ENDING\>)>
- _variable_<(ASC\<ENDING\> | DESC\<ENDING\>)>
- _format_<(ASC\<ENDING\> | DESC\<ENDING\>)>

指定各分类在输出数据集中的排列顺序依据。

**Default** : #FREQ(DESCENDING)

默认情况下，各分类按照频数从大到小排列，频数较大的分类将显示在输出数据集中靠前的位置。

当指定一个输出格式作为排序依据时，该输出格式应当使用 `VALUE` 语句生成，例如：

```sas
proc format;
    value sexn
        1 = "男"
        2 = "女";
run;
```

宏程序将根据格式化之前的数值对各分类进行排序。

> [!IMPORTANT]
>
> - 若参数 `BY` 指定了基于某个输出格式进行排序，则该格式必须是 CATALOG-BASED，即在 `DICTIONARY.FORMATS` 表中，变量 `source` 的值应当是 `C`。

**Usage** :

```sas
BY = #freq
BY = SEXN(asc)
BY = SEXN.(descending)
```

[**Example**](#指定分类排序方式)

---

### UID

**Syntax** : _variable_

指定唯一标识符变量。宏程序将根据参数 `UID` 指定的变量，对分析数据集统计频数和频次，`UID` 的值通常是能够标识观测所属试验对象的变量，例如：`USUBJID`。

**Default** : #NULL

默认情况下，宏程序将分析数据集中的每一条观测都视为不同试验对象的观测结果，在这种情况下，输出数据集中的频数和频次计算结果相同。

> [!IMPORTANT]
>
> - 由于默认不输出频次统计结果，因此还需要在参数 [OUTDATA](#outdata) 中通过数据集选项指定显示频次统计结果，例如：`OUTDATA = T1(KEEP = ITEM VALUE TIMES)`。

**Usage** :

```sas
UID = USUBJID
```

[**Example**](#指定唯一标识符变量)

---

### PATTERN

**Syntax** : <_string(s)_>#_statistic-keyword-1_<_string(s)_><#_statistic-keyword-2_<_string(s)_>><...>

指定需计算的统计量及统计量的输出模式，输出模式定义了统计量是如何进行组合的，以及统计量在输出数据集中的位置。

其中，_`statistic-keyword`_ 可以指定以下统计量：

| 统计量 | 含义         |
| ------ | ------------ |
| RATE   | 构成比（率） |
| N      | 频数         |

_`string(s)`_ 可以是任意字符（串），若字符串含有字符 `#`，则使用 `##` 进行转义。

**Default** : `%nrstr(#N(#RATE))`

**Usage** :

```sas
PATTERN = #N
PATTERN = #N[#RATE]##
```

[**Example**](#指定统计量的输出模式)

---

### MISSING

**Syntax** : TRUE | FALSE

指定是否统计缺失分类。

**Default** : FALSE

默认情况下，宏程序不统计缺失分类的频数和频率。

**Usage** :

```sas
MISSING = TRUE
```

[**Example**](#指定是否统计缺失分类)

---

### MISSING_NOTE

**Syntax** : _string_

指定缺失分类的的说明文字，该字符串必须使用匹配的单（双）引号包围。

如果指定的 `MISSING_NOTE` 中含有不匹配的引号，例如，需要指定 `MISSING_NOTE` 为一个单引号，可以选择以下传参方式：

```sas
MISSING_NOTE = "'"
```

但不能使用以下传参方式：

```sas
MISSING_NOTE = ''''
```

**Default** : "缺失"

**Usage** :

```sas
MISSING_NOTE = "缺失-n(%)"
```

[**Example**](#指定缺失分类的说明文字)

---

### MISSING_POSITION

**Syntax** : FIRST | LAST

指定缺失分类在输出数据集中显示的位置。FIRST 表示显示在所有分类前面，LAST 表示显示在所有分类后面。

当指定 `MISSING = FALSE` 时，该参数将被忽略。

**Default** : LAST

**Usage** :

```sas
MISSING_POSITION = FIRST
```

[**Example**](#指定缺失分类的显示位置)

---

### OUTDATA

**Syntax** : <_libname._>_dataset_(_dataset-options_)

指定统计结果输出的数据集，可包含数据集选项，用法同参数 [INDATA](#indata)。

输出数据集有 7 个变量，具体如下：

| 变量名                                   | 含义                                          |
| ---------------------------------------- | --------------------------------------------- |
| SEQ                                      | 行号                                          |
| ITEM                                     | 分类名称（展示名称）                          |
| VALUE                                    | 统计量在 [PATTERN](#pattern) 指定的模式下的值 |
| FREQ                                     | 频数                                          |
| FREQ_FMT                                 | 频数格式化值                                  |
| <font color=red>N<sup>1</sup></font>     | 频数                                          |
| <font color=red>N_FMT<sup>1</sup></font> | 频数格式化值                                  |
| TIMES                                    | 频次                                          |
| TIMES_FMT                                | 频次格式化值                                  |
| RATE                                     | 频率                                          |
| RATE_FMT                                 | 频率格式化值                                  |

> [!IMPORTANT]
>
> <sup>1</sup> 建议改用 `FREQ`, `FREQ_FMT`，保留 `N`, `N_FMT` 仅为兼容旧版本程序，未来的版本 (_v1.5+_) 可能不受支持；

其中，变量 `ITEM` 和 `VALUE` 默认输出到 `OUTDATA` 指定的数据集中，其余变量默认隐藏。

**Default** : #AUTO

默认情况下，输出数据集被命名为 `RES_`_`var`_，其中 _`var`_ 为参数 [VAR](#var) 指定的变量的名称。

> [!TIP]
>
> - 如需显示隐藏的变量，可使用数据集选项实现，例如：`OUTDATA = T1(KEEP = SEQ ITEM VALUE FREQ TIMES)`

**Usage** :

```sas
OUTDATA = T1
OUTDATA = T1(KEEP = SEQ ITEM VALUE FREQ TIMES)
```

[**Example**](#指定需要保留的变量)

**See Also** :

- [qualify_multi](../qualify_multi/readme.md#outdata)

---

### STAT_FORMAT

**Syntax** : <(> #_statistic-keyword-1_ = _format-1_ <, #_statistic-keyword-2_ = _format-2_ <, ...>><)>

指定输出结果中统计量的输出格式。

其中，_`statistic-keyword`_ 可以指定以下统计量：

| 统计量                               | 含义          | 默认值               |
| ------------------------------------ | ------------- | -------------------- |
| FREQ                                 | 频数          | BEST.                |
| <font color=red>N<sup>1</sup></font> | 频数          | BEST.                |
| TIMES                                | 频次          | BEST.                |
| RATE                                 | 构成比（率）  | PERCENTN9.2          |
| TS <sup>2</sup>                      | 检验统计量    | _#AUTO_ <sup>2</sup> |
| P <sup>3</sup>                       | 假设检验 P 值 | _#AUTO_ <sup>3</sup> |

> [!IMPORTANT]
>
> - <sup>1</sup> 建议改用 `FREQ`，保留 `N` 仅为兼容旧版本程序，未来的版本 (_v1.5+_) 可能不受支持；
>
> - <sup>2</sup> 仅在宏 `%qualify_multi_test` 中可用；
>
> - <sup>3</sup> 检验统计量输出格式的默认值为 _w.d_，其中：
>
>   - _w_ = $\max(\lceil\log_{10}\left|s\right|\rceil, 7)$， $s$ 表示检验统计量的值
>   - _d_ = 4
>
> - <sup>3</sup> 假设检验 P 值输出格式的默认值为 `qlmt_pvalue.`，`qlmt_pvalue.` 由以下 PROC FORMAT 过程定义：
>
>   ```sas
>   proc format;
>       picture qlmt_pvalue(round  max = 7)
>               low - < 0.0001 = "<0.0001"(noedit)
>               other = "9.9999";
>   run;
>   ```

**Usage** :

```sas
STAT_FORMAT = (#N = z4., #RATE = percentn9.2)
STAT_FORMAT = (#RATE = qual., #TS = 8.4, #P = pv.)
```

[**Example**](#指定统计量的输出格式)

---

### LABEL

**Syntax** : _string_

指定输出结果中第一行显示的标签字符串，该字符串必须使用匹配的单（双）引号包围。

如果指定的 `LABEL` 中含有不匹配的引号，例如，需要指定 `LABEL` 为一个单引号，可以选择以下传参方式：

```sas
LABEL = "'"
```

但不能使用以下传参方式：

```sas
LABEL = ''''
```

**Default** : #AUTO

默认情况下，宏程序将自动获取变量 [VAR](#var) 的标签，若标签为空，则使用变量 [VAR](#var) 的变量名作为标签。

**Usage** :

```sas
LABEL = "性别-n(%)"
```

[**Example**](#指定分析变量标签)

---

### INDENT

**Syntax** : _string_

指定输出结果各分类的缩进字符串，该字符串必须使用匹配的单（双）引号包围。

如果指定的 `INDENT` 中含有不匹配的引号，例如，需要指定 `INDENT` 为一个单引号，可以选择以下传参方式：

```sas
INDENT = "'"
```

但不能使用以下传参方式：

```sas
INDENT = ''''
```

**Default** : #AUTO

默认情况下，各分类前使用 4 个英文空格作为缩进字符。

> [!TIP]
>
> - 可以使用 RTF 控制符控制缩进，例如：五号字体下缩进 2 个中文字符，可指定参数 `INDENT = "\li420 "`；

**Usage** :

```sas
INDENT = "\li420 "
```

[**Example**](#指定缩进字符串)

---

### SUFFIX

**Syntax** : _string_

指定输出结果各分类名称的后缀，该字符串必须使用匹配的单（双）引号包围。

如果指定的 `SUFFIX` 中含有不匹配的引号，例如，需要指定 `SUFFIX` 为一个单引号，可以选择以下传参方式：

```sas
SUFFIX = "'"
```

但不能使用以下传参方式：

```sas
SUFFIX = ''''
```

**Default** : #AUTO

默认情况下，各分类名称不添加后缀。

**Usage** :

```sas
SUFFIX = "，n(%)"
```

[**Example**](#指定分类名称后缀)

---

### TOTAL

**Syntax** : TRUE | FALSE

指定是否在标签行输出各分类合计的统计结果。

**Default** : FALSE

默认情况下，标签行仅显示参数 [LABEL](#label) 指定的字符串，不显示各分类合计的统计结果。

**Usage** :

```sas
TOTAL = TRUE
```

[**Example**](#指定分类名称后缀)

---

### DEL_TEMP_DATA

**Syntax** : TRUE | FALSE

指定是否删除宏程序运行过程生成的中间数据集。

**Default** : TRUE

默认情况下，宏程序会自动删除运行过程生成的中间数据集。

> [!NOTE]
>
> 此参数用于开发者调试，一般无需关注。

---

## 例子

### 打开帮助文档

```sas
%qualify();
%qualify(help);
```

### 一般用法

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig);
```

![](./assets/example-var.png)

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig("异常无临床意义" = "NCS", "异常有临床意义" = "CS"));
```

![](./assets/example-var-category-note.png)

### 指定统计量的输出模式

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig, pattern = %str(#n[#rate]##));
```

![](./assets/example-pattern.png)

上述例子中，使用参数 `PATTERN` 改变了默认的统计量输出模式，构成比使用中括号[]包围，结尾使用 `##` 对 `#` 进行转义。

### 指定分类排序方式

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig, by = #freq(desc));
```

![](./assets/example-by-freq.png)

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig, by = ecgcsign);
```

![](./assets/example-by-var.png)

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")), var = ecgcsig, by = clsig.);
```

![](./assets/example-by-format.png)

输出格式 `clsig.` 包含的具体分类如下：

![](./assets/example-by-format-label.png)

### 指定唯一标识符变量

```sas
%qualify(indata = adam.addv(where = (FASFL = "Y")),
         var = dvtype,
         uid = usubjid,
         outdata = t1(keep = item value freq times));
```

![](./assets/example-uid.png)

### 指定是否统计缺失分类

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true);
```

![](./assets/example-missing.png)

### 指定缺失分类的说明文字

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true,
         missing_note = "不适用");
```

![](./assets/example-missing-note.png)

### 指定缺失分类的显示位置

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true,
         missing_note = "不适用",
         missing_position = first);
```

![](./assets/example-missing-position.png)

### 指定需要保留的变量

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true,
         outdata = t1(keep = seq item value n rate));
```

![](./assets/example-outdata.png)

### 指定统计量的输出格式

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
        var = ecgcsig,
        by = clsig.,
        missing = true,
        stat_format = (#N = z4., #RATE = 5.3));
```

![](./assets/example-stat-format.png)

### 指定分析变量标签

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true,
         label = "ECG 临床意义判定-n(%)");
```

![](./assets/example-label.png)

### 指定缩进字符串

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true,
         label = "ECG 临床意义判定-n(%)",
         indent = "\li420 ");
```

![](./assets/example-indent.png)

上述例子中，使用参数 `INDENT` 指定了 RTF 控制符 `\li420` 作为缩进字符串。如需使 RTF 控制符生效，需要在传送至 ODS 的同时，指定相关元素的 `PROTECTSPECIALCHAR` 属性值为 `OFF`。

### 指定分类名称后缀

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true,
         label = "ECG 临床意义判定",
         indent = "\li420 ",
         suffix = "，n(%)");
```

![](./assets/example-suffix.png)

### 指定是否输出各分类合计的统计结果

```sas
%qualify(indata = adam.adsl(where = (FASFL = "Y")),
         var = ecgcsig,
         by = clsig.,
         missing = true,
         label = "ECG 临床意义判定",
         indent = "\li420 ",
         suffix = "，n(%)",
         total = true);
```

![](./assets/example-total.png)
