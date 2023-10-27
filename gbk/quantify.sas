/*
===================================
Macro Name: quantify
Macro Label:����ָ�����
Author: wtwang
Version Date: 2023-03-16 V1.3.1
===================================
*/

%macro quantify(INDATA, VAR, PATTERN = %nrstr(#N(#NMISS)|#MEAN(#STD)|#MEDIAN(#Q1, #Q3)|#MIN, #MAX),
                OUTDATA = RES_&VAR, STAT_FORMAT = #NULL, STAT_NOTE = #NULL, LABEL = #AUTO, INDENT = %bquote(    )) /des = "����ָ�����" parmbuff;


    /*�򿪰����ĵ�*/
    %if %superq(SYSPBUFF) = %bquote((HELP)) or %superq(SYSPBUFF) = %bquote(()) %then %do;
        /*
        %let host = %bquote(192.168.0.199);
        %let help = %bquote(\\&host\ͳ�Ʋ�\SAS��\06 quantify\05 �����ĵ�\readme.html);
        %if %sysfunc(system(ping &host -n 1 -w 10)) = 0 %then %do;
            %if %sysfunc(fileexist("&help")) %then %do;
                X explorer "&help";
            %end;
            %else %do;
                X mshta vbscript:msgbox("�����ĵ�������, Ŀ���ļ������ѱ��ƶ���ɾ����Orz",48,"��ʾ")(window.close);
            %end;
        %end;
        %else %do;
                X mshta vbscript:msgbox("�����ĵ�������, ��Ϊ�޷����ӵ��������� Orz",48,"��ʾ")(window.close);
        %end;
        */
        X explorer "https://www.bio-statistics.top/macro-help-doc/06%20quantify/readme.html";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %upcase(%sysfunc(strip(%bquote(&var))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let stat_format          = %upcase(%sysfunc(strip(%bquote(&stat_format))));

    /*��֧�ֵ�ͳ����*/
    %let stat_supported = %bquote(KURTOSIS|SKEWNESS|MEDIAN|QRANGE|STDDEV|STDERR|NMISS|RANGE|KURT|LCLM|MEAN|MODE|SKEW|UCLM|CSS|MAX|MIN|P10|P20|P25|P30|P40|P50|P60|P70|P75|P80|P90|P95|P99|STD|SUM|USS|VAR|CV|P1|P5|Q1|Q3|N);

    /*ͳ������Ӧ��˵������*/
    %let KURTOSIS_note = %bquote(���);
    %let SKEWNESS_note = %bquote(ƫ��);
    %let MEDIAN_note   = %bquote(��λ��);
    %let QRANGE_note   = %bquote(�ķ�λ���);
    %let STDDEV_note   = %bquote(��׼��);
    %let STDERR_note   = %bquote(��׼��);
    %let NMISS_note    = %bquote(ȱʧ);
    %let RANGE_note    = %bquote(����);
    %let KURT_note     = %bquote(���);
    %let LCLM_note     = %bquote(��ֵ�� 95% ��������);
    %let MEAN_note     = %bquote(��ֵ);
    %let MODE_note     = %bquote(����);
    %let SKEW_note     = %bquote(ƫ��);
    %let UCLM_note     = %bquote(��ֵ�� 95% ��������);
    %let CSS_note      = %bquote(У��ƽ����);
    %let MAX_note      = %bquote(���ֵ);
    %let MIN_note      = %bquote(��Сֵ);
    %let P10_note      = %bquote(�� 10 �ٷ�λ��);
    %let P20_note      = %bquote(�� 20 �ٷ�λ��);
    %let P25_note      = %bquote(�� 25 �ٷ�λ��);
    %let P30_note      = %bquote(�� 30 �ٷ�λ��);
    %let P40_note      = %bquote(�� 40 �ٷ�λ��);
    %let P50_note      = %bquote(�� 50 �ٷ�λ��);
    %let P60_note      = %bquote(�� 60 �ٷ�λ��);
    %let P70_note      = %bquote(�� 70 �ٷ�λ��);
    %let P75_note      = %bquote(�� 75 �ٷ�λ��);
    %let P80_note      = %bquote(�� 80 �ٷ�λ��);
    %let P90_note      = %bquote(�� 90 �ٷ�λ��);
    %let P95_note      = %bquote(�� 95 �ٷ�λ��);
    %let P99_note      = %bquote(�� 99 �ٷ�λ��);
    %let STD_note      = %bquote(��׼��);
    %let SUM_note      = %bquote(�ܺ�);
    %let USS_note      = %bquote(δУ��ƽ����);
    %let VAR_note      = %bquote(����);
    %let CV_note       = %bquote(����ϵ��);
    %let P1_note       = %bquote(�� 1 �ٷ�λ��);
    %let P5_note       = %bquote(�� 5 �ٷ�λ��);
    %let Q1_note       = %bquote(Q1);
    %let Q3_note       = %bquote(Q3);
    %let N_note        = %bquote(����);
    

    /*ͳ������Ӧ��PROC MEANS������������ݼ��еı�����*/
    %let KURTOSIS_var = %bquote(&var._Kurt);
    %let SKEWNESS_var = %bquote(&var._Skew);
    %let MEDIAN_var   = %bquote(&var._Median);
    %let QRANGE_var   = %bquote(&var._QEange);
    %let STDDEV_var   = %bquote(&var._StdDev);
    %let STDERR_var   = %bquote(&var._StdErr);
    %let NMISS_var    = %bquote(&var._NMiss);
    %let RANGE_var    = %bquote(&var._Range);
    %let KURT_var     = %bquote(&var._Kurt);
    %let LCLM_var     = %bquote(&var._LCLM);
    %let MEAN_var     = %bquote(&var._Mean);
    %let MODE_var     = %bquote(&var._Mode);
    %let SKEW_var     = %bquote(&var._Skew);
    %let UCLM_var     = %bquote(&var._UCLM);
    %let CSS_var      = %bquote(&var._CSS);
    %let MAX_var      = %bquote(&var._Max);
    %let MIN_var      = %bquote(&var._Min);
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
    %let STD_var      = %bquote(&var._StdDev);
    %let SUM_var      = %bquote(&var._Sum);
    %let USS_var      = %bquote(&var._USS);
    %let VAR_var      = %bquote(&var._Var);
    %let CV_var       = %bquote(&var._CV);
    %let P1_var       = %bquote(&var._P1);
    %let P5_var       = %bquote(&var._P5);
    %let Q1_var       = %bquote(&var._Q1);
    %let Q3_var       = %bquote(&var._Q3);
    %let N_var        = %bquote(&var._N);
    
    

    /*ͳ������Ӧ�������ʽ*/
    %let KURTOSIS_format = %bquote(best.);
    %let SKEWNESS_format = %bquote(best.);
    %let MEDIAN_format   = %bquote(best.);
    %let QRANGE_format   = %bquote(best.);
    %let STDDEV_format   = %bquote(best.);
    %let STDERR_format   = %bquote(best.);
    %let NMISS_format    = %bquote(best.);
    %let RANGE_format    = %bquote(best.);
    %let KURT_format     = %bquote(best.);
    %let LCLM_format     = %bquote(best.);
    %let MEAN_format     = %bquote(best.);
    %let MODE_format     = %bquote(best.);
    %let SKEW_format     = %bquote(best.);
    %let UCLM_format     = %bquote(best.);
    %let CSS_format      = %bquote(best.);
    %let MAX_format      = %bquote(best.);
    %let MIN_format      = %bquote(best.);
    %let P10_format      = %bquote(best.);
    %let P20_format      = %bquote(best.);
    %let P25_format      = %bquote(best.);
    %let P30_format      = %bquote(best.);
    %let P40_format      = %bquote(best.);
    %let P50_format      = %bquote(best.);
    %let P60_format      = %bquote(best.);
    %let P70_format      = %bquote(best.);
    %let P75_format      = %bquote(best.);
    %let P80_format      = %bquote(best.);
    %let P90_format      = %bquote(best.);
    %let P95_format      = %bquote(best.);
    %let P99_format      = %bquote(best.);
    %let STD_format      = %bquote(best.);
    %let SUM_format      = %bquote(best.);
    %let USS_format      = %bquote(best.);
    %let VAR_format      = %bquote(best.);
    %let CV_format       = %bquote(best.);
    %let P1_format       = %bquote(best.);
    %let P5_format       = %bquote(best.);
    %let Q1_format       = %bquote(best.);
    %let Q3_format       = %bquote(best.);
    %let N_format        = %bquote(best.);


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

    %let reg_var = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %bquote(&var))) = 0 %then %do;
        %put ERROR: ���� VAR = %bquote(&var) ��ʽ����ȷ��;
        %goto exit;
    %end;
    %else %do;
        proc sql noprint;
            select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&var";
        quit;
        %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
            %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� &var;
            %goto exit;
        %end;
        %else %if &type = char %then %do; /*����������һ���ַ��ͱ���*/
            %put ERROR: �޷����ַ��ͱ��� &var ���ж���������;
            %goto exit;
        %end;
    %end;


    /*PATTERN*/
    %if %bquote(&pattern) = %bquote() %then %do;
        %put ERROR: ���� PATTERN Ϊ�գ�;
        %goto exit;
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
        %goto exit;
    %end;

    /*��ȡÿһ�е�ͳ�������ַ���*/
    %let reg_stat_expr_unit = %bquote(((?:.|\n)*?)(?:(?<!#)#(&stat_supported))\.?);
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
            %put ERROR: �ڶԲ��� PATTERN ������ &i ��ͳ�������Ƽ������ַ�ʱ�����˴��󣬵��´����ԭ�������ָ���˲���֧�ֵ�ͳ����������δʹ�á�##�����ַ���#������ת�壡;
            %goto exit;
        %end;
    %end;

    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: ���� OUTDATA Ϊ�գ�;
        %goto exit;
    %end;
    %else %do;
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
        %let reg_stat_format_expr_unit = %bquote(\s*#(&stat_supported)\s*=\s*((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)\s*);
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

    /*STAT_NOTE*/
    %if %bquote(&stat_note) = %bquote() %then %do;
        %put ERROR: ���� STAT_NOTE Ϊ�գ�;
        %goto exit;
    %end; 

    %if %bquote(&stat_note) ^= #NULL %then %do;
        %let stat_note_n = %eval(%sysfunc(kcountw(%bquote(&stat_note), %bquote(=), q)) - 1);
        %let reg_stat_note_expr_unit = %bquote(\s*#(&stat_supported)\s*=\s*"((?:.|\n)*)"\s*);
        %let reg_stat_note_expr = %bquote(/^\(?%sysfunc(repeat(&reg_stat_note_expr_unit, %eval(&stat_note_n - 1)))\)?$/i);
        %let reg_stat_note_id = %sysfunc(prxparse(&reg_stat_note_expr));

        %if %sysfunc(prxmatch(&reg_stat_note_id, %bquote(&stat_note))) %then %do;
            %do i = 1 %to &stat_note_n;
                %let stat_whose_note_2be_update = %upcase(%sysfunc(prxposn(&reg_stat_note_id, %eval(&i * 2 - 1), &stat_note)));
                %let stat_new_note = %sysfunc(prxposn(&reg_stat_note_id, %eval(&i * 2), &stat_note));
                %let &stat_whose_note_2be_update._note = %bquote(&stat_new_note); /*����ͳ������˵������*/
            %end;
        %end;
        %else %do;
            %put ERROR: ���� STAT_NOTE = %bquote(&stat_note) ��ʽ����ȷ��;
            %goto exit;
        %end;
    %end;

    /*LABEL*/
    %if %superq(label) = %bquote() %then %do;
        %put ERROR: ���� LABEL Ϊ�գ�;
        %goto exit;
    %end;
    %else %if %qupcase(&label) = #AUTO %then %do;
        proc sql noprint;
            select
                (case when label ^= "" then cats(label)
                      else cats(name, "-n(%)") end)
                into: label from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&VAR";
        quit;
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
        proc means data = &indata %do i = 1 %to &part_n;
                                      %do j = 1 %to &&stat_&i;
                                          %bquote( )%bquote(&&stat_&i._&j)
                                      %end;
                                  %end;
                                  noprint
                                  ;
            var &var;
            output out = temp_stat %do i = 1 %to &part_n;
                                       %do j = 1 %to &&stat_&i;
                                           %bquote(&&stat_&i._&j)%bquote(=)%bquote( )
                                       %end;
                                   %end;
                                   /autoname autolabel;
        run;
    %end;
    %else %do; /*δָ���κ�ͳ��������Ȼ��� temp_stat ���ݼ����Լ��ݺ���������*/
        %put NOTE: δָ���κ�ͳ������;
        data temp_stat;
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
        create table temp_out as
            select
                0        as SEQ,
                "&label" as ITEM,
                ""       as VALUE
            from temp_stat
            outer union corr
            %do i = 1 %to &part_n;
                select
                    &i as SEQ,
                    cat(%unquote(
                                 "&indent" %bquote(,)
                                 %do j = 1 %to &&stat_&i;
                                     %temp_combpl_hash("&&string_&i._&j") %bquote(,)
                                     "&&&&&&stat_&i._&j.._note" %bquote(,)
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
                from temp_stat
                %if &i < &part_n %then %do;
                    outer union corr
                %end;
                %else %do;
                    %bquote(;)
                %end;
            %end;
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
        delete temp_stat
               temp_out
               ;
    quit;

    /*ɾ����ʱ��*/
    proc catalog catalog = work.sasmacr;
        delete temp_combpl_hash.macro;
    quit;


    %exit:
    %put NOTE: �� quantify �ѽ������У�;
%mend;
