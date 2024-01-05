/*
===================================
Macro Name: quantify_multi_test
Macro Label:多组别定量指标汇总统计
Author: wtwang
Version Date: 2024-01-05 0.1
===================================
*/

%macro quantify_multi_test(INDATA,
                           VAR,
                           GROUP,
                           GROUPBY,
                           OUTDATA = RES_&VAR,
                           PATTERN = %nrstr(#N(#NMISS)|#MEAN±#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX), 
                           STAT_FORMAT = #AUTO,
                           STAT_NOTE = #AUTO,
                           LABEL = #AUTO,
                           INDENT = #AUTO,
                           T_FORMAT = #AUTO,
                           P_FORMAT = #AUTO,
                           PROCHTTP_PROXY = 127.0.0.1:7890,
                           DEL_TEMP_DATA = TRUE)
                           /des = "多组别定量指标汇总统计" parmbuff;

    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/quantify_multi_test/readme.md";
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
           libname_in memname_in dataset_options_in
           libname_out memname_out dataset_options_out;

    /*检查依赖*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUANTIFY_MULTI";
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

        filename predpc "quantify_multi.sas";
        proc http url = "https://raw.githubusercontent.com/Snoopy1866/Descriptive-Statistics-Macro/main/&sub_folder/quantify_multi.sas" out = predpc;
        run;
        %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
            %if &SYS_PROCHTTP_STATUS_CODE = 200 %then %do;
                %include predpc;
            %end;
            %else %do;
                %put ERROR: 远程主机连接成功，但并未成功获取目标文件，请手动导入前置依赖 %nrbquote(%nrstr(%%))QUANTIFY_MULTI 后再次尝试运行！;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: 远程主机连接失败，请检查网络连接和代理设置，或手动导入前置依赖 %nrbquote(%nrstr(%%))QUANTIFY_MULTI 后再次尝试运行！;
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
    %quantify_multi(INDATA      = tmp_qmt_indata,
                    VAR         = %superq(VAR),
                    GROUP       = %superq(GROUP),
                    GROUPBY     = %superq(GROUPBY),
                    OUTDATA     = tmp_qmt_outdata,
                    PATTERN     = %superq(PATTERN),
                    STAT_FORMAT = %superq(STAT_FORMAT),
                    STAT_NOTE   = %superq(STAT_NOTE),
                    LABEL       = %superq(LABEL),
                    INDENT      = %superq(INDENT));

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

    /*正态性检验*/
    proc univariate data = tmp_qmt_indata normaltest noprint;
        var %superq(VAR);
        class %superq(GROUPBY);
        output out = tmp_qmt_nrmtest normaltest = normaltest probn = probn;
    run;

    proc sql noprint;
        select sum(probn < 0.05) into : nrmtest_reject from tmp_qmt_nrmtest;
    quit;

    /*至少一个组别不符合正态性，使用 Wilcoxon 检验*/
    %if &nrmtest_reject > 0 %then %do;
        %put NOTE: 至少一个组别不符合正态性，使用 Wilcoxon 检验！;
        proc npar1way data = tmp_qmt_indata wilcoxon noprint;
            var %superq(VAR);
            class %superq(GROUPBY);
            output out = tmp_qmt_wcxtest wilcoxon;
        run;
        proc sql noprint;
            %if %superq(t_format) = #AUTO %then %do;
                select max(ceil(log10(abs(Z_WIL))) + 6, 7) into : t_fmt_width from tmp_qmt_wcxtest; /*计算输出格式的宽度*/
                %let t_format = &t_fmt_width..4;
            %end;
            insert into tmp_qmt_outdata
                set item = "&indent_sql_expr.统计量",
                    value_1 = "Wilcoxon秩和检验",
                    value_2 = strip(put((select Z_WIL from tmp_qmt_wcxtest), &t_format));
            insert into tmp_qmt_outdata
                set item = "&indent_sql_expr.P值",
                    value_1 = strip(put((select P2_WIL from tmp_qmt_wcxtest), &p_format));
        quit;
    %end;
    %else %do;
        ods html close;
        ods output TTests = tmp_qmt_ttests Equality = tmp_qmt_equality;
        proc ttest data = tmp_qmt_indata plots = none;
            var %superq(VAR);
            class %superq(GROUPBY);
        run;
        ods html;

        /*方差齐性检验*/
        proc sql noprint;
            select sum(ProbF < 0.05) into : homovar_reject from tmp_qmt_equality;
        quit;

        /*方差不齐，使用 Satterthwaite t 检验*/
        %if &homovar_reject > 0 %then %do;
            %put NOTE: 方差不齐，使用 Satterthwaite t 检验！;
            proc sql noprint;
                %if %superq(t_format) = #AUTO %then %do;
                    select max(ceil(log10(abs(tValue))) + 6, 7) into : t_fmt_width from tmp_qmt_ttests where Variances = "不等于"; /*计算输出格式的宽度*/
                    %let t_format = &t_fmt_width..4;
                %end;
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.统计量",
                        value_1 = "t检验",
                        value_2 = strip(put((select tValue from tmp_qmt_ttests where Variances = "不等于"), &t_format));
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.P值",
                        value_1 = strip(put((select Probt from tmp_qmt_ttests where Variances = "不等于"), &p_format));
            quit;
        %end;
        %else %do;
            proc sql noprint;
                %if %superq(t_format) = #AUTO %then %do;
                    select max(ceil(log10(abs(tValue))) + 6, 7) into : t_fmt_width from tmp_qmt_ttests where Variances = "等于"; /*计算输出格式的宽度*/
                    %let t_format = &t_fmt_width..4;
                %end;
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.统计量",
                        value_1 = "t检验",
                        value_2 = strip(put((select tValue from tmp_qmt_ttests where Variances = "等于"), &t_format));
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.P值",
                        value_1 = strip(put((select Probt from tmp_qmt_ttests where Variances = "等于"), &p_format));
            quit;
        %end;
    %end;
    

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
                   tmp_qmt_outdata
                   Tmp_qmt_nrmtest
                   Tmp_qmt_equality
                   Tmp_qmt_ttests
                   Tmp_qmt_wcxtest
                   ;
        quit;
    %end;

    %exit_with_error:
    %let qmt_exit_with_error = TRUE;

    %exit:
    %put NOTE: 宏 quantify_multi_test 已结束运行！;
%mend;
