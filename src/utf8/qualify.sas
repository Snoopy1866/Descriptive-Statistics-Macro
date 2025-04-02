/*
===================================
Macro Name: qualify
Macro Label:定性指标分析
Author: wtwang
Version Date: 2025-04-02
===================================
*/

%macro qualify(indata,
               var,
               by               = #auto,
               uid              = #null,
               pattern          = %nrstr(#freq(#rate)),
               missing          = false,
               missing_note     = "缺失",
               missing_position = last,
               outdata          = #auto,
               stat_format      = #auto,
               label            = #auto,
               indent           = #auto,
               suffix           = #auto,
               total            = false,
               debug            = false)
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
    %let uid                  = %upcase(%sysfunc(strip(%bquote(&uid))));
    %let missing              = %upcase(%sysfunc(strip(%bquote(&missing))));
    %let missing_position     = %upcase(%sysfunc(strip(%bquote(&missing_position))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let stat_format          = %upcase(%sysfunc(strip(%bquote(&stat_format))));
    %let total                = %upcase(%sysfunc(strip(%bquote(&total))));
    %let debug                = %upcase(%sysfunc(strip(%bquote(&debug))));

    /*受支持的统计量*/
    %let stat_supported = %bquote(FREQ|RATE|TIMES|N);

    /*声明全局变量*/
    /*全局输出格式*/
    %global FREQ_format
            RATE_format
            TIMES_format
            N_format
            ;
    /*全局零频数输出格式*/
    %global FREQ_zero
            FREQ_zero_fmt
            N_zero
            N_zero_fmt
            TIMES_zero
            TIMES_zero_fmt
            RATE_zero
            RATE_zero_fmt
            VALUE_zero
            ;
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

            proc sql noprint;
                select count(*) into : nobs from &indata;
            quit;
            %if &nobs = 0 %then %do;
                %put NOTE: 分析数据集 &indata 为空！;
            %end;
        %end;
    %end;
    %put NOTE: 分析数据集被指定为 &libname_in..&memname_in;


    /*VAR*/
    %if %bquote(&var) = %bquote() %then %do;
        %put ERROR: 未指定分析变量！;
        %goto exit_with_error;
    %end;

    %let reg_var = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:[\s,]*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*=\s*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27))+\s*)?\))?$/);
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

        /*拆分需要进行重命名的水平名称*/
        %let var_level_rename_n = 0;
        %if %bquote(&var_level) ^= %bquote() %then %do; 
            %let reg_var_level_expr_unit = %bquote(/\s*(\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*=\s*(\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)/);
            %let reg_var_level_expr_unit_id = %sysfunc(prxparse(&reg_var_level_expr_unit));
            %let start = 1;
            %let stop = %length(&var_level);
            %let position = 1;
            %let length = 1;
            %let i = 1;
            %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %do %until(&position = 0); /*连续匹配正则表达式*/
                %let var_level_&i._name_pair = %substr(%bquote(&var_level), &position, &length); /*第i个水平的旧名称和新名称*/
                %if %sysfunc(prxmatch(&reg_var_level_expr_unit_id, %bquote(&&var_level_&i._name_pair))) %then %do;
                    %let var_level_&i._name_old = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 1, %bquote(&&var_level_&i._name_pair))); /*拆分第i个水平的旧名称*/
                    %let var_level_&i._name_new = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 2, %bquote(&&var_level_&i._name_pair))); /*拆分第i个水平的新名称*/
                %end;
                %else %do;
                    %put ERROR: 在对参数 VAR 解析第 &i 个分类的新旧名称时发生了意料之外的错误！;
                    %goto exit_with_error;
                %end;
                %let i = %eval(&i + 1);
                %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %end;
            %let var_level_rename_n = %eval(&i - 1); /*计算需要进行重命名的水平名称的数量*/
        %end;
    %end;


    /*BY*/
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
            create table tmp_qualify_distinct_var(where = (not missing(var_level))) as
                select
                    distinct
                    &var_name            as var_level,
                    %if &var_level_rename_n > 0 %then %do;
                        (case &var_name
                            %do i = 1 %to &var_level_rename_n;
                                when &&var_level_&i._name_old then &&var_level_&i._name_new
                            %end;
                                else &var_name
                        end)
                    %end;
                    %else %do;
                        &var_name
                    %end;                as var_level_note,
                    count(&var_name)     as var_level_by_criteria
                from %bquote(&indata)
                group by var_level
                order by var_level_by_criteria &by_direction, var_level ascending;
        quit;
    %end;
    %else %if %bquote(&by_var) ^= %bquote() %then %do;
        proc sql noprint;
            create table tmp_qualify_distinct_var(where = (not missing(var_level))) as
                select
                    distinct
                    &var_name            as var_level,
                    %if &var_level_rename_n > 0 %then %do;
                        (case &var_name
                            %do i = 1 %to &var_level_rename_n;
                                when &&var_level_&i._name_old then &&var_level_&i._name_new
                            %end;
                                else &var_name
                        end)
                    %end;
                    %else %do;
                        &var_name
                    %end;                as var_level_note,
                    &by_var              as var_level_by_criteria
                from %bquote(&indata)
                order by var_level_by_criteria &by_direction, var_level ascending;
        quit;
    %end;
    %else %if %bquote(&by_fmt) ^= %bquote() %then %do;
        proc format library = &by_fmt_libname..&by_fmt_memname cntlout = tmp_qualify_by_fmt;
            select &by_fmt;
        run;
        proc sql noprint;
            create table tmp_qualify_distinct_var(where = (not missing(var_level))) as
                select
                    distinct
                    coalescec(a.&var_name, b.label)       as var_level,
                    %if &var_level_rename_n > 0 %then %do;
                        (case calculated var_level
                            %do i = 1 %to &var_level_rename_n;
                                when &&var_level_&i._name_old then &&var_level_&i._name_new
                            %end;
                                else calculated var_level
                        end)
                    %end;
                    %else %do;
                        calculated var_level
                    %end;                                 as var_level_note,
                    ifn(not missing(b.label), input(strip(b.start), 8.), constant('BIG'))
                                                          as var_level_by_criteria,
                    ifc(missing(b.label), 'Y', '')
                                                          as var_level_fmt_not_defined
                from %bquote(&indata) as a full join tmp_qualify_by_fmt as b on a.&var_name = b.label
                order by var_level_by_criteria &by_direction, var_level ascending;

            select sum(var_level_fmt_not_defined = "Y") into : by_fmt_not_defined_n trimmed from tmp_qualify_distinct_var where not missing(var_level);
            %if &by_fmt_not_defined_n > 0 %then %do;
                %put WARNING: 指定用于排序的输出格式中，存在 &by_fmt_not_defined_n 个分类名称未定义，输出结果可能是非预期的！;
            %end;
        quit;
    %end;


    /*UID*/
    %if %bquote(&uid) = %bquote() %then %do;
        %put ERROR: 未指定唯一标识符变量！;
        %goto exit_with_error;
    %end;

    %if %bquote(&uid) ^= #NULL %then %do;
        %let uid_n = %sysfunc(max(1, %sysfunc(kcountw(%bquote(&uid), %bquote(), s))));
        %if &uid_n = 1 %then %do;
            %let reg_uid = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
        %end;
        %else %do;
            %let reg_uid = %bquote(/^([A-Za-z_][A-Za-z_\d]*)%sysfunc(repeat((?:\s+([A-Za-z_][A-Za-z_\d]*)), %eval(&uid_n - 2)))$/);
        %end;
        %let reg_uid_id = %sysfunc(prxparse(&reg_uid));

        %if %sysfunc(prxmatch(&reg_uid_id, %bquote(&uid))) = 0 %then %do;
            %put ERROR: 参数 UID = %bquote(&uid) 格式不正确！;
            %goto exit_with_error;
        %end;
        %else %do;
            /*判断是否指定重复的变量*/
            %do i = 1 %to &uid_n;
                %let uid_&i = %sysfunc(prxposn(&reg_uid_id, &i, %bquote(&uid)));
                %if &i < &uid_n %then %do;
                    %do j = %eval(&i + 1) %to &uid_n;
                        %let uid_&j = %sysfunc(prxposn(&reg_uid_id, &j, %bquote(&uid)));
                        %if %bquote(&&uid_&i) = %bquote(&&uid_&j) %then %do;
                            %put ERROR: 不允许重复指定标识符变量 %bquote(&&uid_&i)！;
                            %goto exit_with_error;
                        %end;
                    %end;
                %end;
            %end;
            /*判断变量是否存在*/
            %let IS_VALID_UID = TRUE;
            %do i = 1 %to &uid_n;
                %let uid_&i = %sysfunc(prxposn(&reg_uid_id, &i, %bquote(&uid)));
                proc sql noprint;
                    select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&&uid_&i";
                quit;
                %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
                    %put ERROR: 在 &libname_in..&memname_in 中没有找到标识符变量 %bquote(&&uid_&i)！;
                    %let IS_VALID_UID = FALSE;
                %end;
            %end;
            %if &IS_VALID_UID = FALSE %then %goto exit_with_error;
        %end;
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
            %let reg_missing_note_id = %sysfunc(prxparse(%bquote(/^(\x22[^\x22]*\x22|\x27[^\x27]*\x27)$/)));
            %if %sysfunc(prxmatch(&reg_missing_note_id, %superq(missing_note))) %then %do;
                %let missing_note_sql_expr = %superq(missing_note);
            %end;
            %else %do;
                %put ERROR: 参数 MISSING_NOTE 格式不正确，指定的字符串必须使用匹配的引号包围！;
                %goto exit;
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
            data tmp_qualify_distinct_var
                if _n_ = 1 then do;
                    var_level = "";
                    var_level_note = %unquote(%sysfunc(quote(%superq(missing_note_sql_expr))));
                    output;
                end;
                set tmp_qualify_distinct_var;
                output;
            run;
        %end;
        %else %if %superq(missing_position) = LAST %then %do;
            data tmp_qualify_distinct_var;
                set tmp_qualify_distinct_var;
                output;
                var_level = "";
                var_level_note = %unquote(%sysfunc(quote(%superq(missing_note_sql_expr))));
                output;
            run;
        %end;
        %else %do;
            %put ERROR: 参数 MISSING_POSITION 只能是 FIRST 或 LAST！;
            %goto exit_with_error;
        %end;
    %end;

    proc sql noprint;
        select count(*)                    into : var_level_n        from tmp_qualify_distinct_var;
        %if &var_level_n > 0 %then %do;
            select max(length(var_level))      into : var_level_len      from tmp_qualify_distinct_var;
            select max(length(var_level_note)) into : var_level_note_len from tmp_qualify_distinct_var;

            select quote(strip(var_level))      length = %eval(&var_level_len + 2)      into : var_level_1-      from tmp_qualify_distinct_var;
            select quote(strip(var_level_note)) length = %eval(&var_level_note_len + 2) into : var_level_note_1- from tmp_qualify_distinct_var;
            select count(var_level)                                                     into : var_level_n       from tmp_qualify_distinct_var;
        %end;
        %else %do;
            %put NOTE: 数据集中没有任何分类！;
        %end;
    quit;

    data tmp_qualify_indata;
        set &libname_in..&memname_in(&dataset_options_in);
        %if &var_level_n > 0 %then %do;
            if &var_name in (%do i = 1 %to &var_level_n; &&var_level_&i %end;);
        %end;
        %else %do;
            delete;
        %end;
    run;


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
    %let FREQ_format  = best.;
    %let RATE_format  = percentn9.2;
    %let TIMES_format = &FREQ_format;
    %let N_format     = &FREQ_format;

    %if %bquote(&stat_format) ^= #AUTO %then %do;
        %let stat_format_n = %eval(%sysfunc(kcountw(%bquote(&stat_format), %bquote(=), q)) - 1);
        %if &stat_format_n <= 0 %then %do;
            %put ERROR: 参数 STAT_FORMAT 为空！;
            %goto exit_with_error;
        %end;

        %let reg_stat_format_expr_unit = %bquote(\s*#(&stat_supported|TS|P)\s*=\s*((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)[\s,]*);
        %let reg_stat_format_expr = %bquote(/^\(?%sysfunc(repeat(&reg_stat_format_expr_unit, %eval(&stat_format_n - 1)))\)?$/i);
        %let reg_stat_format_id = %sysfunc(prxparse(&reg_stat_format_expr));

        %if %sysfunc(prxmatch(&reg_stat_format_id, %bquote(&stat_format))) %then %do;
            %let IS_VALID_STAT_FORMAT = TRUE;
            %do i = 1 %to &stat_format_n;
                %let stat_whose_format_2be_update = %upcase(%sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3 - 2), %bquote(&stat_format))));
                %let stat_new_format = %sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3 - 1), %bquote(&stat_format)));
                %let stat_new_format_base = %sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3), %bquote(&stat_format)));

                %if %bquote(&stat_new_format_base) ^= %bquote() %then %do;
                    proc sql noprint;
                        select * from DICTIONARY.FORMATS where fmtname = "&stat_new_format_base" and fmttype = "F";
                    quit;
                    %if &SQLOBS = 0 %then %do;
                        %put ERROR: 为统计量 &stat_whose_format_2be_update 指定的输出格式 &stat_new_format_base 不存在！;
                        %let IS_VALID_STAT_FORMAT = FALSE;
                    %end;
                %end;

                /*更新统计量的输出格式*/
                %let &stat_whose_format_2be_update._format = %bquote(&stat_new_format);

                /*对于存在别名的统计量，需同步修改输出格式*/
                %if &stat_whose_format_2be_update = N %then %do;
                    %let FREQ_format = %bquote(&stat_new_format);
                %end;
                %else %if &stat_whose_format_2be_update = FREQ %then %do;
                    %let N_format = %bquote(&stat_new_format);
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
    %if %superq(label) = %bquote() %then %do;
        %let label_sql_expr = %bquote('');
    %end;
    %else %if %qupcase(&label) = #AUTO %then %do;
        proc sql noprint;
            select
                (case when label ^= "" then cats("'", label, "'")
                      else cats("'", name, "-n(%)", "'") end)
                into: label_sql_expr from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var_name";
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


    /*SUFFIX*/
    %if %superq(suffix) = %bquote() %then %do;
        %let suffix_sql_expr = %bquote('');
    %end;
    %else %if %qupcase(&suffix) = #AUTO %then %do;
        %let suffix_sql_expr = %bquote('    ');
    %end;
    %else %do;
        %let reg_suffix_id = %sysfunc(prxparse(%bquote(/^(\x22[^\x22]*\x22|\x27[^\x27]*\x27)$/)));
        %if %sysfunc(prxmatch(&reg_suffix_id, %superq(suffix))) %then %do;
            %let suffix_sql_expr = %superq(suffix);
        %end;
        %else %do;
            %put ERROR: 参数 SUFFIX 格式不正确，指定的字符串必须使用匹配的引号包围！;
            %goto exit;
        %end;
    %end;


    /*TOTAL*/
    %if %superq(total) = %bquote() %then %do;
        %put ERROR: 参数 TOTAL 为空！;
        %goto exit;
    %end;

    %if %superq(total) ^= TRUE and %superq(total) ^= FALSE %then %do;
        %put ERROR: 参数 TOTAL 只能是 TRUE 和 FALSE 其中之一！;
        %goto exit;
    %end;


    /*----------------------------------------------主程序----------------------------------------------*/
    /*1. 去重UID*/
    %if %superq(uid) = #NULL %then %do;
        data tmp_qualify_indata_unique_total
             tmp_qualify_indata_unique_var;
            set tmp_qualify_indata;
            output tmp_qualify_indata_unique_total;
            output tmp_qualify_indata_unique_var;
        run;
    %end;
    %else %do;
        proc sort data = tmp_qualify_indata out = tmp_qualify_indata_unique_total nodupkey;
            by %do i = 1 %to &uid_n; &&uid_&i %end;;
        run;
        proc sort data = tmp_qualify_indata out = tmp_qualify_indata_unique_var nodupkey;
            by %do i = 1 %to &uid_n; &&uid_&i %end; &var_name;
        run;
    %end;


    /*2. 计算频数、频次、频率*/
    /*替换 "#|" 为 "|", "##" 为 "#"*/
    %macro temp_combpl_hash(string);
        transtrn(transtrn(&string, "#|", "|"), "##", "#")
    %mend;

    /*频数为零的输出结果*/
    %if %sysmexecname(%sysmexecdepth - 1) = QUALIFY_MULTI %then %do;
        %let FREQ_zero      = 0;
        %let FREQ_zero_fmt  = %sysfunc(putn(&FREQ_zero, &FREQ_format -R));
        %let N_zero         = 0;
        %let N_zero_fmt     = %sysfunc(putn(&N_zero, &N_format -R));
        %let TIMES_zero     = 0;
        %let TIMES_zero_fmt = %sysfunc(putn(&TIMES_zero, &TIMES_format -R));
        %let RATE_zero      = 0;
        %let RATE_zero_fmt  = %sysfunc(putn(&RATE_zero, &RATE_format -R));
        data _null_;
            VALUE_zero = cat(%unquote(%do j = 1 %to &stat_n;
                                          %temp_combpl_hash("&&string_&j") %bquote(,) strip("&&&&&&stat_&j.._zero_fmt") %bquote(,)
                                      %end;
                                      %temp_combpl_hash("&&string_&j")
                                     )
                            );
            call symputx("VALUE_zero", VALUE_zero, "G");
        run;
    %end;

    /*汇总*/
    proc sql noprint;
        select count(*) into :total_n from tmp_qualify_indata_unique_total;
        create table tmp_qualify_outdata_label as
            select
                distinct
                0                                 as IDT,
                0                                 as SEQ,
                %unquote(%superq(label_sql_expr)) as ITEM,
                %if &total = TRUE %then %do;
                    /*频数*/
                    coalesce(count(*), 0)                                                  as FREQ,
                    strip(put(calculated FREQ, &FREQ_format))                              as FREQ_FMT,
                    /*频数-兼容旧版本*/
                    calculated FREQ                                                        as N,
                    calculated FREQ_FMT                                                    as N_FMT,
                    /*频次*/
                    coalesce((select count(*) from tmp_qualify_indata), 0)                 as TIMES,
                    strip(put(calculated TIMES, &TIMES_format))                            as TIMES_FMT,
                    /*频率*/
                    ifn(&total_n = 0, ., 1)                                                as RATE,
                    ifc(not missing(calculated RATE), strip(put(1, &RATE_format)), "-")
                                                                                           as RATE_FMT,
                    %do j = 1 %to &stat_n;
                        %temp_combpl_hash("&&string_&j") || strip(calculated &&stat_&j.._FMT) ||
                    %end;
                    %temp_combpl_hash("&&string_&j")                                       as VALUE
                %end;
                %else %do;
                    sum(.)                                                                 as FREQ,
                    ""                                                                     as FREQ_FMT,
                    sum(.)                                                                 as N,
                    ""                                                                     as N_FMT,
                    sum(.)                                                                 as TIMES,
                    ""                                                                     as TIMES_FMT,
                    sum(.)                                                                 as RATE,
                    ""                                                                     as RATE_FMT,
                    ""                                                                     as VALUE
                %end;
            from tmp_qualify_indata_unique_total;
    quit;

    %do i = 1 %to &var_level_n;
        proc sql noprint;
            create table tmp_qualify_outdata_level_&i as
                select
                    1                                                                      as IDT,
                    &i                                                                     as SEQ,
                    %unquote(%superq(indent_sql_expr)) || %unquote(&&var_level_note_&i) || %unquote(%superq(suffix_sql_expr))
                                                                                           as ITEM,
                    /*频数*/
                    coalesce(sum(&var_name = &&var_level_&i), 0)                           as FREQ,
                    strip(put(calculated FREQ, &FREQ_format))                              as FREQ_FMT,
                    /*频数-兼容旧版本*/
                    calculated FREQ                                                        as N,
                    calculated FREQ_FMT                                                    as N_FMT,
                    /*频次*/
                    coalesce((select sum(&var_name = &&var_level_&i) from tmp_qualify_indata), 0)
                                                                                           as TIMES,
                    strip(put(calculated TIMES, &TIMES_format))                            as TIMES_FMT,
                    /*频率*/
                    calculated N/count(*)                                                  as RATE,
                    ifc(not missing(calculated RATE), strip(put(calculated RATE, &RATE_format)), "-")
                                                                                           as RATE_FMT,
                    %do j = 1 %to &stat_n;
                        %temp_combpl_hash("&&string_&j") || strip(calculated &&stat_&j.._FMT) ||
                    %end;
                    %temp_combpl_hash("&&string_&j")                                       as VALUE
                from tmp_qualify_indata_unique_var;
        quit;
    %end;


    /*3. 输出数据集*/
    proc sql noprint;
        create table tmp_qualify_outdata as
            select * from tmp_qualify_outdata_label
            %do i = 1 %to &var_level_n;
                outer union corr select * from tmp_qualify_outdata_level_&i
            %end;
            ;

        select max(length(item)), max(length(FREQ_FMT)), max(length(N_FMT)), max(length(TIMES_FMT)), max(length(RATE_FMT)), max(length(value))
            into :column_item_len_max, :column_freq_fmt_len_max, :column_n_fmt_len_max, :column_times_fmt_len_max, :column_rate_fmt_len_max, :column_value_len_max from tmp_qualify_outdata;
        %let column_freq_fmt_len_max  = %sysfunc(max(&column_freq_fmt_len_max, %length(FREQ_zero_fmt)));
        %let column_n_fmt_len_max     = %sysfunc(max(&column_n_fmt_len_max, %length(N_zero_fmt)));
        %let column_times_fmt_len_max = %sysfunc(max(&column_times_fmt_len_max, %length(TIMES_zero_fmt)));
        %let column_rate_fmt_len_max  = %sysfunc(max(&column_rate_fmt_len_max, %length(RATE_zero_fmt)));
        %let column_value_len_max  = %sysfunc(max(&column_value_len_max, %length(VALUE_zero)));

        alter table tmp_qualify_outdata
            modify item      char(&column_item_len_max),
                   freq_fmt  char(&column_freq_fmt_len_max),
                   n_fmt     char(&column_n_fmt_len_max),
                   times_fmt char(&column_times_fmt_len_max),
                   rate_fmt  char(&column_rate_fmt_len_max),
                   value     char(&column_value_len_max);
    quit;

    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        %if &uid ^= #NULL %then %do;
                                            keep = item times_fmt value
                                        %end;
                                        %else %do;
                                            keep = item value
                                        %end;
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_qualify_outdata;
    run;


    /*----------------------------------------------运行后处理----------------------------------------------*/
    /*删除中间数据集*/
    %if &debug = false %then %do;
        proc datasets noprint nowarn;
            delete tmp_qualify_indata
                   tmp_qualify_indata_unique_total
                   %if not (%sysmexecname(%sysfunc(max(%sysmexecdepth - 2, 0))) = QUALIFY_MULTI_TEST) %then %do; /*如果被 %qualify_multi_test 调用，则保留数据集 tmp_qualify_indata_unique_var*/
                       tmp_qualify_indata_unique_var
                   %end;
                   tmp_qualify_by_fmt
                   tmp_qualify_distinct_var
                   tmp_qualify_outdata_label
                   %do i = 1 %to &var_level_n;
                       tmp_qualify_outdata_level_&i
                   %end;
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
