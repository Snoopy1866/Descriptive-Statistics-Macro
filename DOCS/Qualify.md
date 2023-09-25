# %Qualify 使用指南

[TOC]

## 1. 功能

单个定性指标分析，输出频数、构成比（率）指标。

## 2. 语法

- <font color = blue>**%Qualify()**</font>
- <font color = blue>**%Qualify(help)**</font>
- <font color = blue>**%Qualify(_requried-argument-1_, *requried-argument-2* <, _optional-argument-1_ <, _optional-argument-2_> <, ...>>)**</font>

<font color = grey>**Tips**</font> : 运行**%Qualify()**或**%Qualify(help)**将会在浏览器中打开帮助文档。

### 2.1 Requried Argument

#### <font color = blue>INDATA</font>

<font color = grey>**Syntax**</font> : **<font color = blue><_libname._>_dataset_(_dataset_options_)</font>**

指定用于定性分析的数据集，可包含数据集选项

**_libname_**: 数据集所在的逻辑库名称

**_dataset_**: 数据集名称

**_dataset_options_**: 数据集选项，兼容 SAS 系统支持的所有数据集选项

<font color = grey>**Example**</font> :

- INDATA = ADSL
- INDATA = SHKY.ADSL
- INDATA = SHKY.ADSL(where = (FAS = "Y"))

---

#### <font color = blue>VAR</font>

<font color = grey>**Syntax**</font> :

- <font color = blue>**_variable_**</font>
- <font color = blue>**_variable_("_value-1_" <"_value-2_" ...>)**</font>
- <font color = blue>**_variable_("_value-1_" <= "_note-1_"> <"_value-2_" <= "_note-2_"> ...>)**</font>

指定定性分析的变量。

<font color = grey>**Caution**</font> :

1. 参数 VAR 不允许指定不存在于参数 INDATA 指定的数据集中的变量
2. 参数 VAR 不允许指定数值型变量

<font color = grey>**Tips**</font> :

1. 参数 VAR 可以指定空字符串作为一个分类，在这种情况下，宏程序将计算缺失分类的频数，例如：VAR = SEX("男" "女" "")。

<font color = grey>**Example**</font> :

- VAR = SEX
- VAR = SEX("男" "女")
- VAR = SEX("" = "Missing" "男" = "Male" "女" = "Female")

### 2.2 Optional Argument

#### <a id="pattern"></a><font color = blue>PATTERN</font>

<font color = grey>**Syntax**</font> : <font color = blue>**<_string(s)_>_statistic-keyword-1_<_string(s)_><_statistic-keyword-2_<_string(s)_>>**</font>

指定需计算的统计量及统计量的输出模式，输出模式定义了统计量是如何进行组合的以及在输出数据集中的位置。

其中，<font color = blue>**_statistic-keyword_**</font> 可以指定以下统计量：

- <font color = blue>RATE</font>：构成比（率）
- <font color = blue>N</font>: 频数

<font color = blue>**_string(s)_**</font> 可以是任意字符（串），若字符串含有"**#**"，则使用"**##**"进行转义。<a href="#example_3.3">示例代码</a>

