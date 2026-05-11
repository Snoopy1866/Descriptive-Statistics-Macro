/* -----------------------------------------------------------------
 * 多组定性汇总 + 假设检验 — %qualify_multi_test 的核心分析
 *
 * 此脚本对应 src/utf8/qualify_multi_test.sas 中定义的
 * %qualify_multi_test 宏，先做分组定性汇总，再做卡方检验
 * (Pearson Chi-Square) 与 Fisher 精确检验，演示
 * docs/qualify_multi_test/readme.md "一般用法" 章节的调用：
 *
 *   %qualify_multi_test(indata = adam.adsl(where = (FASFL = "Y")),
 *                       var    = ecgcsig,
 *                       group  = arm);
 *
 * 该宏的核心实现是 PROC FREQ TABLES var * group / CHISQ FISHER，
 * 本脚本直接执行底层调用并打印检验结果数据集。
 * -----------------------------------------------------------------*/

/* ADSL 模拟数据：FAS 集，ECG 临床意义判定 × 治疗组 */
data adsl;
    length usubjid $ 6 ecgcsig $ 16 arm $ 8 fasfl $ 1;
    input usubjid $ ecgcsig $ arm $ fasfl $;
    datalines;
S001 NORMAL           ACTIVE   Y
S002 NORMAL           ACTIVE   Y
S003 NORMAL           ACTIVE   Y
S004 NORMAL           ACTIVE   Y
S005 NORMAL           ACTIVE   Y
S006 NORMAL           ACTIVE   Y
S007 NORMAL           ACTIVE   Y
S008 ABNORMAL_NCS     ACTIVE   Y
S009 ABNORMAL_NCS     ACTIVE   Y
S010 ABNORMAL_CS      ACTIVE   Y
S011 NORMAL           PLACEBO  Y
S012 NORMAL           PLACEBO  Y
S013 ABNORMAL_NCS     PLACEBO  Y
S014 ABNORMAL_NCS     PLACEBO  Y
S015 ABNORMAL_NCS     PLACEBO  Y
S016 ABNORMAL_CS      PLACEBO  Y
S017 ABNORMAL_CS      PLACEBO  Y
S018 ABNORMAL_CS      PLACEBO  Y
S019 ABNORMAL_CS      PLACEBO  Y
S020 NORMAL           PLACEBO  Y
;
run;

/* %qualify_multi_test(indata=adsl, var=ecgcsig, group=arm) 核心分析：
   PROC FREQ TABLES var * group / CHISQ — Pearson 卡方与 Fisher 精确检验 */
proc freq data = adsl (where = (fasfl = "Y"));
    tables ecgcsig * arm / chisq fisher norow nocol nopercent;
    output out = res_chisq chisq;
run;

proc print data = res_chisq noobs label;
    var _pchi_ df_pchi p_pchi;
    label _pchi_  = "Pearson 卡方统计量"
          df_pchi = "自由度"
          p_pchi  = "p 值";
run;
