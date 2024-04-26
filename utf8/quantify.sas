/*
===================================
Macro Name: quantify
Macro Label:定量指标分析
Author: wtwang
Version Date: 2023-03-16 1.3.1
              2023-11-08 1.3.2
              2023-11-27 1.3.3
              2024-01-05 1.3.4
              2024-01-18 1.3.5
              2024-01-23 1.3.6
              2024-03-06 1.3.7
              2024-03-07 1.3.8
              2024-03-19 1.3.9
              2024-04-26 1.3.10
===================================
*/

%macro quantify(INDATA,
                VAR,
                PATTERN = %nrstr(#N(#NMISS)|#MEAN±#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX),
                OUTDATA = RES_&VAR,
                STAT_FORMAT = #AUTO,
                STAT_NOTE = #AUTO,
                LABEL = #AUTO,
                INDENT = #AUTO,
                DEL_TEMP_DATA = TRUE)
                /des = "定量指标分析" parmbuff;


    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/quantify/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------初始化----------------------------------------------*/
    /*统一参数大小写*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %upcase(%sysfunc(strip(%bquote(&var))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let stat_format          = %upcase(%sysfunc(strip(%bquote(&stat_format))));
    %let del_temp_data        = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));

    /*受支持的统计量*/
    %let stat_supported = %bquote(KURTOSIS|SKEWNESS|MEDIAN|QRANGE|STDDEV|STDERR|NMISS|RANGE|KURT|LCLM|MEAN|MODE|SKEW|UCLM|CSS|MAX|MIN|P10|P20|P25|P30|P40|P50|P60|P70|P75|P80|P90|P95|P99|STD|SUM|USS|VAR|CV|P1|P5|Q1|Q3|N);

    /*统计量对应的说明文字*/
    %let KURTOSIS_note = %bquote(峰度);
    %let SKEWNESS_note = %bquote(偏度);
    %let MEDIAN_note   = %bquote(中位数);
    %let QRANGE_note   = %bquote(四分位间距);
    %let STDDEV_note   = %bquote(标准差);
    %let STDERR_note   = %bquote(标准误);
    %let NMISS_note    = %bquote(缺失);
    %let RANGE_note    = %bquote(极差);
    %let KURT_note     = %bquote(峰度);
    %let LCLM_note     = %bquote(均值的 95% 置信下限);
    %let MEAN_note     = %bquote(均值);
    %let MODE_note     = %bquote(众数);
    %let SKEW_note     = %bquote(偏度);
    %let UCLM_note     = %bquote(均值的 95% 置信上限);
    %let CSS_note      = %bquote(校正平方和);
    %let MAX_note      = %bquote(最大值);
    %let MIN_note      = %bquote(最小值);
    %let P10_note      = %bquote(第 10 百分位数);
    %let P20_note      = %bquote(第 20 百分位数);
    %let P25_note      = %bquote(第 25 百分位数);
    %let P30_note      = %bquote(第 30 百分位数);
    %let P40_note      = %bquote(第 40 百分位数);
    %let P50_note      = %bquote(第 50 百分位数);
    %let P60_note      = %bquote(第 60 百分位数);
    %let P70_note      = %bquote(第 70 百分位数);
    %let P75_note      = %bquote(第 75 百分位数);
    %let P80_note      = %bquote(第 80 百分位数);
    %let P90_note      = %bquote(第 90 百分位数);
    %let P95_note      = %bquote(第 95 百分位数);
    %let P99_note      = %bquote(第 99 百分位数);
    %let STD_note      = %bquote(标准差);
    %let SUM_note      = %bquote(总和);
    %let USS_note      = %bquote(未校正平方和);
    %let VAR_note      = %bquote(方差);
    %let CV_note       = %bquote(变异系数);
    %let P1_note       = %bquote(第 1 百分位数);
    %let P5_note       = %bquote(第 5 百分位数);
    %let Q1_note       = %bquote(Q1);
    %let Q3_note       = %bquote(Q3);
    %let N_note        = %bquote(例数);


    /*统计量对应的PROC MEANS过程输出的数据集中的变量名*/
    %let KURTOSIS_var = %bquote(&var._Kurt);
    %let SKEWNESS_var = %bquote(&var._Skew);
    %let MEDIAN_var   = %bquote(&var._Median);
    %let QRANGE_var   = %bquote(&var._QEange);
    %let STDDEV_var   = %bquote(&var._StdDev);
    %let STDERR_var   = %bquote(&var._StdErr);
    %let NMISS_var    = %bquote(&var._NMiss);
    %let RANGE_var    = %bquote(&var._Range);
    %let KURT_var     = %bquote(&var._Kurt);
    %let LCLM_var     = %bquote(&var._LCLM);
    %let MEAN_var     = %bquote(&var._Mean);
    %let MODE_var     = %bquote(&var._Mode);
    %let SKEW_var     = %bquote(&var._Skew);
    %let UCLM_var     = %bquote(&var._UCLM);
    %let CSS_var      = %bquote(&var._CSS);
    %let MAX_var      = %bquote(&var._Max);
    %let MIN_var      = %bquote(&var._Min);
    %let P10_var      = %bquote(&var._P10);
    %let P20_var      = %bquote(&var._P20);
    %let P25_var      = %bquote(&var._P25);
    %let P30_var      = %bquote(&var._P30);
    %let P40_var      = %bquote(&var._P40);
    %let P50_var      = %bquote(&var._P50);
    %let P60_var      = %bquote(&var._P60);
    %let P70_var      = %bquote(&var._P70);
    %let P75_var      = %bquote(&var._P75);
    %let P80_var      = %bquote(&var._P80);
    %let P90_var      = %bquote(&var._P90);
    %let P95_var      = %bquote(&var._P95);
    %let P99_var      = %bquote(&var._P99);
    %let STD_var      = %bquote(&var._StdDev);
    %let SUM_var      = %bquote(&var._Sum);
    %let USS_var      = %bquote(&var._USS);
    %let VAR_var      = %bquote(&var._Var);
    %let CV_var       = %bquote(&var._CV);
    %let P1_var       = %bquote(&var._P1);
    %let P5_var       = %bquote(&var._P5);
    %let Q1_var       = %bquote(&var._Q1);
    %let Q3_var       = %bquote(&var._Q3);
    %let N_var        = %bquote(&var._N);


    /*声明全局变量*/
    /*全局输出格式*/
    %global KURTOSIS_format
            SKEWNESS_format
            MEDIAN_format
            QRANGE_format
            STDDEV_format
            STDERR_format
            NMISS_format
            RANGE_format
            KURT_format
            LCLM_format
            MEAN_format
            MODE_format
            SKEW_format
            UCLM_format
            CSS_format
            MAX_format
            MIN_format
            P10_format
            P20_format
            P25_format
            P30_format
            P40_format
            P50_format
            P60_format
            P70_format
            P75_format
            P80_format
            P90_format
            P95_format
            P99_format
            STD_format
            SUM_format
            USS_format
            VAR_format
            CV_format
            P1_format
            P5_format
            Q1_format
            Q3_format
            N_format
            ;
    %global quantify_exit_with_error;
    %let quantify_exit_with_error = FALSE;

    /*声明局部变量*/
    %local i j
           libname_in  memname_in  dataset_options_in
           libname_out memname_out dataset_options_out;

    /*----------------------------------------------参数检查----------------------------------------------*/
    /*INDATA*/
    %if %bquote(&indata) = %bquote() %then %do;
        %put ERROR: 未指定分析数据集！;
        %goto exit_with_error;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, %bquote(&indata))) = 0 %then %do;
            %put ERROR: 参数 INDATA = %bquote(&indata) 格式不正确！;
            %goto exit_with_error;
        %end;
        %else %do;
            %let libname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 1, %bquote(&indata))));
            %let memname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 2, %bquote(&indata))));
            %let dataset_options_in = %sysfunc(prxposn(&reg_indata_id, 3, %bquote(&indata)));
            %if &libname_in = %bquote() %then %let libname_in = WORK; /*未指定逻辑库，默认为WORK目录*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_in 逻辑库不存在！;
                %goto exit_with_error;
            %end;

            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in" and memname = "&memname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: 在 &libname_in 逻辑库中没有找到 &memname_in 数据集！;
                %goto exit_with_error;
            %end;

            proc sql noprint;
                select count(*) into : nobs from &indata;
            quit;
            %if &nobs = 0 %then %do;
                %put ERROR: 分析数据集 &indata 为空！;
                %goto exit_with_error;
            %end;
        %end;
    %end;
    %put NOTE: 分析数据集被指定为 &libname_in..&memname_in;

    /*VAR*/
    %if %bquote(&var) = %bquote() %then %do;
        %put ERROR: 未指定分析变量！;
        %goto exit_with_error;
    %end;

    %let reg_var = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %bquote(&var))) = 0 %then %do;
        %put ERROR: 参数 VAR = %bquote(&var) 格式不正确！;
        %goto exit_with_error;
    %end;
    %else %do;
        proc sql noprint;
            select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var";
        quit;
        %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
            %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 &var;
            %goto exit_with_error;
        %end;
        %else %if &type = char %then %do; /*分析变量是一个字符型变量*/
            %put ERROR: 无法对字符型变量 &var 进行定量分析！;
            %goto exit_with_error;
        %end;
    %end;


    /*PATTERN*/
    %if %bquote(&pattern) = %bquote() %then %do;
        %put ERROR: 参数 PATTERN 为空！;
        %goto exit_with_error;
    %end;

    /*提取每一行的模式*/
    %let part_n = %eval(%sysfunc(count(%bquote(&pattern), %bquote(|))) - %sysfunc(count(%bquote(&pattern), %bquote(#|))) + 1);

    %if &part_n = 1 %then %do;
        %let reg_part_expr = %bquote(/^((?:.|\n)+)$/);
    %end;
    %else %do;
        %let reg_part_expr_unit = %bquote(((?:.|\n)+)(?<!#)\|);
        %let reg_part_expr = %bquote(/^%sysfunc(repeat(%bquote(&reg_part_expr_unit), %eval(&part_n - 2)))((?:.|\n)+)$/);
    %end;
    %let reg_part_id = %sysfunc(prxparse(&reg_part_expr));

    %if %sysfunc(prxmatch(&reg_part_id, %bquote(&pattern))) %then %do;
        %do i = 1 %to &part_n;
            %let part_&i = %sysfunc(prxposn(&reg_part_id, &i, %bquote(&pattern))); /*每一行的pattern*/
        %end;
    %end;
    %else %do;
        %put ERROR: 参数 PATTERN = %bquote(&pattern) 格式不正确！;
        %goto exit_with_error;
    %end;

    /*提取每一行的统计量和字符串*/
    %let reg_stat_expr_unit = %bquote(((?:.|\n)*?)\.?(?:(?<!#)#(&stat_supported))\.?);
    %let IS_VALID_PATTERN_PART = TRUE;
    %do i = 1 %to &part_n;
        %let stat_&i = %eval(%sysfunc(count(%bquote(&&part_&i), %bquote(#))) - %sysfunc(count(%bquote(&&part_&i), %bquote(#|)))
                                                                             - %sysfunc(count(%bquote(&&part_&i), %bquote(##)))*2);

        %if &&stat_&i = 0 %then %do;
            %let reg_stat_expr = %bquote(/^((?:.|\n)*?)$/i);
        %end;
        %else %do;
            %let reg_stat_expr = %bquote(/^%sysfunc(repeat(%bquote(&reg_stat_expr_unit), %eval(&&stat_&i - 1)))((?:.|\n)*?)$/i);
        %end;
        %let reg_stat_id = %sysfunc(prxparse(&reg_stat_expr));

        %if %sysfunc(prxmatch(&reg_stat_id, %bquote(&&part_&i))) %then %do;
            %do j = 1 %to &&stat_&i;
                %let string_&i._&j = %bquote(%sysfunc(prxposn(&reg_stat_id, %eval(&j * 2 - 1), %bquote(&&part_&i))));
                %let stat_&i._&j = %upcase(%sysfunc(prxposn(&reg_stat_id, %eval(&j * 2), %bquote(&&part_&i))));
            %end;
            %let string_&i._&j = %sysfunc(prxposn(&reg_stat_id, %eval(&&stat_&i * 2 + 1), %bquote(&&part_&i)));
        %end;
        %else %do;
            %put ERROR: 在对参数 PATTERN 解析第 &i 行 %bquote(&&part_&i) 统计量名称及其他字符时发生了错误，导致错误的原因可能是指定了不受支持的统计量，或者未使用“##”对字符“#”进行转义！;
            %let IS_VALID_PATTERN_PART = FALSE;
        %end;
    %end;

    %if &IS_VALID_PATTERN_PART = FALSE %then %do;
        %goto exit_with_error;
    %end;

    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: 参数 OUTDATA 为空！;
        %goto exit_with_error;
    %end;
    %else %do;
        %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_outdata_id, %bquote(&outdata))) = 0 %then %do;
            %put ERROR: 参数 OUTDATA = %bquote(&outdata) 格式不正确！;
            %goto exit_with_error;
        %end;
        %else %do;
            %let libname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 1, &outdata)));
            %let memname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 2, &outdata)));
            %let dataset_options_out = %sysfunc(prxposn(&reg_outdata_id, 3, &outdata));
            %if &libname_out = %bquote() %then %let libname_out = WORK; /*未指定逻辑库，默认为WORK目录*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_out";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_out 逻辑库不存在！;
                %goto exit_with_error;
            %end;
        %end;
        %put NOTE: 输出数据集被指定为 &libname_out..&memname_out;
    %end;

    /*STAT_FORMAT*/
    %if %bquote(&stat_format) = %bquote() %then %do;
        %put ERROR: 参数 STAT_FORMAT 为空！;
        %goto exit_with_error;
    %end;

    %if %bquote(&stat_format) = #PREV %then %do;
        %put NOTE: 使用上一次调用时的统计量输出格式！;
    %end;
    %else %do;
        data tmp_quantify_valuefmt;
            set &indata;
            &var._fmt = strip(vvalue(&var));
            keep &var &var._fmt;
        run;

        /*计算整数部分和小数部分的位数*/
        proc sql noprint;
            select max(lengthn(scan(&var._fmt, 1, "."))) into : int_len trimmed from tmp_quantify_valuefmt;
            select max(lengthn(scan(&var._fmt, 2, "."))) into : dec_len trimmed from tmp_quantify_valuefmt;
        quit;

        /*自动计算统计量的输出格式*/
        %let KURTOSIS_format = %eval(&int_len + %sysfunc(min(&dec_len + 3, 4)) + 2).%sysfunc(min(&dec_len + 3, 4)); /*比原始数据小数位数多3，最多不超过4*/
        %let SKEWNESS_format = &KURTOSIS_format;
        %let MEDIAN_format   = %eval(&int_len + %sysfunc(min(&dec_len + 1, 4)) + 2).%sysfunc(min(&dec_len + 1, 4)); /*比原始数据小数位数多1，最多不超过4*/
        %let QRANGE_format   = &MEDIAN_format;
        %let STDDEV_format   = %eval(&int_len + %sysfunc(min(&dec_len + 2, 4)) + 2).%sysfunc(min(&dec_len + 2, 4)); /*比原始数据小数位数多2，最多不超过4*/
        %let STDERR_format   = &STDDEV_format;
        %let NMISS_format    = best.; /*计数统计量，由 SAS 决定输出格式*/
        %let RANGE_format    = %eval(&int_len + %sysfunc(min(&dec_len, 4)) + 2).%sysfunc(min(&dec_len, 4)); /*与原始数据小数位数相同，最多不超过4*/
        %let KURT_format     = &KURTOSIS_format;
        %let LCLM_format     = &MEDIAN_format;
        %let MEAN_format     = &MEDIAN_format;
        %let MODE_format     = &RANGE_format;
        %let SKEW_format     = &SKEWNESS_format;
        %let UCLM_format     = &LCLM_format;
        %let CSS_format      = &STDDEV_format;
        %let MAX_format      = &RANGE_format;
        %let MIN_format      = &RANGE_format;
        %let P10_format      = &MEDIAN_format;
        %let P20_format      = &MEDIAN_format;
        %let P25_format      = &MEDIAN_format;
        %let P30_format      = &MEDIAN_format;
        %let P40_format      = &MEDIAN_format;
        %let P50_format      = &MEDIAN_format;
        %let P60_format      = &MEDIAN_format;
        %let P70_format      = &MEDIAN_format;
        %let P75_format      = &MEDIAN_format;
        %let P80_format      = &MEDIAN_format;
        %let P90_format      = &MEDIAN_format;
        %let P95_format      = &MEDIAN_format;
        %let P99_format      = &MEDIAN_format;
        %let STD_format      = &STDDEV_format;
        %let SUM_format      = &RANGE_format;
        %let USS_format      = &CSS_format;
        %let VAR_format      = &STD_format;
        %let CV_format       = &STD_format;
        %let P1_format       = &MEDIAN_format;
        %let P5_format       = &MEDIAN_format;
        %let Q1_format       = &MEDIAN_format;
        %let Q3_format       = &MEDIAN_format;
        %let N_format        = &NMISS_format;

        %if %bquote(&stat_format) ^= #AUTO %then %do;
            %let stat_format_n = %eval(%sysfunc(kcountw(%bquote(&stat_format), %bquote(=), q)) - 1);
            %let reg_stat_format_expr_unit = %bquote(\s*#(&stat_supported|TS|P)\s*=\s*((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)[\s,]*);
            %let reg_stat_format_expr = %bquote(/^\(?%sysfunc(repeat(&reg_stat_format_expr_unit, %eval(&stat_format_n - 1)))\)?$/i);
            %let reg_stat_format_id = %sysfunc(prxparse(&reg_stat_format_expr));

            %if %sysfunc(prxmatch(&reg_stat_format_id, %bquote(&stat_format))) %then %do;
                %let IS_VALID_STAT_FORMAT = TRUE;
                %do i = 1 %to &stat_format_n;
                    %let stat_whose_format_2be_update = %upcase(%sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3 - 2), %bquote(&stat_format))));
                    %let stat_new_format = %sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3 - 1), %bquote(&stat_format)));
                    %let stat_new_format_base = %sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3), %bquote(&stat_format)));
                    %let &stat_whose_format_2be_update._format = %bquote(&stat_new_format); /*更新统计量的输出格式*/

                    %if %bquote(&stat_new_format_base) ^= %bquote() %then %do;
                        proc sql noprint;
                            select * from DICTIONARY.FORMATS where fmtname = "&stat_new_format_base" and fmttype = "F";
                        quit;
                        %if &SQLOBS = 0 %then %do;
                            %put ERROR: 为统计量 &stat_whose_format_2be_update 指定的输出格式 &stat_new_format_base 不存在！;
                            %let IS_VALID_STAT_FORMAT = FALSE;
                        %end;
                    %end;
                %end;
                %if &IS_VALID_STAT_FORMAT = FALSE %then %do;
                    %goto exit_with_error;
                %end;
            %end;
            %else %do;
                %put ERROR: 参数 STAT_FORMAT = %bquote(&stat_format) 格式不正确！;
                %goto exit_with_error;
            %end;
        %end;
    %end;


    /*STAT_NOTE*/
    %if %bquote(&stat_note) = %bquote() %then %do;
        %put ERROR: 参数 STAT_NOTE 为空！;
        %goto exit_with_error;
    %end; 

    %if %bquote(&stat_note) ^= #AUTO %then %do;
        %let stat_note_n = %eval(%sysfunc(kcountw(%bquote(&stat_note), %bquote(=), q)) - 1);
        %let reg_stat_note_expr_unit = %bquote(\s*#(&stat_supported)\s*=\s*"((?:.|\n)*)"[\s,]*);
        %let reg_stat_note_expr = %bquote(/^\(?%sysfunc(repeat(&reg_stat_note_expr_unit, %eval(&stat_note_n - 1)))\)?$/i);
        %let reg_stat_note_id = %sysfunc(prxparse(&reg_stat_note_expr));

        %if %sysfunc(prxmatch(&reg_stat_note_id, %bquote(&stat_note))) %then %do;
            %do i = 1 %to &stat_note_n;
                %let stat_whose_note_2be_update = %upcase(%sysfunc(prxposn(&reg_stat_note_id, %eval(&i * 2 - 1), %bquote(&stat_note))));
                %let stat_new_note = %sysfunc(prxposn(&reg_stat_note_id, %eval(&i * 2), %bquote(&stat_note)));
                %let &stat_whose_note_2be_update._note = %bquote(&stat_new_note); /*更新统计量的说明文字*/
            %end;
        %end;
        %else %do;
            %put ERROR: 参数 STAT_NOTE = %bquote(&stat_note) 格式不正确！;
            %goto exit_with_error;
        %end;
    %end;


    /*LABEL*/
    %if %superq(label) = %bquote() %then %do;
        %let label_sql_expr = %bquote('');
    %end;
    %else %if %qupcase(&label) = #AUTO %then %do;
        proc sql noprint;
            select
                (case when label ^= "" then cats("'", label, "'")
                      else cats("'", name, "-n(%)", "'") end)
                into: label_sql_expr from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&VAR";
        quit;
    %end;
    %else %do;
        %let reg_label_id = %sysfunc(prxparse(%bquote(/^(\x22[^\x22]*\x22|\x27[^\x27]*\x27)$/)));
        %if %sysfunc(prxmatch(&reg_label_id, %superq(label))) %then %do;
            %let label_sql_expr = %superq(label);
        %end;
        %else %do;
            %put ERROR: 参数 LABEL 格式不正确，指定的字符串必须使用匹配的引号包围！;
            %goto exit;
        %end;
    %end;


    /*INDENT*/
    %if %superq(indent) = %bquote() %then %do;
        %let indent_sql_expr = %bquote('');
    %end;
    %else %if %qupcase(&indent) = #AUTO %then %do;
        %let indent_sql_expr = %bquote('    ');
    %end;
    %else %do;
        %let reg_indent_id = %sysfunc(prxparse(%bquote(/^(\x22[^\x22]*\x22|\x27[^\x27]*\x27)$/)));
        %if %sysfunc(prxmatch(&reg_indent_id, %superq(indent))) %then %do;
            %let indent_sql_expr = %superq(indent);
        %end;
        %else %do;
            %put ERROR: 参数 INDENT 格式不正确，指定的字符串必须使用匹配的引号包围！;
            %goto exit;
        %end;
    %end;
    


    /*----------------------------------------------主程序----------------------------------------------*/
    /*1. 检查参数 PATTERN 是否指定了统计量*/
    %let IS_NO_STAT_SPECIFIED = TRUE;
    %do i = 1 %to &part_n;
        %if &&stat_&i > 0 %then %do;
            %let IS_NO_STAT_SPECIFIED = FALSE;
        %end;
    %end;

    %if &IS_NO_STAT_SPECIFIED = FALSE %then %do; /*指定了任意一个统计量，可以调用 PROC MEANS 过程*/
        proc means data = &indata %do i = 1 %to &part_n;
                                      %do j = 1 %to &&stat_&i;
                                          %bquote( )%bquote(&&stat_&i._&j)
                                      %end;
                                  %end;
                                  noprint
                                  ;
            var &var;
            output out = tmp_quantify_stat %do i = 1 %to &part_n;
                                       %do j = 1 %to &&stat_&i;
                                           %bquote(&&stat_&i._&j)%bquote(=)%bquote( )
                                       %end;
                                   %end;
                                   /autoname autolabel;
        run;
    %end;
    %else %do; /*未指定任何统计量，仍然输出 tmp_quantify_stat 数据集，以兼容后续程序步骤*/
        %put NOTE: 未指定任何统计量！;
        data tmp_quantify_stat;
            INFO = "NO_STAT_SPECIFIED";
        run;
    %end;


    /*2. 根据参数 PATTERN 提取统计量输出结果，调整格式*/
    /*替换 "#|" 为 "|", "##" 为 "#"*/
    %macro temp_combpl_hash(string);
        transtrn(transtrn(&string, "#|", "|"), "##", "#")
    %mend;

    %let reg_digit_format_id = %sysfunc(prxparse(%bquote(/\d+\.(\d+)?/))); /*w.d输出格式，改用 round 函数处理，避免舍入错误*/

    proc sql noprint;
        create table tmp_quantify_outdata as
            select
                0                                 as SEQ,
                %unquote(%superq(label_sql_expr)) as ITEM,
                ""                                as VALUE
            from tmp_quantify_stat
            outer union corr
            %do i = 1 %to &part_n;
                select
                    &i as SEQ,
                    cat(%unquote(%superq(indent_sql_expr)),
                        %unquote(
                                 %do j = 1 %to &&stat_&i;
                                     %temp_combpl_hash("&&string_&i._&j") %bquote(,)
                                     "&&&&&&stat_&i._&j.._note" %bquote(,)
                                 %end;
                                 %temp_combpl_hash("&&string_&i._&j")
                                )
                        )
                        as ITEM,
                    cat(%unquote(
                                 %do j = 1 %to &&stat_&i;
                                     %temp_combpl_hash("&&string_&i._&j") %bquote(,)
                                     %if %sysfunc(prxmatch(&reg_digit_format_id, &&&&&&stat_&i._&j.._format)) %then %do;
                                         %let precision = %sysfunc(prxposn(&reg_digit_format_id, 1, &&&&&&stat_&i._&j.._format)); /*保留有效数字的位数*/
                                         %if %bquote(&precision) = %bquote() %then %do;
                                             %let precision = 0;
                                         %end;
                                         strip(put(round(&&&&&&stat_&i._&j.._var, 1e-&precision), &&&&&&stat_&i._&j.._format)) /*w.d 格式，先 round 然后 put*/
                                     %end;
                                     %else %do;
                                         strip(put(&&&&&&stat_&i._&j.._var, &&&&&&stat_&i._&j.._format)) /*其他格式，直接 put*/
                                     %end;
                                     %bquote(,)
                                 %end;
                                 %temp_combpl_hash("&&string_&i._&j")
                                )
                        )
                        as VALUE
                from tmp_quantify_stat
                %if &i < &part_n %then %do;
                    outer union corr
                %end;
                %else %do;
                    %bquote(;)
                %end;
            %end;
    quit;

    /*3. 输出数据集*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item value
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_quantify_outdata;
    run;

    /*----------------------------------------------运行后处理----------------------------------------------*/
    /*删除中间数据集*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_quantify_stat
                   tmp_quantify_outdata
                   tmp_quantify_valuefmt
                   ;
        quit;
    %end;

    /*删除临时宏*/
    proc catalog catalog = work.sasmacr;
        delete temp_combpl_hash.macro;
    quit;
    %goto exit;

    /*异常退出*/
    %exit_with_error:
    %let quantify_exit_with_error = TRUE;

    /*正常退出*/
    %exit:
    %put NOTE: 宏 quantify 已结束运行！;
%mend;
