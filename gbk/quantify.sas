/*
===================================
Macro Name: quantify
Macro Label:����ָ�����
Author: wtwang
Version Date: 2023-03-16 1.3.1
              2023-11-08 1.3.2
              2023-11-27 1.3.3
              2024-01-05 1.3.4
              2024-01-18 1.3.5
              2024-01-23 1.3.6
              2024-03-06 1.3.7
              2024-03-07 1.3.8
              2024-03-19 1.3.9
              2024-04-26 1.3.10
              2024-04-28 1.3.11
              2024-06-05 1.3.12
              2024-09-18 1.3.13
              2025-01-09 1.3.14
===================================
*/

%macro quantify(INDATA,
                VAR,
                PATTERN       = %nrstr(#N(#NMISS)|#MEAN��#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX),
                OUTDATA       = RES_&VAR,
                STAT_FORMAT   = #AUTO,
                STAT_NOTE     = #AUTO,
                LABEL         = #AUTO,
                INDENT        = #AUTO,
                DEL_TEMP_DATA = TRUE)
                /des = "����ָ�����" parmbuff;


    /*�򿪰����ĵ�*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/quantify/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %upcase(%sysfunc(strip(%bquote(&var))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let stat_format          = %upcase(%sysfunc(strip(%bquote(&stat_format))));
    %let del_temp_data        = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));

    /*��֧�ֵ�ͳ����*/
    %let stat_supported = %bquote(KURTOSIS|SKEWNESS|MEDIAN|QRANGE|STDDEV|STDERR|NMISS|RANGE|KURT|LCLM|MEAN|MODE|SKEW|UCLM|CSS|MAX|MIN|P10|P20|P25|P30|P40|P50|P60|P70|P75|P80|P90|P95|P99|STD|SUM|USS|VAR|CV|P1|P5|Q1|Q3|N);

    /*ͳ������Ӧ��˵������*/
    %let KURTOSIS_note = %bquote('���');
    %let SKEWNESS_note = %bquote('ƫ��');
    %let MEDIAN_note   = %bquote('��λ��');
    %let QRANGE_note   = %bquote('�ķ�λ���');
    %let STDDEV_note   = %bquote('��׼��');
    %let STDERR_note   = %bquote('��׼��');
    %let NMISS_note    = %bquote('ȱʧ');
    %let RANGE_note    = %bquote('����');
    %let KURT_note     = %bquote('���');
    %let LCLM_note     = %bquote('��ֵ�� 95% ��������');
    %let MEAN_note     = %bquote('��ֵ');
    %let MODE_note     = %bquote('����');
    %let SKEW_note     = %bquote('ƫ��');
    %let UCLM_note     = %bquote('��ֵ�� 95% ��������');
    %let CSS_note      = %bquote('У��ƽ����');
    %let MAX_note      = %bquote('���ֵ');
    %let MIN_note      = %bquote('��Сֵ');
    %let P10_note      = %bquote('�� 10 �ٷ�λ��');
    %let P20_note      = %bquote('�� 20 �ٷ�λ��');
    %let P25_note      = %bquote('�� 25 �ٷ�λ��');
    %let P30_note      = %bquote('�� 30 �ٷ�λ��');
    %let P40_note      = %bquote('�� 40 �ٷ�λ��');
    %let P50_note      = %bquote('�� 50 �ٷ�λ��');
    %let P60_note      = %bquote('�� 60 �ٷ�λ��');
    %let P70_note      = %bquote('�� 70 �ٷ�λ��');
    %let P75_note      = %bquote('�� 75 �ٷ�λ��');
    %let P80_note      = %bquote('�� 80 �ٷ�λ��');
    %let P90_note      = %bquote('�� 90 �ٷ�λ��');
    %let P95_note      = %bquote('�� 95 �ٷ�λ��');
    %let P99_note      = %bquote('�� 99 �ٷ�λ��');
    %let STD_note      = %bquote('��׼��');
    %let SUM_note      = %bquote('�ܺ�');
    %let USS_note      = %bquote('δУ��ƽ����');
    %let VAR_note      = %bquote('����');
    %let CV_note       = %bquote('����ϵ��');
    %let P1_note       = %bquote('�� 1 �ٷ�λ��');
    %let P5_note       = %bquote('�� 5 �ٷ�λ��');
    %let Q1_note       = %bquote('Q1');
    %let Q3_note       = %bquote('Q3');
    %let N_note        = %bquote('����');


    /*ͳ������Ӧ��PROC MEANS������������ݼ��еı�����*/
    %let KURTOSIS_var = %bquote(&var._KURTOSIS);
    %let SKEWNESS_var = %bquote(&var._SKEWNESS);
    %let MEDIAN_var   = %bquote(&var._MEDIAN);
    %let QRANGE_var   = %bquote(&var._QRANGE);
    %let STDDEV_var   = %bquote(&var._STDDEV);
    %let STDERR_var   = %bquote(&var._STDERR);
    %let NMISS_var    = %bquote(&var._NMISS);
    %let RANGE_var    = %bquote(&var._RANGE);
    %let KURT_var     = %bquote(&var._KURT);
    %let LCLM_var     = %bquote(&var._LCLM);
    %let MEAN_var     = %bquote(&var._MEAN);
    %let MODE_var     = %bquote(&var._MODE);
    %let SKEW_var     = %bquote(&var._SKEW);
    %let UCLM_var     = %bquote(&var._UCLM);
    %let CSS_var      = %bquote(&var._CSS);
    %let MAX_var      = %bquote(&var._MAX);
    %let MIN_var      = %bquote(&var._MIN);
    %let P10_var      = %bquote(&var._P10);
    %let P20_var      = %bquote(&var._P20);
    %let P25_var      = %bquote(&var._P25);
    %let P30_var      = %bquote(&var._P30);
    %let P40_var      = %bquote(&var._P40);
    %let P50_var      = %bquote(&var._P50);
    %let P60_var      = %bquote(&var._P60);
    %let P70_var      = %bquote(&var._P70);
    %let P75_var      = %bquote(&var._P75);
    %let P80_var      = %bquote(&var._P80);
    %let P90_var      = %bquote(&var._P90);
    %let P95_var      = %bquote(&var._P95);
    %let P99_var      = %bquote(&var._P99);
    %let STD_var      = %bquote(&var._STD);
    %let SUM_var      = %bquote(&var._SUM);
    %let USS_var      = %bquote(&var._USS);
    %let VAR_var      = %bquote(&var._VAR);
    %let CV_var       = %bquote(&var._CV);
    %let P1_var       = %bquote(&var._P1);
    %let P5_var       = %bquote(&var._P5);
    %let Q1_var       = %bquote(&var._Q1);
    %let Q3_var       = %bquote(&var._Q3);
    %let N_var        = %bquote(&var._N);


    /*����ȫ�ֱ���*/
    /*ȫ�������ʽ*/
    %global KURTOSIS_format
            SKEWNESS_format
            MEDIAN_format
            QRANGE_format
            STDDEV_format
            STDERR_format
            NMISS_format
            RANGE_format
            KURT_format
            LCLM_format
            MEAN_format
            MODE_format
            SKEW_format
            UCLM_format
            CSS_format
            MAX_format
            MIN_format
            P10_format
            P20_format
            P25_format
            P30_format
            P40_format
            P50_format
            P60_format
            P70_format
            P75_format
            P80_format
            P90_format
            P95_format
            P99_format
            STD_format
            SUM_format
            USS_format
            VAR_format
            CV_format
            P1_format
            P5_format
            Q1_format
            Q3_format
            N_format
            ;
    %global quantify_exit_with_error;
    %let quantify_exit_with_error = FALSE;

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

            proc sql noprint;
                select count(*) into : nobs from &indata;
            quit;
            %if &nobs = 0 %then %do;
                %put ERROR: �������ݼ� &indata Ϊ�գ�;
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

    %let reg_var = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %bquote(&var))) = 0 %then %do;
        %put ERROR: ���� VAR = %bquote(&var) ��ʽ����ȷ��;
        %goto exit_with_error;
    %end;
    %else %do;
        proc sql noprint;
            select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var";
        quit;
        %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
            %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� &var;
            %goto exit_with_error;
        %end;
        %else %if &type = char %then %do; /*����������һ���ַ��ͱ���*/
            %put ERROR: �޷����ַ��ͱ��� &var ���ж���������;
            %goto exit_with_error;
        %end;
    %end;


    /*PATTERN*/
    %if %bquote(&pattern) = %bquote() %then %do;
        %put ERROR: ���� PATTERN Ϊ�գ�;
        %goto exit_with_error;
    %end;

    /*��ȡÿһ�е�ģʽ*/
    %let part_n = %eval(%sysfunc(count(%bquote(&pattern), %bquote(|))) - %sysfunc(count(%bquote(&pattern), %bquote(#|))) + 1);

    %if &part_n = 1 %then %do;
        %let reg_part_expr = %bquote(/^((?:.|\n)+)$/);
    %end;
    %else %do;
        %let reg_part_expr_unit = %bquote(((?:.|\n)+)(?<!#)\|);
        %let reg_part_expr = %bquote(/^%sysfunc(repeat(%bquote(&reg_part_expr_unit), %eval(&part_n - 2)))((?:.|\n)+)$/);
    %end;
    %let reg_part_id = %sysfunc(prxparse(&reg_part_expr));

    %if %sysfunc(prxmatch(&reg_part_id, %bquote(&pattern))) %then %do;
        %do i = 1 %to &part_n;
            %let part_&i = %sysfunc(prxposn(&reg_part_id, &i, %bquote(&pattern))); /*ÿһ�е�pattern*/
        %end;
    %end;
    %else %do;
        %put ERROR: ���� PATTERN = %bquote(&pattern) ��ʽ����ȷ��;
        %goto exit_with_error;
    %end;

    /*��ȡÿһ�е�ͳ�������ַ���*/
    %let reg_stat_expr_unit = %bquote(((?:.|\n)*?)\.?(?:(?<!#)#(&stat_supported))\.?);
    %let IS_VALID_PATTERN_PART = TRUE;
    %do i = 1 %to &part_n;
        %let stat_&i = %eval(%sysfunc(count(%bquote(&&part_&i), %bquote(#))) - %sysfunc(count(%bquote(&&part_&i), %bquote(#|)))
                                                                             - %sysfunc(count(%bquote(&&part_&i), %bquote(##)))*2);

        %if &&stat_&i = 0 %then %do;
            %let reg_stat_expr = %bquote(/^((?:.|\n)*?)$/i);
        %end;
        %else %do;
            %let reg_stat_expr = %bquote(/^%sysfunc(repeat(%bquote(&reg_stat_expr_unit), %eval(&&stat_&i - 1)))((?:.|\n)*?)$/i);
        %end;
        %let reg_stat_id = %sysfunc(prxparse(&reg_stat_expr));

        %if %sysfunc(prxmatch(&reg_stat_id, %bquote(&&part_&i))) %then %do;
            %do j = 1 %to &&stat_&i;
                %let string_&i._&j = %bquote(%sysfunc(prxposn(&reg_stat_id, %eval(&j * 2 - 1), %bquote(&&part_&i))));
                %let stat_&i._&j = %upcase(%sysfunc(prxposn(&reg_stat_id, %eval(&j * 2), %bquote(&&part_&i))));
            %end;
            %let string_&i._&j = %sysfunc(prxposn(&reg_stat_id, %eval(&&stat_&i * 2 + 1), %bquote(&&part_&i)));
        %end;
        %else %do;
            %put ERROR: �ڶԲ��� PATTERN ������ &i �� %bquote(&&part_&i) ͳ�������Ƽ������ַ�ʱ�����˴��󣬵��´����ԭ�������ָ���˲���֧�ֵ�ͳ����������δʹ�á�##�����ַ���#������ת�壡;
            %let IS_VALID_PATTERN_PART = FALSE;
        %end;
    %end;

    %if &IS_VALID_PATTERN_PART = FALSE %then %do;
        %goto exit_with_error;
    %end;

    /*����ȡ����ͳ����ȥ��*/
    data tmp_quantify_pattern_stat;
        length stat $10;
        %do i = 1 %to &part_n;
            %do j = 1 %to &&stat_&i;
                stat = "&&stat_&i._&j"; output;
            %end;
        %end;
    run;

    data tmp_quantify_pattern_stat;
        set tmp_quantify_pattern_stat;

        length stat_processed $10;
        select (stat);
            when ("STDDEV")   stat_processed = "STD";
            when ("KURTOSIS") stat_processed = "KURT";
            when ("SKEWNESS") stat_processed = "SKEW";
            otherwise stat_processed = stat;
        end;
    run;

    proc sql noprint;
        select distinct stat_processed      into : stat_list_nodup separated by " " from tmp_quantify_pattern_stat; /*ͳ����ȥ�ص��б�*/
        select cats(stat, "= &var._", stat) into : stat_list_names separated by " " from tmp_quantify_pattern_stat; /*ͳ��������ı�����*/
    quit;


    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: ���� OUTDATA Ϊ�գ�;
        %goto exit_with_error;
    %end;
    %else %do;
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
    %if %bquote(&stat_format) = #PREV %then %do;
        %put NOTE: ʹ����һ�ε���ʱ��ͳ���������ʽ��;
    %end;
    %else %do;
        data tmp_quantify_valuefmt;
            set &indata;
            &var._fmt = strip(vvalue(&var));
            keep &var &var._fmt;
        run;

        /*�����������ֺ�С�����ֵ�λ��*/
        proc sql noprint;
            select max(lengthn(scan(&var._fmt, 1, "."))) into : int_len trimmed from tmp_quantify_valuefmt;
            select max(lengthn(scan(&var._fmt, 2, "."))) into : dec_len trimmed from tmp_quantify_valuefmt;
        quit;

        /*�Զ�����ͳ�����������ʽ*/
        %let KURTOSIS_format = %eval(&int_len + %sysfunc(min(&dec_len + 3, 4)) + 2).%sysfunc(min(&dec_len + 3, 4)); /*��ԭʼ����С��λ����3����಻����4*/
        %let SKEWNESS_format = &KURTOSIS_format;
        %let MEDIAN_format   = %eval(&int_len + %sysfunc(min(&dec_len + 1, 4)) + 2).%sysfunc(min(&dec_len + 1, 4)); /*��ԭʼ����С��λ����1����಻����4*/
        %let QRANGE_format   = &MEDIAN_format;
        %let STDDEV_format   = %eval(&int_len + %sysfunc(min(&dec_len + 2, 4)) + 2).%sysfunc(min(&dec_len + 2, 4)); /*��ԭʼ����С��λ����2����಻����4*/
        %let STDERR_format   = &STDDEV_format;
        %let NMISS_format    = best.; /*����ͳ�������� SAS ���������ʽ*/
        %let RANGE_format    = %eval(&int_len + %sysfunc(min(&dec_len, 4)) + 2).%sysfunc(min(&dec_len, 4)); /*��ԭʼ����С��λ����ͬ����಻����4*/
        %let KURT_format     = &KURTOSIS_format;
        %let LCLM_format     = &MEDIAN_format;
        %let MEAN_format     = &MEDIAN_format;
        %let MODE_format     = &RANGE_format;
        %let SKEW_format     = &SKEWNESS_format;
        %let UCLM_format     = &LCLM_format;
        %let CSS_format      = &STDDEV_format;
        %let MAX_format      = &RANGE_format;
        %let MIN_format      = &RANGE_format;
        %let P10_format      = &MEDIAN_format;
        %let P20_format      = &MEDIAN_format;
        %let P25_format      = &MEDIAN_format;
        %let P30_format      = &MEDIAN_format;
        %let P40_format      = &MEDIAN_format;
        %let P50_format      = &MEDIAN_format;
        %let P60_format      = &MEDIAN_format;
        %let P70_format      = &MEDIAN_format;
        %let P75_format      = &MEDIAN_format;
        %let P80_format      = &MEDIAN_format;
        %let P90_format      = &MEDIAN_format;
        %let P95_format      = &MEDIAN_format;
        %let P99_format      = &MEDIAN_format;
        %let STD_format      = &STDDEV_format;
        %let SUM_format      = &RANGE_format;
        %let USS_format      = &CSS_format;
        %let VAR_format      = &STD_format;
        %let CV_format       = &STD_format;
        %let P1_format       = &MEDIAN_format;
        %let P5_format       = &MEDIAN_format;
        %let Q1_format       = &MEDIAN_format;
        %let Q3_format       = &MEDIAN_format;
        %let N_format        = &NMISS_format;

        %if %bquote(&stat_format) ^= #AUTO %then %do;
            %let stat_format_n = %eval(%sysfunc(kcountw(%bquote(&stat_format), %bquote(=), q)) - 1);

            %if &stat_format_n <= 0 %then %do;
                %put ERROR: ���� STAT_FORMAT Ϊ�գ�;
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
                            %put ERROR: Ϊͳ���� &stat_whose_format_2be_update ָ���������ʽ &stat_new_format_base �����ڣ�;
                            %let IS_VALID_STAT_FORMAT = FALSE;
                        %end;
                    %end;

                    /*����ͳ�����������ʽ*/
                    %let &stat_whose_format_2be_update._format = %bquote(&stat_new_format);

                    /*���ڴ��ڱ�����ͳ��������ͬ���޸������ʽ*/
                    %if &stat_whose_format_2be_update = STDDEV %then %do;
                        %let STD_format = %bquote(&stat_new_format);
                    %end;
                    %else %if &stat_whose_format_2be_update = STD %then %do;
                        %let STDDEV_format = %bquote(&stat_new_format);
                    %end;
                    %else %if &stat_whose_format_2be_update = KURTOSIS %then %do;
                        %let KURT_format = %bquote(&stat_new_format);
                    %end;
                    %else %if &stat_whose_format_2be_update = KURT %then %do;
                        %let KURTOSIS_format = %bquote(&stat_new_format);
                    %end;
                    %else %if &stat_whose_format_2be_update = SKEWNESS %then %do;
                        %let SKEW_format = %bquote(&stat_new_format);
                    %end;
                    %else %if &stat_whose_format_2be_update = SKEW %then %do;
                        %let SKEWNESS_format = %bquote(&stat_new_format);
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
    %end;


    /*STAT_NOTE*/
    %if %bquote(&stat_note) = %bquote() %then %do;
        %put ERROR: ���� STAT_NOTE Ϊ�գ�;
        %goto exit_with_error;
    %end; 

    %if %bquote(&stat_note) ^= #AUTO %then %do;
        %let stat_note_n = %eval(%sysfunc(kcountw(%bquote(&stat_note), %bquote(=), q)) - 1);
        %let reg_stat_note_expr_unit = %bquote(\s*#(&stat_supported)\s*=\s*(\x22[^\x22]*\x22|\x27[^\x27]*\x27)[\s,]*);
        %let reg_stat_note_expr = %bquote(/^\(?%sysfunc(repeat(&reg_stat_note_expr_unit, %eval(&stat_note_n - 1)))\)?$/i);
        %let reg_stat_note_id = %sysfunc(prxparse(&reg_stat_note_expr));

        %if %sysfunc(prxmatch(&reg_stat_note_id, %bquote(&stat_note))) %then %do;
            %do i = 1 %to &stat_note_n;
                %let stat_whose_note_2be_update = %upcase(%sysfunc(prxposn(&reg_stat_note_id, %eval(&i * 2 - 1), %bquote(&stat_note))));
                %let stat_new_note = %sysfunc(prxposn(&reg_stat_note_id, %eval(&i * 2), %bquote(&stat_note)));
                %let &stat_whose_note_2be_update._note = %bquote(&stat_new_note); /*����ͳ������˵������*/
            %end;
        %end;
        %else %do;
            %put ERROR: ���� STAT_NOTE = %bquote(&stat_note) ��ʽ����ȷ��;
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
                      else cats("'", name, "'") end)
                into: label_sql_expr from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&VAR";
        quit;
    %end;
    %else %do;
        %let reg_label_id = %sysfunc(prxparse(%bquote(/^(\x22[^\x22]*\x22|\x27[^\x27]*\x27)$/)));
        %if %sysfunc(prxmatch(&reg_label_id, %superq(label))) %then %do;
            %let label_sql_expr = %superq(label);
        %end;
        %else %do;
            %put ERROR: ���� LABEL ��ʽ����ȷ��ָ�����ַ�������ʹ��ƥ������Ű�Χ��;
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
            %put ERROR: ���� INDENT ��ʽ����ȷ��ָ�����ַ�������ʹ��ƥ������Ű�Χ��;
            %goto exit;
        %end;
    %end;
    


    /*----------------------------------------------������----------------------------------------------*/
    /*1. ������ PATTERN �Ƿ�ָ����ͳ����*/
    %let IS_NO_STAT_SPECIFIED = TRUE;
    %do i = 1 %to &part_n;
        %if &&stat_&i > 0 %then %do;
            %let IS_NO_STAT_SPECIFIED = FALSE;
        %end;
    %end;

    %if &IS_NO_STAT_SPECIFIED = FALSE %then %do; /*ָ��������һ��ͳ���������Ե��� PROC MEANS ����*/
        proc means data = &indata &stat_list_nodup noprint;
            var &var;
            output out = tmp_quantify_stat &stat_list_names /autoname autolabel;
        run;
    %end;
    %else %do; /*δָ���κ�ͳ��������Ȼ��� tmp_quantify_stat ���ݼ����Լ��ݺ���������*/
        %put NOTE: δָ���κ�ͳ������;
        data tmp_quantify_stat;
            INFO = "NO_STAT_SPECIFIED";
        run;
    %end;


    /*2. ���ݲ��� PATTERN ��ȡͳ������������������ʽ*/
    /*�滻 "#|" Ϊ "|", "##" Ϊ "#"*/
    %macro temp_combpl_hash(string);
        transtrn(transtrn(&string, "#|", "|"), "##", "#")
    %mend;

    %let reg_digit_format_id = %sysfunc(prxparse(%bquote(/\d+\.(\d+)?/))); /*w.d�����ʽ������ round �������������������*/

    proc sql noprint;
        create table tmp_quantify_outdata as
            select
                0                                 as SEQ,
                %unquote(%superq(label_sql_expr)) as ITEM,
                ""                                as VALUE
            from tmp_quantify_stat
            outer union corr
            %do i = 1 %to &part_n;
                select
                    &i as SEQ,
                    cat(%unquote(%superq(indent_sql_expr)),
                        %unquote(
                                 %do j = 1 %to &&stat_&i;
                                     %temp_combpl_hash("&&string_&i._&j") %bquote(,)
                                     %unquote(&&&&&&stat_&i._&j.._note) %bquote(,)
                                 %end;
                                 %temp_combpl_hash("&&string_&i._&j")
                                )
                        )
                        as ITEM,
                    cat(%unquote(
                                 %do j = 1 %to &&stat_&i;
                                     %temp_combpl_hash("&&string_&i._&j") %bquote(,)
                                     %if %sysfunc(prxmatch(&reg_digit_format_id, &&&&&&stat_&i._&j.._format)) %then %do;
                                         %let precision = %sysfunc(prxposn(&reg_digit_format_id, 1, &&&&&&stat_&i._&j.._format)); /*������Ч���ֵ�λ��*/
                                         %if %bquote(&precision) = %bquote() %then %do;
                                             %let precision = 0;
                                         %end;
                                         strip(put(round(&&&&&&stat_&i._&j.._var, 1e-&precision), &&&&&&stat_&i._&j.._format)) /*w.d ��ʽ���� round Ȼ�� put*/
                                     %end;
                                     %else %do;
                                         strip(put(&&&&&&stat_&i._&j.._var, &&&&&&stat_&i._&j.._format)) /*������ʽ��ֱ�� put*/
                                     %end;
                                     %bquote(,)
                                 %end;
                                 %temp_combpl_hash("&&string_&i._&j")
                                )
                        )
                        as VALUE
                from tmp_quantify_stat
                %if &i < &part_n %then %do;
                    outer union corr
                %end;
                %else %do;
                    %bquote(;)
                %end;
            %end;
    quit;

    /*3. ������ݼ�*/
    proc sql noprint;
        select max(length(item)), max(length(value)) into :column_item_len_max, :column_value_len_max from tmp_quantify_outdata;

        alter table tmp_quantify_outdata
            modify item  char(&column_item_len_max),
                   value char(&column_value_len_max);
    quit;
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item value
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_quantify_outdata;
    run;

    /*----------------------------------------------���к���----------------------------------------------*/
    /*ɾ���м����ݼ�*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_quantify_pattern_stat
                   tmp_quantify_stat
                   tmp_quantify_outdata
                   tmp_quantify_valuefmt
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
    %let quantify_exit_with_error = TRUE;

    /*�����˳�*/
    %exit:
    %put NOTE: �� quantify �ѽ������У�;
%mend;
