/*
===================================
Macro Name: desc_coun
Macro Label:定性资料描述性分析
Author: wtwang
Version Date: 2023-02-09 V1.11
              2024-03-18 V1.12
===================================
*/


%macro desc_coun(INDATA, VAR, FORMAT = PERCENTN9.2, BY = &VAR, MISSING = FALSE, DENOMINATOR = #AUTO,
                 INDENT = %bquote(    ), LABEL = #AUTO, IS_LABEL_INDENT = FALSE, IS_LABEL_DISPLAY = TRUE,
                 OUTDATA = #AUTO, DEL_TEMP_DATA = TRUE, DEL_DUP_BY_VAR = #NULL,
                 SKIP_PARAM_CHECK = FALSE, SKIP_MAIN_PROG = FALSE, PARAM_VALID_FLAG_VAR = #NULL,
                 PARAM_LIST_BUFFER = #NULL) /des = "定性资料描述分析" parmbuff;
/*
----Required Argument----
INDATA               待分析数据集
VAR                  待分析变量

----Optional Argument----
FORMAT               百分比输出格式
BY                   排序依据(ASC, DESC, VARIABLE)
MISSING              是否将缺失值视为一类(将会占据上一层级下的一个分类)
DENOMINATOR          计算百分比基于的变量或数值(#ALL, 表示基于合计频数进行计算
                                                #LAST，表示基于上一层级的频数进行计算)
INDENT               相邻层级之间的缩进字符(串)
LABEL                输出数据集的表头标签(例如: 性别-n(%))
IS_LABEL_INDENT      表头标签是否缩进
IS_LABEL_DISPLAY     表头标签是否展示(IS_LABEL_DISPLAY = FALSE时, 参数LABEL, IS_LABEL_INDENT仍然生效)
OUTDATA              输出数据集名称

----Developer Argument----
DEL_TEMP_DATA        是否删除中间数据集
DEL_DUP_BY_VAR       删除重复观测基于的变量（例如：统计某个SOC下的AE例数时，需指定 DEL_DUP_BY_VAR = USUBJID）
SKIP_PARAM_CHECK     是否跳过参数检查
SKIP_MAIN_PROG       是否跳过主程序
PARAM_VALID_FLAG_VAR 参数合法性标识变量
PARAM_LIST_BUFFER    参数列表缓冲池
*/

    /*打开帮助文档*/
    %if %bquote(%upcase(&SYSPBUFF)) = %bquote((HELP)) or %bquote(%upcase(&SYSPBUFF)) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/desc_coun/readme.md";
        %goto exit;
    %end;

    /*统一参数大小写*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&var)))))));
    %let format               = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&format)))))));
    %let by                   = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&by)))))));
    %let missing              = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&missing)))))));
    %let denominator          = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&denominator)))))));
    %let label                = %sysfunc(strip(%bquote(&label)));
    %let is_label_indent      = %upcase(%sysfunc(strip(%bquote(&is_label_indent))));
    %let is_label_display     = %upcase(%sysfunc(strip(%bquote(&is_label_display))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let del_temp_data        = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));
    %let del_dup_by_var       = %upcase(%sysfunc(strip(%bquote(&del_dup_by_var))));
    %let skip_param_check     = %upcase(%sysfunc(strip(%bquote(&skip_param_check))));
    %let skip_main_prog       = %upcase(%sysfunc(strip(%bquote(&skip_main_prog))));
    %let param_valid_flag_var = %upcase(%sysfunc(strip(%bquote(&param_valid_flag_var))));
    %let param_list_buffer    = %upcase(%sysfunc(strip(%bquote(&param_list_buffer))));


    /*声明局部变量*/
    %local i j;

    

    /*----------------------------------------------参数检查----------------------------------------------*/
    /*SKIP_PARAM_CHECK*/
    %if %bquote(&SKIP_PARAM_CHECK) ^= TRUE and %bquote(&SKIP_PARAM_CHECK) ^= FALSE %then %do;
        %put ERROR: 参数 SKIP_PARAM_CHECK 必须是 TRUE 或 FALSE！;
        %goto exit;
    %end;
    %else %if %bquote(&SKIP_PARAM_CHECK) = TRUE %then %do;
        %put NOTE: 调用宏程序 %nrstr(%%desc_coun) 时使用参数 SKIP_PARAM_CHECK = TRUE 跳过了参数检查步骤！;
        %goto prog;
    %end;

    /*INDATA*/
    %if %bquote(&indata) = %bquote() %then %do;
        %put ERROR: 未指定分析数据集！;
        %goto exit_err;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, &indata)) = 0 %then %do;
            %put ERROR: 参数 INDATA = &indata 格式不正确！;
            %goto exit_err;
        %end;
        %else %do;
            %let libname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 1, &indata)));
            %let memname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 2, &indata)));
            %let dataset_options_in = %sysfunc(prxposn(&reg_indata_id, 3, &indata));
            %if &libname_in = %bquote() %then %let libname_in = WORK; /*未指定逻辑库，默认为WORK目录*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_in 逻辑库不存在！;
                %goto exit_err;
            %end;
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in" and memname = "&memname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: 在 &libname_in 逻辑库中没有找到 &memname_in 数据集！;
                %goto exit_err;
            %end;
        %end;
    %end;
    %put NOTE: 分析数据集被指定为 &libname_in..&memname_in;

    /*VAR*/
    %if %bquote(&var) = %bquote() %then %do;
        %put ERROR: 未指定分析变量！;
        %goto exit_err;
    %end;
    %else %do;
        %let var_n = %eval(%sysfunc(count(&var, %bquote( ))) + 1);
        %if &var_n = 1 %then %do;
            %let reg_var_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
        %end;
        %else %do;
            %let reg_var_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*)%sysfunc(repeat(\s+([A-Za-z_][A-Za-z_\d]*), %eval(&var_n - 2)))$/);
        %end;
        %let reg_var_id = %sysfunc(prxparse(&reg_var_expr));
        %if %sysfunc(prxmatch(&reg_var_id, &var)) = 0 %then %do;
            %put ERROR: 参数 VAR = &var 格式不正确！;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_VAR = TRUE;
            /*判断分析变量是否重复*/
            %do i = 1 %to &var_n;
                %let VAR_&i = %sysfunc(prxposn(&reg_var_id, &i, &var));
                %if &i < &var_n %then %do;
                    %do j = %eval(&i + 1) %to &var_n;
                        %let VAR_&j = %sysfunc(prxposn(&reg_var_id, &j, &var));
                        %if %bquote(&&VAR_&i) = %bquote(&&VAR_&j) %then %do;
                            %put ERROR: 不允许重复指定分析变量 &&VAR_&i ！;
                            %goto exit_err;
                        %end;
                    %end;
                %end;
            %end;
            /*判断分析变量是否存在*/
            %do i = 1 %to &var_n;
                %let VAR_&i = %sysfunc(prxposn(&reg_var_id, &i, &var));
                proc sql noprint;
                    select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&&VAR_&i";
                quit;
                %if &SQLOBS = 0 %then %do;
                    %put ERROR: 在 &libname_in..&memname_in 中没有找到分析变量 &&VAR_&i;
                    %let IS_VALID_VAR = FALSE;
                %end;
            %end;
            %if &IS_VALID_VAR = FALSE %then %goto exit_err;
        %end;
    %end;

    /*FORMAT*/
    %if %bquote(&format) = %bquote() %then %do;
        %put ERROR: 参数 FORMAT 为空！;
        %goto exit_err;
    %end;
    %else %do;
        %let format_n = %eval(%sysfunc(count(&format, %bquote( ))) + 1);
        %if &format_n < &var_n %then %do; /*格式数少于变量个数*/
            %if &format_n = 1 %then %do;
                %put NOTE: 指定输出格式统一为 &format ！;
                %let format = %bquote(&format%sysfunc(repeat(%bquote( &format), %eval(&var_n - 2))));
            %end;
            %else %do;
                %let format = %bquote(&format%sysfunc(repeat(%bquote( %scan(&format, -1, %bquote( ))), %eval(&var_n - &format_n - 1))));
                %put WARNING: 指定的输出格式数量少于变量个数，未匹配的变量将使用参数 FORMAT 的最后一个输出格式！;
            %end;
        %end;
        %else %if &format_n > &var_n %then %do;
            %let temp_format = %scan(&format, 1, %bquote( ));
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_format = &temp_format %scan(&format, &i, %bquote( ));
                %end;
            %end;
            %let format = &temp_format;
            %put WARNING: 指定的输出格式数量多于变量个数，多余的输出格式将被忽略！;
        %end;

        %let format_n = %eval(%sysfunc(count(&format, %bquote( ))) + 1);
        %if &format_n = 1 %then %do;
            %let reg_format_expr = %bquote(/^((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)$/);
        %end;
        %else %do;
            %let reg_format_expr = %bquote(/^((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)%sysfunc(repeat(\s+((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*), %eval(&format_n - 2)))$/);
        %end;
        %let reg_format_id = %sysfunc(prxparse(&reg_format_expr));
        %if %sysfunc(prxmatch(&reg_format_id, &format)) = 0 %then %do;
            %put ERROR: 参数 FORMAT = &format 格式不正确！;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_FORMAT = TRUE;
            %do i = 1 %to &format_n;
                %let FORMAT_&i = %sysfunc(prxposn(&reg_format_id, %eval(2 * &i - 1), &format));
                %let FORMAT_BASE_&i = %sysfunc(prxposn(&reg_format_id, %eval(2 * &i), &format));
                %if %bquote(&&FORMAT_BASE_&i) ^= %bquote() %then %do; /*输出格式含有名称*/
                    proc sql noprint;
                        select * from DICTIONARY.FORMATS where fmtname = "&&FORMAT_BASE_&i" and fmttype = "F";
                    quit;
                    %if &SQLOBS = 0 %then %do;
                        %put ERROR: 输出格式 &&FORMAT_&i 不存在！;
                        %let IS_VALID_FORMAT = FALSE;
                    %end;
                %end;
            %end;
        %end;
        %if &IS_VALID_FORMAT = FALSE %then %goto exit_err;
    %end;

    /*BY*/
    %if %bquote(&by) = %bquote() %then %do;
        %put ERROR: 参数 BY 为空！;
        %goto exit_err;
    %end;
    %else %do;
        %let by_n = %eval(%sysfunc(count(&by, %bquote( ))) + 1);
        %if &by_n < &var_n %then %do; /*排序准则数少于变量个数*/
            %if %bquote(&by) = #FREQ_MIN %then %do;
                %put NOTE: 指定排序准则统一为 &by (从小到大排列)！;
                %let by = %bquote(&by%sysfunc(repeat(%bquote( &by), %eval(&var_n - 2))));
            %end;
            %else %if %bquote(&by) = #FREQ_MAX %then %do;
                %put NOTE: 指定排序准则统一为 &by (从大到小排列)！;
                %let by = %bquote(&by%sysfunc(repeat(%bquote( &by), %eval(&var_n - 2))));
            %end;
            %else %do;
                %unquote(%nrstr(%%let by =)) %sysfunc(compbl(&by
                                                                %do i = %eval(&by_n + 1) %to &var_n;
                                                                    %bquote( )%scan(&var, &i, %bquote( ))
                                                                %end;
                                                            )
                                                     );
                %put NOTE: 指定的排序变量(准则)个数少于分析变量个数，未匹配的变量将基于自身的值进行排序！;
            %end;
        %end;
        %else %if &by_n > &var_n %then %do; /*排序准则数多于变量个数*/
            %let temp_by = %scan(&by, 1, %bquote( ));
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_by = &temp_by %scan(&by, &i, %bquote( ));
                %end;
            %end;
            %let by = &temp_by;
            %put WARNING: 指定的排序变量(准则)个数多于分析变量个数，多余的排序变量(准则)将被忽略！;
        %end;

        %let by_n = %eval(%sysfunc(count(&by, %bquote( ))) + 1);
        %if &by_n = 1 %then %do;
            %let reg_by_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*(?:\((?:(?:DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?|#FREQ_MIN|#FREQ_MAX)$/);
        %end;
        %else %do;
            %let reg_by_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*(?:\((?:(?:DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?|#FREQ_MIN|#FREQ_MAX)%sysfunc(repeat(\s+([A-Za-z_][A-Za-z_\d]*(?:\((?:(?:DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?|#FREQ_MIN|#FREQ_MAX), %eval(&by_n - 2)))$/);
        %end;
        %let reg_by_id = %sysfunc(prxparse(&reg_by_expr));
        %if %sysfunc(prxmatch(&reg_by_id, &by)) = 0 %then %do;
            %put ERROR: 参数 BY = &by 格式不正确！;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_BY = TRUE;
            %do i = 1 %to &by_n; /*逐个排序依据的解析，包括排序使用的变量与排序的方向*/
                %let BY_&i = %sysfunc(prxposn(&reg_by_id, &i, &by));
                %if %bquote(&&BY_&i) ^= #FREQ_MIN and %bquote(&&BY_&i) ^= #FREQ_MAX %then %do;
                    %let reg_by_var_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\((?:(DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?$/);
                    %let reg_by_var_expr_id = %sysfunc(prxparse(&reg_by_var_expr));
                    %if %sysfunc(prxmatch(&reg_by_var_expr_id, &&BY_&i)) %then %do;
                        %let SCEND_BASE_&i = %sysfunc(prxposn(&reg_by_var_expr_id, 1, &&BY_&i)); /*排序依据的变量*/
                        %let SCEND_DIRECTION_&i = %sysfunc(prxposn(&reg_by_var_expr_id, 2, &&BY_&i)); /*排序方向*/
                        
                        %if %bquote(&&SCEND_DIRECTION_&i) = %bquote() %then %do;
                            %put NOTE: 未指定排序变量 &&SCEND_BASE_&i 的排序方向，默认升序排列！;
                            %let SCEND_DIRECTION_&i = ASC;
                        %end;
                        %else %if %bquote(&&SCEND_DIRECTION_&i) = DESCENDING %then %let SCEND_DIRECTION_&i = DESC;
                        %else %if %bquote(&&SCEND_DIRECTION_&i) = ASCENDING %then %let SCEND_DIRECTION_&i = ASC;
                    %end;
                %end;
                %else %if %bquote(&&BY_&i) = #FREQ_MAX %then %do;
                    %let SCEND_DIRECTION_&i = DESC;
                    %let SCEND_BASE_&i = #FREQ;
                %end;
                %else %if %bquote(&&BY_&i) = #FREQ_MIN %then %do;
                    %let SCEND_DIRECTION_&i = ASC;
                    %let SCEND_BASE_&i = #FREQ;
                %end;
            %end;
            
            %do i = 1 %to &by_n;
                /*判断排序变量是否重复*/
                %if &i < &by_n %then %do;
                    %do j = %eval(&i + 1) %to &by_n;
                        %if %bquote(&&SCEND_BASE_&i) ^= #FREQ and %bquote(&&SCEND_BASE_&j) ^= #FREQ and %bquote(&&SCEND_BASE_&i) = %bquote(&&SCEND_BASE_&j) %then %do;
                            %put ERROR: 不允许重复指定排序变量 &&SCEND_BASE_&i ！;
                            %let IS_VALID_BY = FALSE;
                        %end;
                    %end;
                %end;
                
                %if %bquote(&&SCEND_BASE_&i) ^= #FREQ %then %do;
                    /*判断排序变量是否与分析变量冲突*/
                    %if %sysfunc(whichc(&&SCEND_BASE_&i, %unquote(%sysfunc(transtrn(&VAR, %bquote( ), %bquote(,)))))) and &&SCEND_BASE_&i ^= &&VAR_&i %then %do;
                        %put ERROR: 不允许对分析变量 &&VAR_&i 指定另一个分析变量 &&SCEND_BASE_&i 作为排序变量！;
                        %let IS_VALID_BY = FALSE;
                    %end;
                    %else %do;
                        /*判断排序变量是否存在*/
                        proc sql noprint;
                            select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&&SCEND_BASE_&i";
                        quit;
                        %if &SQLOBS = 0 %then %do;
                            %put ERROR: 在 &libname_in..&memname_in 中没有找到排序变量 &&SCEND_BASE_&i;
                            %let IS_VALID_BY = FALSE;
                        %end;
                    %end;
                %end;
            %end;
        %end;
        %if &IS_VALID_BY = FALSE %then %goto exit_err;
    %end;

    /*MISSING*/
    %if %bquote(&missing) = %bquote() %then %do;
        %put ERROR: 参数 MISSING 为空！;
        %goto exit_err;
    %end;
    %else %do;
        %let missing_n = %eval(%sysfunc(count(&missing, %bquote( ))) + 1);
        %if &missing_n < &var_n %then %do; /*指定的“是否将缺失值考虑为一类进行统计”标识数量少于变量个数*/
            %if &missing_n = 1 %then %do;
                %put NOTE: 指定“是否将缺失值考虑为一类进行统计”标识统一为 &missing ！;
                %let missing = %bquote(&missing%sysfunc(repeat(%bquote( &missing), %eval(&var_n - 2))));
            %end;
            %else %do;
                %let missing = %bquote(&missing%sysfunc(repeat(%bquote( %scan(&missing, -1, %bquote( ))), %eval(&var_n - &missing_n - 1))));
                %put WARNING: 指定的“是否将缺失值考虑为一类进行统计”标识数量少于分析变量个数，未匹配的变量将使用参数 MISSING 的最后一个标识的值！;
            %end;
        %end;
        %else %if &missing_n > &var_n %then %do; /*指定的“是否将缺失值考虑为一类进行统计”标识数量多于变量个数*/
            %let temp_missing = %scan(&missing, 1, %bquote( ));
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_missing = &temp_missing %scan(&missing, &i, %bquote( ));
                %end;
            %end;
            %let missing = &temp_missing;
            %put WARNING: 指定的“是否将缺失值考虑为一类进行统计”标识数量多于分析变量个数，多余的标识将被忽略！;
        %end;

        %let missing_n = %eval(%sysfunc(count(&missing, %bquote( ))) + 1);
        %if &missing_n = 1 %then %do;
            %let reg_missing_expr = %bquote(/^(TRUE|FALSE)$/);
        %end;
        %else %do;
            %let reg_missing_expr = %bquote(/^(TRUE|FALSE)%sysfunc(repeat(\s+(TRUE|FALSE), %eval(&by_n - 2)))$/);
        %end;
        %let reg_missing_id = %sysfunc(prxparse(&reg_missing_expr));
        %if %sysfunc(prxmatch(&reg_missing_id, &missing)) = 0 %then %do;
            %put ERROR: 参数 MISSING = &missing 格式不正确！;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_MISSING = TRUE;
            %do i = 1 %to &missing_n;
                %let MISSING_&i = %sysfunc(prxposn(&reg_missing_id, &i, &missing));
            %end;
        %end;
        %if &IS_VALID_MISSING = FALSE %then %goto exit_err;
    %end;

    /*DENOMINATOR*/
    %if %bquote(&denominator) = #AUTO %then %do;
        %if &var_n = 1 %then %do;
            %let denominator = %bquote();
        %end;
        %else %do;
            %let denominator = %sysfunc(strip(%sysfunc(repeat(%bquote( #ALL), %eval(&var_n - 2)))));
        %end;
    %end;
    %if %bquote(&denominator) = %bquote() %then %do;
        %if &var_n = 1 %then %do;
            %let denominator = #ALL;
        %end;
        %else %do;
            %put ERROR: 参数 DENOMINATOR 为空！;
            %goto exit_err;
        %end;
    %end;
    %else %do;
        %if %bquote(&denominator) = %bquote() %then %do;
            %let denominator_n = 0;
        %end;
        %else %do;
            %let denominator_n = %eval(%sysfunc(count(&denominator, %bquote( ))) + 1);
        %end;
        %if %sysfunc(prxmatch(%bquote(/^\d*(?:\.\d+)?$/), &denominator)) %then %do; /*参数 DENOMINATOR 被指定为一个数值，仅供构建其他程序时使用*/
            %let denominator = %sysfunc(strip(%sysfunc(repeat(%bquote( &denominator), %eval(&var_n - 1)))));
            %put NOTE: 指定计算频率的分母统一为数值！;
        %end;
        %else %if %eval(&denominator_n + 1) < &var_n %then %do; /*参数 DENOMINATOR 指定的值的数量+1少于变量个数*/
            %if &denominator = #ALL %then %do;
                %let denominator = %bquote(&denominator%sysfunc(repeat(%bquote( &denominator), %eval(&var_n - 2))));
                %put NOTE: 指定计算频率的分母统一为合计频数！;
            %end;
            %else %if &denominator = #LAST %then %do;
                %let denominator = %bquote(#ALL%sysfunc(repeat(%bquote( &denominator), %eval(&var_n - 2))));
                %put NOTE: 指定除首层分析变量之外，其余分析变量用于计算频率的分母统一为上一层分析变量的频数！;
            %end;
            %else %do;
                %let denominator = %bquote(#ALL &denominator%sysfunc(repeat(%bquote( #ALL), %eval(&var_n - &denominator_n - 2))));
                %put NOTE: 指定的用于计算频率的分母的变量(依据)个数少于非最顶层分析变量个数，未匹配的分析变量将使用合计频数作为频率计算的分母！;
            %end;
        %end;
        %else %if %eval(&denominator_n + 1) > &var_n %then %do; /*参数 DENOMINATOR 指定的值的数量+1多于变量个数*/
            %let temp_denominator = #ALL;
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_denominator = &temp_denominator %scan(&denominator, %eval(&i - 1), %bquote( ));
                %end;
            %end;
            %let denominator = &temp_denominator;
            %put WARNING: 指定的用于计算频率的分母的变量(依据)个数多于非最顶层分析变量个数，多余的变量将被忽略！;
        %end;
        %else %do; /*参数 DENOMINATOR 指定的值的数量+1等于变量个数*/
            %let denominator = %sysfunc(strip(%bquote(#ALL &denominator)));
        %end;
    %end;

    %let denominator_n = %eval(%sysfunc(count(&denominator, %bquote( ))) + 1);
    %if &denominator_n = 1 %then %do;
        %let reg_denominator_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*|(\d*(?:\.\d+)?)|#ALL|#LAST)$/);
    %end;
    %else %do;
        %let reg_denominator_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*|(\d*(?:\.\d+)?)|#ALL|#LAST)%sysfunc(repeat(\s+([A-Za-z_][A-Za-z_\d]*|(\d*(?:\.\d+)?)|#ALL|#LAST), %eval(&denominator_n - 2)))$/);
    %end;
    %let reg_denominator_id = %sysfunc(prxparse(&reg_denominator_expr));
    %if %sysfunc(prxmatch(&reg_denominator_id, &denominator)) = 0 %then %do;
        %put ERROR: 参数 DENOMINATOR = &denominator 格式不正确！;
        %goto exit_err;
    %end;
    %else %do;
        %let IS_VALID_DENOMINATOR = TRUE;
        %do i = 1 %to &denominator_n;
            %let DENOMINATOR_&i = %sysfunc(prxposn(&reg_denominator_id, %eval(2 * &i - 1), &denominator));
            %let DENOMINATOR_NUM_&i = %sysfunc(prxposn(&reg_denominator_id, %eval(2 * &i), &denominator));
            %if %bquote(&&DENOMINATOR_NUM_&i) ^= %bquote() %then %do; /*指定用作分母的是一个数值*/
                %let DENOMINATOR_&i = #NUM;
            %end;
            %else %if &&DENOMINATOR_&i ^= #ALL and &&DENOMINATOR_&i ^= #LAST %then %do; /*指定用作分母的是一个变量*/
                %if %sysfunc(count(&var, &&DENOMINATOR_&i)) = 0 %then %do;
                    %put ERROR: 不允许指定分析变量 &var 之外的变量 &&DENOMINATOR_&i 作为计算分析变量 &&VAR_&i 的频率的分母！;
                    %let IS_VALID_DENOMINATOR = FALSE;
                %end;
                %else %do;
                    %let DENOMINATOR_LEVEL = %sysfunc(whichc(&&DENOMINATOR_&i, %unquote(%sysfunc(transtrn(&var, %bquote( ), %bquote(,)))))); /*指定的用作分母的变量在参数 VAR 的位置*/
                    %if &DENOMINATOR_LEVEL > &i %then %do;
                        %put ERROR: 不允许指定较低层级的分析变量 &&DENOMINATOR_&i 作为计算较高层级的分析变量 &&VAR_&i 的频率的分母！;
                        %let IS_VALID_DENOMINATOR = FALSE;
                    %end;
                    %else %if &DENOMINATOR_LEVEL = &i %then %do;
                        %put ERROR: 不允许指定分析变量 &&DENOMINATOR_&i 自身作为计算分析变量 &&VAR_&i 的频率的分母！;
                        %let IS_VALID_DENOMINATOR = FALSE;
                    %end;
                %end;
            %end;
        %end;
        %if &IS_VALID_DENOMINATOR = FALSE %then %do;
            %goto exit_err;
        %end;
    %end;


    /*LABEL*/
    %if %bquote(&label) = %bquote() %then %do;
        %put ERROR: 试图指定参数 LABEL 为空！;
        %goto exit_err;
    %end;
    %else %if %nrbquote(%upcase(&label)) = #AUTO %then %do;
        proc sql noprint;
            select
                (case when label ^= "" then cats(label, "-n(%)")
                      else cats(name, "-n(%)") end)
                into: label from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&VAR_1";
        quit;
    %end;
    
    /*IS_LABEL_INDENT*/
    %if %bquote(&IS_LABEL_INDENT) ^= TRUE and %bquote(&IS_LABEL_INDENT) ^= FALSE %then %do;
        %put ERROR: 参数 IS_LABEL_INDENT 必须是 TRUE 或 FALSE！;
        %goto exit_err;
    %end;

    /*IS_LABEL_DISPLAY*/
    %if %bquote(&IS_LABEL_DISPLAY) ^= TRUE and %bquote(&IS_LABEL_DISPLAY) ^= FALSE %then %do;
        %put ERROR: 参数 IS_LABEL_DISPLAY 必须是 TRUE 或 FALSE！;
        %goto exit_err;
    %end;

    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: 试图指定 OUTDATA 为空！;
        %goto exit_err;
    %end;
    %else %if %bquote(&outdata) = #NULL %then %do;
        %put NOTE: 参数 OUTDATA 被指定为 #NULL，结果将不会被输出！;
    %end;
    %else %do;
        %if %bquote(&outdata) = #AUTO %then %do;
            %let outdata = RES_&VAR_1;
        %end;

        %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_outdata_id, &outdata)) = 0 %then %do;
            %put ERROR: 参数 OUTDATA = &outdata 格式不正确！;
            %goto exit_err;
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
                %goto exit_err;
            %end;
        %end;
        %put NOTE: 输出数据集被指定为 &libname_out..&memname_out;
    %end;


    /*DEL_TEMP_DATA*/
    %if %bquote(&DEL_TEMP_DATA) ^= TRUE and %bquote(&DEL_TEMP_DATA) ^= FALSE %then %do;
        %put ERROR: 参数 DEL_TEMP_DATA 必须是 TRUE 或 FALSE！;
        %goto exit_err;
    %end;


    /*DEL_DUP_BY_VAR*/
    %if %bquote(&DEL_DUP_BY_VAR) = %bquote() %then %do;
        %put ERROR: 参数 DEL_DUP_BY_VAR 为空！;
        %goto exit_err;
    %end;
    %else %if %bquote(&DEL_DUP_BY_VAR) ^= #NULL %then %do;
        %if %sysfunc(prxmatch(%bquote(/^[A-Za-z_][A-Za-z_\d]*$/), &DEL_DUP_BY_VAR)) %then %do;
            proc sql noprint;
                select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&DEL_DUP_BY_VAR";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 &DEL_DUP_BY_VAR;
                %goto exit_err;
            %end;
            %else %if %sysfunc(count(&var, &DEL_DUP_BY_VAR)) > 0 %then %do;
                %put ERROR: 不允许指定分析变量 &DEL_DUP_BY_VAR 作为辅助去重的变量！;
                %goto exit_err;
            %end;
        %end;
        %else %do;
            %put ERROR: 参数 DEL_DUP_BY_VAR 必须是一个变量名！;
            %goto exit_err;
        %end;
    %end;

    /*----------捕获所有参数----------*/
    %if %bquote(&PARAM_LIST_BUFFER) ^= #NULL %then %do;
        %if %symexist(&PARAM_LIST_BUFFER) %then %do;
            %unquote(%nrstr(%%let)) &PARAM_LIST_BUFFER =
                                                        %nrstr(%%let) libname_in = &libname_in%str(;)
                                                        %nrstr(%%let) memname_in = &memname_in%str(;)
                                                        %nrstr(%%let) dataset_options_in = &dataset_options_in%str(;)
                                                        %nrstr(%%let) var_n = &var_n%str(;)
                                                        %do i = 1 %to &var_n;
                                                            %nrstr(%%let) VAR_&i = &&VAR_&i%str(;)
                                                            %nrstr(%%let) FORMAT_&i = &&FORMAT_&i%str(;)
                                                            %nrstr(%%let) SCEND_BASE_&i = &&SCEND_BASE_&i%str(;)
                                                            %nrstr(%%let) SCEND_DIRECTION_&i = &&SCEND_DIRECTION_&i%str(;)
                                                            %nrstr(%%let) MISSING_&i = &&MISSING_&i%str(;)
                                                            %nrstr(%%let) DENOMINATOR_&i = &&DENOMINATOR_&i%str(;)
                                                            %nrstr(%%let) DENOMINATOR_NUM_&i = &&DENOMINATOR_NUM_&i%str(;)
                                                        %end;
                                                        %nrstr(%%let) libname_out = &libname_out%str(;)
                                                        %nrstr(%%let) memname_out = &memname_out%nrstr(;)
                                                        %nrstr(%%let) dataset_options_out = &dataset_options_out%str(;)
                                                        ;
        %end;
        %else %do;
            %put ERROR: 未定义用于接收处理之后的参数列表的宏变量！;
            %goto exit_err;
        %end;
    %end;
                           

    /*主程序前处理*/
    %prog:
    /*SKIP_MAIN_PROG*/
    %if %bquote(&SKIP_MAIN_PROG) ^= TRUE and %bquote(&SKIP_MAIN_PROG) ^= FALSE %then %do;
        %put ERROR: 参数 SKIP_MAIN_PROG 必须是 TRUE 或 FALSE！;
        %goto exit_err;
    %end;
    %else %if %bquote(&SKIP_MAIN_PROG) = TRUE %then %do;
        %put NOTE: 调用宏程序 %nrstr(%%desc_coun) 时使用参数 SKIP_MAIN_PROG = TRUE 跳过了主程序步骤！;
        %goto exit;
    %end;

    /*----------释放所有参数----------*/
    %if %bquote(&PARAM_LIST_BUFFER) ^= #NULL %then %do;
        %unquote(&&&PARAM_LIST_BUFFER)
    %end;

    /*----------------------------------------------主程序----------------------------------------------*/
    /*0.重复值剔除*/
    %if &DEL_DUP_BY_VAR ^= #NULL %then %do;
        %do i = 1 %to &var_n;
            proc sort data = &libname_in..&memname_in%if %bquote(&dataset_options_in) ^= %bquote() %then %do;(&dataset_options_in)%end;
                      out = temp_nodup_&&VAR_&i nodupkey;
                by &DEL_DUP_BY_VAR %do j = 1 %to &i; %bquote( &&VAR_&j) %end;;
            run;
        %end;
    %end;


    /*1.生成各层级的频数表*/
    proc sql noprint;
        %do i = 1 %to &var_n;
            %unquote(%nrstr(%%let MISSING_STRATA_CAT =)) %sysfunc(catx(%bquote( ) %unquote(%do j = 1 %to &i; %bquote(,)%bquote(&&MISSING_&j) %end;))); /*前i个MISSING的值*/
            create table temp_strata_freq_&&VAR_&i as
                select
                    distinct
                    &i as STRATA label = "层级", /*该变量用于缩进*/
                    %do j = 1 %to &i;
                        (case when &j = &i then 1 else 0 end) as &&VAR_&j.._LV label = "&&VAR_&j.._LV", /*该变量用于排序，确保各层的合计结果排在细分子类的前面*/
                    %end;
                    %sysfunc(catx(%bquote(, ) %unquote(%do j = 1 %to &i; %bquote(, &&VAR_&j) %end;))),
                    %do j = 1 %to &i;
                        %if &&SCEND_BASE_&j ^= #FREQ and &&SCEND_BASE_&j ^= &&VAR_&j %then %do;
                            %bquote(&&SCEND_BASE_&j,)
                        %end;
                    %end;
                    count(*)    as FREQ    label = "频数"
                from %if &DEL_DUP_BY_VAR = #NULL %then %do;
                         &libname_in..&memname_in%if %bquote(&dataset_options_in) ^= %bquote() %then %do;(&dataset_options_in)%end;
                     %end;
                     %else %do;
                         temp_nodup_&&VAR_&i
                     %end;
                %if %sysfunc(count(&MISSING_STRATA_CAT, FALSE)) > 0 %then %do;
                    where
                        %sysfunc(catx(%bquote( and ) %unquote(
                                                              %do j = 1 %to &var_n;
                                                                  %if &&MISSING_&j = FALSE %then %do;
                                                                      %bquote(,)%bquote(not missing(&&VAR_&j))
                                                                  %end;
                                                              %end;
                                                             )
                                     )
                                )
                %end;
                group by %sysfunc(catx(%bquote(, ) %unquote(%do j = 1 %to &i; %bquote(,)%bquote(&&VAR_&j) %end;)))
                ;
        %end;
    quit;

    /*2. 计算各层级的频率，应用format*/
    proc sql noprint;
        select sum(FREQ) into: GRN_ALL from temp_strata_freq_&VAR_1; /*频数合计*/
        %do i = 1 %to &var_n;
            %if &&DENOMINATOR_&i ^= #ALL and &&DENOMINATOR_&i ^= #NUM %then %do;
                %if &&DENOMINATOR_&i = #LAST %then %do;
                    %let DENOMINATOR_SRTATA_N = %eval(&i - 1); /*基于的分母的层数*/
                %end;
                %else %do;
                    %let DENOMINATOR_SRTATA_N = %sysfunc(whichc(&&DENOMINATOR_&i, %unquote(%sysfunc(transtrn(&VAR, %bquote( ), %bquote(,)))))); /*基于的分母的层数*/
                %end;
                %do j = 1 %to &DENOMINATOR_SRTATA_N;
                    %let DENOMINATOR_SRTATA_&j = &&VAR_&j; /*基于的分母的层级*/
                %end;
            %end;
            create table temp_strata_pct_&&VAR_&i as
                select
                    a.*,
                    %if &&DENOMINATOR_&i = #ALL %then %do;
                        a.FREQ/&GRN_ALL as FREQPCT label = "百分比",
                        put(a.FREQ/&GRN_ALL, &&FORMAT_&i) as FREQPCTC label = "百分比（C）"
                    %end;
                    %else %if &&DENOMINATOR_&i = #NUM %then %do;
                        a.FREQ/&&DENOMINATOR_NUM_&i as FREQPCT label = "百分比",
                        put(a.FREQ/&&DENOMINATOR_NUM_&i, &&FORMAT_&i) as FREQPCTC label = "百分比（C）"
                    %end;
                    %else %if &&DENOMINATOR_&i = #LAST %then %do;
                        a.FREQ/b.FREQ as FREQPCT label = "百分比",
                        put(a.FREQ/b.FREQ, &&FORMAT_&i) as FREQPCTC label = "百分比（C）"
                    %end;
                    %else %do;
                        a.FREQ/b.FREQ as FREQPCT label = "百分比",
                        put(a.FREQ/b.FREQ, &&FORMAT_&i) as FREQPCTC label = "百分比（C）"
                    %end;
                from temp_strata_freq_&&VAR_&i as a %if &&DENOMINATOR_&i ^= #ALL  and &&DENOMINATOR_&i ^= #NUM %then %do;
                                                        left join %if &&DENOMINATOR_&i = #LAST %then %do;
                                                                      %unquote(temp_strata_freq_%nrbquote(&&)VAR_%eval(&i - 1)) as b
                                                                  %end;
                                                                  %else %do;
                                                                      temp_strata_freq_&&DENOMINATOR_&i as b
                                                                  %end;
                                                                  on %do j = 1 %to &DENOMINATOR_SRTATA_N;
                                                                         %if &j < &DENOMINATOR_SRTATA_N %then %do;
                                                                             a.&&DENOMINATOR_SRTATA_&j = b.&&DENOMINATOR_SRTATA_&j and 
                                                                         %end;
                                                                         %else %do;
                                                                             a.&&DENOMINATOR_SRTATA_&j = b.&&DENOMINATOR_SRTATA_&j
                                                                         %end;
                                                                     %end;
                                                    %end;
                ;
        %end;
    quit;

    /*3. 合并各层级的频数频率表*/
    proc sql noprint;
        create table temp_union as
            %sysfunc(catx(%bquote( outer union corr ) %unquote(
                                                               %do i = 1 %to &var_n;
                                                                   %bquote(,)%bquote(select * from temp_strata_pct_&&VAR_&i)
                                                               %end;
                                                               )
                         )
                    );
    quit;

    /*4. 将各层级的频数衍生出用于排序的单独变量*/
    /*例如：对于某个观测的某一分析变量，对应的衍生变量值为该观测在这一分析变量的水平上的频数，无论该观测此时处于哪一层级中*/
    proc sql noprint;
        create table temp_union_freq as
            select
                temp_union.*,
                %do i = 1 %to &var_n;
                    %if &i < &var_n %then %do;
                        temp_strata_freq_&&VAR_&i...FREQ as &&VAR_&i.._FQ label = "&&VAR_&i.._FQ",
                    %end;
                    %else %do;
                        temp_strata_freq_&&VAR_&i...FREQ as &&VAR_&i.._FQ label = "&&VAR_&i.._FQ"
                    %end;
                %end;
            from temp_union %do i = 1 %to &var_n;
                                left join temp_strata_freq_&&VAR_&i on 
                                %do j = 1 %to &i;
                                    %if &j < &i %then %do;
                                        temp_union.&&VAR_&j = temp_strata_freq_&&VAR_&i...&&VAR_&j and 
                                    %end;
                                    %else %do;
                                        temp_union.&&VAR_&j = temp_strata_freq_&&VAR_&i...&&VAR_&j
                                    %end;
                                %end;
                            %end;
            ;
    quit;

    /*5. 将各层级的水平名称根据参数INDENT及IS_LABEL_INDENT对齐，添加缩进符号(如有)，组合频数和频率*/
    proc sql noprint;
        create table temp_align as
            select
                *,
                (case
                    %if &IS_LABEL_INDENT = TRUE %then %do; /*首层缩进*/
                        %do i = 1 %to &var_n;
                            when strata = &i then repeat("&INDENT", %eval(&i - 1)) || strip(&&VAR_&i)
                        %end;
                    %end;
                    %else %do; /*首层不缩进*/
                        when strata = 1 then strip(&VAR_1)
                        %do i = 2 %to &var_n;
                            when strata = &i then repeat("&INDENT", %eval(&i - 2)) || strip(&&VAR_&i)
                        %end;
                    %end;
                end)                           as ITEM  label = "指标",
                cats(FREQ, "(", FREQPCTC, ")") as VALUE label = "指标值"
            from temp_union_freq;
    quit;
    

    /*6. 按指定顺序排序*/
    proc sql noprint;
        create table temp_sort as
            select * from temp_align
                order by %sysfunc(catx(%bquote(, ) %unquote(
                                                               %do i = 1 %to &var_n;
                                                                   %if &&SCEND_BASE_&i = #FREQ %then %do;
                                                                       %bquote(,)%bquote(&&VAR_&i.._FQ &&SCEND_DIRECTION_&i)
                                                                   %end;
                                                                   %else %do;
                                                                       %bquote(,)%bquote(&&SCEND_BASE_&i &&SCEND_DIRECTION_&i)
                                                                   %end;
                                                                       %bquote(,)%bquote(&&VAR_&i)%bquote(,)%bquote(&&VAR_&i.._LV DESC)
                                                               %end;
                                                           )
                                      )
                                 );
    quit;

    /*7. 添加或不添加 LABEL */
    %if &IS_LABEL_DISPLAY = TRUE %then %do; /*不显示标签, 因此无需生成 TEMP_LABEL 数据集, 节省资源*/
        data temp_label;
            ITEM = "&label";
        run;
    %end;
    proc sql noprint;
        create table temp_add_label as
            %if &IS_LABEL_DISPLAY = TRUE %then %do; /*不显示标签*/
                select * from temp_label
                outer union corr
            %end;
            select
                *
            from temp_sort;
    quit;

    /*8. 输出数据集*/
    %if %bquote(&outdata) ^= #NULL %then %do;
        %if &libname_in = &libname_out and &memname_in = &memname_out %then %do;
            %put WARNING: 指定的输出数据集与分析数据集一致，&libname_in..&memname_in 将被覆盖！;
        %end;
        data &libname_out..&memname_out(%if %bquote(&dataset_options_out) = %bquote() %then %do;
                                            keep = item value
                                        %end;
                                        %else %do;
                                            &dataset_options_out
                                        %end;);
            set temp_add_label;
        run;
    %end;

    /*----------------------------------------------运行后处理----------------------------------------------*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn; /*删除临时数据集*/
            delete %do i = 1 %to &var_n;
                       temp_nodup_&&VAR_&i
                       temp_strata_freq_&&VAR_&i
                       temp_strata_pct_&&VAR_&i
                   %end;
                   temp_union
                   temp_union_freq
                   temp_align
                   temp_sort
                   temp_label
                   temp_add_label
                   ;
        quit;
    %end;
    %goto exit;


    /*异常退出*/
    %exit_err:
    %if &PARAM_VALID_FLAG_VAR ^= #NULL %then %do;
        %if %symexist(&PARAM_VALID_FLAG_VAR) %then %do;
            %let &PARAM_VALID_FLAG_VAR = FALSE;
        %end;
        %else %do;
            %put ERROR: 未定义用于表示宏参数合法性的宏变量！;
            %goto exit;
        %end;
    %end;

    /*正常退出*/
    %exit:
    %put NOTE: 宏 desc_coun 已结束运行！;
%mend;
