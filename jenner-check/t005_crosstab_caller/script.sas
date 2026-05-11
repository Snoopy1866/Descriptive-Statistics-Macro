/* -----------------------------------------------------------------
 * 交叉表 — %crosstab 的核心分析
 *
 * 此脚本对应 src/utf8/crosstab.sas 中定义的 %crosstab 宏，
 * 用于对两个定性变量做交叉分类汇总，演示
 * docs/crosstab/readme.md 中描述的双向频数表分析。
 *
 *   %crosstab(indata = adam.adsl(where = (FASFL = "Y")),
 *             row    = sex,
 *             col    = arm);
 *
 * %crosstab 的核心是 PROC FREQ TABLES row * col，输出每个
 * 单元格的频数、行百分比、列百分比与总百分比。本脚本直接
 * 调用底层 PROC FREQ TABLES，使用 sex × arm 的经典临床
 * 受试者分布交叉表。
 * -----------------------------------------------------------------*/

/* ADSL 模拟数据：性别 × 治疗组分布 */
data adsl;
    length usubjid $ 6 arm $ 8 sex $ 1 fasfl $ 1;
    input usubjid $ sex $ arm $ fasfl $;
    datalines;
S001 M ACTIVE  Y
S002 F ACTIVE  Y
S003 M ACTIVE  Y
S004 F ACTIVE  Y
S005 M ACTIVE  Y
S006 F ACTIVE  Y
S007 M ACTIVE  Y
S008 F ACTIVE  Y
S009 M ACTIVE  Y
S010 F ACTIVE  Y
S011 M PLACEBO Y
S012 F PLACEBO Y
S013 F PLACEBO Y
S014 M PLACEBO Y
S015 F PLACEBO Y
S016 M PLACEBO Y
S017 F PLACEBO Y
S018 M PLACEBO Y
;
run;

/* %crosstab(indata=adsl, row=sex, col=arm) 的核心分析 */
proc freq data = adsl (where = (fasfl = "Y"));
    tables sex * arm / out = res_sex_arm;
run;

proc print data = res_sex_arm noobs label;
    label sex   = "性别 (row)"
          arm   = "治疗组 (col)"
          count = "频数";
run;
