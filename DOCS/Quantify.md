# %Quantify 使用指南

[TOC]

## 1. 功能

单个定量指标分析，输出均值、中位数、标准差、最小值、最大值、Q1、Q3 等指标。

## 2. 语法

- <font color = blue>**%Quantify()**</font>
- <font color = blue>**%Quantify(help)**</font>
- <font color = blue>**%Quantify(_requried-argument-1_, *requried-argument-2* <, _optional-argument-1_ <, _optional-argument-2_> <, ...>>)**</font>

<font color = grey>**Tips**</font> : 运行**%Quantify()**或**%Quantify(help)**将会在浏览器中打开帮助文档。

### 2.1 Requried Argument

#### <font color = blue>INDATA</font>

<font color = grey>**Syntax**</font> : **<font color = blue><_libname._>_dataset_(_dataset_options_)</font>**

指定用于定量分析的数据集，可包含数据集选项

**_libname_**: 数据集所在的逻辑库名称

**_dataset_**: 数据集名称

**_dataset_options_**: 数据集选项，兼容 SAS 系统支持的所有数据集选项

<font color = grey>**Example**</font> :

- INDATA = ADSL
- INDATA = SHKY.ADSL
- INDATA = SHKY.ADSL(where = (FAS = "Y"))

---

#### <font color = blue>VAR</font>

<font color = grey>**Syntax**</font> : <font color = blue>**_variable_**</font>

指定定量分析的变量。

<font color = grey>**Caution**</font> :

1. 参数 VAR 不允许指定不存在于参数 INDATA 指定的数据集中的变量
2. 参数 VAR 不允许指定字符型变量

<font color = grey>**Example**</font> :

- VAR = AGE

### 2.2 Optional Argument

#### <a id="pattern"></a><font color = blue>PATTERN</font>

<font color = grey>**Syntax**</font> : <font color = blue>**_row-1-specification<|row-2-specification><|row-3-specification><...>_**</font>

指定需计算的统计量及统计量的输出模式，输出模式定义了统计量是如何进行组合的以及在输出数据集中的位置。_row-i-specification_ 表示输出数据集中第 _i+1_ 行（第 1 行固定为分析变量的标签）的统计量结果展示模式，输出数据集中的每一行均用一个 _row-i-specification_ 进行定义，不同行的定义间使用字符 "**|**" 隔开，其中 <font color = blue>**_row-i-specification_**</font> 的语法如下：

- <font color=blue>**_string(s)_**</font>

- <font color = blue>**#_statistic-keyword_**</font>

- <font color = blue>**<_string(s)_>#_statistic-keyword_<_string(s)_>**</font>

- <font color = blue>**<_string(s)_>#_statistic-keyword-1_<_string(s)_><#_statistic-keyword-2_><_string(s)_><...>**</font>

  <font color = blue>**_statistic-keyword_**</font> 可以是如下所述的统计量之一：

  - <font color = blue>N</font> : 例数
  - <font color = blue>NMISS</font> : 缺失
  - <font color = blue>MEAN</font> : 均值
  - <font color = blue>VAR</font> : 方差
  - <font color = blue>STDDEV/STD</font> : 标准差
  - <font color = blue>STDERR</font> : 标准误
  - <font color = blue>RANGE</font> : 极差
  - <font color = blue>MEDIAN</font> : 中位数
  - <font color = blue>MODE</font> : 众数
  - <font color = blue>Q1</font> : 下四分位数
  - <font color = blue>Q3</font> : 上四分位数
  - <font color = blue>QRANGE</font> : 四分位间距
  - <font color = blue>MIN</font> : 最小值
  - <font color = blue>MAX</font> : 最大值
  - <font color = blue>CV</font> : 变异系数
  - <font color = blue>KURTOSIS/KURT</font> : 峰度
  - <font color = blue>SKEWNESS/SKEW</font> : 偏度
  - <font color = blue>LCLM</font> : 均值的 95% 置信下限
  - <font color = blue>UCLM</font> : 均值的 95% 置信上限
  - <font color = blue>SUM</font> : 总和
  - <font color = blue>USS</font> : 未校正平方和
  - <font color = blue>CSS</font> : 校正平方和
  - <font color = blue>P1</font> : 第 1 百分位数
  - <font color = blue>P5</font> : 第 5 百分位数
  - <font color = blue><font color = blue>P10</font> : </font>第 10 百分位数
  - <font color = blue><font color = blue>P20</font> : </font>第 20 百分位数
  - <font color = blue><font color = blue>P25</font> : </font>第 25 百分位数
  - <font color = blue><font color = blue>P30</font> : </font>第 30 百分位数
  - <font color = blue><font color = blue>P40</font> : </font>第 40 百分位数
  - <font color = blue><font color = blue>P50</font> : </font>第 50 百分位数
  - <font color = blue><font color = blue>P60</font> : </font>第 60 百分位数
  - <font color = blue><font color = blue>P70</font> : </font>第 70 百分位数
  - <font color = blue><font color = blue>P75</font> : </font>第 75 百分位数
  - <font color = blue><font color = blue>P80</font> : </font>第 80 百分位数
  - <font color = blue><font color = blue>P90</font> : </font>第 90 百分位数
  - <font color = blue><font color = blue>P95</font> : </font>第 95 百分位数
  - <font color = blue><font color = blue>P99</font> : </font>第 99 百分位数

  <font color = blue>**_string(s)_**</font> 可以是任意字符（串），若字符串含有字符"**|**"，则使用"**#|**"进行转义，若字符串含有"**#**"，则使用"**##**"进行转义。<a href="#example_3.3">示例代码</a>

