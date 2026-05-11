/* -----------------------------------------------------------------
 * 多组定性汇总 — %qualify_multi 的核心分析
 *
 * 此脚本对应 src/utf8/qualify_multi.sas 中定义的 %qualify_multi 宏，
 * 用于在不同治疗组 (ARM) 之间对一个定性指标进行频数与构成比汇总，
 * 演示 docs/qualify_multi/readme.md "一般用法" 章节的调用形式：
 *
 *   %qualify_multi(indata = adam.adsl(where = (FASFL = "Y")),
 *                  var    = ecgcsig,
 *                  group  = arm);
 *
 * %qualify_multi 内部对 ARM × ECG 做交叉频数统计，等价于
 * 调用 PROC FREQ 的双变量交叉表分析。本脚本直接对 ADSL
 * 模拟数据执行底层 PROC FREQ TABLES arm * ecgcsig。
 * -----------------------------------------------------------------*/

/* ADSL 模拟数据：FAS 集，含治疗组与 ECG 临床意义判定 */
data adsl;
    length usubjid $ 6 ecgcsig $ 16 arm $ 8 fasfl $ 1;
    input usubjid $ ecgcsig $ arm $ fasfl $;
    datalines;
S001 NORMAL           ACTIVE   Y
S002 ABNORMAL_NCS     ACTIVE   Y
S003 NORMAL           ACTIVE   Y
S004 ABNORMAL_CS      ACTIVE   Y
S005 NORMAL           ACTIVE   Y
S006 NORMAL           ACTIVE   Y
S007 NORMAL           ACTIVE   Y
S008 ABNORMAL_NCS     ACTIVE   Y
S009 NORMAL           PLACEBO  Y
S010 NORMAL           PLACEBO  Y
S011 ABNORMAL_CS      PLACEBO  Y
S012 NORMAL           PLACEBO  Y
S013 NORMAL           PLACEBO  Y
S014 ABNORMAL_NCS     PLACEBO  Y
S015 NORMAL           PLACEBO  Y
S016 NORMAL           PLACEBO  Y
;
run;

/* %qualify_multi(indata=adsl, var=ecgcsig, group=arm) 的核心分析 */
proc freq data = adsl (where = (fasfl = "Y"));
    tables arm * ecgcsig / out = res_arm_ecg nopercent;
run;

/* 各组内构成比，使用 PROC FREQ 的 ROW 统计 */
proc freq data = adsl (where = (fasfl = "Y"));
    tables arm * ecgcsig / norow nocol nopercent;
run;

proc print data = res_arm_ecg label;
    label arm     = "治疗组 (group)"
          ecgcsig = "ECG 临床意义判定"
          count   = "频数";
run;
