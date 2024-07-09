/*
��ϸ�ĵ���ǰ�� Github ����: https://github.com/Snoopy1866/Descriptive-Statistics-Macro
*/
/*
var = A
var = A, B, C
var = A, B, C, D, E, F, G
var = A(C), B, C, D, E, F, G
var = A(C, D, E, F, G), B, C, D, E, F, G
var = A(C(E, F, G), D, E, F, G), B, C, D, E, F, G
var = A(C(E(G), F, G), D, E, F, G), B, C, D, E, F, G


var = A(C(E(G), F, G), D(F, G), E(G), F, G), B(D(F, G), E(G), F, G), C(E(G), F, G), D(F, G), E(G), F, G

var = A, (C, (E, F)|D, (F)|E, F)|B, (D, (F)|E, F)|C, ((F)|E, F)|D, (F)|E, F

*/
%macro qualify_strata(INDATA,
                      VAR,
                      BY            = #AUTO,
                      UID           = #NULL,
                      GROUP         = #NULL,
                      GROUPBY       = #AUTO,
                      OUTDATA       = #AUTO,
                      DEL_TEMP_DATA = NULL) /des = "������㼶����ָ�����" parmbuff;

    /*�򿪰����ĵ�*/
    %if %bquote(%upcase(&SYSPBUFF)) = %bquote((HELP)) or %bquote(%upcase(&SYSPBUFF)) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify_strata/readme.md";
        %goto exit;
    %end;

    /*ͳһ������Сд*/
    %let indata               = %sysfunc(strip(%superq(indata)));
    %let var                  = %upcase(%sysfunc(strip(%superq(var))));
    %let by                   = %upcase(%sysfunc(strip(%superq(by))));
    %let uid                  = %upcase(%sysfunc(strip(%superq(uid))));
    %let group                = %upcase(%sysfunc(strip(%superq(group))));
    %let group                = %upcase(%sysfunc(strip(%superq(groupby))));
    %let outdata              = %sysfunc(strip(%superq(outdata)));
    %let del_temp_data        = %upcase(%sysfunc(strip(%superq(del_temp_data))));

    /*�����ֲ�����*/
    %local i j;

    

    /*----------------------------------------------�������----------------------------------------------*/
    /*INDATA*/
    %if %superq(indata) = %bquote() %then %do;
        %put ERROR: δָ���������ݼ���;
        %goto exit_with_error;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, %superq(indata))) %then %do;
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
        %else %do;
            %put ERROR: ���� INDATA = %superq(indata) ��ʽ����ȷ��;
            %goto exit_with_error;
        %end;
    %end;
    %put NOTE: �������ݼ���ָ��Ϊ &libname_in..&memname_in;


    /*VAR*/
    %if %superq(var) = %bquote() %then %do;
        %put ERROR: δָ������������;
        %goto exit_with_error;
    %end;

    %let reg_var = %bquote(/^[A-Za-z_][A-Za-z_\d]*(?:[,\s][A-Za-z_][A-Za-z_\d]*)*$/);
    %let reg_var_id = %sysfunc(prxparse(&reg_var));
    %if %sysfunc(prxmatch(&reg_var_id, %superq(var))) %then %do;
        %let var_n = %sysfunc(countw(%bquote(&var), %bquote(,), s));
        %let IS_VAR_NOT_VALID = FALSE;
        %do i = 1 %to &var_n;
            %let var_&i = %scan(%bquote(&var), &i, %bquote(,), s);
            %put &&var_&i;

            proc sql noprint;
                select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&&var_&i";
            quit;
            /*������������*/
            %if &SQLOBS = 0 %then %do;
                %let IS_VAR_NOT_VALID = TRUE;
                %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� &&var_&i;
            %end;
            /*����������*/
            %else %if %bquote(&type) = num %then %do;
                %let IS_VAR_NOT_VALID = TRUE;
                %put ERROR: ���� VAR ��֧����ֵ�ͱ�����;
            %end;
        %end;

        %if &IS_VAR_NOT_VALID = TRUE %then %do;
            %goto exit_with_error;
        %end;
    %end;
    %else %do;
        %put ERROR: ���� VAR = %superq(var) ��ʽ����ȷ��;
        %goto exit_with_error;
    %end;


    /*UID*/
    %if %superq(uid) = %bquote() %then %do;
        %put ERROR: δָ��Ψһ��ʶ��������;
        %goto exit_with_error;
    %end;

    %if %superq(uid) ^= #NULL %then %do;
        %let reg_uid = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
        %let reg_uid_id = %sysfunc(prxparse(&reg_uid));
        %if %sysfunc(prxmatch(&reg_uid_id, %superq(uid))) %then %do;
            proc sql noprint;
                select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&uid";
            quit;
            %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
                %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� &uid;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: ���� UID = %superq(uid) ��ʽ����ȷ��;
            %goto exit_with_error;
        %end;
    %end;


    /*OUTDATA*/
    %if %superq(outdata) = %bquote() %then %do;
        %put ERROR: ���� OUTDATA Ϊ�գ�;
        %goto exit_with_error;
    %end;
    %else %do;
        %if %qupcase(&outdata) = %bquote(#AUTO) %then %do;
            %let outdata = RES_&var_1;
        %end;

        %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_outdata_id, %superq(outdata))) %then %do;
            %let libname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 1, %bquote(&outdata))));
            %let memname_out = %upcase(%sysfunc(prxposn(&reg_outdata_id, 2, %bquote(&outdata))));
            %let dataset_options_out = %sysfunc(prxposn(&reg_outdata_id, 3, %bquote(&outdata)));
            %if &libname_out = %bquote() %then %let libname_out = WORK; /*δָ���߼��⣬Ĭ��ΪWORKĿ¼*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_out";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_out �߼��ⲻ���ڣ�;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: ���� OUTDATA = %superq(outdata) ��ʽ����ȷ��;
            %goto exit_with_error;
        %end;
    %end;
    %put NOTE: ������ݼ���ָ��Ϊ &libname_out..&memname_out;


    /*GROUP*/
    %if %superq(group) = %bquote() %then %do;
        %put ERROR: δָ�����������;
        %goto exit_with_error;
    %end;

    %let reg_group_id = %sysfunc(prxparse(%bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:[\s,]*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*)+)?\))?$/)));
    %if %sysfunc(prxmatch(&reg_group_id, %superq(group))) %then %do;
        %let group_var = %upcase(%sysfunc(prxposn(&reg_group_id, 1, %superq(group))));
        %let group_level = %sysfunc(prxposn(&reg_group_id, 2, %superq(group)));

        /*������������*/
        proc sql noprint;
            select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&group_var";
        quit;
        %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
            %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� &group_var;
            %goto exit_with_error;
        %end;
        /*����������*/
        %if %bquote(&type) = num %then %do;
            %put ERROR: ���� GROUP ��֧����ֵ�ͱ�����;
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
        %put ERROR: ���� GROUP = %superq(group) ��ʽ����ȷ��;
        %goto exit_with_error;
    %end;

    /*GROUPBY*/
    %if &IS_GROUP_LEVEL_SPECIFIED = TRUE %then %do;
        %if %superq(groupby) ^= %bquote() and %superq(groupby) ^= #AUTO %then %do;
            %put WARNING: ��ͨ������ GROUP ָ���˷�������򣬲��� GROUPBY �ѱ����ԣ�;
        %end;
    %end;
    %else %do;
        %if %superq(groupby) = %bquote() %then %do;
            %put ERROR: δָ���������������;
            %goto exit_with_error;
        %end;
        %else %if %superq(groupby) = #AUTO %then %do;
            proc sql noprint;
                create table tmp_qualify_m_groupby_sorted as select * from %superq(indata) where not missing(&group_var);
            quit;
        %end;
        %else %do;
            %let reg_groupby_id = %sysfunc(prxparse(%bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:ASC|DESC)(?:ENDING)?)\))?$/)));
            %if %sysfunc(prxmatch(&reg_groupby_id, %superq(groupby))) %then %do;
                %let groupby_var = %sysfunc(prxposn(&reg_groupby_id, 1, %superq(groupby)));
                %let groupby_direction = %sysfunc(prxposn(&reg_groupby_id, 2, %superq(groupby)));

                /*����������������*/
                proc sql noprint;
                    select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&groupby_var";
                quit;
                %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
                    %put ERROR: �� &libname_in..&memname_in ��û���ҵ������������ &groupby_var;
                    %goto exit_with_error;
                %end;

                proc sql noprint;
                    create table tmp_qualify_m_groupby_sorted as
                        select
                            distinct
                            &group_var,
                            &groupby_var
                        from %superq(indata) where not missing(&group_var) order by &groupby_var &groupby_direction, &group_var;
                quit;
            %end;
            %else %do;
                %put ERROR: ���� GROUPBY = %superq(groupby) ��ʽ����ȷ��;
                %goto exit_with_error;
            %end;
        %end;

        /*���������������������ݼ��ı�����ǩ*/
        proc sql noprint;
            select quote(strip(&group_var))                         into : group_level_1-           from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(Ƶ��)')             into : group_level_freq_1-      from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(Ƶ����ʽ��)')       into : group_level_freq_fmt_1-  from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(Ƶ��)')             into : group_level_times_1-     from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(Ƶ�θ�ʽ��)')       into : group_level_times_fmt_1- from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(Ƶ��)')             into : group_level_rate_1-      from tmp_qualify_m_groupby_sorted;
            select quote(strip(&group_var) || '(Ƶ�ʸ�ʽ��)')       into : group_level_rate_fmt_1-  from tmp_qualify_m_groupby_sorted;
            select count(distinct &group_var)                       into : group_level_n            from tmp_qualify_m_groupby_sorted;
        quit;
    %end;

    /*----------------------------------------------������----------------------------------------------*/


    /*----------------------------------------------���к���----------------------------------------------*/
   
    /*�쳣�˳�*/
    %exit_with_error:

    /*�����˳�*/
    %exit:
    %put NOTE: �� desc_coun �ѽ������У�;
%mend;

options symbolgen mlogic mprint;
%qualify_strata(indata = adam.adcm,
                var = cmatc2 cmdecod);
options nosymbolgen nomlogic nomprint;
