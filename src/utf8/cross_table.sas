/*
===================================
Macro Name: cross_table
Macro Label:基本列联表
Author: wtwang
Version Date: 2022-09-21 V1.1
              2024-05-28 V1.2
              2024-06-05 V1.2.1
===================================
*/

%macro cross_table(INDATA,
                   ROWCAT,
                   COLCAT,
                   OUTDATA,
                   ROWCAT_BY       = #AUTO,
                   COLCAT_BY       = #AUTO,
                   N               = #AUTO,
                   ADD_CAT_MISSING = FALSE FALSE,
                   ADD_CAT_OTHER   = FALSE FALSE,
                   ADD_CAT_ALL     = TRUE TRUE,
                   PCT_OUT         = FALSE,
                   FORMAT          = PERCENTN9.2,
                   DEL_TEMP_DATA   = TRUE) /des = "基本列联表" parmbuff;

    /*打开帮助文档*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/cross_table/readme.md";
        %goto exit;
    %end;


    /*统一参数大小写*/
    %let indata          = %sysfunc(strip(%bquote(&indata)));
    %let rowcat          = %sysfunc(strip(%bquote(&rowcat)));
    %let colcat          = %sysfunc(strip(%bquote(&colcat)));
    %let outdata         = %sysfunc(strip(%bquote(&outdata)));
    %let rowcat_by       = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&rowcat_by)))))));
    %let colcat_by       = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&colcat_by)))))));
    %let n               = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&n)))))));
    %let add_cat_missing = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&add_cat_missing)))))));
    %let add_cat_other   = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&add_cat_other)))))));
    %let add_cat_all     = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&add_cat_all)))))));
    %let pct_out         = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&pct_out)))))));
    %let format          = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&format)))))));
    %let del_temp_data   = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));

    /*声明局部变量*/
    %local i j;



    /*-------------------------------------------参数检查-------------------------------------------*/
    /*INDATA*/
    %if %bquote(&indata) = %bquote() %then %do;
        %put ERROR: 未指定分析数据集！;
        %goto exit;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, &indata)) = 0 %then %do;
            %put ERROR: 参数 INDATA = &indata 格式不正确！;
            %goto exit;
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
                %goto exit;
            %end;
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in" and memname = "&memname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: 在 &libname_in 逻辑库中没有找到 &memname_in 数据集！;
                %goto exit;
            %end;
        %end;
    %end;
    %put NOTE: 分析数据集被指定为 &libname_in..&memname_in;


    /*ROWCAT*/
    %if %bquote(&rowcat) = %bquote() %then %do;
        %put ERROR: 未指定构建列联表的行变量名！;
        %goto exit;
    %end;

    %let IS_ROW_CAT_SPECIFIED = FALSE;
    %let reg_rowcat = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\((\s*".*"(?:[\s,]+".*")*\s*)?\))?$/);
    %let reg_rowcat_id = %sysfunc(prxparse(&reg_rowcat));
    %if %sysfunc(prxmatch(&reg_rowcat_id, &rowcat)) = 0 %then %do;
        %put ERROR: 参数 ROWCAT = &rowcat 格式不正确！;
        %goto exit;
    %end;
    %else %do;
        %let row_var = %upcase(%sysfunc(prxposn(&reg_rowcat_id, 1, &rowcat))); /*行变量*/
        %let row_val = %sysfunc(prxposn(&reg_rowcat_id, 2, &rowcat)); /*行分类*/
        proc sql noprint;
            select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&row_var";
        quit;
        %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
            %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 %upcase(&row_var);
            %goto exit;
        %end;
        %else %do;
            %if %bquote(&row_val) = %bquote() %then %do; /*未指定分类的值*/
                proc sql noprint;
                    select distinct cats("""", &row_var, """") into :row_val separated by "," from &indata where not missing(&row_var);
                quit;
            %end;
            %else %do; /*指定了分类的值*/
                %let IS_ROW_CAT_SPECIFIED = TRUE;
            %end;
        %end;
    %end;



    /*COLCAT*/
    %if %bquote(&colcat) = %bquote() %then %do;
        %put ERROR: 未指定构建列联表的列变量名！;
        %goto exit;
    %end;

    %let IS_COL_CAT_SPECIFIED = FALSE;
    %let reg_colcat = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\((\s*".*"(?:[\s,]+".*")*\s*)?\))?$/);
    %let reg_colcat_id = %sysfunc(prxparse(&reg_colcat));
    %if %sysfunc(prxmatch(&reg_colcat_id, &colcat)) = 0 %then %do;
        %put ERROR: 参数 COLCAT = &colcat 格式不正确！;
        %goto exit;
    %end;
    %else %do;
        %let col_var = %upcase(%sysfunc(prxposn(&reg_colcat_id, 1, &colcat))); /*列变量*/
        %let col_val = %sysfunc(prxposn(&reg_colcat_id, 2, &colcat)); /*列分类*/
        %if &row_var = &col_var %then %do;
            %put WARNING: 列联表的行列变量相同，输出结果可能是非预期的！;
        %end;
        proc sql noprint;
            select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&col_var";
        quit;
        %if &SQLOBS = 0 %then %do; /*数据集中没有找到变量*/
            %put ERROR: 在 &libname_in..&memname_in 中没有找到变量 %upcase(&col_var);
            %goto exit;
        %end;
        %else %do;
            %if %bquote(&col_val) = %bquote() %then %do; /*未指定分类的值*/
                proc sql noprint;
                    select distinct cats("""", &col_var, """") into :col_val separated by "," from &indata where not missing(&col_var);
                quit;
            %end;
            %else %do; /*指定了分类的值*/
                %let IS_COL_CAT_SPECIFIED = TRUE;
            %end;
        %end;
    %end;


    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: 试图指定 OUTDATA 为空！;
        %goto exit;
    %end;
    %else %if %bquote(&outdata) = #AUTO %then %do;
        %let outdata = RES_&VAR_1;
    %end;

    %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
    %if %sysfunc(prxmatch(&reg_outdata_id, &outdata)) = 0 %then %do;
        %put ERROR: 参数 OUTDATA = &outdata 格式不正确！;
        %goto exit;
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
            %goto exit;
        %end;
    %end;
    %put NOTE: 输出数据集被指定为 &libname_out..&memname_out;


    /*ROWCAT_BY*/
    %if &IS_ROW_CAT_SPECIFIED = TRUE %then %do; /*参数冲突判定*/
        %if %bquote(&rowcat_by) ^= #AUTO %then %do;
            %put WARNING: 已通过参数 ROWCAT 指定了行分类的出现顺序，参数 ROWCAT_BY 的值已被忽略！;
        %end;
    %end;
    %else %do;
        %if %bquote(&rowcat_by) = %bquote() %then %do; /*空值判定*/
            %put ERROR: 试图指定参数 ROWCAT_BY 为空！;
            %goto exit;
        %end;
        %else %if %bquote(&rowcat_by) ^= #AUTO %then %do;
            %let reg_rowcat_by = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:ASC|DESC)(?:ENDING)?)?\))?$/);
            %let reg_rowcat_by_id = %sysfunc(prxparse(&reg_rowcat_by));
            %if %sysfunc(prxmatch(&reg_rowcat_by_id, &rowcat_by)) = 0 %then %do; /*语法格式判定*/
                %put ERROR: 参数 ROWCAT_BY 格式不正确！;
                %goto exit;
            %end;
            %else %do;
                %let rowcat_by_var = %sysfunc(prxposn(&reg_rowcat_by_id, 1, &rowcat_by));
                %let rowcat_by_direction = %sysfunc(prxposn(&reg_rowcat_by_id, 2, &rowcat_by));
                
                %if &rowcat_by_var = &row_var %then %do; /*行变量自身作为排序变量，发出warning*/
                    %put WARNING: 为行变量 &row_var 指定了自身作为分类排序的变量！;
                %end;
                %else %do;
                    proc sql noprint;
                        select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&rowcat_by_var";
                    quit;
                    %if &SQLOBS = 0 %then %do; /*变量存在性判定*/
                        %put ERROR: 在 &libname_in..&memname_in 中没有找到用于对行分类排序的变量 &rowcat_by_var;
                        %goto exit;
                    %end;
                    %else %do;
                        %if &rowcat_by_direction = %bquote() %then %do;
                            %put NOTE: 未指定行分类的排序方向，默认升序排列！;
                            %let rowcat_by_direction = ASC;
                        %end;
                        %else %if &rowcat_by_direction = ASCENDING %then %do;
                            %let rowcat_by_direction = ASC;
                        %end;
                        %else %if &rowcat_by_direction = DESCENDING %then %do;
                            %let rowcat_by_direction = DESC;
                        %end;
                    %end;
                %end;
            %end;
        %end;
    %end;



    /*COLCAT_BY*/
    %if &IS_COL_CAT_SPECIFIED = TRUE %then %do; /*参数冲突判定*/
        %if %bquote(&colcat_by) ^= #AUTO %then %do;
            %put WARNING: 已通过参数 COLCAT 指定了行分类的出现顺序，参数 COLCAT_BY 的值已被忽略！;
        %end;
    %end;
    %else %do;
        %if %bquote(&colcat_by) = %bquote() %then %do; /*空值判定*/
            %put ERROR: 试图指定参数 COLCAT_BY 为空！;
            %goto exit;
        %end;
        %else %if %bquote(&colcat_by) ^= #AUTO %then %do;
            %let reg_colcat_by = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:ASC|DESC)(?:ENDING)?)?\))?$/);
            %let reg_colcat_by_id = %sysfunc(prxparse(&reg_colcat_by));
            %if %sysfunc(prxmatch(&reg_colcat_by_id, &colcat_by)) = 0 %then %do; /*语法格式判定*/
                %put ERROR: 参数 COLCAT_BY 格式不正确！;
                %goto exit;
            %end;
            %else %do;
                %let colcat_by_var = %sysfunc(prxposn(&reg_colcat_by_id, 1, &colcat_by));
                %let colcat_by_direction = %sysfunc(prxposn(&reg_colcat_by_id, 2, &colcat_by));
                
                %if &colcat_by_var = &col_var %then %do; /*行变量自身作为排序变量，发出warning*/
                    %put WARNING: 为行变量 &col_var 指定了自身作为分类排序的变量！;
                %end;
                %else %do;
                    proc sql noprint;
                        select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&colcat_by_var";
                    quit;
                    %if &SQLOBS = 0 %then %do; /*变量存在性判定*/
                        %put ERROR: 在 &libname_in..&memname_in 中没有找到用于对列分类排序的变量 &colcat_by_var;
                        %goto exit;
                    %end;
                    %else %do;
                        %if &colcat_by_direction = %bquote() %then %do;
                            %put NOTE: 未指定列分类的排序方向，默认升序排列！;
                            %let colcat_by_direction = ASC;
                        %end;
                        %else %if &colcat_by_direction = ASCENDING %then %do;
                            %let colcat_by_direction = ASC;
                        %end;
                        %else %if &colcat_by_direction = DESCENDING %then %do;
                            %let colcat_by_direction = DESC;
                        %end;
                    %end;
                %end;
            %end;
        %end;
    %end;



    /*ADD_CAT_MISSING*/
    %if %bquote(&add_cat_missing) = %bquote() %then %do;
        %put ERROR: 试图指定参数 ADD_CAT_MISSING 为空！;
        %goto exit;
    %end;

    %let reg_add_cat_missing = %bquote(/^(TRUE|FALSE)(?:\s(TRUE|FALSE))?$/);
    %let reg_add_cat_missing_id = %sysfunc(prxparse(&reg_add_cat_missing));
    %if %sysfunc(prxmatch(&reg_add_cat_missing_id, &add_cat_missing)) = 0 %then %do;
        %put ERROR: 参数 ADD_CAT_MISSING 格式不正确！;
        %goto exit;
    %end;
    %else %do;
        %let add_cat_missing_row = %sysfunc(prxposn(&reg_add_cat_missing_id, 1, &add_cat_missing));
        %let add_cat_missing_col = %sysfunc(prxposn(&reg_add_cat_missing_id, 2, &add_cat_missing));

        %if %bquote(&add_cat_missing_col) = %bquote() %then %do;
            %let add_cat_missing_col = &add_cat_missing_row;
            %put NOTE: 参数 ADD_CAT_MISSING 未指定列变量是否计算“缺失”分类，默认与行变量一致！;
        %end;
    %end;


    /*ADD_CAT_OTHER*/
    %if %bquote(&add_cat_other) = %bquote() %then %do;
        %put ERROR: 试图指定参数 ADD_CAT_OTHER 为空！;
        %goto exit;
    %end;

    %let reg_add_cat_other = %bquote(/^(TRUE(?:\((?:\s?TYPE\s?=\s?([12])\s?)?\))?|FALSE)(?:\s(TRUE(?:\((?:\s?TYPE\s?=\s?([12])\s?)?\))?|FALSE))?$/);
    %let reg_add_cat_other_id = %sysfunc(prxparse(&reg_add_cat_other));
    %if %sysfunc(prxmatch(&reg_add_cat_other_id, &add_cat_other)) = 0 %then %do;
        %put ERROR: 参数 ADD_CAT_OTHER 格式不正确！;
        %goto exit;
    %end;
    %else %do;
        %let add_cat_other_row = %sysfunc(prxposn(&reg_add_cat_other_id, 1, &add_cat_other));
        %let add_cat_other_row_type = %sysfunc(prxposn(&reg_add_cat_other_id, 2, &add_cat_other));
        %let add_cat_other_col = %sysfunc(prxposn(&reg_add_cat_other_id, 3, &add_cat_other));
        %let add_cat_other_col_type = %sysfunc(prxposn(&reg_add_cat_other_id, 4, &add_cat_other));

        %if %bquote(&add_cat_other_row) ^= %bquote() and %bquote(&add_cat_other_row) ^= FALSE %then %do;
            %let add_cat_other_row = TRUE;
        %end;
        %if %bquote(&add_cat_other_col) ^= %bquote() and %bquote(&add_cat_other_col) ^= FALSE %then %do;
            %let add_cat_other_col = TRUE;
        %end;

        %if %bquote(&add_cat_other_row) = TRUE and %bquote(&add_cat_other_row_type) = %bquote() %then %do;
            %let add_cat_other_row_type = 1;
            %put NOTE: 参数 ADD_CAT_OTHER 未指定行变量计算“其他”分类的具体类型，默认指定 TYPE = 1，缺失值不计入行变量的“其他”分类！;
        %end;

        %if %bquote(&add_cat_other_col) = %bquote() %then %do;
            %let add_cat_other_col = &add_cat_other_row;
            %let add_cat_other_col_type = &add_cat_other_row_type;
            %put NOTE: 参数 ADD_CAT_OTHER 未指定列变量是否计算“其他”分类及具体类型，默认与行变量一致！;
        %end;

        %if %bquote(&add_cat_other_col) = TRUE and %bquote(&add_cat_other_col_type) = %bquote() %then %do;
            %let add_cat_other_col_type = 1;
            %put NOTE: 参数 ADD_CAT_OTHER 未指定列变量计算“其他”分类的具体类型，默认指定 TYPE = 1，缺失值不计入列变量的“其他”分类！;
        %end;
    %end;


    /*ADD_CAT_ALL*/
    %if %bquote(&add_cat_all) = %bquote() %then %do;
        %put ERROR: 试图指定参数 ADD_CAT_ALL 为空！;
        %goto exit;
    %end;

    %let reg_add_cat_all = %bquote(/^(TRUE|FALSE)(?:\s(TRUE|FALSE))?$/);
    %let reg_add_cat_all_id = %sysfunc(prxparse(&reg_add_cat_all));
    %if %sysfunc(prxmatch(&reg_add_cat_all_id, &add_cat_all)) = 0 %then %do;
        %put ERROR: 参数 ADD_CAT_ALL 格式不正确！;
        %goto exit;
    %end;
    %else %do;
        %let add_cat_all_row = %sysfunc(prxposn(&reg_add_cat_all_id, 1, &add_cat_all));
        %let add_cat_all_col = %sysfunc(prxposn(&reg_add_cat_all_id, 2, &add_cat_all));

        %if %bquote(&add_cat_all_col) = %bquote() %then %do;
            %let add_cat_all_col = &add_cat_all_row;
            %put NOTE: 参数 ADD_CAT_ALL 未指定列变量是否计算“合计”分类，默认与行变量一致！;
        %end;
    %end;



    /*N*/
    proc sql noprint;
        select count(*) into :n_obs from &indata
        %if &add_cat_missing_row = FALSE and &add_cat_missing_col = FALSE %then %do;
            where not (missing(&row_var) and missing(&col_var))
        %end;
        ; /*观测数*/
    quit;
    %if %bquote(&n) = #AUTO %then %do;
        %let n = &n_obs;
    %end;
    %else %do;
        %if %bquote(&n) = %bquote() %then %do;
            %put ERROR: 试图指定参数 N 为空！;
            %goto exit;
        %end;
        %else %do;
            %let reg_n = %bquote(/^(?:\d*\.?\d*|-(?:\d+(?:\.\d*)?|\.\d*))$/);
            %let reg_n_id = %sysfunc(prxparse(&reg_n));
            %if %sysfunc(prxmatch(&reg_n_id, &n)) = 0 %then %do;
                %put ERROR: 参数 N 格式不正确！;
                %goto exit;
            %end;
            %else %do;
                %if %sysevalf(&n < 0) %then %do;
                    %put WARNING: 参数 N 指定了一个负数作为合计频数！;
                %end;
                %else %if %sysevalf(&n = 0) %then %do;
                    %put WARNING: 参数 N 指定数值 0 作为合计频数！;
                %end;
                %else %if %sysevalf(%sysfunc(mod(&n, 1)) ^= 0) %then %do;
                    %put WARNING: 参数 N 指定了一个浮点数作为合计频数！;
                %end;
                %else %if %sysevalf(&n < &n_obs) %then %do;
                    %put WARNING: 参数 N 指定的合计频数小于数据集 &libname_in..&memname_in 的观测数！;
                %end;
            %end;
        %end;
    %end;


    /*PCT_OUT*/
    %if %bquote(&pct_out) = %bquote() %then %do;
        %put ERROR: 试图指定参数 PCT_OUT 为空！;
        %goto exit;
    %end;
    %else %if %bquote(&pct_out) ^= TRUE and %bquote(&pct_out) ^= FALSE %then %do;
        %put ERROR: 参数 PCT_OUT 必须是 TRUE 和 FALSE 其中之一！;
        %goto exit;
    %end;

    


    /*FORMAT*/
    %if %bquote(&pct_out) = FALSE %then %do;
        %if %bquote(&format) ^= PERCENTN9.2 %then %do;
            %put WARNING: 参数 PCT_OUT 已被指定为 FALSE, 参数 FORMAT 的值将被忽略！;
        %end;
    %end;
    %else %do;
        %if %bquote(&format) = %bquote() %then %do;
            %put ERROR: 试图指定参数 FORMAT 为空！;
            %goto exit;
        %end;
        %else %do;
            %let reg_format = %bquote(/^((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)$/);
            %let reg_format_id = %sysfunc(prxparse(&reg_format));
            %if %sysfunc(prxmatch(&reg_format_id, &format)) = 0 %then %do;
                %put ERROR: 参数 FORMAT 格式不正确！;
                %goto exit;
            %end;
            %else %do;
                %let format_base = %sysfunc(prxposn(&reg_format_id, 2, &format));
                %if %bquote(&format_base) ^= %bquote() %then %do;
                    proc sql noprint;
                        select * from DICTIONARY.FORMATS where fmtname = "&format_base" and fmttype = "F";
                    quit;
                    %if &SQLOBS = 0 %then %do;
                        %put ERROR: 输出格式 &format 不存在！;
                        %goto exit;
                    %end;
                %end;
            %end;
        %end;
    %end;

    
    /*DEL_TEMP_DATA*/
    %if %bquote(&DEL_TEMP_DATA) ^= TRUE and %bquote(&DEL_TEMP_DATA) ^= FALSE %then %do;
        %put ERROR: 参数 DEL_TEMP_DATA 必须是 TRUE 或 FALSE！;
        %goto exit;
    %end;

    /*-------------------------------------------主程序-------------------------------------------*/
    
    /*1. 行分类的生成与排序*/
    %if &IS_ROW_CAT_SPECIFIED = FALSE and %bquote(&rowcat_by) ^= #AUTO %then %do;
        /*指定了排序变量，行分类的顺序调整*/
        proc sql noprint;
            create table temp_rowcat as
                select
                    distinct
                    &row_var as ROWCAT,
                    &rowcat_by_var as ROWCAT_BY
                from &indata where not missing(&row_var)
                order by &rowcat_by_var &rowcat_by_direction, &row_var;

            %let row_cat_n = &SQLOBS;
            %do i = 1 %to &row_cat_n;
                select distinct cats("""", ROWCAT, """") into :row_&i separated by " " from temp_rowcat(firstobs = &i obs = &i);
            %end;
        quit;
    %end;
    %else %do;
        /*直接指定分类值，拆分rowval的分类*/
        %let row_cat_n = %sysfunc(kcountw(%bquote(&row_val), %bquote(,), qs));
        %do i = 1 %to &row_cat_n;
            %let row_&i = %sysfunc(kscanx(%bquote(&row_val), &i, %bquote(,), qs));
        %end;
    %end;
    
    /*row_cat_n:行类别数量，row_n:输出列联表行数*/
    %let row_n = &row_cat_n;
    %if &add_cat_missing_row = TRUE %then %do;
        %let row_n = %eval(&row_n + 1);
        %let row_&row_n = #MISSING;
    %end;
    %if &add_cat_other_row = TRUE %then %do;
        %let row_n = %eval(&row_n + 1);
        %if &add_cat_other_row_type = 1 %then %do;
            %let row_&row_n = #OTHER#1;
        %end;
        %else %if &add_cat_other_row_type = 2 %then %do;
            %let row_&row_n = #OTHER#2;
        %end;
    %end;
    %if &add_cat_all_row = TRUE %then %do;
        %let row_n = %eval(&row_n + 1);
        %let row_&row_n = #ALL;
    %end;


    /*2. 列分类的生成与排序*/
    %if &IS_COL_CAT_SPECIFIED = FALSE and %bquote(&colcat_by) ^= #AUTO %then %do;
        /*指定了排序变量，列分类的顺序调整*/
        proc sql noprint;
            create table temp_colcat as
                select
                    distinct
                    &col_var as COLCAT,
                    &colcat_by_var as COLCAT_BY
                from &indata where not missing(&col_var)
                order by &colcat_by_var &colcat_by_direction, &col_var;

            %let col_cat_n = &SQLOBS;
            %do i = 1 %to &col_cat_n;
                select distinct cats("""", COLCAT, """") into :col_&i separated by " " from temp_colcat(firstobs = &i obs = &i);
            %end;
        quit;
    %end;
    %else %do;
        /*直接指定分类值，拆分colval的分类*/
        %let col_cat_n = %sysfunc(kcountw(%bquote(&col_val), %bquote(,), qs));
        %do i = 1 %to &col_cat_n;
            %let col_&i = %sysfunc(kscanx(%bquote(&col_val), &i, %bquote(,), qs));
        %end;
    %end;

    /*col_cat_n:行类别数量，col_n:输出列联表行数*/
    %let col_n = &col_cat_n;
    %if &add_cat_missing_col = TRUE %then %do;
        %let col_n = %eval(&col_n + 1);
        %let col_&col_n = #MISSING;
    %end;
    %if &add_cat_other_col = TRUE %then %do;
        %let col_n = %eval(&col_n + 1);
        %if &add_cat_other_col_type = 1 %then %do;
            %let col_&col_n = #OTHER#1;
        %end;
        %else %if &add_cat_other_col_type = 2 %then %do;
            %let col_&col_n = #OTHER#2;
        %end;
    %end;
    %if &add_cat_all_col = TRUE %then %do;
        %let col_n = %eval(&col_n + 1);
        %let col_&col_n = #ALL;
    %end;


    /*3. 构建列联表*/
    %if &pct_out = TRUE %then %do;
        proc sql noprint;
            create table temp_crosstable as
                %do i = 1 %to &row_n;
                    select
                        /*第1列*/
                        %if &i <= &row_cat_n %then %do;
                            &&row_&i
                        %end;
                        %else %do;
                            %if &&row_&i = #MISSING %then %do;
                                "缺失"
                            %end;
                            %else %if &&row_&i = #OTHER#1 or &&row_&i = #OTHER#2 %then %do;
                                "其他"
                            %end;
                            %else %if &&row_&i = #ALL %then %do;
                                "合计"
                            %end;
                        %end;
                            as COL_0 label = "行分类",

                        /*第2~列*/
                        %do j = 1 %to &col_n;
                            /*%put NOTE: %bquote(第 &i 行，第 &j 列：&row_var = &&row_&i and &col_var = &&col_&j);*/
                            %if &i <= &row_cat_n and &j <= &col_cat_n %then %do; /*行<=分类数, 列<=分类数*/
                                cats(sum(&row_var = &&row_&i and &col_var = &&col_&j), "(", put(sum(&row_var = &&row_&i and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                            %end;
                            %else %do;
                                %if &i <= &row_cat_n %then %do;
                                    %if &&col_&j = #MISSING %then %do; /*行<=分类数, 列=缺失*/
                                        cats(sum(&row_var = &&row_&i and missing(&col_var)), "(", put(sum(&row_var = &&row_&i and missing(&col_var))/&N, &format), ")") as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行<=分类数, 列=其他, 类型1*/
                                        cats(sum(&row_var = &&row_&i and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(&row_var = &&row_&i and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行<=分类数, 列=其他, 类型2*/
                                        cats(sum(&row_var = &&row_&i and &col_var not in (&col_val)), "(", put(sum(&row_var = &&row_&i and &col_var not in (&col_val))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行<=分类数, 列=合计*/
                                        cats(sum(&row_var = &&row_&i), "(", put(sum(&row_var = &&row_&i)/&N, &format), ")") as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #MISSING %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=缺失, 列<=分类数*/
                                        cats(sum(missing(&row_var) and &col_var = &&col_&j), "(", put(sum(missing(&row_var) and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=缺失, 列=缺失*/
                                        cats(&N - sum(not (missing(&row_var) and missing(&col_var))), "(", put((&N - sum(not (missing(&row_var) and missing(&col_var))))/&N, &format), ")") as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=缺失, 列=其他, 类型1*/
                                        cats(sum(missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=缺失, 列=其他, 类型2*/
                                        cats(&N - sum(not (missing(&row_var) and &col_var not in (&col_val))), "(", put((&N - sum(not (missing(&row_var) and &col_var not in (&col_val))))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=缺失, 列=合计*/
                                        cats(&N - sum(not missing(&row_var)), "(", put((&N - sum(not missing(&row_var)))/&N, &format), ")") as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#1 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=其他, 类型1, 列<=分类数*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var = &&col_&j), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=其他, 类型1, 列=缺失*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and missing(&col_var)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and missing(&col_var))/&N, &format), ")") as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=其他, 类型1, 列=其他, 类型1*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=其他, 类型1, 列=其他, 类型2*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=其他, 类型1, 列=合计*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var))/&N, &format), ")") as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#2 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=其他, 类型2, 列<=分类数*/
                                        cats(sum(&row_var not in (&row_val) and &col_var = &&col_&j), "(", put(sum(&row_var not in (&row_val) and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=其他, 类型2, 列=缺失*/
                                        cats(&N - sum(not (&row_var not in (&row_val) and missing(&col_var))), "(", put((&N - sum(not (&row_var not in (&row_val) and missing(&col_var))))/&N, &format), ")") as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=其他, 类型2, 列=其他, 类型1*/
                                        cats(sum(&row_var not in (&row_val) and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(&row_var not in (&row_val) and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=其他, 类型2, 列=其他, 类型2*/
                                        cats(&N - sum(not (&row_var not in (&row_val) and &col_var not in (&col_val))), "(", put((&N - sum(not (&row_var not in (&row_val) and &col_var not in (&col_val))))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=其他, 类型2, 列=合计*/
                                        cats(&N - sum(&row_var in (&row_val)), "(", put((&N - sum(&row_var in (&row_val)))/&N, &format), ")") as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #ALL %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=合计, 列<=分类数*/
                                        cats(sum(&col_var = &&col_&j), "(", put(sum(&col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=合计, 列=缺失*/
                                        cats(&N - sum(not missing(&col_var)), "(", put((&N - sum(not missing(&col_var)))/&N, &format), ")") as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=合计, 列=其他, 类型1*/
                                        cats(sum(&col_var not in (&col_val) and not missing(&col_var)), "(", put((sum(&col_var not in (&col_val) and not missing(&col_var)))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=合计, 列=其他, 类型2*/
                                        cats(&N - sum(&col_var in (&col_val)), "(", put((&N - sum(&col_var in (&col_val)))/&N, &format), ")") as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=合计, 列=合计*/
                                        cats(&N, "(", put(1, &format), ")") as COL_ALL label = "合计"
                                    %end;
                                %end;
                            %end;
                            %if &j < &col_n %then %do; %str(,) %end;
                        %end;
                    from &indata
                    %if &i < &row_n %then %do;
                        outer union corr
                    %end;
                %end;
                ;
        quit;
    %end;
    %else %do;
        proc sql noprint;
            create table temp_crosstable as
                %do i = 1 %to &row_n;
                    select
                        /*第1列*/
                        %if &i <= &row_cat_n %then %do;
                            &&row_&i
                        %end;
                        %else %do;
                            %if &&row_&i = #MISSING %then %do;
                                "缺失"
                            %end;
                            %else %if &&row_&i = #OTHER#1 or &&row_&i = #OTHER#2 %then %do;
                                "其他"
                            %end;
                            %else %if &&row_&i = #ALL %then %do;
                                "合计"
                            %end;
                        %end;
                            as COL_0 label = "行分类",

                        /*第2~列*/
                        %do j = 1 %to &col_n;
                            /*%put NOTE: %bquote(第 &i 行，第 &j 列：&row_var = &&row_&i and &col_var = &&col_&j);*/
                            %if &i <= &row_cat_n and &j <= &col_cat_n %then %do; /*行<=分类数, 列<=分类数*/
                                sum(&row_var = &&row_&i and &col_var = &&col_&j) as COL_&j label = &&col_&j
                            %end;
                            %else %do;
                                %if &i <= &row_cat_n %then %do;
                                    %if &&col_&j = #MISSING %then %do; /*行<=分类数, 列=缺失*/
                                        sum(&row_var = &&row_&i and missing(&col_var)) as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行<=分类数, 列=其他, 类型1*/
                                        sum(&row_var = &&row_&i and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行<=分类数, 列=其他, 类型2*/
                                        sum(&row_var = &&row_&i and &col_var not in (&col_val)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行<=分类数, 列=合计*/
                                        sum(&row_var = &&row_&i) as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #MISSING %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=缺失, 列<=分类数*/
                                        sum(missing(&row_var) and &col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=缺失, 列=缺失*/
                                        &N - sum(not (missing(&row_var) and missing(&col_var))) as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=缺失, 列=其他, 类型1*/
                                        sum(missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=缺失, 列=其他, 类型2*/
                                        &N - sum(not (missing(&row_var) and &col_var not in (&col_val))) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=缺失, 列=合计*/
                                        &N - sum(not missing(&row_var)) as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#1 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=其他, 类型1, 列<=分类数*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=其他, 类型1, 列=缺失*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and missing(&col_var)) as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=其他, 类型1, 列=其他, 类型1*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=其他, 类型1, 列=其他, 类型2*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=其他, 类型1, 列=合计*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var)) as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#2 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=其他, 类型2, 列<=分类数*/
                                        sum(&row_var not in (&row_val) and &col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=其他, 类型2, 列=缺失*/
                                        &N - sum(not (&row_var not in (&row_val) and missing(&col_var))) as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=其他, 类型2, 列=其他, 类型1*/
                                        sum(&row_var not in (&row_val) and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=其他, 类型2, 列=其他, 类型2*/
                                        &N - sum(not (&row_var not in (&row_val) and &col_var not in (&col_val))) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=其他, 类型2, 列=合计*/
                                        &N - sum(&row_var in (&row_val)) as COL_ALL label = "合计"
                                    %end;
                                %end;
                                %else %if &&row_&i = #ALL %then %do;
                                    %if &j <= &col_cat_n %then %do; /*行=合计, 列<=分类数*/
                                        sum(&col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*行=合计, 列=缺失*/
                                        &N - sum(not missing(&col_var)) as COL_MISSING label = "缺失"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*行=合计, 列=其他, 类型1*/
                                        sum(&col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*行=合计, 列=其他, 类型2*/
                                        &N - sum(&col_var in (&col_val)) as COL_OTHER label = "其他"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*行=合计, 列=合计*/
                                        &N as COL_ALL label = "合计"
                                    %end;
                                %end;
                            %end;
                            %if &j < &col_n %then %do; %str(,) %end;
                        %end;
                    from &indata
                    %if &i < &row_n %then %do;
                        outer union corr
                    %end;
                %end;
                ;
        quit;
    %end;

    /*4. 输出数据集*/
    data &libname_out..&memname_out(&dataset_options_out);
        set temp_crosstable;
    run;

    /*----------------------------------------------运行后处理----------------------------------------------*/

    %if &DEL_TEMP_DATA = TRUE %then %do;
        /*删除中间数据集*/
        proc datasets noprint nowarn;
            delete temp_rowcat
                   temp_colcat
                   temp_crosstable
                   ;
        quit;
    %end;

    /*退出宏程序*/
    %exit:
    %put NOTE: 宏 cross_table 已结束运行！;
%mend;


