/*
===================================
Macro Name: qualify
Macro Label:����ָ�����
Author: wtwang
Version Date: 2023-03-08 V1.0.1
Version Date: 2023-11-06 V1.0.2
===================================
*/

%macro qualify(INDATA, VAR, PATTERN = %nrstr(#N(#RATE)), BY = #NULL,
               OUTDATA = #AUTO, STAT_FORMAT = (#N = BEST. #RATE = PERCENTN9.2), LABEL = #AUTO, INDENT = %bquote(    )) /des = "����ָ�����" parmbuff;


    /*�򿪰����ĵ�*/
    %if %bquote(%upcase(&SYSPBUFF)) = %bquote((HELP)) or %bquote(%upcase(&SYSPBUFF)) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %sysfunc(strip(%bquote(&var)));
    %let by                   = %upcase(%sysfunc(strip(%bquote(&by))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let stat_format          = %upcase(%sysfunc(strip(%bquote(&stat_format))));

    /*ͳ������Ӧ�������ʽ*/
    %let N_format = %bquote(best.);
    %let RATE_format = %bquote(percentn9.2);

    /*�����ֲ�����*/
    %local i j;

    /*----------------------------------------------�������----------------------------------------------*/
    /*INDATA*/
    %if %bquote(&indata) = %bquote() %then %do;
        %put ERROR: δָ���������ݼ���;
        %goto exit;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, %bquote(&indata))) = 0 %then %do;
            %put ERROR: ���� INDATA = %bquote(&indata) ��ʽ����ȷ��;
            %goto exit;
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
                %goto exit;
            %end;
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in" and memname = "&memname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: �� &libname_in �߼�����û���ҵ� &memname_in ���ݼ���;
                %goto exit;
            %end;
        %end;
    %end;
    %put NOTE: �������ݼ���ָ��Ϊ &libname_in..&memname_in;

    /*VAR*/
    %if %bquote(&var) = %bquote() %then %do;
        %put ERROR: δָ������������;
        %goto exit;
    %end;

    %let reg_var = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:\s*".*"\s*(?:=\s*".*")?)+\s*)?\))?$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %bquote(&var))) = 0 %then %do;
        %put ERROR: ���� VAR = %bquote(&var) ��ʽ����ȷ��;
        %goto exit;
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
            %goto exit;
        %end;
        /*����������*/
        %if %bquote(&type) = num %then %do;
            %put ERROR: ���� VAR ��֧����ֵ�ͱ�����;
            %goto exit;
        %end;
        
        %if %bquote(&var_level) = %bquote() %then %do;
            %let IS_LEVEL_SPECIFIED = FALSE; /*δָ����ˮƽ����*/
        %end;
        %else %do;
            %let IS_LEVEL_SPECIFIED = TRUE; /*��ָ����ˮƽ����*/
            /*��ֱ���ˮƽ*/
            %let reg_var_level_expr_unit = %bquote(/\s*(".*?")\s*(?:=\s*(".*?"))?/);
            %let reg_var_level_expr_unit_id = %sysfunc(prxparse(&reg_var_level_expr_unit));
            %let start = 1;
            %let stop = %length(&var_level);
            %let position = 1;
            %let length = 1;
            %let i = 1;
            %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %do %until(&position = 0); /*����ƥ��������ʽ*/
                %let var_level_&i._str = %substr(&var_level, &position, &length); /*��i��ˮƽ���ƺͱ���*/
                %if %sysfunc(prxmatch(&reg_var_level_expr_unit_id, %bquote(&&var_level_&i._str))) %then %do;
                    %let var_level_&i = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 1, %bquote(&&var_level_&i._str))); /*��ֵ�i��ˮƽ����*/
                    %let var_level_&i._note = %sysfunc(prxposn(&reg_var_level_expr_unit_id, 2, %bquote(&&var_level_&i._str))); /*��ֵ�i��ˮƽ����*/
                    %if %bquote(&&var_level_&i._note) = %bquote() %then %do;
                        %let var_level_&i._note = %bquote(&&var_level_&i);
                    %end;
                %end;
                %else %do;
                    %put ERROR: �ڶԲ��� VAR ������ &i ����������ʱ����������֮��Ĵ���;
                    %goto exit;
                %end;
                %let i = %eval(&i + 1);
                %syscall prxnext(reg_var_level_expr_unit_id, start, stop, var_level, position, length);
            %end;
            %let var_level_n = %eval(&i - 1); /*����ƥ�䵽��ˮƽ����*/
        %end;
    %end;


    /*BY*/
    %if %bquote(&IS_LEVEL_SPECIFIED) = TRUE %then %do; /*��ָ��˳�������£����� by ��������*/
        %if %bquote(&by) ^= %bquote() and %bquote(&by) ^= #NULL %then %do;
            %put WARNING: ��ͨ������ VAR ָ���������˳�򣬲��� BY �ѱ����ԣ�;
        %end;
    %end;
    %else %do; /*δָ��˳������������ by ����ָ��˳��*/
        %if %bquote(&by) = %bquote() %then %do;
            %put ERROR: ���� BY Ϊ�գ�;
            %goto exit;
        %end;
        %else %if %bquote(&by) = #NULL %then %do;
            %put NOTE: δָ�������������ʽ�������ո������Ƶ���Ӵ�С��������;
            %let by = #FREQ_MAX;
        %end;

        /*�������� by, ���Ϸ���*/
        %if %bquote(&by) = #FREQ_MAX %then %do;
            %let by_var = #FREQ;
            %let by_direction = DESCENDING;
        %end;
        %else %if %bquote(&by) = #FREQ_MIN %then %do;
            %let by_var = #FREQ;
            %let by_direction = ASCENDING;
        %end;
        %else %do;
            %let reg_by_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(\s*(?:(DESC(?:ENDING)?|ASC(?:ENDING)?))?\s*\))?$/);
            %let reg_by_id = %sysfunc(prxparse(&reg_by_expr));
            %if %sysfunc(prxmatch(&reg_by_id, %bquote(&by))) %then %do;
                %let by_var = %sysfunc(prxposn(&reg_by_id, 1, %bquote(&by))); /*�������*/
                %let by_direction = %sysfunc(prxposn(&reg_by_id, 2, %bquote(&by))); /*������*/

                /*����������������*/
                proc sql noprint;
                    select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&by_var";
                quit;
                %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
                    %put ERROR: �� &libname_in..&memname_in ��û���ҵ�������� &by_var;
                    %goto exit;
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
                %goto exit;
            %end;
        %end;

        /*���ݲ��� by ����������˳�����ɺ�����Թ���������*/
        %if %bquote(&by_var) = #FREQ %then %do;
            proc sql noprint;
                create table temp_distinct_var as
                    select distinct &var_name, count(&var_name) as &var_name._freq from &libname_in..&memname_in(&dataset_options_in)
                    group by &var_name
                    order by &var_name._freq &by_direction, &var_name ascending
                                             ;
            quit;
        %end;
        %else %do;
            proc sql noprint;
                create table temp_distinct_var as
                    select distinct &var_name, &by_var from &libname_in..&memname_in(&dataset_options_in)
                    order by &by_var &by_direction, &var_name ascending;
            quit;
        %end;

        proc sql noprint;
            select count(*) into :var_level_n from temp_distinct_var;
            %do i = 1 %to &var_level_n;
                select cat("""", trimn(&var_name), """") into :var_level_&i from temp_distinct_var(firstobs = &i obs = &i);
                %let var_level_&i._note = %bquote(&&var_level_&i);
            %end;
        quit;
    %end;
    

    /*PATTERN*/
    %if %bquote(&pattern) = %bquote() %then %do;
        %put ERROR: ���� PATTERN Ϊ�գ�;
        %goto exit;
    %end;

    %let reg_pattern_expr = %bquote(/^((?:.|\n)*?)(?<!#)#(RATE|N)((?:.|\n)*?)(?:(?<!#)#(RATE|N)((?:.|\n)*?))?$/i);
    %let reg_pattern_id = %sysfunc(prxparse(&reg_pattern_expr));

    %if %sysfunc(prxmatch(&reg_pattern_id, %bquote(&pattern))) %then %do;
        %let string_1 = %sysfunc(prxposn(&reg_pattern_id, 1, %bquote(&pattern))); /*�ַ���1*/
        %let stat_1   = %sysfunc(prxposn(&reg_pattern_id, 2, %bquote(&pattern))); /*ͳ����1*/
        %let string_2 = %sysfunc(prxposn(&reg_pattern_id, 3, %bquote(&pattern))); /*�ַ���2*/
        %let stat_2   = %sysfunc(prxposn(&reg_pattern_id, 4, %bquote(&pattern))); /*ͳ����2*/
        %let string_3 = %sysfunc(prxposn(&reg_pattern_id, 5, %bquote(&pattern))); /*�ַ���3*/
    %end;
    %else %do;
        %put ERROR: ���� PATTERN = %bquote(&pattern) ��ʽ����ȷ��;
        %goto exit;
    %end;


    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: ���� OUTDATA Ϊ�գ�;
        %goto exit;
    %end;
    %else %do;
        %if %bquote(%upcase(&outdata)) = %bquote(#AUTO) %then %do;
            %let outdata = RES_&var_name;
        %end;
 
        %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_outdata_id, %bquote(&outdata))) = 0 %then %do;
            %put ERROR: ���� OUTDATA = %bquote(&outdata) ��ʽ����ȷ��;
            %goto exit;
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
                %goto exit;
            %end;
        %end;
        %put NOTE: ������ݼ���ָ��Ϊ &libname_out..&memname_out;
    %end;


    /*STAT_FORMAT*/
    %if %bquote(&stat_format) = %bquote() %then %do;
        %put ERROR: ���� STAT_FORMAT Ϊ�գ�;
        %goto exit;
    %end;

    %if %bquote(&stat_format) ^= #NULL %then %do;
        %let stat_format_n = %eval(%sysfunc(kcountw(%bquote(&stat_format), %bquote(=), q)) - 1);
        %let reg_stat_format_expr_unit = %bquote(\s*#(RATE|N)\s*=\s*((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)\s*);
        %let reg_stat_format_expr = %bquote(/^\(?%sysfunc(repeat(&reg_stat_format_expr_unit, %eval(&stat_format_n - 1)))\)?$/i);
        %let reg_stat_format_id = %sysfunc(prxparse(&reg_stat_format_expr));

        %if %sysfunc(prxmatch(&reg_stat_format_id, %bquote(&stat_format))) %then %do;
            %let IS_VALID_STAT_FORMAT = TRUE;
            %do i = 1 %to &stat_format_n;
                %let stat_whose_format_2be_update = %upcase(%sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3 - 2), &stat_format)));
                %let stat_new_format = %sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3 - 1), &stat_format));
                %let stat_new_format_base = %sysfunc(prxposn(&reg_stat_format_id, %eval(&i * 3), &stat_format));
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
                %goto exit;
            %end;
        %end;
        %else %do;
            %put ERROR: ���� STAT_FORMAT = %bquote(&stat_format) ��ʽ����ȷ��;
            %goto exit;
        %end;
    %end;


    /*LABEL*/
    %if %bquote(&label) = %bquote() %then %do;
        %put ERROR: ���� LABEL Ϊ�գ�;
        %goto exit;
    %end;
    %else %if %bquote(%upcase(&label)) = #AUTO %then %do;
        proc sql noprint;
            select
                (case when label ^= "" then cats(label)
                      else cats(name, "-n(%)") end)
                into: label from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var_name";
        quit;
    %end;


    /*----------------------------------------------������----------------------------------------------*/
    /*1. ���Ʒ�������*/
    proc sql noprint;
        create table temp_indata as
            select * from &libname_in..&memname_in(&dataset_options_in);
    quit;

    /*2. ����Ƶ��Ƶ��*/
    /*�滻 "#|" Ϊ "|", "##" Ϊ "#"*/
    %macro combpl_hash(string);
        transtrn(transtrn(&string, "#|", "|"), "##", "#")
    %mend;

    proc sql noprint;
        create table temp_out as
            select
                0        as SEQ,
                "&label" as ITEM,
                ""       as VALUE
            from temp_indata(firstobs = 1 obs = 1)
            %do i = 1 %to &var_level_n;
                outer union corr
                select
                    &i as SEQ,
                    cat("&indent", %unquote(&&var_level_&i._note)) as ITEM,
                    cat(%combpl_hash("&string_1"),
                        %if %upcase(%bquote(&stat_1)) = %bquote(N) %then %do;
                            strip(put(sum(&var_name = &&var_level_&i), &&&stat_1._format))
                        %end;
                        %else %if %upcase(%bquote(&stat_1)) = %bquote(RATE) %then %do;
                            strip(put(sum(&var_name = &&var_level_&i)/count(*), &&&stat_1._format))
                        %end;
                        ,
                        %combpl_hash("&string_2"),
                        %if %upcase(%bquote(&stat_2)) = %bquote(N) %then %do;
                            strip(put(sum(&var_name = &&var_level_&i), &&&stat_2._format))
                        %end;
                        %else %if %upcase(%bquote(&stat_2)) = %bquote(RATE) %then %do;
                            strip(put(sum(&var_name = &&var_level_&i)/count(*), &&&stat_2._format))
                        %end;
                        %else %if %upcase(%bquote(&stat_2)) = %bquote() %then %do;
                            ""
                        %end;
                        ,
                        %combpl_hash("&string_3")
                        ) as VALUE
                from temp_indata
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
        set temp_out;
    run;

    


    /*----------------------------------------------���к���----------------------------------------------*/
    /*ɾ���м����ݼ�*/
    proc datasets noprint nowarn;
        delete temp_indata
               temp_distinct_var
               temp_out
               ;
    quit;


    %exit:
    %put NOTE: �� Qualify �ѽ������У�;
%mend;
