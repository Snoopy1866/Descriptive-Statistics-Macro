/*
===================================
Macro Name: qualify_multi
Macro Label:多组别定性指标分析
Author: wtwang
Version Date: 2023-12-26 0.1
              2024-01-19 0.2
              2024-01-22 0.3
              2024-04-16 0.4
              2024-04-18 0.5
              2024-04-25 0.6
              2024-04-25 0.7
              2024-06-04 0.8
              2024-06-13 0.9
              2024-07-15 0.10
              2024-11-14 0.11
              2025-01-14 0.12
              2025-01-15 0.13
===================================
*/

%macro qualify_multi(INDATA,
                     VAR,
                     GROUP,
                     GROUPBY          = #AUTO,
                     BY               = #AUTO,
                     UID              = #NULL,
                     PATTERN          = %nrstr(#FREQ(#RATE)),
                     MISSING          = FALSE,
                     MISSING_NOTE     = "缺失",
                     MISSING_POSITION = LAST,
                     OUTDATA          = RES_&VAR,
                     STAT_FORMAT      = #AUTO,
                     LABEL            = #AUTO,
                     INDENT           = #AUTO,
                     SUFFIX           = #AUTO,
                     TOTAL            = FALSE,
                     PROCHTTP_PROXY   = 127.0.0.1:7890,
                     debug    = false)
                     /des = "多组别定性指标分析" parmbuff;

    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify_multi/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------初始化----------------------------------------------*/
    /*统一参数大小写*/
    %let group                = %sysfunc(strip(%bquote(&group)));
    %let groupby              = %upcase(%sysfunc(strip(%bquote(&groupby))));
    %let debug        = %upcase(%sysfunc(strip(%bquote(&debug))));

    /*声明全局变量*/
    %global qualify_multi_exit_with_error;
    %let qualify_multi_exit_with_error = FALSE;

    /*声明局部变量*/
    %local i j
           libname_in memname_in dataset_options_in
           libname_out memname_out dataset_options_out;

    /*检查依赖*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUALIFY";
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
        proc http url = "https://raw.githubusercontent.com/Snoopy1866/Descriptive-Statistics-Macro/main/&sub_folder/qualify.sas" out = predpc;
        run;
        %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
            %if &SYS_PROCHTTP_STATUS_CODE = 200 %then %do;
                %include predpc;
            %end;
            %else %do;
                %put ERROR: 远程主机连接成功，但并未成功获取目标文件，请手动导入前置依赖 %nrbquote(%nrstr(%%))QUALIFY 后再次尝试运行！;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: 远程主机连接失败，请检查网络连接和代理设置，或手动导入前置依赖 %nrbquote(%nrstr(%%))QUALIFY 后再次尝试运行！;
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
                %put NOTE: 分析数据集 &indata 为空！;
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
                %let group_level_unquote_&i = %sysfunc(compress(&&group_level_&i, %nrstr(%")));

                %let group_level_freq_&i      = "&&group_level_unquote_&i(频数)";
                %let group_level_freq_fmt_&i  = "&&group_level_unquote_&i(频数格式化)";
                %let group_level_n_&i         = "&&group_level_unquote_&i(频数)(兼容)";
                %let group_level_n_fmt_&i     = "&&group_level_unquote_&i(频数格式化)(兼容)";
                %let group_level_times_&i     = "&&group_level_unquote_&i(频次)";
                %let group_level_times_fmt_&i = "&&group_level_unquote_&i(频次格式化)";
                %let group_level_rate_&i      = "&&group_level_unquote_&i(频率)";
                %let group_level_rate_fmt_&i  = "&&group_level_unquote_&i(频率格式化)";
            %end;
        %end;
    %end;
    %else %do;
        %put ERROR: 参数 GROUP 格式错误！;
        %goto exit_with_error;
    %end;

    /*GROUPBY*/
    %if %superq(groupby) = %bquote() %then %do;
        %put ERROR: 参数 GROUPBY 为空！;
        %goto exit_with_error;
    %end;
    %else %if %superq(groupby) = #AUTO %then %do;
        %put NOTE: 未指定分组的排序方式，将按照分组变量自身的值升序排列！;
        %let groupby = &group_var(desc);
    %end;

    /*解析参数 by, 检查合法性*/
    %let reg_groupby_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)|(?:([A-Za-z_]+(?:\d+[A-Za-z_]+)?)\.))(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/)));
    %if %sysfunc(prxmatch(&reg_groupby_id, %superq(groupby))) %then %do;
        %let groupby_var       = %sysfunc(prxposn(&reg_groupby_id, 1, %superq(groupby)));
        %let groupby_fmt       = %sysfunc(prxposn(&reg_groupby_id, 2, %superq(groupby)));
        %let groupby_direction = %sysfunc(prxposn(&reg_groupby_id, 3, %superq(groupby)));

        %if %bquote(&groupby_var) ^= %bquote() %then %do;
            /*检查排序变量存在性*/
            proc sql noprint;
                select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&groupby_var";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: 在 &libname_in..&memname_in 中没有找到分组排序变量 &groupby_var;
                %goto exit_with_error;
            %end;
        %end;

        %if %bquote(&groupby_fmt) ^= %bquote() %then %do;
            /*检查排序格式存在性*/
            proc sql noprint;
                select libname, memname, source into :groupby_fmt_libname, :groupby_fmt_memname, :groupby_fmt_source from DICTIONARY.FORMATS where fmtname = "&groupby_fmt";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: 参数 BY 指定的排序格式 &groupby_fmt.. 不存在！;
                %goto exit_with_error;
            %end;
            %else %do;
                %if &groupby_fmt_source ^= C %then %do;
                    %put ERROR: 参数 BY 指定的排序格式 &groupby_fmt.. 不是 CATALOG-BASED！;
                    %goto exit_with_error;
                %end;
            %end;
        %end;

        /*检查排序方向*/
        %if %bquote(&groupby_direction) = %bquote() %then %do;
            %put NOTE: 未指定分组的排序方向，默认升序排列！;
            %let groupby_direction = ASCENDING;
        %end;
        %else %if %bquote(&groupby_direction) = ASC %then %do;
            %let groupby_direction = ASCENDING;
        %end;
        %else %if %bquote(&groupby_direction) = DESC %then %do;
            %let groupby_direction = DESCENDING;
        %end;
    %end;
    %else %do;
        %put ERROR: 参数 GROUPBY = %bquote(&groupby) 格式不正确！;
        %goto exit_with_error;
    %end;

    %if %bquote(&groupby_var) ^= %bquote() %then %do;
        proc sql noprint;
            create table tmp_qualify_m_groupby_sorted as
                select
                    distinct
                    &group_var                       as group_level,
                    &groupby_var                     as group_level_by_criteria
                from %superq(indata) where not missing(&group_var) order by &groupby_var &groupby_direction, &group_var;
        quit;
    %end;
    %else %if %bquote(&groupby_fmt) ^= %bquote() %then %do;
        proc format library = &groupby_fmt_libname..&groupby_fmt_memname cntlout = tmp_qualify_m_groupby_fmt;
            select &groupby_fmt;
        run;
        proc sql noprint;
            create table tmp_qualify_m_groupby_sorted(where = (not missing(group_level))) as
                select
                    distinct
                    coalescec(a.&group_var, b.label) as group_level,
                    ifn(not missing(b.label), input(strip(b.start), 8.), constant('BIG'))
                                                     as group_level_by_criteria,
                    ifc(missing(b.label), 'Y', '')   as group_level_fmt_not_defined
                from %superq(indata) as a full join tmp_qualify_m_groupby_fmt as b on a.&group_var = b.label
                order by group_level_by_criteria &groupby_direction, group_level ascending;

            select sum(group_level_fmt_not_defined = "Y") into : groupby_fmt_not_defined_n trimmed from tmp_qualify_m_groupby_sorted where not missing(group_level);
            %if &groupby_fmt_not_defined_n > 0 %then %do;
                %put WARNING: 指定用于分组排序的输出格式中，存在 &groupby_fmt_not_defined_n 个分类名称未定义，输出结果可能是非预期的！;
            %end;
        quit;
    %end;

    /*创建宏变量，用于输出数据集的变量标签*/
    proc sql noprint;
        select quote(strip(group_level))                         into : group_level_1-           from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频数)')             into : group_level_freq_1-      from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频数格式化)')       into : group_level_freq_fmt_1-  from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频数)(兼容)')       into : group_level_n_1-         from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频数格式化)(兼容)') into : group_level_n_fmt_1-     from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频次)')             into : group_level_times_1-     from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频次格式化)')       into : group_level_times_fmt_1- from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频率)')             into : group_level_rate_1-      from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(频率格式化)')       into : group_level_rate_fmt_1-  from tmp_qualify_m_groupby_sorted;
        select count(distinct group_level)                       into : group_level_n            from tmp_qualify_m_groupby_sorted;
    quit;


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
    data tmp_qualify_m_indata;
        %unquote(set %superq(indata));
    run;

    /*2. 整体统计*/
    %put NOTE: ===================================合计===================================;
    %qualify(INDATA      = tmp_qualify_m_indata(where = (&group_var in (%do i = 1 %to &group_level_n;
                                                                            &&group_level_&i %bquote(,)
                                                                        %end;))),
             VAR              = %superq(VAR),
             BY               = %superq(BY),
             UID              = %superq(UID),
             PATTERN          = %superq(PATTERN),
             MISSING          = %superq(MISSING),
             MISSING_NOTE     = %superq(MISSING_NOTE),
             MISSING_POSITION = %superq(MISSING_POSITION),
             OUTDATA          = tmp_qualify_m_res_sum(rename = (VALUE     = VALUE_SUM
                                                                FREQ      = FREQ_SUM
                                                                FREQ_FMT  = FREQ_SUM_FMT
                                                                N         = N_SUM
                                                                N_FMT     = N_SUM_FMT
                                                                TIMES     = TIMES_SUM
                                                                TIMES_FMT = TIMES_SUM_FMT
                                                                RATE      = RATE_SUM
                                                                RATE_FMT  = RATE_SUM_FMT)),
             STAT_FORMAT      = %superq(STAT_FORMAT),
             LABEL            = %superq(LABEL),
             INDENT           = %superq(INDENT),
             SUFFIX           = %superq(SUFFIX),
             TOTAL            = %superq(TOTAL));

    %if %bquote(&qualify_exit_with_error) = TRUE %then %do; /*判断子程序调用是否产生错误*/
        %goto exit_with_error;
    %end;

    %if %sysmexecname(%sysmexecdepth - 1) = QUALIFY_MULTI_TEST %then %do; /*如果被 %qualify_multi_test 调用，则保留数据集 tmp_qualify_indata_unique_var*/
        proc datasets library = work noprint nowarn;
            delete tmp_qmt_indata_unique_var;
            change tmp_qualify_indata_unique_var = tmp_qmt_indata_unique_var;
        quit;
    %end;

    /*3. 分组别统计*/
    %do i = 1 %to &group_level_n;
        %put NOTE: ===================================&&group_level_&i===================================;
        %qualify(INDATA           = tmp_qualify_m_indata(where = (&group_var = &&group_level_&i)),
                 VAR              = %superq(VAR),
                 BY               = %superq(BY),
                 UID              = %superq(UID),
                 PATTERN          = %superq(PATTERN),
                 MISSING          = %superq(MISSING),
                 MISSING_NOTE     = %superq(MISSING_NOTE),
                 MISSING_POSITION = %superq(MISSING_POSITION),
                 OUTDATA          = tmp_qualify_m_res_group_&i(rename = (VALUE     = VALUE_&i
                                                                         FREQ      = FREQ_&i
                                                                         FREQ_FMT  = FREQ_&i._FMT
                                                                         N         = N_&i
                                                                         N_FMT     = N_&i._FMT
                                                                         TIMES     = TIMES_&i
                                                                         TIMES_FMT = TIMES_&i._FMT
                                                                         RATE      = RATE_&i
                                                                         RATE_FMT  = RATE_&i._FMT)),
                 STAT_FORMAT      = %superq(STAT_FORMAT),
                 LABEL            = %superq(LABEL),
                 INDENT           = %superq(INDENT),
                 SUFFIX           = %superq(SUFFIX),
                 TOTAL            = %superq(TOTAL));

        %if %bquote(&qualify_exit_with_error) = TRUE %then %do; /*判断子程序调用是否产生错误*/
            %goto exit_with_error;
        %end;
    %end;

    /*4. 合并上述结果*/
    proc sql noprint;
        create table tmp_qualify_m_outdata as
            select
                sum.idt,
                sum.seq,
                sum.item                 label = "分类",
                %do i = 1 %to &group_level_n;
                    sub&i..value_&i      label = &&group_level_&i,
                    sub&i..freq_&i       label = &&group_level_freq_&i,
                    sub&i..freq_&i._fmt  label = &&group_level_freq_fmt_&i,
                    sub&i..n_&i          label = &&group_level_n_&i,
                    sub&i..n_&i._fmt     label = &&group_level_n_fmt_&i,
                    sub&i..times_&i      label = &&group_level_times_&i,
                    sub&i..times_&i._fmt label = &&group_level_times_fmt_&i,
                    sub&i..rate_&i       label = &&group_level_rate_&i,
                    sub&i..rate_&i._fmt  label = &&group_level_rate_fmt_&i,
                %end;
                sum.value_sum            label = "合计",
                sum.freq_sum             label = "合计(频数)",
                sum.freq_sum_fmt         label = "合计(频数)",
                sum.n_sum                label = "合计(频数)(兼容)",
                sum.n_sum_fmt            label = "合计(频数格式化)(兼容)",
                sum.times_sum            label = "合计(频次)",
                sum.times_sum_fmt        label = "合计(频次格式化)",
                sum.rate_sum             label = "合计(频率)",
                sum.rate_sum_fmt         label = "合计(频率格式化)"
            from tmp_qualify_m_res_sum as sum %do i = 1 %to &group_level_n;
                                                  left join tmp_qualify_m_res_group_&i as sub&i on sum.item = sub&i..item
                                              %end;
            order by sum.seq;

        %do i = 1 %to &group_level_n;
            update tmp_qualify_m_outdata
                set value_&i      = "%superq(VALUE_zero)",
                    freq_&i       = %superq(FREQ_zero),
                    freq_&i._fmt  = "%superq(FREQ_zero_fmt)",
                    n_&i          = %superq(N_zero),
                    n_&i._fmt     = "%superq(N_zero_fmt)",
                    times_&i      = %superq(TIMES_zero),
                    times_&i._fmt = "%superq(TIMES_zero_fmt)",
                    rate_&i       = %superq(RATE_zero),
                    rate_&i._fmt  = "%superq(RATE_zero_fmt)"
            where seq > 0 and missing(freq_&i);
        %end;
    quit;

    /*5. 输出数据集*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item %if &uid ^= #NULL %then %do;
                                                        %do i = 1 %to &group_level_n;
                                                            times_&i._fmt value_&i
                                                        %end;
                                                        %if &group_level_n > 1 %then %do;
                                                            times_sum_fmt value_sum
                                                        %end;
                                                    %end;
                                                    %else %do;
                                                        %do i = 1 %to &group_level_n;
                                                            value_&i
                                                        %end;
                                                        %if &group_level_n > 1 %then %do;
                                                            value_sum
                                                        %end;
                                                    %end;
                                                    
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_qualify_m_outdata;
    run;

    /*----------------------------------------------运行后处理----------------------------------------------*/
    /*删除中间数据集*/
    %if &debug = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_qualify_m_indata
                   tmp_qualify_m_outdata
                   tmp_qualify_m_groupby_fmt
                   tmp_qualify_m_groupby_sorted
                   tmp_qualify_m_res_sum
                   %do i = 1 %to &group_level_n;
                       tmp_qualify_m_res_group_&i
                   %end;
                   ;
        quit;
    %end;
    %goto exit;

    /*异常退出*/
    %exit_with_error:
    %let qualify_multi_exit_with_error = TRUE;

    /*正常退出*/
    %exit:
    %put NOTE: 宏 qualify_multi 已结束运行！;
%mend;
