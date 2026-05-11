/* -----------------------------------------------------------------
 * 多组定量汇总 + 假设检验 — %quantify_multi_test 的核心分析
 *
 * 此脚本对应 src/utf8/quantify_multi_test.sas 中定义的
 * %quantify_multi_test 宏，先做分组定量汇总，再做组间差异性检验，
 * 演示 docs/quantify_multi_test/readme.md "一般用法" 章节的调用：
 *
 *   %quantify_multi_test(indata  = adam.adsl(where = (fasfl = "Y")),
 *                        var     = age,
 *                        group   = arm,
 *                        groupby = armn);
 *
 * %quantify_multi_test 内部依次调用：
 *   - PROC UNIVARIATE NORMALTEST    (正态性检验)
 *   - PROC NPAR1WAY WILCOXON        (非参数检验)
 *   - PROC TTEST                    (两样本 t 检验)
 * 本脚本直接调用 PROC TTEST 作为最具代表性的两组 age 检验。
 * -----------------------------------------------------------------*/

/* ADSL 模拟数据：FAS 集，治疗组 × 年龄 */
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
S007 ACTIVE  41 Y
S008 ACTIVE  44 Y
S009 ACTIVE  39 Y
S010 ACTIVE  47 Y
S011 PLACEBO 56 Y
S012 PLACEBO 62 Y
S013 PLACEBO 67 Y
S014 PLACEBO 58 Y
S015 PLACEBO 54 Y
S016 PLACEBO 60 Y
S017 PLACEBO 51 Y
S018 PLACEBO 64 Y
S019 PLACEBO 57 Y
S020 PLACEBO 53 Y
;
run;

/* %quantify_multi_test 核心：PROC TTEST 比较两治疗组 age */
proc ttest data = adsl (where = (fasfl = "Y")) plots = none;
    class arm;
    var age;
run;

/* 同时输出 PROC MEANS 分组描述统计，与宏汇总输出一致 */
proc means data = adsl (where = (fasfl = "Y"))
           n mean std min max maxdec=2;
    class arm;
    var age;
run;
