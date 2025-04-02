/*
===================================
Macro Name: quantify
Macro Label:多组别定量指标分析
Author: wtwang
Version Date: 2023-12-21 0.1
              2023-12-25 0.2
              2024-01-05 0.3
              2024-01-19 0.4
              2024-11-14 0.5
===================================
*/

%macro quantify_multi(INDATA,
                      VAR,
                      GROUP,
                      GROUPBY        = #AUTO,
                      OUTDATA        = RES_&VAR,
                      PATTERN        = %nrstr(#N(#NMISS)|#MEAN±#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX), 
                      STAT_FORMAT    = #AUTO,
                      STAT_NOTE      = #AUTO,
                      LABEL          = #AUTO,
                      INDENT         = #AUTO,
                      PROCHTTP_PROXY = 127.0.0.1:7890,
                      debug  = TRUE)
                      /des = "多组别定量指标分析" parmbuff;

    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/quantify_multi/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------初始化----------------------------------------------*/
    /*统一参数大小写*/
    %let group                = %sysfunc(strip(%bquote(&group)));
    %let groupby              = %upcase(%sysfunc(strip(%bquote(&groupby))));

    /*声明全局变量*/
    %global quantify_multi_exit_with_error;
    %let quantify_multi_exit_with_error = FALSE;

    /*声明局部变量*/
    %local i j
           libname_in memname_in dataset_options_in
           libname_out memname_out dataset_options_out;

    /*检查依赖*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUANTIFY";
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

        filename predpc "quantify.sas";
        proc http url = "https://raw.githubusercontent.com/Snoopy1866/Descriptive-Statistics-Macro/main/&sub_folder/quantify.sas" out = predpc;
        run;
        %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
            %if &SYS_PROCHTTP_STATUS_CODE = 200 %then %do;
                %include predpc;
            %end;
            %else %do;
                %put ERROR: 远程主机连接成功，但并未成功获取目标文件，请手动导入前置依赖 %nrbquote(%nrstr(%%))QUANTIFY 后再次尝试运行！;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: 远程主机连接失败，请检查网络连接和代理设置，或手动导入前置依赖 %nrbquote(%nrstr(%%))QUANTIFY 后再次尝试运行！;
            %goto exit_with_error;
        %end;
    %end;


    /*----------------------------------------------参数检查----------------------------------------------*/
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
        %put ERROR: 参数 GROUP 格式错误！;
        %goto exit_with_error;
    %end;

    /*GROUPBY*/
    %if &IS_GROUP_LEVEL_SPECIFIED = TRUE %then %do;
        %if %superq(groupby) ^= %bquote() and %superq(groupby) ^= #AUTO %then %do;
            %put WARNING: 已通过参数 GROUP 指定了分组的排序，参数 GROUPBY 已被忽略！;
        %end;
        %let groupby_criteria = &group_var;
    %end;
    %else %do;
        %if %superq(groupby) = %bquote() %then %do;
            %put ERROR: 未指定分组排序变量！;
            %goto exit_with_error;
        %end;
        %else %if %superq(groupby) = #AUTO %then %do;
            proc sql noprint;
                select distinct quote(strip(&group_var)) into : group_level_1- from %superq(indata) where not missing(&group_var);
                select count(distinct &group_var) into : group_level_n from %superq(indata);
            quit;
        %end;
        %else %do;
            %let reg_groupby_id = %sysfunc(prxparse(%bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:ASC|DESC)(?:ENDING)?)\))?$/)));
            %if %sysfunc(prxmatch(&reg_groupby_id, %superq(groupby))) %then %do;
                %let groupby_criteria = %sysfunc(prxposn(&reg_groupby_id, 1, %superq(groupby)));
                %let groupby_direction = %sysfunc(prxposn(&reg_groupby_id, 2, %superq(groupby)));

                /*检查排序变量存在性*/
                proc sql noprint;
                    select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&groupby_criteria";
                quit;
                %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
                    %put ERROR: 在 &libname_in..&memname_in 中没有找到分组排序变量 &groupby_criteria;
                    %goto exit_with_error;
                %end;

                proc sql noprint;
                    create table tmp_quantify_m_groupby_sorted as
                        select
                            distinct
                            &group_var,
                            &groupby_criteria
                        from %superq(indata) where not missing(&group_var) order by &groupby_criteria &groupby_direction, &group_var;
                    select quote(strip(&group_var)) into : group_level_1- from tmp_quantify_m_groupby_sorted;
                    select count(distinct &group_var) into : group_level_n from tmp_quantify_m_groupby_sorted;
                quit;
            %end;
            %else %do;
                %put ERROR: 参数 GROUPBY 必须指定一个合法的变量名！;
                %goto exit_with_error;
            %end;
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




    /*----------------------------------------------主程序----------------------------------------------*/
    /*1. 复制数据*/
    data tmp_quantify_m_indata;
        %unquote(set %superq(indata));
    run;

    /*2. 整体统计*/
    %put NOTE: ===================================合计===================================;
    %quantify(INDATA      = tmp_quantify_m_indata(where = (&group_var in (%do i = 1 %to &group_level_n;
                                                                              &&group_level_&i %bquote(,)
                                                                          %end;))),
              VAR         = %superq(VAR),
              OUTDATA     = tmp_quantify_m_res_sum(rename = (value = value_sum)),
              PATTERN     = %superq(PATTERN),
              STAT_FORMAT = %superq(STAT_FORMAT),
              STAT_NOTE   = %superq(STAT_NOTE),
              LABEL       = %superq(LABEL),
              INDENT      = %superq(INDENT));

    %if %bquote(&quantify_exit_with_error) = TRUE %then %do; /*判断子程序调用是否产生错误*/
        %goto exit_with_error;
    %end;

    /*3. 分组别统计*/
    %do i = 1 %to &group_level_n;
        %put NOTE: ===================================&&group_level_&i===================================;
        %quantify(INDATA      = tmp_quantify_m_indata(where = (&group_var = &&group_level_&i)),
                  VAR         = %superq(VAR),
                  OUTDATA     = temp_res_group_level_&i(rename = (value = value_&i)),
                  PATTERN     = %superq(PATTERN),
                  STAT_FORMAT = #PREV,
                  STAT_NOTE   = %superq(STAT_NOTE),
                  LABEL       = %superq(LABEL),
                  INDENT      = %superq(INDENT));

        %if %bquote(&quantify_exit_with_error) = TRUE %then %do; /*判断子程序调用是否产生错误*/
            %goto exit_with_error;
        %end;
    %end;

    /*4. 合并上述结果*/
    data tmp_quantify_m_outdata;
        merge %do i = 1 %to &group_level_n;
                  temp_res_group_level_&i
              %end;
              tmp_quantify_m_res_sum
              ;
        label %do i = 1 %to &group_level_n;
                  value_&i = &&group_level_&i
              %end;
              value_sum = "合计"
              item = "统计量";
    run;

    /*5. 输出数据集*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item %do i = 1 %to &group_level_n;
                                                        value_&i
                                                    %end;
                                                    %if &group_level_n > 1 %then %do;
                                                        value_sum
                                                    %end;
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_quantify_m_outdata;
    run;

    /*----------------------------------------------运行后处理----------------------------------------------*/
    /*删除中间数据集*/
    %if &debug = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_quantify_m_indata
                   tmp_quantify_m_outdata
                   tmp_quantify_m_groupby_sorted
                   tmp_quantify_m_res_sum
                   %do i = 1 %to &group_level_n;
                       temp_res_group_level_&i
                   %end;
                   ;
        quit;
    %end;
    %goto exit;

    /*异常退出*/
    %exit_with_error:
    %let quantify_multi_exit_with_error = TRUE;

    /*正常退出*/
    %exit:
    %put NOTE: 宏 quantify_multi 已结束运行！;
%mend;