<font color = grey>**Default**</font> : %nrstr(#N(#NMISS)|#MEAN(#STD)|#MEDIAN(#Q1, #Q3)|#MIN, #MAX)

<font color = grey>**Caution**</font> :

1. 若紧跟在 _statistic-keyword_ 之后的 _string(s)_ 的部分字符与 _statistical-keyword_ 可以组合成另一个 _statistica-keyword_，为了避免混淆，应当在 _statistic-keyword_ 后添加一个 "."，然后再添加 _string(s)_。例如：PATTERN = #N(#N**.MISS**)|#MEAN(#STD)，其中 #N.MISS 代表计算例数，与字符串 "MISS" 连接；
2. 若 _statistic-keyword_ 之后的第一个字符是 "."，则需要使用两个 "." 才能正确表达。例如：PATTERN = #N(#N**..MISS**)|#MEAN(#STD)；
3. 若未指定任何 _statistic-keyword_，则会直接输出原始字符串，而不进行任何统计量的计算。

<font color = grey>**Example**</font> :

- PATTERN = #N(#NMISS)|#MEAN**±**#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX
- PATTERN = #N(#NMISS)|#MEAN(**##**#STD)|#MEDIAN(#Q1, #Q3)|#MIN**#|#|**#max|#KURTOSIS, #SKEWNESS|(#LCLM, #UCLM)

---

#### <font color = blue>OUTDATA</font>

<font color = grey>**Syntax**</font> : <font color = blue>**<_libname._>_dataset_(_dataset_options_)**</font>

指定统计结果输出的数据集，可包含数据集选项，用法同参数 INDATA 。

<font color = grey>**Default**</font> : RES\_&_VAR_

默认情况下，输出数据集名称为 RES\_&_VAR_。

输出数据集有 3 个变量，分别为

- **SEQ**：行号
- **ITEM**：指标名称
- **VALUE**：指标值

其中，变量 SEQ 默认不输出到参数 OUTDATA 指定的数据集中。

<font color = grey>**Tips**</font> :

1. 如需在输出数据集中显示变量 SEQ，可使用数据集选项实现，例如：OUTDATA = T1(KEEP = SEQ ITEM VALUE) <a href="#example_3.4">示例代码</a>

---

#### <font color = blue>STAT_FORMAT</font>

<font color = grey>**Syntax**</font> : <font color = blue>**<(> #_statistic-keyword-1_ = *format-1* <#*statistic-keyword-2* = _format-2_> <...> <)>**</font>

指定输出结果中统计量的输出格式。<a href="#example_3.5">示例代码</a>

<font color = grey>**Default**</font> : #NULL

默认情况下，所有统计量的输出格式均为 best.，可通过参数 STAT*FORMAT 重新指定某个统计量的输出格式，\*\*\_statistic-keyword*\*\* 的用法详见 <a href="#pattern">PATTERN</a>。

<font color = grey>**Example**</font> :

- STAT_FORMAT = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1)

---

#### <font color = blue>STAT_NOTE</font>

<font color = grey>**Syntax**</font> : <font color = blue>**<(> #_statistic-keyword-1_ = *string-1* <#*statistic-keyword-2* = _string-2_> <...> <)>**</font>

指定输出结果中统计量的说明文字，该说明文字将会出现在输出数据集的第一列（ITEM 列）中。<a href="#example_3.6">示例代码</a>

<font color = grey>**Default**</font> : #NULL

默认情况下，绝大部分统计量的说明文字如参数 PATTERN 对 _statistic-keyword_ 的描述一样（Q1 和 Q3 除外），Q1 和 Q3 的说明文字如下：

- <font color = blue>Q1</font> : Q1
- <font color = blue>Q3</font> : Q3

可通过参数 STAT*NOTE 重新指定某个统计量的说明文字，\*\*\_statistic-keyword*\*\* 的用法详见 <a href="#pattern">PATTERN</a>，_string_ 应当使用双引号包围。

<font color = grey>**Example**</font> :

- STAT_NOTE = (#N = "靶区数" #MEAN = "平均值" #Q1 = "下四分位数" #Q3 = "上四分位数")

---

#### <font color = blue>LABEL</font>

<font color = grey>**Syntax**</font> : <font color = blue>**_string_**</font>

指定输出结果中第一行显示的标签。<a href="#example_3.7">示例代码</a>

<font color = grey>**Default**</font> : #AUTO

默认情况下，宏程序将自动获取分析变量 VAR 的标签，若标签为空，则使用变量名 VAR 作为标签。

<font color = grey>**Example**</font> :

- LABEL = 年龄(岁)

---

#### <font color = blue>INDENT</font>

<font color = grey>**Syntax**</font> : <font color = blue>**_string_**</font>

指定输出结果各分类的缩进字符串。<a href="#example_3.8">示例代码</a>

<font color = grey>**Default**</font> : %bquote( )

默认情况下，各分类前使用 4 个英文空格作为缩进字符。

<font color = grey>**Tips**</font> :

1. 可以使用 RTF 控制符控制缩进，例如：5 号字体下缩进 2 个中文字符，可指定参数 INDENT = %str(\li420 )

<font color = grey>**Example**</font> :

- LABEL = %str(\li420 )

## 3. 例子

点击 <a href="../02 验证程序" target="_blank">此处</a> 打开示例程序目录（出于安全限制，Chromium 内核的浏览器不支持直接在资源管理器中打开文件夹，仅 IE 浏览器支持此特性）。

### <a id="example_3.1"></a>3.1 打开帮助文档

```SAS
%Quantify();
%Quantify(help);
```

### <a id="example_3.2"></a>3.2 一般用法

```sas
%Quantify(indata = adsl, var = age);
```

![image-20221108220141725](readme.assets/image-20221108220141725.png)

### <a id="example_3.3"></a>3.3 指定统计量的模式

```SAS
%Quantify(indata = adsl, var = age, pattern = %nrstr(#N(#NMISS)#Q1|#MEAN(###STD)|#MEDIAN(#Q1, #Q3)|#MIN#|#|#max));
```

![image-20221108220306609](readme.assets/image-20221108220306609.png)

上述例子中，使用参数 PATTERN 改变了默认的统计量输出模式，第二行额外输出了统计量 Q1，第三行使用 "##" 对 "#" 进行转义，最后一行最小值和最大值使用两个连续的 "|" 进行分隔，同样使用 "#|" 对 "|" 进行转义。

### <a id="example_3.4"></a>3.4 指定需要保留的变量

```SAS
%Quantify(indata = adsl, var = age, outdata = t1(keep = seq item value));
```

![image-20230202101005140](readme.assets/image-20230202101005140.png)

### <a id="example_3.5"></a>3.5 指定统计量的格式

```SAS
%Quantify(indata = adsl, var = age, stat_format = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1));
```

![image-20221108220700937](readme.assets/image-20221108220700937.png)

### <a id="example_3.6"></a>3.6 指定统计量的说明文字

```SAS
%Quantify(indata = adsl, var = age, stat_note = (#N = "靶区数" #MEAN = "平均值" #Q1 = "下四分位数" #Q3 = "上四分位数"));
```

![image-20221108221053415](readme.assets/image-20221108221053415.png)

### <a id="example_3.7"></a>3.7 指定分析变量标签

```SAS
%Quantify(indata = adsl, var = age, stat_format = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1), label = 年龄(岁));
```

![image-20221108221223083](readme.assets/image-20221108221223083.png)

### <a id="example_3.8"></a>3.8 指定缩进字符串

```SAS
%Quantify(indata = adsl, var = age, stat_format = (#MEAN = 4.1 #STD = 5.2 #MEDIAN = 4.1 #Q1 = 4.1 #Q3 = 4.1), indent = %str(\li420 ));
```

![image-20230104165045484](readme.assets/image-20230104165045484.png)

## 4. 更新日志
