﻿/*
===================================
Macro Name: qualify
Macro Label:定性指标分析
Author: wtwang
Version Date: 2023-03-08 1.0.1
              2023-11-06 1.0.2
              2023-11-08 1.0.3
              2023-11-27 1.0.4
              2023-11-28 1.0.5
              2023-12-26 1.0.6
              2023-12-28 1.0.7
              2024-01-18 1.0.8
              2024-01-22 1.0.9
              2024-01-23 1.0.10
===================================
*/

%macro qualify(INDATA,
               VAR,
               PATTERN = %nrstr(#N(#RATE)),
               BY = #AUTO,
               MISSING = FALSE,
               MISSING_NOTE = "缺失",
               MISSING_POSITION = LAST,
               OUTDATA = #AUTO,
               STAT_FORMAT = (#N = BEST., #RATE = PERCENTN9.2),
               LABEL = #AUTO,
               INDENT = #AUTO,
               SUFFIX = #AUTO,
               DEL_TEMP_DATA = TRUE)
               /des = "定性指标分析" parmbuff;


    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------初始化----------------------------------------------*/
    /*统一参数大小写*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %sysfunc(strip(%bquote(&var)));
    %let by                   = %upcase(%sysfunc(strip(%bquote(&by))));
    %let missing              = %upcase(%sysfunc(strip(%bquote(&missing))));
    %let missing_position     = %upcase(%sysfunc(strip(%bquote(&missing_position))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let stat_format          = %upcase(%sysfunc(strip(%bquote(&stat_format))));
    %let del_temp_data        = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));

    /*受支持的统计量*/
    %let stat_supported = %bquote(RATE|N);

    /*统计量对应的输出格式*/
    %let N_format = %bquote(best.);
    %let RATE_format = %bquote(percentn9.2);

    /*声明全局变量*/
    %global qualify_exit_with_error;
    %let qualify_exit_with_error = FALSE;

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
        %end;
    %end;
    %put NOTE: 分析数据集被指定为 &libname_in..&memname_in;


    /*VAR*/
    %if %bquote(&var) = %bquote() %then %do;
        %put ERROR: 未指定分析变量！;
        %goto exit_with_error;
    %end;

    %let reg_var = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:[\s,]*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*(?:=\s*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27))?)+\s*)?\))?$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %bquote(&var))) = 0 %then %do;
        %put ERROR: 参数 VAR = %bquote(&var) 格式不正确！;
        %goto exit_with_error;
    %end;
    %else %do;
        %let var_name = %upcase(%sysfunc(prxposn(&reg_var_id, 1, %bquote(&var)))); /*变量名*/
        %let var_level = %sysfunc(prxposn(&reg_var_id, 2, %bquote(&var))); /*变量水平*/

        /*检查变量存在性*/
        proc sql noprint;
            select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var_name";
        quit;
        %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
            %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 &var_name;
            %goto exit_with_error;
        %end;
        /*检查变量类型*/
        %if %bquote(&type) = num %then %do;
            %put ERROR: 参数 VAR 不支持数值型变量！;
            %goto exit_with_error;
        %end;
        
        %if %bquote(&var_level) = %bquote() %then %do;
            %let IS_LEVEL_SPECIFIED = FALSE; /*未指定各水平名称*/
        %end;
        %else %do;
            %let IS_LEVEL_SPECIFIED = TRUE; /*已指定各水平名称*/
            /*拆分变量水平*/
            %let reg_var_level_expr_unit = %bquote(/\s*(\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*(?:=\s*(\x22[^\x22]*?\x22|\x27[^\x27]*?\x27))?/);
            %let reg_var_level_expr_unit_id = %sysfunc(prxparse(&reg_var_level_expr_unit));
            %let start = 1;
            %let stop = %length(&var_level);
            %let position = 1;
            %let length = 1;
            %let i = 1;
            %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %do %until(&position = 0); /*连续匹配正则表达式*/
                %let var_level_&i._str = %substr(%bquote(&var_level), &position, &length); /*第i个水平名称和别名*/
                %if %sysfunc(prxmatch(&reg_var_level_expr_unit_id, %bquote(&&var_level_&i._str))) %then %do;
                    %let var_level_&i = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 1, %bquote(&&var_level_&i._str))); /*拆分第i个水平名称*/
                    %let var_level_&i._note = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 2, %bquote(&&var_level_&i._str))); /*拆分第i个水平别名*/
                    %if %bquote(&&var_level_&i._note) = %bquote() %then %do;
                        %let var_level_&i._note = %bquote(&&var_level_&i);
                    %end;
                %end;
                %else %do;
                    %put ERROR: 在对参数 VAR 解析第 &i 个分类名称时发生了意料之外的错误！;
                    %goto exit_with_error;
                %end;
                %let i = %eval(&i + 1);
                %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %end;
            %let var_level_n = %eval(&i - 1); /*计算匹配到的水平数量*/
        %end;
    %end;


    /*BY*/
    %if %bquote(&IS_LEVEL_SPECIFIED) = TRUE %then %do; /*已指定顺序的情况下，参数 by 不起作用*/
        %if %bquote(&by) ^= %bquote() and %bquote(&by) ^= #AUTO %then %do;
            %put WARNING: 已通过参数 VAR 指定各分类的顺序，参数 BY 已被忽略！;
        %end;
    %end;
    %else %do; /*未指定顺序的情况，参数 by 用于指定顺序*/
        %if %bquote(&by) = %bquote() %then %do;
            %put ERROR: 参数 BY 为空！;
            %goto exit_with_error;
        %end;
        %else %if %bquote(&by) = #AUTO %then %do;
            %put NOTE: 未指定各分类的排序方式，将按照各分类的频数从大到小进行排序！;
            %let by = #FREQ(DESCENDING);
        %end;

        /*解析参数 by, 检查合法性*/
        %let reg_by_expr = %bquote(/^(?:(#FREQ)|([A-Za-z_][A-Za-z_\d]*)|(?:([A-Za-z_]+(?:\d+[A-Za-z_]+)?)\.))(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/i);
        %let reg_by_id = %sysfunc(prxparse(&reg_by_expr));
        %if %sysfunc(prxmatch(&reg_by_id, %bquote(&by))) %then %do;
            %let by_stat      = %sysfunc(prxposn(&reg_by_id, 1, %bquote(&by))); /*排序基于的统计量*/
            %let by_var       = %sysfunc(prxposn(&reg_by_id, 2, %bquote(&by))); /*排序基于的变量*/
            %let by_fmt       = %sysfunc(prxposn(&reg_by_id, 3, %bquote(&by))); /*排序基于的输出格式*/
            %let by_direction = %sysfunc(prxposn(&reg_by_id, 4, %bquote(&by))); /*排序方向*/

            %if %bquote(&by_var) ^= %bquote() %then %do;
                /*检查排序变量存在性*/
                proc sql noprint;
                    select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&by_var";
                quit;
                %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
                    %put ERROR: 在 &libname_in..&memname_in 中没有找到排序变量 &by_var;
                    %goto exit_with_error;
                %end;
            %end;

            %if %bquote(&by_fmt) ^= %bquote() %then %do;
                /*检查排序格式存在性*/
                proc sql noprint;
                    select libname, memname, source into : by_fmt_libname, : by_fmt_memname, : by_fmt_source from DICTIONARY.FORMATS where fmtname = "&by_fmt";
                quit;
                %if &SQLOBS = 0 %then %do;
                    %put ERROR: 参数 BY 指定的排序格式 &by_fmt.. 不存在！;
                    %goto exit_with_error;
                %end;
                %else %do;
                    %if &by_fmt_source ^= C %then %do;
                        %put ERROR: 参数 BY 指定的排序格式 &by_fmt.. 不是 CATALOG-BASED！;
                        %goto exit_with_error;
                    %end;
                %end;
            %end;

            /*检查排序方向*/
            %if %bquote(&by_direction) = %bquote() %then %do;
                %put NOTE: 未指定排序方向，默认升序排列！;
                %let by_direction = ASCENDING;
            %end;
            %else %if %bquote(&by_direction) = ASC %then %do;
                %let by_direction = ASCENDING;
            %end;
            %else %if %bquote(&by_direction) = DESC %then %do;
                %let by_direction = DESCENDING;
            %end;
        %end;
        %else %do;
            %put ERROR: 参数 BY = %bquote(&by) 格式不正确！;
            %goto exit_with_error;
        %end;

        /*根据参数 by 调整各分类顺序，生成宏变量以供后续调用*/
        %if %bquote(&by_stat) ^= %bquote() %then %do;
            proc sql noprint;
                create table tmp_qualify_distinct_var as
                    select
                        distinct
                        &var_name        as var_level,
                        count(&var_name) as var_level_by_criteria
                    from &libname_in..&memname_in(&dataset_options_in)
                    group by var_level
                    order by var_level_by_criteria &by_direction, var_level ascending;
            quit;
        %end;
        %else %if %bquote(&by_var) ^= %bquote() %then %do;
            proc sql noprint;
                create table tmp_qualify_distinct_var as
                    select
                        distinct
                        &var_name as var_level,
                        &by_var   as var_level_by_criteria
                    from &libname_in..&memname_in(&dataset_options_in)
                    order by var_level_by_criteria &by_direction, var_level ascending;
            quit;
        %end;
        %else %if %bquote(&by_fmt) ^= %bquote() %then %do;
            proc format library = &by_fmt_libname..&by_fmt_memname cntlout = tmp_qualify_by_fmt;
                select &by_fmt;
            run;
            proc sql noprint;
                create table tmp_qualify_distinct_var as
                    select
                        label                   as var_level,
                        input(strip(start), 8.) as var_level_by_criteria
                    from tmp_qualify_by_fmt
                    order by var_level_by_criteria &by_direction, var_level ascending;
            quit;
        %end;

        proc sql noprint;
            select quote(strip(var_level)) into : var_level_1- from tmp_qualify_distinct_var;
            select count(var_level)        into : var_level_n  from tmp_qualify_distinct_var;

            %do i = 1 %to &var_level_n;
                %let var_level_&i._note = %bquote(&&var_level_&i);
            %end;
        quit;
    %end;


    /*MISSING*/
    %if %superq(missing) = %bquote() %then %do;
        %put ERROR: 参数 MISSING 为空！;
        %goto exit_with_error;
    %end;
    
    %if %superq(missing) ^= TRUE and %superq(missing) ^= FALSE %then %do;
        %put ERROR: 参数 MISSING 只能是 TRUE 或 FALSE！;
        %goto exit_with_error;
    %end;


    /*MISSING_NOTE*/
    %if %superq(missing) = TRUE %then %do;
        %if %superq(missing_note) = %bquote() %then %do;
            %put ERROR: 参数 MISSING_NOTE 为空！;
            %goto exit_with_error;
        %end;
        %else %do;
            %let reg_missing_note_id = %sysfunc(prxparse(%bquote(/^(?:\x22([^\x22]*)\x22|\x27([^\x27]*)\x27|(.*))$/)));
            %if %sysfunc(prxmatch(&reg_missing_note_id, %superq(missing_note))) %then %do;
                %let missing_note_pos_1 = %bquote(%sysfunc(prxposn(&reg_missing_note_id, 1, %superq(missing_note))));
                %let missing_note_pos_2 = %bquote(%sysfunc(prxposn(&reg_missing_note_id, 2, %superq(missing_note))));
                %let missing_note_pos_3 = %bquote(%sysfunc(prxposn(&reg_missing_note_id, 3, %superq(missing_note))));
                %if %superq(missing_note_pos_1) ^= %bquote() %then %do;
                    %let missing_note_quoted = %sysfunc(quote(%superq(missing_note_pos_1)));
                %end;
                %else %if %superq(missing_note_pos_2) ^= %bquote() %then %do;
                    %let missing_note_quoted = %sysfunc(quote(%superq(missing_note_pos_2)));
                %end;
                %else %if %superq(missing_note_pos_3) ^= %bquote() %then %do;
                    %let missing_note_quoted = %sysfunc(quote(%superq(missing_note_pos_3)));
                %end;
            %end;
        %end;
    %end;


    /*MISSING_POSITION*/
    %if %superq(missing) = TRUE %then %do;
        %if %superq(missing_position) = %bquote() %then %do;
            %put ERROR: 参数 MISSING_POSITION 为空！;
            %goto exit_with_error;
        %end;
        %else %if %superq(missing_position) = FIRST %then %do;
            %let var_level_n = %eval(&var_level_n + 1);
            %do i = &var_level_n %to 2 %by -1;
                %let var_level_&i = %unquote(%nrbquote(&&)var_level_%eval(&i - 1));
                %let var_level_&i._note = &&var_level_&i;
            %end;
            %let var_level_1 = "";
            %let var_level_1_note = %superq(missing_note_quoted);
        %end;
        %else %if %superq(missing_position) = LAST %then %do;
            %let var_level_n = %eval(&var_level_n + 1);
            %let var_level_&var_level_n = "";
            %let var_level_&var_level_n._note = %superq(missing_note_quoted);
        %end;
        %else %do;
            %put ERROR: 参数 MISSING_POSITION 只能是 FIRST 或 LAST！;
            %goto exit_with_error;
        %end;
    %end;


    /*PATTERN*/
    %if %bquote(&pattern) = %bquote() %then %do;
        %put ERROR: 参数 PATTERN 为空！;
        %goto exit_with_error;
    %end;

    %let reg_stat_expr_unit = %bquote(((?:.|\n)*?)\.?(?:(?<!#)#(&stat_supported))\.?);
    %let stat_n = %eval(%sysfunc(count(%bquote(&pattern), %bquote(#))) - %sysfunc(count(%bquote(&pattern), %bquote(##)))*2);

    %if &stat_n = 0 %then %do;
        %let reg_stat_expr = %bquote(/^((?:.|\n)*?)$/i);
    %end;
    %else %do;
        %let reg_stat_expr = %bquote(/^%sysfunc(repeat(%bquote(&reg_stat_expr_unit), %eval(&stat_n - 1)))((?:.|\n)*?)$/i);
    %end;
    %let reg_stat_id = %sysfunc(prxparse(&reg_stat_expr));

    %if %sysfunc(prxmatch(&reg_stat_id, %bquote(&pattern))) %then %do;
        %do i = 1 %to &stat_n;
            %let string_&i = %bquote(%sysfunc(prxposn(&reg_stat_id, %eval(&i * 2 - 1), %bquote(&pattern))));
            %let stat_&i   = %upcase(%sysfunc(prxposn(&reg_stat_id, %eval(&i * 2), %bquote(&pattern))));
        %end;
        %let string_&i = %sysfunc(prxposn(&reg_stat_id, %eval(&stat_n * 2 + 1), %bquote(&pattern)));
    %end;
    %else %do;
        %put ERROR: 在对参数 PATTERN 解析统计量名称及其他字符时发生了错误，导致错误的原因可能是指定了不受支持的统计量，或者未使用“##”对字符“#”进行转义！;
        %goto exit_with_error;
    %end;


    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: 参数 OUTDATA 为空！;
        %goto exit_with_error;
    %end;
    %else %do;
        %if %bquote(%upcase(&outdata)) = %bquote(#AUTO) %then %do;
            %let outdata = RES_&var_name;
        %end;

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

    %if %bquote(&stat_format) ^= #NULL %then %do;
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


    /*LABEL*/
    %if %bquote(&label) = %bquote() %then %do;
        %let label_sql_expr = %bquote();
    %end;
    %else %if %bquote(%upcase(&label)) = #AUTO %then %do;
        proc sql noprint;
            select
                (case when label ^= "" then cats(label)
                      else cats(name, "-n(%)") end)
                into: label_sql_expr from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var_name";
        quit;
    %end;
    %else %do;
        %let reg_label_id = %sysfunc(prxparse(%bquote(/^(?:\x22([^\x22]*)\x22|\x27([^\x27]*)\x27|(.*))$/)));
        %if %sysfunc(prxmatch(&reg_label_id, %superq(label))) %then %do;
            %let label_pos_1 = %bquote(%sysfunc(prxposn(&reg_label_id, 1, %superq(label))));
            %let label_pos_2 = %bquote(%sysfunc(prxposn(&reg_label_id, 2, %superq(label))));
            %let label_pos_3 = %bquote(%sysfunc(prxposn(&reg_label_id, 3, %superq(label))));
            %if %superq(label_pos_1) ^= %bquote() %then %do;
                %let label_sql_expr = %superq(label_pos_1);
            %end;
            %else %if %superq(label_pos_2) ^= %bquote() %then %do;
                %let label_sql_expr = %superq(label_pos_2);
            %end;
            %else %if %superq(label_pos_3) ^= %bquote() %then %do;
                %let label_sql_expr = %superq(label_pos_3);
            %end;
            %else %do;
                %let label_sql_expr = %bquote();
            %end;
        %end;
    %end;


    /*INDENT*/
    %if %bquote(&indent) = %bquote() %then %do;
        %let indent_sql_expr = %bquote();
    %end;
    %else %if %bquote(%upcase(&indent)) = #AUTO %then %do;
        %let indent_sql_expr = %bquote();
    %end;
    %else %do;
        %let reg_indent_id = %sysfunc(prxparse(%bquote(/^(?:\x22([^\x22]*)\x22|\x27([^\x27]*)\x27|(.*))$/)));
        %if %sysfunc(prxmatch(&reg_indent_id, %superq(indent))) %then %do;
            %let indent_pos_1 = %bquote(%sysfunc(prxposn(&reg_indent_id, 1, %superq(indent))));
            %let indent_pos_2 = %bquote(%sysfunc(prxposn(&reg_indent_id, 2, %superq(indent))));
            %let indent_pos_3 = %bquote(%sysfunc(prxposn(&reg_indent_id, 3, %superq(indent))));
            %if %superq(indent_pos_1) ^= %bquote() %then %do;
                %let indent_sql_expr = %superq(indent_pos_1);
            %end;
            %else %if %superq(indent_pos_2) ^= %bquote() %then %do;
                %let indent_sql_expr = %superq(indent_pos_2);
            %end;
            %else %if %superq(indent_pos_3) ^= %bquote() %then %do;
                %let indent_sql_expr = %superq(indent_pos_3);
            %end;
            %else %do;
                %let indent_sql_expr = %bquote();
            %end;
        %end;
    %end;


    /*SUFFIX*/
    %if %bquote(&suffix) = %bquote() %then %do;
        %let suffix_sql_expr = %bquote();
    %end;
    %else %if %bquote(%upcase(&suffix)) = #AUTO %then %do;
        %let suffix_sql_expr = %bquote(    );
    %end;
    %else %do;
        %let reg_suffix_id = %sysfunc(prxparse(%bquote(/^(?:\x22([^\x22]*)\x22|\x27([^\x27]*)\x27|(.*))$/)));
        %if %sysfunc(prxmatch(&reg_suffix_id, %superq(suffix))) %then %do;
            %let suffix_pos_1 = %bquote(%sysfunc(prxposn(&reg_suffix_id, 1, %superq(suffix))));
            %let suffix_pos_2 = %bquote(%sysfunc(prxposn(&reg_suffix_id, 2, %superq(suffix))));
            %let suffix_pos_3 = %bquote(%sysfunc(prxposn(&reg_suffix_id, 3, %superq(suffix))));
            %if %superq(suffix_pos_1) ^= %bquote() %then %do;
                %let suffix_sql_expr = %superq(suffix_pos_1);
            %end;
            %else %if %superq(suffix_pos_2) ^= %bquote() %then %do;
                %let suffix_sql_expr = %superq(suffix_pos_2);
            %end;
            %else %if %superq(suffix_pos_3) ^= %bquote() %then %do;
                %let suffix_sql_expr = %superq(suffix_pos_3);
            %end;
            %else %do;
                %let suffix_sql_expr = %bquote();
            %end;
        %end;
    %end;


    /*----------------------------------------------主程序----------------------------------------------*/
    /*1. 复制分析数据*/
    proc sql noprint;
        create table tmp_qualify_indata as
            select * from &libname_in..&memname_in(&dataset_options_in);
    quit;


    /*2. 计算频数频率*/
    /*替换 "#|" 为 "|", "##" 为 "#"*/
    %macro temp_combpl_hash(string);
        transtrn(transtrn(&string, "#|", "|"), "##", "#")
    %mend;

    proc sql noprint;
        create table tmp_qualify_outdata as
            select
                0                                as SEQ,
                %sysfunc(quote(&label_sql_expr)) as ITEM,
                ""                               as VALUE
            from tmp_qualify_indata(firstobs = 1 obs = 1)
            %do i = 1 %to &var_level_n;
                outer union corr
                select
                    &i                                                                     as SEQ,
                    cat(%sysfunc(quote(&indent_sql_expr)),
                        %unquote(&&var_level_&i._note),
                        %sysfunc(quote(&suffix_sql_expr)))                                 as ITEM,
                    sum(&var_name = &&var_level_&i)                                        as N,
                    strip(put(calculated N, &N_format))                                    as N_FMT,
                    sum(&var_name = &&var_level_&i)/count(*)                               as RATE,
                    strip(put(calculated RATE, &RATE_FORMAT))                              as RATE_FMT,
                    cat(%unquote(
                                 %do j = 1 %to &stat_n;
                                     %temp_combpl_hash("&&string_&j") %bquote(,) strip(calculated &&stat_&j.._FMT) %bquote(,)
                                 %end;
                                 %temp_combpl_hash("&&string_&j")
                                )
                        )                                                                  as VALUE
                from tmp_qualify_indata
            %end;
            %bquote(;)
    quit;


    /*3. 输出数据集*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item value
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_qualify_outdata;
    run;

    
    /*----------------------------------------------运行后处理----------------------------------------------*/
    /*删除中间数据集*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_qualify_indata
                   tmp_qualify_by_fmt
                   tmp_qualify_distinct_var
                   tmp_qualify_outdata
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
    %let qualify_exit_with_error = TRUE;

    /*正常退出*/
    %exit:
    %put NOTE: 宏 Qualify 已结束运行！;
%mend;
