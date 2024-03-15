/*
===================================
Macro Name: qualify
Macro Label:����ָ�����
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
              2024-03-15 1.0.11
===================================
*/

%macro qualify(INDATA,
               VAR,
               PATTERN = %nrstr(#N(#RATE)),
               BY = #AUTO,
               MISSING = FALSE,
               MISSING_NOTE = "ȱʧ",
               MISSING_POSITION = LAST,
               OUTDATA = #AUTO,
               STAT_FORMAT = (#N = BEST., #RATE = PERCENTN9.2),
               LABEL = #AUTO,
               INDENT = #AUTO,
               SUFFIX = #AUTO,
               DEL_TEMP_DATA = TRUE)
               /des = "����ָ�����" parmbuff;


    /*�򿪰����ĵ�*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %sysfunc(strip(%bquote(&var)));
    %let by                   = %upcase(%sysfunc(strip(%bquote(&by))));
    %let missing              = %upcase(%sysfunc(strip(%bquote(&missing))));
    %let missing_position     = %upcase(%sysfunc(strip(%bquote(&missing_position))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let stat_format          = %upcase(%sysfunc(strip(%bquote(&stat_format))));
    %let del_temp_data        = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));

    /*��֧�ֵ�ͳ����*/
    %let stat_supported = %bquote(RATE|N);

    /*ͳ������Ӧ�������ʽ*/
    %let N_format = %bquote(best.);
    %let RATE_format = %bquote(percentn9.2);

    /*����ȫ�ֱ���*/
    %global qualify_exit_with_error;
    %let qualify_exit_with_error = FALSE;

    /*�����ֲ�����*/
    %local i j
           libname_in  memname_in  dataset_options_in
           libname_out memname_out dataset_options_out;

    /*----------------------------------------------�������----------------------------------------------*/
    /*INDATA*/
    %if %bquote(&indata) = %bquote() %then %do;
        %put ERROR: δָ���������ݼ���;
        %goto exit_with_error;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, %bquote(&indata))) = 0 %then %do;
            %put ERROR: ���� INDATA = %bquote(&indata) ��ʽ����ȷ��;
            %goto exit_with_error;
        %end;
        %else %do;
            %let libname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 1, %bquote(&indata))));
            %let memname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 2, %bquote(&indata))));
            %let dataset_options_in = %sysfunc(prxposn(&reg_indata_id, 3, %bquote(&indata)));
            %if &libname_in = %bquote() %then %let libname_in = WORK; /*δָ���߼��⣬Ĭ��ΪWORKĿ¼*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_in �߼��ⲻ���ڣ�;
                %goto exit_with_error;
            %end;
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in" and memname = "&memname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: �� &libname_in �߼�����û���ҵ� &memname_in ���ݼ���;
                %goto exit_with_error;
            %end;
        %end;
    %end;
    %put NOTE: �������ݼ���ָ��Ϊ &libname_in..&memname_in;


    /*VAR*/
    %if %bquote(&var) = %bquote() %then %do;
        %put ERROR: δָ������������;
        %goto exit_with_error;
    %end;

    %let reg_var = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:[\s,]*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*(?:=\s*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27))?)+\s*)?\))?$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %bquote(&var))) = 0 %then %do;
        %put ERROR: ���� VAR = %bquote(&var) ��ʽ����ȷ��;
        %goto exit_with_error;
    %end;
    %else %do;
        %let var_name = %upcase(%sysfunc(prxposn(&reg_var_id, 1, %bquote(&var)))); /*������*/
        %let var_level = %sysfunc(prxposn(&reg_var_id, 2, %bquote(&var))); /*����ˮƽ*/

        /*������������*/
        proc sql noprint;
            select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var_name";
        quit;
        %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
            %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� &var_name;
            %goto exit_with_error;
        %end;
        /*����������*/
        %if %bquote(&type) = num %then %do;
            %put ERROR: ���� VAR ��֧����ֵ�ͱ�����;
            %goto exit_with_error;
        %end;
        
        %if %bquote(&var_level) = %bquote() %then %do;
            %let IS_LEVEL_SPECIFIED = FALSE; /*δָ����ˮƽ����*/
        %end;
        %else %do;
            %let IS_LEVEL_SPECIFIED = TRUE; /*��ָ����ˮƽ����*/
            /*��ֱ���ˮƽ*/
            %let reg_var_level_expr_unit = %bquote(/\s*(\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*(?:=\s*(\x22[^\x22]*?\x22|\x27[^\x27]*?\x27))?/);
            %let reg_var_level_expr_unit_id = %sysfunc(prxparse(&reg_var_level_expr_unit));
            %let start = 1;
            %let stop = %length(&var_level);
            %let position = 1;
            %let length = 1;
            %let i = 1;
            %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %do %until(&position = 0); /*����ƥ��������ʽ*/
                %let var_level_&i._str = %substr(%bquote(&var_level), &position, &length); /*��i��ˮƽ���ƺͱ���*/
                %if %sysfunc(prxmatch(&reg_var_level_expr_unit_id, %bquote(&&var_level_&i._str))) %then %do;
                    %let var_level_&i = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 1, %bquote(&&var_level_&i._str))); /*��ֵ�i��ˮƽ����*/
                    %let var_level_&i._note = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 2, %bquote(&&var_level_&i._str))); /*��ֵ�i��ˮƽ����*/
                    %if %bquote(&&var_level_&i._note) = %bquote() %then %do;
                        %let var_level_&i._note = %bquote(&&var_level_&i);
                    %end;
                %end;
                %else %do;
                    %put ERROR: �ڶԲ��� VAR ������ &i ����������ʱ����������֮��Ĵ���;
                    %goto exit_with_error;
                %end;
                %let i = %eval(&i + 1);
                %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %end;
            %let var_level_n = %eval(&i - 1); /*����ƥ�䵽��ˮƽ����*/
        %end;
    %end;


    /*BY*/
    %if %bquote(&IS_LEVEL_SPECIFIED) = TRUE %then %do; /*��ָ��˳�������£����� by ��������*/
        %if %bquote(&by) ^= %bquote() and %bquote(&by) ^= #AUTO %then %do;
            %put WARNING: ��ͨ������ VAR ָ���������˳�򣬲��� BY �ѱ����ԣ�;
        %end;
    %end;
    %else %do; /*δָ��˳������������ by ����ָ��˳��*/
        %if %bquote(&by) = %bquote() %then %do;
            %put ERROR: ���� BY Ϊ�գ�;
            %goto exit_with_error;
        %end;
        %else %if %bquote(&by) = #AUTO %then %do;
            %put NOTE: δָ�������������ʽ�������ո������Ƶ���Ӵ�С��������;
            %let by = #FREQ(DESCENDING);
        %end;

        /*�������� by, ���Ϸ���*/
        %let reg_by_expr = %bquote(/^(?:(#FREQ)|([A-Za-z_][A-Za-z_\d]*)|(?:([A-Za-z_]+(?:\d+[A-Za-z_]+)?)\.))(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/i);
        %let reg_by_id = %sysfunc(prxparse(&reg_by_expr));
        %if %sysfunc(prxmatch(&reg_by_id, %bquote(&by))) %then %do;
            %let by_stat      = %sysfunc(prxposn(&reg_by_id, 1, %bquote(&by))); /*������ڵ�ͳ����*/
            %let by_var       = %sysfunc(prxposn(&reg_by_id, 2, %bquote(&by))); /*������ڵı���*/
            %let by_fmt       = %sysfunc(prxposn(&reg_by_id, 3, %bquote(&by))); /*������ڵ������ʽ*/
            %let by_direction = %sysfunc(prxposn(&reg_by_id, 4, %bquote(&by))); /*������*/

            %if %bquote(&by_var) ^= %bquote() %then %do;
                /*����������������*/
                proc sql noprint;
                    select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&by_var";
                quit;
                %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
                    %put ERROR: �� &libname_in..&memname_in ��û���ҵ�������� &by_var;
                    %goto exit_with_error;
                %end;
            %end;

            %if %bquote(&by_fmt) ^= %bquote() %then %do;
                /*��������ʽ������*/
                proc sql noprint;
                    select libname, memname, source into : by_fmt_libname, : by_fmt_memname, : by_fmt_source from DICTIONARY.FORMATS where fmtname = "&by_fmt";
                quit;
                %if &SQLOBS = 0 %then %do;
                    %put ERROR: ���� BY ָ���������ʽ &by_fmt.. �����ڣ�;
                    %goto exit_with_error;
                %end;
                %else %do;
                    %if &by_fmt_source ^= C %then %do;
                        %put ERROR: ���� BY ָ���������ʽ &by_fmt.. ���� CATALOG-BASED��;
                        %goto exit_with_error;
                    %end;
                %end;
            %end;

            /*���������*/
            %if %bquote(&by_direction) = %bquote() %then %do;
                %put NOTE: δָ��������Ĭ���������У�;
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
            %put ERROR: ���� BY = %bquote(&by) ��ʽ����ȷ��;
            %goto exit_with_error;
        %end;

        /*���ݲ��� by ����������˳�����ɺ�����Թ���������*/
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
        %put ERROR: ���� MISSING Ϊ�գ�;
        %goto exit_with_error;
    %end;
    
    %if %superq(missing) ^= TRUE and %superq(missing) ^= FALSE %then %do;
        %put ERROR: ���� MISSING ֻ���� TRUE �� FALSE��;
        %goto exit_with_error;
    %end;


    /*MISSING_NOTE*/
    %if %superq(missing) = TRUE %then %do;
        %if %superq(missing_note) = %bquote() %then %do;
            %put ERROR: ���� MISSING_NOTE Ϊ�գ�;
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
            %put ERROR: ���� MISSING_POSITION Ϊ�գ�;
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
            %put ERROR: ���� MISSING_POSITION ֻ���� FIRST �� LAST��;
            %goto exit_with_error;
        %end;
    %end;


    /*PATTERN*/
    %if %bquote(&pattern) = %bquote() %then %do;
        %put ERROR: ���� PATTERN Ϊ�գ�;
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
        %put ERROR: �ڶԲ��� PATTERN ����ͳ�������Ƽ������ַ�ʱ�����˴��󣬵��´����ԭ�������ָ���˲���֧�ֵ�ͳ����������δʹ�á�##�����ַ���#������ת�壡;
        %goto exit_with_error;
    %end;


    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: ���� OUTDATA Ϊ�գ�;
        %goto exit_with_error;
    %end;
    %else %do;
        %if %bquote(%upcase(&outdata)) = %bquote(#AUTO) %then %do;
            %let outdata = RES_&var_name;
        %end;

        %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_outdata_id, %bquote(&outdata))) = 0 %then %do;
            %put ERROR: ���� OUTDATA = %bquote(&outdata) ��ʽ����ȷ��;
            %goto exit_with_error;
        %end;
        %else %do;
            %let libname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 1, &outdata)));
            %let memname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 2, &outdata)));
            %let dataset_options_out = %sysfunc(prxposn(&reg_outdata_id, 3, &outdata));
            %if &libname_out = %bquote() %then %let libname_out = WORK; /*δָ���߼��⣬Ĭ��ΪWORKĿ¼*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_out";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_out �߼��ⲻ���ڣ�;
                %goto exit_with_error;
            %end;
        %end;
        %put NOTE: ������ݼ���ָ��Ϊ &libname_out..&memname_out;
    %end;


    /*STAT_FORMAT*/
    %if %bquote(&stat_format) = %bquote() %then %do;
        %put ERROR: ���� STAT_FORMAT Ϊ�գ�;
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
                %let &stat_whose_format_2be_update._format = %bquote(&stat_new_format); /*����ͳ�����������ʽ*/

                %if %bquote(&stat_new_format_base) ^= %bquote() %then %do;
                    proc sql noprint;
                        select * from DICTIONARY.FORMATS where fmtname = "&stat_new_format_base" and fmttype = "F";
                    quit;
                    %if &SQLOBS = 0 %then %do;
                        %put ERROR: Ϊͳ���� &stat_whose_format_2be_update ָ���������ʽ &stat_new_format_base �����ڣ�;
                        %let IS_VALID_STAT_FORMAT = FALSE;
                    %end;
                %end;
            %end;
            %if &IS_VALID_STAT_FORMAT = FALSE %then %do;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: ���� STAT_FORMAT = %bquote(&stat_format) ��ʽ����ȷ��;
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


    /*----------------------------------------------������----------------------------------------------*/
    /*1. ���Ʒ�������*/
    proc sql noprint;
        create table tmp_qualify_indata as
            select * from &libname_in..&memname_in(&dataset_options_in);
    quit;


    /*2. ����Ƶ��Ƶ��*/
    /*�滻 "#|" Ϊ "|", "##" Ϊ "#"*/
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


    /*3. ������ݼ�*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item value
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_qualify_outdata;
    run;

    
    /*----------------------------------------------���к���----------------------------------------------*/
    /*ɾ���м����ݼ�*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_qualify_indata
                   tmp_qualify_by_fmt
                   tmp_qualify_distinct_var
                   tmp_qualify_outdata
                   ;
        quit;
    %end;

    /*ɾ����ʱ��*/
    proc catalog catalog = work.sasmacr;
        delete temp_combpl_hash.macro;
    quit;
    %goto exit;

    /*�쳣�˳�*/
    %exit_with_error:
    %let qualify_exit_with_error = TRUE;

    /*�����˳�*/
    %exit:
    %put NOTE: �� Qualify �ѽ������У�;
%mend;
