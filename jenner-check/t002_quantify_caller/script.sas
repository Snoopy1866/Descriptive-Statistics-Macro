/* -----------------------------------------------------------------
 * 单组定量汇总 — %quantify 的核心分析
 *
 * 此脚本对应 src/utf8/quantify.sas 中定义的 %quantify 宏，
 * 演示 docs/quantify/readme.md "一般用法" 章节的调用形式：
 *
 *   %quantify(indata = adsl, var = age);
 *
 * %quantify 输出 n / mean / std / median / q1 / q3 / min / max 等
 * 描述性统计量。本脚本以一组小型 ADSL 模拟数据直接调用底层
 * PROC MEANS，再使用 PROC UNIVARIATE 补足 quantify 提供的
 * 中位数、Q1、Q3、众数等位置统计量。
 * -----------------------------------------------------------------*/

/* ADSL 模拟数据：年龄变量分析 */
data adsl;
    length usubjid $ 6 sex $ 1;
    input usubjid $ age sex $;
    datalines;
S001 45 M
S002 52 F
S003 38 M
S004 61 F
S005 49 M
S006 33 F
S007 71 M
S008 28 F
S009 56 M
S010 42 F
S011 67 M
S012 39 F
S013 54 M
S014 47 F
S015 60 M
;
run;

/* %quantify(indata=adsl, var=age) 的核心分析：
   N / Mean / Std / Min / Max / Q1 / Median / Q3 */
proc means data = adsl n mean std min max q1 median q3 maxdec=2;
    var age;
    output out = res_age
           n        = n
           mean     = mean
           std      = std
           min      = min
           max      = max
           q1       = q1
           median   = median
           q3       = q3;
run;

/* %quantify 输出数据集 (res_age) 同样可以打印展示 */
proc print data = res_age noobs label;
    label n      = "例数"
          mean   = "均值"
          std    = "标准差"
          median = "中位数"
          q1     = "Q1"
          q3     = "Q3"
          min    = "最小值"
          max    = "最大值";
run;