<font color = grey>**Default**</font> : %nrstr(#N(#RATE))

<font color = grey>**Example**</font> :

- PATTERN = #N
- PATTERN = #N[#RATE]##

---

#### <font color = blue>BY</font>

<font color = grey>**Syntax**</font> :

- <font color = blue>**#FREQ_MAX|#FREQ_MIN**</font>
- <font color = blue>**_variable_<(ASC\<ENDING>|DESC\<ENDING>)>**</font>

指定各分类在输出数据集中的排列顺序。<a href="#example_3.4">示例代码</a>

<font color = grey>**Default**</font> : #FREQ_MAX

默认情况下，各分类按照频数从大到小排列，频数较大的分类将显示在输出数据集中靠前的位置。

<font color = grey>**Caution**</font> :

1. 若参数 VAR 指定了分析变量的分类名称，则按照各分类在参数 VAR 中指定的顺序显示在输出数据集中，此时参数 BY 无效；

---

#### <font color = blue>OUTDATA</font>

<font color = grey>**Syntax**</font> : <font color = blue>**<_libname._>_dataset_(_dataset_options_)**</font>

指定统计结果输出的数据集，可包含数据集选项，用法同参数 INDATA 。

<font color = grey>**Default**</font> : RES\_&_VAR_

默认情况下，输出数据集名称为 RES\_&_VAR_。

输出数据集有 3 个变量，分别为

- **SEQ**：行号
- **ITEM**：分类名称
- **VALUE**：指标值

其中，变量 SEQ 默认不输出到参数 OUTDATA 指定的数据集中。

<font color = grey>**Tips**</font> :

1. 如需在输出数据集中显示变量 SEQ，可使用数据集选项实现，例如：OUTDATA = T1(KEEP = SEQ ITEM VALUE) <a href="#example_3.5">示例代码</a>

---

#### <font color = blue>STAT_FORMAT</font>

<font color = grey>**Syntax**</font> : <font color = blue>**<(> #_statistic-keyword-1_ = *format-1* <#*statistic-keyword-2* = _format-2_> <...> <)>**</font>

指定输出结果中统计量的输出格式。[示例代码](#3.5 指定统计量的输出格式)

<font color = grey>**Default**</font> : (#N = BEST. #RATE = PERCENT9.2)

默认情况下，频数的输出格式为 BEST.，构成比（率）的输出格式为 PERCENT9.2，可通过参数 STAT*FORMAT 重新指定某个统计量的输出格式，\*\*\_statistic-keyword*\*\* 的用法详见 <a href="#example_3.6">示例代码</a>

<font color = grey>**Example**</font> :

- STAT_FORMAT = (#N = percent9.2 #RATE = 4.1)

---

#### <font color = blue>LABEL</font>

<font color = grey>**Syntax**</font> : <font color = blue>**_string_**</font>

指定输出结果中第一行显示的标签。<a href="#example_3.7">示例代码</a>

<font color = grey>**Default**</font> : #AUTO

默认情况下，宏程序将自动获取分析变量 VAR 的标签，若标签为空，则使用变量名 VAR 作为标签。

<font color = grey>**Example**</font> :

- LABEL = %nrstr(性别, n(%%))

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
%Qualify();
%Qualify(help);
```

### <a id="example_3.2"></a>3.2 一般用法

```sas
%Qualify(indata = adsl, var = sex);
```

![image-20230104160612553](readme.assets/image-20230104160612553-1672819577714-1.png)

```SAS
%Qualify(indata = adsl, var = sex("" = "Missing" "男" = "Male" "女" = "Female"));
```

![image-20230104160757471](readme.assets/image-20230104160757471.png)

### <a id="example_3.3"></a>3.3 指定统计量的模式

```SAS
%Qualify(indata = adsl, var = sex, pattern = %nrstr(#N[#RATE]##));
```

![image-20230104160935574](readme.assets/image-20230104160935574.png)

上述例子中，使用参数 PATTERN 改变了默认的统计量输出模式，构成比使用中括号[]包围，结尾使用 "##" 对 "#" 进行转义。

### <a id="example_3.4"></a>3.4 指定分类排序方式

```SAS
%Qualify(indata = adsl(where = (FASFL = "Y")), var = tuloc, by = #freq_max);
```

![image-20230104161141148](readme.assets/image-20230104161141148.png)

### <a id="example_3.5"></a>3.5 指定需要保留的变量

```SAS
%Qualify(indata = adsl(where = (FASFL = "Y")), var = tuloc, outdata = t1(keep = seq item value));
```

![image-20230308092641940](readme.assets/image-20230308092641940.png)

### <a id="example_3.6"></a>3.6 指定统计量的输出格式

```SAS
%Qualify(indata = adsl(where = (FASFL = "Y")), var = tuloc, stat_format = (#N = 4.0 #RATE = 5.3));
```

![image-20230104161420207](readme.assets/image-20230104161420207.png)

### <a id="example_3.7"></a>3.7 指定分析变量标签

```SAS
%Qualify(indata = adsl(where = (FASFL = "Y")), var = tuloc, by = tulocn, label = %nrstr(肿瘤部位，n(%%)));
```

![image-20230104161606223](readme.assets/image-20230104161606223.png)

### <a id="example_3.8"></a>3.8 指定缩进字符串

```SAS
%Qualify(indata = adsl(where = (FASFL = "Y")), var = tuloc, by = tulocn, label = %nrstr(肿瘤部位，n(%%)), indent = %str(\li420 ));
```

![image-20230104163050874](readme.assets/image-20230104163050874.png)

上述例子中，使用参数 INDENT 指定了缩进字符串，如需使 RTF 控制符生效，需要在传送至 ODS 的同时，指定相关元素的 PROTECTSPECIALCHAR 属性为 OFF。
