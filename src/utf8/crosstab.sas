/*
 * Macro Name:    crosstab
 * Macro Purpose: 交叉表
 * Author:        wtwang
 * Version:       2.0
 * Version Date:  2025-11-14
 * 详细文档请前往 Github 查阅: https://github.com/Snoopy1866/sas-summarize
*/

%macro crosstab(indata,
                outdata,
                rowcat,
                colcat,
                rowcat_by,
                colcat_by,
                rowcat_missing = true,
                colcat_missing = true,
                rowcat_total   = true,
                colcat_total   = true,
                arm            = #null,
                arm_by         = #null,
                format_freq    = best12.,
                output_rate    = true,
                format_rate    = percentn9.2,
                debug          = false) / parmbuff;
    /*  indata:                 输入数据集
     *  outdata:                输出数据集
     *  rowcat:                 行分类变量
     *  colcat:                 列分类变量
     *  rowcat_by:              行分类变量字典，应当是一个 format
     *  colcat_by:              列分类变量字典，应当是一个 format
     *  rowcat_missing:         是否统计行分类变量的缺失值
     *  colcat_missing:         是否统计列分类变量的缺失值
     *  rowcat_total:           是否统计行分类变量的合计值
     *  colcat_total:           是否统计列分类变量的合计值
     *  arm:                    组别变量，#null 表示单组
     *  arm_by:                 组别变量字典，应当是一个 format，#null 表示单组
     *  format_freq:            频数的输出格式
     *  output_rate:            是否输出率
     *  format_rate:            率的输出格式
     *  debug:                  调试模式
    */

    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/sas-summarize/blob/v2/docs/crosstab/readme.md";
        %goto exit;
    %end;


    /*统一参数大小写*/
    %let indata          = %sysfunc(strip(%superq(indata)));
    %let outdata         = %sysfunc(strip(%superq(outdata)));
    %let rowcat          = %upcase(%sysfunc(strip(%bquote(&rowcat))));
    %let colcat          = %upcase(%sysfunc(strip(%bquote(&colcat))));
    %let rowcat_by       = %upcase(%sysfunc(strip(%bquote(&rowcat_by))));
    %let colcat_by       = %upcase(%sysfunc(strip(%bquote(&colcat_by))));
    %let rowcat_missing  = %upcase(%sysfunc(strip(%bquote(&rowcat_missing))));
    %let colcat_missing  = %upcase(%sysfunc(strip(%bquote(&colcat_missing))));
    %let rowcat_total    = %upcase(%sysfunc(strip(%bquote(&rowcat_total))));
    %let colcat_total    = %upcase(%sysfunc(strip(%bquote(&colcat_total))));
    %let arm             = %upcase(%sysfunc(strip(%bquote(&arm))));
    %let arm_by          = %upcase(%sysfunc(strip(%bquote(&arm_by))));
    %let format_freq     = %upcase(%sysfunc(strip(%bquote(&format_freq))));
    %let output_rate     = %upcase(%sysfunc(strip(%bquote(&output_rate))));
    %let format_rate     = %upcase(%sysfunc(strip(%bquote(&format_rate))));
    %let debug           = %upcase(%sysfunc(strip(%bquote(&debug))));


    /*声明局部变量*/
    %local i j k;


    /*参数预处理*/
    /*rowcat_by*/
    %let reg_rowcat_by_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/)));
    %if %sysfunc(prxmatch(&reg_rowcat_by_id, %superq(rowcat_by))) %then %do;
        %let rowcat_by_fmt       = %sysfunc(prxposn(&reg_rowcat_by_id, 1, %superq(rowcat_by)));
        %let rowcat_by_direction = %sysfunc(prxposn(&reg_rowcat_by_id, 2, %superq(rowcat_by)));

        /*检查排序方向*/
        %if %bquote(&rowcat_by_direction) = %bquote() %then %do;
            %put NOTE: (ROWCAT_BY) 未指定行分类的排序方向，默认升序排列！;
            %let rowcat_by_direction = ASCENDING;
        %end;
        %else %if %bquote(&rowcat_by_direction) = ASC %then %do;
            %let rowcat_by_direction = ASCENDING;
        %end;
        %else %if %bquote(&rowcat_by_direction) = DESC %then %do;
            %let rowcat_by_direction = DESCENDING;
        %end;

        proc sql noprint;
            select libname, memname, source into :rowcat_by_fmt_libname, :rowcat_by_fmt_memname, :rowcat_by_fmt_source from dictionary.formats where fmtname = "&rowcat_by_fmt";
        quit;
        %if &sqlobs = 0 %then %do;
            %put ERROR: (ROWCAT_BY) &rowcat_by_fmt 未定义！;
            %goto exit;
        %end;

        proc format library = &rowcat_by_fmt_libname..&rowcat_by_fmt_memname cntlout = tmp_rowcat_by_fmt;
            select &rowcat_by_fmt;
        run;

        proc sql noprint;
            create table tmp_rowcat_sorted as
                select
                    label,
                    (case when start = "LOW"  then -constant("BIG")
                          when start = "HIGH" then  constant("BIG")
                          else input(strip(start), 8.)
                    end)             as rowcat_by_fmt_start,
                    (case when end = "LOW"  then -constant("BIG")
                          when end = "HIGH" then  constant("BIG")
                          else input(strip(end), 8.)
                    end)             as rowcat_by_fmt_end
                from tmp_rowcat_by_fmt
                order by rowcat_by_fmt_start &rowcat_by_direction, rowcat_by_fmt_end &rowcat_by_direction;
            select label into :rowcat_1- from tmp_rowcat_sorted;
            %let rowcat_n = &sqlobs;
            %if &rowcat_n = 0 %then %do;
                %put ERROR: (ROWCAT_BY) 指定的行分类至少要有一个类别！;
                %goto exit;
            %end;
            select max(length(label)) into :rowcat_len_max trimmed from tmp_rowcat_sorted;
        quit;
    %end;
    %else %do;
        %put ERROR: (ROWCAT_BY) 值 %superq(rowcat_by) 格式不正确！;
        %goto exit;
    %end;

    /*colcat_by*/
    %let reg_colcat_by_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/)));
    %if %sysfunc(prxmatch(&reg_colcat_by_id, %superq(colcat_by))) %then %do;
        %let colcat_by_fmt       = %sysfunc(prxposn(&reg_colcat_by_id, 1, %superq(colcat_by)));
        %let colcat_by_direction = %sysfunc(prxposn(&reg_colcat_by_id, 2, %superq(colcat_by)));

        /*检查排序方向*/
        %if %bquote(&colcat_by_direction) = %bquote() %then %do;
            %put NOTE: (COLCAT_BY) 未指定列分类的排序方向，默认升序排列！;
            %let colcat_by_direction = ASCENDING;
        %end;
        %else %if %bquote(&colcat_by_direction) = ASC %then %do;
            %let colcat_by_direction = ASCENDING;
        %end;
        %else %if %bquote(&colcat_by_direction) = DESC %then %do;
            %let colcat_by_direction = DESCENDING;
        %end;

        proc sql noprint;
            select libname, memname, source into :colcat_by_fmt_libname, :colcat_by_fmt_memname, :colcat_by_fmt_source from dictionary.formats where fmtname = "&colcat_by_fmt";
        quit;
        %if &sqlobs = 0 %then %do;
            %put ERROR: (COLCAT_BY) &colcat_by_fmt 未定义！;
            %goto exit;
        %end;

        proc format library = &colcat_by_fmt_libname..&colcat_by_fmt_memname cntlout = tmp_colcat_by_fmt;
            select &colcat_by_fmt;
        run;

        proc sql noprint;
            create table tmp_colcat_sorted as
                select
                    label,
                    (case when start = "LOW"  then -constant("BIG")
                          when start = "HIGH" then  constant("BIG")
                          else input(strip(start), 8.)
                    end)             as colcat_by_fmt_start,
                    (case when end = "LOW"  then -constant("BIG")
                          when end = "HIGH" then  constant("BIG")
                          else input(strip(end), 8.)
                    end)             as colcat_by_fmt_end
                from tmp_colcat_by_fmt
                order by colcat_by_fmt_start &colcat_by_direction, colcat_by_fmt_end &colcat_by_direction;
            select label into :colcat_1- from tmp_colcat_sorted;
            %let colcat_n = &sqlobs;
            %if &colcat_n = 0 %then %do;
                %put ERROR: (COLCAT_BY) 指定的列分类至少要有一个类别！;
                %goto exit;
            %end;
        quit;
    %end;
    %else %do;
        %put ERROR: (COLCAT_BY) 值 %superq(colcat_by) 格式不正确！;
        %goto exit;
    %end;

    /*arm*/
    %if %superq(arm) = #NULL %then %do;
        %let arm_n = 0;
    %end;

    /*arm_by*/
    %if %superq(arm) ^= #NULL %then %do;
        %if %superq(arm_by) = #NULL %then %do;
            %put ERROR: (ARM_BY) 参数 arm 不为 #NULL，必须指定 arm_by！;
            %goto exit;
        %end;
        %else %do;
            %let reg_arm_by_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/)));
            %if %sysfunc(prxmatch(&reg_arm_by_id, %superq(arm_by))) %then %do;
                %let arm_by_fmt       = %sysfunc(prxposn(&reg_arm_by_id, 1, %superq(arm_by)));
                %let arm_by_direction = %sysfunc(prxposn(&reg_arm_by_id, 2, %superq(arm_by)));

                /*检查排序方向*/
                %if %bquote(&arm_by_direction) = %bquote() %then %do;
                    %put NOTE: (ARM_BY) 未指定分组的排序方向，默认升序排列！;
                    %let arm_by_direction = ASCENDING;
                %end;
                %else %if %bquote(&arm_by_direction) = ASC %then %do;
                    %let arm_by_direction = ASCENDING;
                %end;
                %else %if %bquote(&arm_by_direction) = DESC %then %do;
                    %let arm_by_direction = DESCENDING;
                %end;

                proc sql noprint;
                    select libname, memname, source into :arm_by_fmt_libname, :arm_by_fmt_memname, :arm_by_fmt_source from dictionary.formats where fmtname = "&arm_by_fmt";
                quit;
                %if &sqlobs = 0 %then %do;
                    %put ERROR: (ARM_BY) &arm_by_fmt 未定义！;
                    %goto exit;
                %end;

                proc format library = &arm_by_fmt_libname..&arm_by_fmt_memname cntlout = tmp_arm_by_fmt;
                    select &arm_by_fmt;
                run;

                proc sql noprint;
                    create table tmp_arm_sorted as
                        select
                            label,
                            (case when start = "LOW"  then -constant("BIG")
                                  when start = "HIGH" then  constant("BIG")
                                  else input(strip(start), 8.)
                            end)             as arm_by_fmt_start,
                            (case when end = "LOW"  then -constant("BIG")
                                  when end = "HIGH" then  constant("BIG")
                                  else input(strip(end), 8.)
                            end)             as arm_by_fmt_end
                        from tmp_arm_by_fmt
                        order by arm_by_fmt_start &arm_by_direction, arm_by_fmt_end &arm_by_direction;
                    select label into :arm_1- from tmp_arm_sorted;
                    %let arm_n = &sqlobs;
                    %if &arm_n = 0 %then %do;
                        %put ERROR: (ARM_BY) 指定的分组至少要有一个类别！;
                        %goto exit;
                    %end;
                quit;
            %end;
            %else %do;
                %put ERROR: (ARM_BY) 值 %superq(arm_by) 格式不正确！;
                %goto exit;
            %end;
        %end;
    %end;

    /*rowcat_missing*/
    %if %superq(rowcat_missing) = TRUE %then %do;
        %let rowcat_len_max = %sysfunc(max(%length(缺失), &rowcat_len_max));
    %end;

    /*rowcat_total*/
    %if %superq(rowcat_total) = TRUE %then %do;
        %let rowcat_len_max = %sysfunc(max(%length(合计), &rowcat_len_max));
    %end;

    /*复制 indata*/
    data tmp_indata;
        set %unquote(%superq(indata));
    run;

    /*创建各组别子集数据集，计算受试者数量*/
    proc sql noprint;
        select count(*) into :subj_n from tmp_indata;
        %do i = 1 %to &arm_n;
            create table tmp_indata_arm_&i as select * from tmp_indata where &arm = %unquote(%str(%')%superq(arm_&i)%str(%'));
            select count(*) into :arm_&i._subj_n trimmed from tmp_indata_arm_&i;
        %end;
    quit;

    /*构建交叉表*/
    proc sql noprint;
        /*建立数据框架*/
        create table tmp_crosstab
            (ITEM                         char(&rowcat_len_max) label = '行分类',
             %do i = 1 %to &arm_n;
                 %do j = 1 %to &colcat_n;
                     G&i._CAT&j._FREQ     num(8)                label = %unquote(%str(%')%superq(arm_&i)-%superq(colcat_&j)-例数%str(%')),
                     G&i._CAT&j._RATE     num(8)                label = %unquote(%str(%')%superq(arm_&i)-%superq(colcat_&j)-率%str(%')),
                 %end;
                 %if %superq(colcat_missing) = TRUE %then %do;
                     G&i._CATM_FREQ       num(8)                label = %unquote(%str(%')%superq(arm_&i)-缺失-例数%str(%')),
                     G&i._CATM_RATE       num(8)                label = %unquote(%str(%')%superq(arm_&i)-缺失-率%str(%')),
                 %end;
                 %if %superq(colcat_total) = TRUE %then %do;
                     G&i._CATT_FREQ       num(8)                label = %unquote(%str(%')%superq(arm_&i)-合计-例数%str(%')),
                     G&i._CATT_RATE       num(8)                label = %unquote(%str(%')%superq(arm_&i)-合计-率%str(%')),
                 %end;
             %end;
             %do j = 1 %to &colcat_n;
                 ALL_CAT&j._FREQ          num(8)                label = %unquote(%str(%')%superq(colcat_&j)-例数%str(%')),
                 ALL_CAT&j._RATE          num(8)                label = %unquote(%str(%')%superq(colcat_&j)-率%str(%')),
             %end;
             %if %superq(colcat_missing) = TRUE %then %do;
                 ALL_CATM_FREQ            num(8)                label = %unquote(%str(%')缺失-例数%str(%')),
                 ALL_CATM_RATE            num(8)                label = %unquote(%str(%')缺失-率%str(%')),
             %end;
             %if %superq(colcat_total) = TRUE %then %do;
                 ALL_CATT_FREQ            num(8)                label = %unquote(%str(%')合计-例数%str(%')),
                 ALL_CATT_RATE            num(8)                label = %unquote(%str(%')合计-率%str(%')),
             %end;
             _PLACEHOLDER_                char(1)
            );

        /*计算频数*/
        %do i = 1 %to &rowcat_n;
            insert into tmp_crosstab
                set ITEM = %unquote(%str(%')%superq(rowcat_&i)%str(%')),
                    %do j = 1 %to &arm_n;
                        %do k = 1 %to &colcat_n;
                            G&j._CAT&k._FREQ = (select count(*) from tmp_indata_arm_&j where %superq(rowcat) = %unquote(%str(%')%superq(rowcat_&i)%str(%')) and %superq(colcat) = %unquote(%str(%')%superq(colcat_&k)%str(%'))),
                        %end;
                        %if %superq(colcat_missing) = TRUE %then %do;
                            G&j._CATM_FREQ   = (select count(*) from tmp_indata_arm_&j where %superq(rowcat) = %unquote(%str(%')%superq(rowcat_&i)%str(%')) and missing(%superq(colcat))),
                        %end;
                        %if %superq(colcat_total) = TRUE %then %do;
                            G&j._CATT_FREQ   = (select count(*) from tmp_indata_arm_&j where %superq(rowcat) = %unquote(%str(%')%superq(rowcat_&i)%str(%'))),
                        %end;
                    %end;
                    %do k = 1 %to &colcat_n;
                        ALL_CAT&k._FREQ = (select count(*) from tmp_indata where %superq(rowcat) = %unquote(%str(%')%superq(rowcat_&i)%str(%')) and %superq(colcat) = %unquote(%str(%')%superq(colcat_&k)%str(%'))),
                    %end;
                    %if %superq(colcat_missing) = TRUE %then %do;
                        ALL_CATM_FREQ   = (select count(*) from tmp_indata where %superq(rowcat) = %unquote(%str(%')%superq(rowcat_&i)%str(%')) and missing(%superq(colcat))),
                    %end;
                    %if %superq(colcat_total) = TRUE %then %do;
                        ALL_CATT_FREQ   = (select count(*) from tmp_indata where %superq(rowcat) = %unquote(%str(%')%superq(rowcat_&i)%str(%'))),
                    %end;
                    _PLACEHOLDER_            = ""
                    ;
        %end;
        %if %superq(rowcat_missing) = TRUE %then %do;
            insert into tmp_crosstab
                set ITEM = '缺失',
                    %do j = 1 %to &arm_n;
                        %do k = 1 %to &colcat_n;
                            G&j._CAT&k._FREQ = (select count(*) from tmp_indata_arm_&j where missing(%superq(rowcat)) and %superq(colcat) = %unquote(%str(%')%superq(colcat_&k)%str(%'))),
                        %end;
                        %if %superq(colcat_missing) = TRUE %then %do;
                            G&j._CATM_FREQ   = (select count(*) from tmp_indata_arm_&j where missing(%superq(rowcat)) and missing(%superq(colcat))),
                        %end;
                        %if %superq(colcat_total) = TRUE %then %do;
                            G&j._CATT_FREQ   = (select count(*) from tmp_indata_arm_&j where missing(%superq(rowcat))),
                        %end;
                    %end;
                    %do k = 1 %to &colcat_n;
                        ALL_CAT&k._FREQ = (select count(*) from tmp_indata where missing(%superq(rowcat)) and %superq(colcat) = %unquote(%str(%')%superq(colcat_&k)%str(%'))),
                    %end;
                    %if %superq(colcat_missing) = TRUE %then %do;
                        ALL_CATM_FREQ   = (select count(*) from tmp_indata where missing(%superq(rowcat)) and missing(%superq(colcat))),
                    %end;
                    %if %superq(colcat_total) = TRUE %then %do;
                        ALL_CATT_FREQ   = (select count(*) from tmp_indata where missing(%superq(rowcat))),
                    %end;
                    _PLACEHOLDER_            = ""
                    ;
        %end;
        %if %superq(rowcat_total) = TRUE %then %do;
            insert into tmp_crosstab
                set ITEM = '合计',
                    %do j = 1 %to &arm_n;
                        %do k = 1 %to &colcat_n;
                            G&j._CAT&k._FREQ = (select count(*) from tmp_indata_arm_&j where %superq(colcat) = %unquote(%str(%')%superq(colcat_&k)%str(%'))),
                        %end;
                        %if %superq(colcat_missing) = TRUE %then %do;
                            G&j._CATM_FREQ   = (select count(*) from tmp_indata_arm_&j where missing(%superq(colcat))),
                        %end;
                        %if %superq(colcat_total) = TRUE %then %do;
                            G&j._CATT_FREQ   = (select count(*) from tmp_indata_arm_&j),
                        %end;
                    %end;
                    %do k = 1 %to &colcat_n;
                        ALL_CAT&k._FREQ = (select count(*) from tmp_indata where %superq(colcat) = %unquote(%str(%')%superq(colcat_&k)%str(%'))),
                    %end;
                    %if %superq(colcat_missing) = TRUE %then %do;
                        ALL_CATM_FREQ   = (select count(*) from tmp_indata where missing(%superq(colcat))),
                    %end;
                    %if %superq(colcat_total) = TRUE %then %do;
                        ALL_CATT_FREQ   = (select count(*) from tmp_indata),
                    %end;
                    _PLACEHOLDER_            = ""
                    ;
        %end;

        /*计算频率*/
        update tmp_crosstab
            set %do j = 1 %to &arm_n;
                    %do k = 1 %to &colcat_n;
                        G&j._CAT&k._RATE = G&j._CAT&k._FREQ / &&arm_&j._subj_n,
                    %end;
                    %if %superq(colcat_missing) = TRUE %then %do;
                        G&j._CATM_RATE   = G&j._CATM_FREQ / &&arm_&j._subj_n,
                    %end;
                    %if %superq(colcat_total) = TRUE %then %do;
                        G&j._CATT_RATE   = G&j._CATT_FREQ / &&arm_&j._subj_n,
                    %end;
                %end;
                %do k = 1 %to &colcat_n;
                    ALL_CAT&k._RATE = ALL_CAT&k._FREQ / &subj_n,
                %end;
                %if %superq(colcat_missing) = TRUE %then %do;
                    ALL_CATM_RATE   = ALL_CATM_FREQ / &subj_n,
                %end;
                %if %superq(colcat_total) = TRUE %then %do;
                    ALL_CATT_RATE   = ALL_CATT_FREQ / &subj_n,
                %end;
                _PLACEHOLDER_            = ""
                ;

        /*格式化值*/
        create table tmp_crosstab_formated as
            select
                ITEM,
                %do j = 1 %to &arm_n;
                    %do k = 1 %to &colcat_n;
                        G&j._CAT&k._FREQ,
                        G&j._CAT&k._RATE,
                        %if %superq(output_rate) = TRUE %then %do;
                            kstrip(put(G&j._CAT&k._FREQ, %superq(format_freq)))                                              as G&j._CAT&k._FREQ_FMT label = %unquote(%str(%')%superq(arm_&j)-%superq(colcat_&k)-频数（C）%str(%')),
                            kstrip(put(G&j._CAT&k._RATE, %superq(format_rate)))                                              as G&j._CAT&k._RATE_FMT label = %unquote(%str(%')%superq(arm_&j)-%superq(colcat_&k)-率（C）%str(%')),
                            kstrip(calculated G&j._CAT&k._FREQ_FMT) || "(" || kstrip(calculated G&j._CAT&k._RATE_FMT) || ")" as G&j._CAT&k._VALUE    label = %unquote(%str(%')%superq(arm_&j)-%superq(colcat_&k)%str(%')),
                        %end;
                        %else %do;
                            kstrip(put(G&j._CAT&k._FREQ, %superq(format_freq)))                                              as G&j._CAT&k._VALUE    label = %unquote(%str(%')%superq(arm_&j)-%superq(colcat_&k)%str(%')),
                        %end;
                    %end;
                    %if %superq(colcat_missing) = TRUE %then %do;
                        G&j._CATM_FREQ,
                        G&j._CATM_RATE,
                        %if %superq(output_rate) = TRUE %then %do;
                            kstrip(put(G&j._CATM_FREQ, %superq(format_freq)))                                                as G&j._CATM_FREQ_FMT   label = %unquote(%str(%')%superq(arm_&j)-缺失-频数（C）%str(%')),
                            kstrip(put(G&j._CATM_RATE, %superq(format_rate)))                                                as G&j._CATM_RATE_FMT   label = %unquote(%str(%')%superq(arm_&j)-缺失-率（C）%str(%')),
                            kstrip(calculated G&j._CATM_FREQ_FMT) || "(" || kstrip(calculated G&j._CATM_RATE_FMT) || ")"     as G&j._CATM_VALUE      label = %unquote(%str(%')%superq(arm_&j)-缺失%str(%')),
                        %end;
                        %else %do;
                            kstrip(put(G&j._CATM_FREQ, %superq(format_freq)))                                                as G&j._CATM_VALUE      label = %unquote(%str(%')%superq(arm_&j)-缺失%str(%')),
                        %end;
                    %end;
                    %if %superq(colcat_total) = TRUE %then %do;
                        G&j._CATT_FREQ,
                        G&j._CATT_RATE,
                        %if %superq(output_rate) = TRUE %then %do;
                            kstrip(put(G&j._CATT_FREQ, %superq(format_freq)))                                                as G&j._CATT_FREQ_FMT   label = %unquote(%str(%')%superq(arm_&j)-合计-频数（C）%str(%')),
                            kstrip(put(G&j._CATT_RATE, %superq(format_rate)))                                                as G&j._CATT_RATE_FMT   label = %unquote(%str(%')%superq(arm_&j)-合计-率（C）%str(%')),
                            kstrip(calculated G&j._CATT_FREQ_FMT) || "(" || kstrip(calculated G&j._CATT_RATE_FMT) || ")"     as G&j._CATT_VALUE      label = %unquote(%str(%')%superq(arm_&j)-合计%str(%')),
                        %end;
                        %else %do;
                            kstrip(put(G&j._CATT_FREQ, %superq(format_freq)))                                                as G&j._CATT_VALUE      label = %unquote(%str(%')%superq(arm_&j)-合计%str(%')),
                        %end;
                    %end;
                %end;
                %do k = 1 %to &colcat_n;
                    ALL_CAT&k._FREQ,
                    ALL_CAT&k._RATE,
                    %if %superq(output_rate) = TRUE %then %do;
                        kstrip(put(ALL_CAT&k._FREQ, %superq(format_freq)))                                                   as ALL_CAT&k._FREQ_FMT  label = %unquote(%str(%')%superq(colcat_&k)-频数（C）%str(%')),
                        kstrip(put(ALL_CAT&k._RATE, %superq(format_rate)))                                                   as ALL_CAT&k._RATE_FMT  label = %unquote(%str(%')%superq(colcat_&k)-率（C）%str(%')),
                        kstrip(calculated ALL_CAT&k._FREQ_FMT) || "(" || kstrip(calculated ALL_CAT&k._RATE_FMT) || ")"       as ALL_CAT&k._VALUE     label = %unquote(%str(%')%superq(colcat_&k)%str(%')),
                    %end;
                    %else %do;
                        kstrip(put(ALL_CAT&k._FREQ, %superq(format_freq)))                                                   as ALL_CAT&k._VALUE     label = %unquote(%str(%')%superq(colcat_&k)%str(%')),
                    %end;
                %end;
                %if %superq(colcat_missing) = TRUE %then %do;
                    ALL_CATM_FREQ,
                    ALL_CATM_RATE,
                    %if %superq(output_rate) = TRUE %then %do;
                        kstrip(put(ALL_CATM_FREQ, %superq(format_freq)))                                                     as ALL_CATM_FREQ_FMT    label = %unquote(%str(%')缺失-频数（C）%str(%')),
                        kstrip(put(ALL_CATM_RATE, %superq(format_rate)))                                                     as ALL_CATM_RATE_FMT    label = %unquote(%str(%')缺失-率（C）%str(%')),
                        kstrip(calculated ALL_CATM_FREQ_FMT) || "(" || kstrip(calculated ALL_CATM_RATE_FMT) || ")"           as ALL_CATM_VALUE       label = %unquote(%str(%')缺失%str(%')),
                    %end;
                    %else %do;
                        kstrip(put(ALL_CATM_FREQ, %superq(format_freq)))                                                     as ALL_CATM_VALUE       label = %unquote(%str(%')缺失%str(%')),
                    %end;
                %end;
                %if %superq(colcat_total) = TRUE %then %do;
                    ALL_CATT_FREQ,
                    ALL_CATT_RATE,
                    %if %superq(output_rate) = TRUE %then %do;
                        kstrip(put(ALL_CATT_FREQ, %superq(format_freq)))                                                     as ALL_CATT_FREQ_FMT    label = %unquote(%str(%')合计-频数（C）%str(%')),
                        kstrip(put(ALL_CATT_RATE, %superq(format_rate)))                                                     as ALL_CATT_RATE_FMT    label = %unquote(%str(%')合计-率（C）%str(%')),
                        kstrip(calculated ALL_CATT_FREQ_FMT) || "(" || kstrip(calculated ALL_CATT_RATE_FMT) || ")"           as ALL_CATT_VALUE       label = %unquote(%str(%')合计%str(%')),
                    %end;
                    %else %do;
                        kstrip(put(ALL_CATT_FREQ, %superq(format_freq)))                                                     as ALL_CATT_VALUE       label = %unquote(%str(%')合计%str(%')),
                    %end;
                %end;
                _PLACEHOLDER_            = ""
            from tmp_crosstab
            ;
    quit;


    /*输出数据集*/
    data &outdata;
        set tmp_crosstab_formated;
        keep ITEM
             %do j = 1 %to &arm_n;
                %do k = 1 %to &colcat_n;
                    G&j._CAT&k._VALUE
                %end;
                %if %superq(colcat_missing) = TRUE %then %do;
                    G&j._CATM_VALUE
                %end;
                %if %superq(colcat_total) = TRUE %then %do;
                    G&j._CATT_VALUE
                %end;
             %end;
             %do k = 1 %to &colcat_n;
                 ALL_CAT&k._VALUE
             %end;
             %if %superq(colcat_missing) = TRUE %then %do;
                 ALL_CATM_VALUE
             %end;
             %if %superq(colcat_total) = TRUE %then %do;
                 ALL_CATT_VALUE
             %end;
             ;
    run;

    /*----------------------------------------------运行后处理----------------------------------------------*/

    %if &debug = FALSE %then %do;
        /*删除中间数据集*/
        proc datasets noprint nowarn;
            delete tmp_indata
                   %do i = 1 %to &arm_n;
                       tmp_indata_arm_&i
                   %end;
                   tmp_rowcat_by_fmt
                   tmp_rowcat_sorted
                   tmp_colcat_by_fmt
                   tmp_colcat_sorted
                   tmp_arm_by_fmt
                   tmp_arm_sorted
                   tmp_crosstab
                   tmp_crosstab_formated
                   ;
        quit;
    %end;

    /*退出宏程序*/
    %exit:
    %put NOTE: 宏 crosstab 已结束运行！;
%mend;
