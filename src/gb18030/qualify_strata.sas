/*
详细文档请前往 Github 查阅: https://github.com/Snoopy1866/Descriptive-Statistics-Macro
*/
/*
var = A
var = A, B, C
var = A, B, C, D, E, F, G
var = A(C), B, C, D, E, F, G
var = A(C, D, E, F, G), B, C, D, E, F, G
var = A(C(E, F, G), D, E, F, G), B, C, D, E, F, G
var = A(C(E(G), F, G), D, E, F, G), B, C, D, E, F, G


var = A(C(E(G), F, G), D(F, G), E(G), F, G), B(D(F, G), E(G), F, G), C(E(G), F, G), D(F, G), E(G), F, G

var = A, (C, (E, F)|D, (F)|E, F)|B, (D, (F)|E, F)|C, ((F)|E, F)|D, (F)|E, F

*/
%macro qualify_strata(INDATA,
                      VAR,
                      BY            = #AUTO,
                      UID           = #NULL,
                      GROUP         = #NULL,
                      GROUPBY       = #AUTO,
                      OUTDATA       = #AUTO,
                      DEL_TEMP_DATA = NULL) /des = "多组别多层级定性指标分析" parmbuff;

    /*打开帮助文档*/
    %if %bquote(%upcase(&SYSPBUFF)) = %bquote((HELP)) or %bquote(%upcase(&SYSPBUFF)) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify_strata/readme.md";
        %goto exit;
    %end;

    /*统一参数大小写*/
    %let indata               = %sysfunc(strip(%superq(indata)));
    %let var                  = %upcase(%sysfunc(strip(%superq(var))));
    %let by                   = %upcase(%sysfunc(strip(%superq(by))));
    %let uid                  = %upcase(%sysfunc(strip(%superq(uid))));
    %let group                = %upcase(%sysfunc(strip(%superq(group))));
    %let group                = %upcase(%sysfunc(strip(%superq(groupby))));
    %let outdata              = %sysfunc(strip(%superq(outdata)));
    %let del_temp_data        = %upcase(%sysfunc(strip(%superq(del_temp_data))));

    /*声明局部变量*/
    %local i j;

    

    /*----------------------------------------------参数检查----------------------------------------------*/
    /*INDATA*/
    %if %superq(indata) = %bquote() %then %do;
        %put ERROR: 未指定分析数据集！;
        %goto exit_with_error;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, %superq(indata))) %then %do;
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
        %else %do;
            %put ERROR: 参数 INDATA = %superq(indata) 格式不正确！;
            %goto exit_with_error;
        %end;
    %end;
    %put NOTE: 分析数据集被指定为 &libname_in..&memname_in;


    /*VAR*/
    %if %superq(var) = %bquote() %then %do;
        %put ERROR: 未指定分析变量！;
        %goto exit_with_error;
    %end;

    %let reg_var = %bquote(/^[A-Za-z_][A-Za-z_\d]*(?:[,\s][A-Za-z_][A-Za-z_\d]*)*$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %superq(var))) %then %do;
        %let var_n = %sysfunc(countw(%bquote(&var), %bquote(,), s));
        %let IS_VAR_NOT_VALID = FALSE;
        %do i = 1 %to &var_n;
            %let var_&i = %scan(%bquote(&var), &i, %bquote(,), s);
            %put &&var_&i;

            proc sql noprint;
                select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&&var_&i";
            quit;
            /*检查变量存在性*/
            %if &SQLOBS = 0 %then %do;
                %let IS_VAR_NOT_VALID = TRUE;
                %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 &&var_&i;
            %end;
            /*检查变量类型*/
            %else %if %bquote(&type) = num %then %do;
                %let IS_VAR_NOT_VALID = TRUE;
                %put ERROR: 参数 VAR 不支持数值型变量！;
            %end;
        %end;

        %if &IS_VAR_NOT_VALID = TRUE %then %do;
            %goto exit_with_error;
        %end;
    %end;
    %else %do;
        %put ERROR: 参数 VAR = %superq(var) 格式不正确！;
        %goto exit_with_error;
    %end;


    /*UID*/
    %if %superq(uid) = %bquote() %then %do;
        %put ERROR: 未指定唯一标识符变量！;
        %goto exit_with_error;
    %end;

    %if %superq(uid) ^= #NULL %then %do;
        %let reg_uid = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
        %let reg_uid_id = %sysfunc(prxparse(&reg_uid));
        %if %sysfunc(prxmatch(&reg_uid_id, %superq(uid))) %then %do;
            proc sql noprint;
                select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&uid";
            quit;
            %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
                %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 &uid;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: 参数 UID = %superq(uid) 格式不正确！;
            %goto exit_with_error;
        %end;
    %end;


    /*OUTDATA*/
    %if %superq(outdata) = %bquote() %then %do;
        %put ERROR: 参数 OUTDATA 为空！;
        %goto exit_with_error;
    %end;
    %else %do;
        %if %qupcase(&outdata) = %bquote(#AUTO) %then %do;
            %let outdata = RES_&var_1;
        %end;

        %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_outdata_id, %superq(outdata))) %then %do;
            %let libname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 1, %bquote(&outdata))));
            %let memname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 2, %bquote(&outdata))));
            %let dataset_options_out = %sysfunc(prxposn(&reg_outdata_id, 3, %bquote(&outdata)));
            %if &libname_out = %bquote() %then %let libname_out = WORK; /*未指定逻辑库，默认为WORK目录*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_out";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_out 逻辑库不存在！;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: 参数 OUTDATA = %superq(outdata) 格式不正确！;
            %goto exit_with_error;
        %end;
    %end;
    %put NOTE: 输出数据集被指定为 &libname_out..&memname_out;


    /*GROUP*/
    %if %superq(group) = %bquote() %then %do;
        %put ERROR: 未指定分组变量！;
        %goto exit_with_error;
    %end;

    %let reg_group_id = %sysfunc(prxparse(%bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:[\s,]*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*)+)?\))?$/)));
    %if %sysfunc(prxmatch(&reg_group_id, %superq(group))) %then %do;
        %let group_var = %upcase(%sysfunc(prxposn(&reg_group_id, 1, %superq(group))));
        %let group_level = %sysfunc(prxposn(&reg_group_id, 2, %superq(group)));

        /*检查变量存在性*/
        proc sql noprint;
            select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&group_var";
        quit;
        %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
            %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 &group_var;
            %goto exit_with_error;
        %end;
        /*检查变量类型*/
        %if %bquote(&type) = num %then %do;
            %put ERROR: 参数 GROUP 不支持数值型变量！;
            %goto exit_with_error;
        %end;

        %if %bquote(&group_level) = %bquote() %then %do;
            %let IS_GROUP_LEVEL_SPECIFIED = FALSE;
        %end;
        %else %do;
            %let IS_GROUP_LEVEL_SPECIFIED = TRUE;
            %let group_level_n = %sysfunc(countw(%bquote(&group_level), %bquote(,), %bquote(sq)));
            %do i = 1 %to &group_level_n;
                %let group_level_&i = %sysfunc(scan(%bquote(&group_level), &i, %bquote(,), %bquote(sq)));
            %end;
        %end;
    %end;
    %else %do;
        %put ERROR: 参数 GROUP = %superq(group) 格式不正确！;
        %goto exit_with_error;
    %end;

    /*GROUPBY*/
    %if &IS_GROUP_LEVEL_SPECIFIED = TRUE %then %do;
        %if %superq(groupby) ^= %bquote() and %superq(groupby) ^= #AUTO %then %do;
            %put WARNING: 已通过参数 GROUP 指定了分组的排序，参数 GROUPBY 已被忽略！;
        %end;
    %end;
    %else %do;
        %if %superq(groupby) = %bquote() %then %do;
            %put ERROR: 未指定分组排序变量！;
            %goto exit_with_error;
        %end;
        %else %if %superq(groupby) = #AUTO %then %do;
            proc sql noprint;
                create table tmp_qualify_m_groupby_sorted as select * from %superq(indata) where not missing(&group_var);
            quit;
        %end;
        %else %do;
            %let reg_groupby_id = %sysfunc(prxparse(%bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:ASC|DESC)(?:ENDING)?)\))?$/)));
            %if %sysfunc(prxmatch(&reg_groupby_id, %superq(groupby))) %then %do;
                %let groupby_var = %sysfunc(prxposn(&reg_groupby_id, 1, %superq(groupby)));
                %let groupby_direction = %sysfunc(prxposn(&reg_groupby_id, 2, %superq(groupby)));

                /*检查排序变量存在性*/
                proc sql noprint;
                    select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&groupby_var";
                quit;
                %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
                    %put ERROR: 在 &libname_in..&memname_in 中没有找到分组排序变量 &groupby_var;
                    %goto exit_with_error;
                %end;

                proc sql noprint;
                    create table tmp_qualify_m_groupby_sorted as
                        select
                            distinct
                            &group_var,
                            &groupby_var
                        from %superq(indata) where not missing(&group_var) order by &groupby_var &groupby_direction, &group_var;
                quit;
            %end;
            %else %do;
                %put ERROR: 参数 GROUPBY = %superq(groupby) 格式不正确！;
                %goto exit_with_error;
            %end;
        %end;

        /*创建宏变量，用于输出数据集的变量标签*/
        proc sql noprint;
            select quote(strip(&group_var))                         into : group_level_1-           from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(频数)')             into : group_level_freq_1-      from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(频数格式化)')       into : group_level_freq_fmt_1-  from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(频次)')             into : group_level_times_1-     from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(频次格式化)')       into : group_level_times_fmt_1- from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(频率)')             into : group_level_rate_1-      from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(频率格式化)')       into : group_level_rate_fmt_1-  from tmp_qualify_m_groupby_sorted;
            select count(distinct &group_var)                       into : group_level_n            from tmp_qualify_m_groupby_sorted;
        quit;
    %end;

    /*----------------------------------------------主程序----------------------------------------------*/


    /*----------------------------------------------运行后处理----------------------------------------------*/
   
    /*异常退出*/
    %exit_with_error:

    /*正常退出*/
    %exit:
    %put NOTE: 宏 desc_coun 已结束运行！;
%mend;

options symbolgen mlogic mprint;
%qualify_strata(indata = adam.adcm,
                var = cmatc2 cmdecod);
options nosymbolgen nomlogic nomprint;
