﻿/*
===================================
Macro Name: qualify_multi_test
Macro Label:多组别定性指标汇总统计
Author: wtwang
Version Date: 2024-01-08 0.1
              2024-01-18 0.2
===================================
*/

%macro qualify_multi_test(INDATA,
                          VAR,
                          GROUP,
                          GROUPBY,
                          OUTDATA = RES_&VAR,
                          PATTERN = %nrstr(#N(#RATE)),
                          BY = #AUTO,
                          STAT_FORMAT = (#N = BEST. #RATE = PERCENT9.2),
                          LABEL = #AUTO,
                          INDENT = #AUTO,
                          T_FORMAT = #AUTO,
                          P_FORMAT = #AUTO,
                          PROCHTTP_PROXY = 127.0.0.1:7890,
                          DEL_TEMP_DATA = TRUE)
                          /des = "多组别定性指标汇总统计" parmbuff;

    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify_multi_test/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------初始化----------------------------------------------*/
    /*统一参数大小写*/
    %let group                = %sysfunc(strip(%bquote(&group)));
    %let groupby              = %upcase(%sysfunc(strip(%bquote(&groupby))));
    %let t_format             = %upcase(%sysfunc(strip(%bquote(&t_format))));
    %let p_format             = %upcase(%sysfunc(strip(%bquote(&p_format))));

    /*声明全局变量*/
    %global qmt_exit_with_error;

    /*声明局部变量*/
    %local i j
           libname_in  memname_in  dataset_options_in
           libname_out memname_out dataset_options_out;

    /*检查依赖*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUALIFY_MULTI";
    quit;
    %if &SQLOBS = 0 %then %do;
        %put WARNING: 前置依赖缺失，正在尝试从网络上下载......;

        %let cur_encoding = %sysfunc(getOption(ENCODING));
        %if %bquote(&cur_encoding) = %bquote(EUC-CN) %then %do;
            %let sub_folder = gbk;
        %end;
        %else %if %bquote(&cur_encoding) = %bquote(UTF-8) %then %do;
            %let sub_folder = utf8;
        %end;

        filename predpc "qualify_multi.sas";
        proc http url = "https://raw.githubusercontent.com/Snoopy1866/Descriptive-Statistics-Macro/main/&sub_folder/qualify_multi.sas" out = predpc;
        run;
        %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
            %if &SYS_PROCHTTP_STATUS_CODE = 200 %then %do;
                %include predpc;
            %end;
            %else %do;
                %put ERROR: 远程主机连接成功，但并未成功获取目标文件，请手动导入前置依赖 %nrbquote(%nrstr(%%))QUALIFY_MULTI 后再次尝试运行！;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: 远程主机连接失败，请检查网络连接和代理设置，或手动导入前置依赖 %nrbquote(%nrstr(%%))QUALIFY_MULTI 后再次尝试运行！;
            %goto exit_with_error;
        %end;
    %end;


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


    /*INDENT*/
    %if %bquote(&indent) = %bquote() %then %do;
        %let indent_sql_expr = %bquote();
    %end;
    %else %if %bquote(%upcase(&indent)) = #AUTO %then %do;
        %let indent_sql_expr = %bquote(    );
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
        %end;
    %end;


    /*----------------------------------------------主程序----------------------------------------------*/
    /*1. 复制数据*/
    data tmp_qmt_indata;
        %unquote(set %superq(indata));
    run;

    /*2. 统计描述*/
    %qualify_multi(INDATA      = tmp_qmt_indata,
                   VAR         = %superq(VAR),
                   GROUP       = %superq(GROUP),
                   GROUPBY     = %superq(GROUPBY),
                   OUTDATA     = tmp_qmt_desc,
                   PATTERN     = %superq(PATTERN),
                   BY          = %superq(BY),
                   MISSING     = FALSE,
                   STAT_FORMAT = %superq(STAT_FORMAT),
                   LABEL       = %superq(LABEL),
                   INDENT      = %superq(INDENT));

    %if %bquote(&qualify_multi_exit_with_error) = TRUE %then %do; /*判断子程序调用是否产生错误*/
        %goto exit_with_error;
    %end;

    /*3. 统计推断*/
    %if %superq(p_format) = #AUTO %then %do;
        /*P值输出格式*/
        proc format;
            picture spvalue(round  max = 7)
                    low - < 0.0001 = "<0.0001"(noedit)
                    other = "9.9999";
        run;
        %let p_format = spvalue.;
    %end;

    /*4. 卡方和Fisher精确检验*/
    proc freq data = tmp_qmt_indata noprint;
        tables &var_name*%superq(GROUPBY) /chisq(warn = (output nolog)) fisher;
        output out = tmp_qmt_chisq chisq;
    run;

    proc sql noprint;
        select * from DICTIONARY.COLUMNS where libname = "WORK" and memname = "TMP_QMT_CHISQ";
        %if &SQLOBS = 0 %then %do; /*行或列的非缺失观测少于2，无法计算统计量*/
            create table tmp_qmt_stat
                (item char(%eval(%length(%bquote(&indent_sql_expr)) + 12)), value_1 char(10), value_2 char(10));
            insert into tmp_qmt_stat
                set item    = "&indent_sql_expr.统计量",
                    value_1 = "-",
                    value_2 = "-";
            insert into tmp_qmt_stat
                set item    = "&indent_sql_expr.P值",
                    value_1 = "-";
        %end;
        %else %do;
            select WARN_PCHI into : chisq_warn from tmp_qmt_chisq;
            %if &chisq_warn = 1 %then %do; /*卡方检验不适用*/
                create table tmp_qmt_stat as
                    select
                        "&indent_sql_expr.统计量" as item,
                        "Fisher精确检验" as value_1,
                        "-" as value_2
                    from tmp_qmt_chisq
                    outer union corr
                    select
                        "&indent_sql_expr.P值" as item,
                        strip(put(XP2_FISH, &p_format)) as value_1
                    from tmp_qmt_chisq;
            %end;
            %else %do; /*卡方检验适用*/
                %if %superq(t_format) = #AUTO %then %do;
                    select max(ceil(log10(abs(_PCHI_))) + 6, 7) into : t_fmt_width from tmp_qmt_chisq; /*计算输出格式的宽度*/
                    %let t_format = &t_fmt_width..4;
                %end;
                create table tmp_qmt_stat as
                    select
                        "&indent_sql_expr.统计量" as item,
                        "卡方检验" as value_1,
                        strip(put(_PCHI_, &t_format)) as value_2
                    from tmp_qmt_chisq
                    outer union corr
                    select
                        "&indent_sql_expr.P值" as item,
                        strip(put(P_PCHI, &p_format)) as value_1
                    from tmp_qmt_chisq;
            %end;
        %end;
    quit;

    /*5. 合并结果*/
    proc sql noprint;
        create table tmp_qmt_outdata as
            select * from tmp_qmt_desc outer union corr
            select * from tmp_qmt_stat;
    quit;


    /*5. 输出数据集*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_qmt_outdata;
    run;


    /*----------------------------------------------运行后处理----------------------------------------------*/
    /*删除中间数据集*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_qmt_indata
                   tmp_qmt_desc
                   tmp_qmt_stat
                   tmp_qmt_outdata
                   Tmp_qmt_chisq
                   ;
        quit;
    %end;

    %exit_with_error:
    %let qmt_exit_with_error = TRUE;

    %exit:
    %put NOTE: 宏 qualify_multi_test 已结束运行！;
%mend;
