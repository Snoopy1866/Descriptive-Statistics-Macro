/* -----------------------------------------------------------------
 * 多组定量汇总 — %quantify_multi 的核心分析
 *
 * 此脚本对应 src/utf8/quantify_multi.sas 中定义的 %quantify_multi 宏，
 * 用于按治疗组 (ARM) 对一个定量指标分组汇总，演示
 * docs/quantify_multi/readme.md "一般用法" 章节的调用形式：
 *
 *   %quantify_multi(indata = adam.adsl(where = (FASFL = "Y")),
 *                   var    = age,
 *                   group  = arm);
 *
 * %quantify_multi 在不同治疗组内分别计算 N / Mean / Std / Median /
 * Q1 / Q3 / Min / Max，相当于在 PROC MEANS / SUMMARY 中使用
 * CLASS arm。本脚本直接对 ADSL 模拟数据执行 PROC MEANS CLASS。
 * -----------------------------------------------------------------*/

/* ADSL 模拟数据：FAS 集，含治疗组与年龄 */
data adsl;
    length usubjid $ 6 arm $ 8 fasfl $ 1;
    input usubjid $ arm $ age fasfl $;
    datalines;
S001 ACTIVE  45 Y
S002 ACTIVE  52 Y
S003 ACTIVE  38 Y
S004 ACTIVE  61 Y
S005 ACTIVE  49 Y
S006 ACTIVE  33 Y
S007 ACTIVE  71 Y
S008 ACTIVE  28 Y
S009 PLACEBO 56 Y
S010 PLACEBO 42 Y
S011 PLACEBO 67 Y
S012 PLACEBO 39 Y
S013 PLACEBO 54 Y
S014 PLACEBO 47 Y
S015 PLACEBO 60 Y
S016 PLACEBO 51 Y
;
run;

/* %quantify_multi(indata=adsl, var=age, group=arm) 的核心分析 */
proc means data = adsl (where = (fasfl = "Y"))
           n mean std min max q1 median q3 maxdec=2;
    class arm;
    var age;
    output out = res_age_by_arm
           n = n  mean = mean  std = std
           min = min  max = max  q1 = q1
           median = median  q3 = q3;
run;

proc print data = res_age_by_arm noobs label;
    where _type_ = 1; /* class arm 层级 */
    var arm n mean std median q1 q3 min max;
    label arm = "治疗组"
          n   = "例数"
          mean = "均值"
          std = "标准差"
          median = "中位数"
          q1 = "Q1" q3 = "Q3"
          min = "最小值" max = "最大值";
run;
