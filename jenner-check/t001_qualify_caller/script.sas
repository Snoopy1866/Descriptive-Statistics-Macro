/* -----------------------------------------------------------------
 * 单组定性汇总 — %qualify 的核心分析
 *
 * 此脚本对应 src/utf8/qualify.sas 中定义的 %qualify 宏，
 * 演示 docs/qualify/readme.md "一般用法" 章节的调用形式：
 *
 *   %qualify(indata = adam.adsl(where = (FASFL = "Y")),
 *            var    = ecgcsig);
 *
 * %qualify 宏在内部对 ECG 临床意义判定变量做频数与构成比统计，
 * 等价于直接调用 PROC FREQ。本脚本以一组小型 ADSL 模拟数据
 * 直接执行底层 PROC FREQ 调用，再使用 PROC PRINT 展示
 * 与宏输出数据集 res_ecgcsig 同构的频数/构成比汇总。
 * -----------------------------------------------------------------*/

/* ADSL 模拟数据：清单 FAS 集 (FASFL = "Y") 中 ECG 异常临床意义判定 */
data adsl;
    length usubjid $ 6 ecgcsig $ 16 fasfl $ 1 sex $ 1;
    input usubjid $ ecgcsig $ fasfl $ age sex $;
    datalines;
S001 NORMAL           Y 45 M
S002 ABNORMAL_NCS     Y 52 F
S003 NORMAL           Y 38 M
S004 ABNORMAL_CS      Y 61 F
S005 NORMAL           Y 49 M
S006 ABNORMAL_NCS     Y 33 F
S007 NORMAL           Y 71 M
S008 ABNORMAL_CS      Y 28 F
S009 NORMAL           Y 56 M
S010 NORMAL           Y 42 F
S011 ABNORMAL_NCS     Y 67 M
S012 NORMAL           Y 39 F
;
run;

/* %qualify(indata=adsl(where=(FASFL="Y")), var=ecgcsig) 的核心分析 */
proc freq data = adsl (where = (fasfl = "Y"));
    tables ecgcsig / out = res_ecgcsig;
run;

/* %qualify 默认输出包含 item / freq / rate 列 — 这里同样展示 */
proc print data = res_ecgcsig label;
    label ecgcsig = "ECG 临床意义判定"
          count   = "频数 (freq)"
          percent = "构成比 % (rate)";
run;
