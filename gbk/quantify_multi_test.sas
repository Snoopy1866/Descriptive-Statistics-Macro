/*
===================================
Macro Name: quantify_multi_test
Macro Label:�������ָ�����ͳ��
Author: wtwang
Version Date: 2024-01-05 0.1
              2024-01-18 0.2
===================================
*/

%macro quantify_multi_test(INDATA,
                           VAR,
                           GROUP,
                           GROUPBY,
                           OUTDATA = RES_&VAR,
                           PATTERN = %nrstr(#N(#NMISS)|#MEAN��#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX), 
                           STAT_FORMAT = #AUTO,
                           STAT_NOTE = #AUTO,
                           LABEL = #AUTO,
                           INDENT = #AUTO,
                           T_FORMAT = #AUTO,
                           P_FORMAT = #AUTO,
                           PROCHTTP_PROXY = 127.0.0.1:7890,
                           DEL_TEMP_DATA = TRUE)
                           /des = "�������ָ�����ͳ��" parmbuff;

    /*�򿪰����ĵ�*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/quantify_multi_test/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let group                = %sysfunc(strip(%bquote(&group)));
    %let groupby              = %upcase(%sysfunc(strip(%bquote(&groupby))));
    %let t_format             = %upcase(%sysfunc(strip(%bquote(&t_format))));
    %let p_format             = %upcase(%sysfunc(strip(%bquote(&p_format))));

    /*����ȫ�ֱ���*/
    %global qmt_exit_with_error;

    /*�����ֲ�����*/
    %local i j
           libname_in  memname_in  dataset_options_in
           libname_out memname_out dataset_options_out;

    /*�������*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUANTIFY_MULTI";
    quit;
    %if &SQLOBS = 0 %then %do;
        %put WARNING: ǰ������ȱʧ�����ڳ��Դ�����������......;

        %let cur_encoding = %sysfunc(getOption(ENCODING));
        %if %bquote(&cur_encoding) = %bquote(EUC-CN) %then %do;
            %let sub_folder = gbk;
        %end;
        %else %if %bquote(&cur_encoding) = %bquote(UTF-8) %then %do;
            %let sub_folder = utf8;
        %end;

        filename predpc "quantify_multi.sas";
        proc http url = "https://raw.githubusercontent.com/Snoopy1866/Descriptive-Statistics-Macro/main/&sub_folder/quantify_multi.sas" out = predpc;
        run;
        %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
            %if &SYS_PROCHTTP_STATUS_CODE = 200 %then %do;
                %include predpc;
            %end;
            %else %do;
                %put ERROR: Զ���������ӳɹ�������δ�ɹ���ȡĿ���ļ������ֶ�����ǰ������ %nrbquote(%nrstr(%%))QUANTIFY_MULTI ���ٴγ������У�;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: Զ����������ʧ�ܣ������������Ӻʹ������ã����ֶ�����ǰ������ %nrbquote(%nrstr(%%))QUANTIFY_MULTI ���ٴγ������У�;
            %goto exit_with_error;
        %end;
    %end;


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
        %end;
    %end;



    /*----------------------------------------------������----------------------------------------------*/
    /*1. ��������*/
    data tmp_qmt_indata;
        %unquote(set %superq(indata));
    run;

    /*2. ͳ������*/
    %quantify_multi(INDATA      = tmp_qmt_indata,
                    VAR         = %superq(VAR),
                    GROUP       = %superq(GROUP),
                    GROUPBY     = %superq(GROUPBY),
                    OUTDATA     = tmp_qmt_outdata,
                    PATTERN     = %superq(PATTERN),
                    STAT_FORMAT = %superq(STAT_FORMAT),
                    STAT_NOTE   = %superq(STAT_NOTE),
                    LABEL       = %superq(LABEL),
                    INDENT      = %superq(INDENT));

    %if %bquote(&quantify_multi_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
        %goto exit_with_error;
    %end;

    /*3. ͳ���ƶ�*/
    %if %superq(p_format) = #AUTO %then %do;
        /*Pֵ�����ʽ*/
        proc format;
            picture spvalue(round  max = 7)
                    low - < 0.0001 = "<0.0001"(noedit)
                    other = "9.9999";
        run;
        %let p_format = spvalue.;
    %end;

    /*��̬�Լ���*/
    proc univariate data = tmp_qmt_indata normaltest noprint;
        var %superq(VAR);
        class %superq(GROUPBY);
        output out = tmp_qmt_nrmtest normaltest = normaltest probn = probn;
    run;

    proc sql noprint;
        select sum(probn < 0.05) into : nrmtest_reject from tmp_qmt_nrmtest;
    quit;

    /*����һ����𲻷�����̬�ԣ�ʹ�� Wilcoxon ����*/
    %if &nrmtest_reject > 0 %then %do;
        %put NOTE: ����һ����𲻷�����̬�ԣ�ʹ�� Wilcoxon ���飡;
        proc npar1way data = tmp_qmt_indata wilcoxon noprint;
            var %superq(VAR);
            class %superq(GROUPBY);
            output out = tmp_qmt_wcxtest wilcoxon;
        run;
        proc sql noprint;
            %if %superq(t_format) = #AUTO %then %do;
                select max(ceil(log10(abs(Z_WIL))) + 6, 7) into : t_fmt_width from tmp_qmt_wcxtest; /*���������ʽ�Ŀ��*/
                %let t_format = &t_fmt_width..4;
            %end;
            insert into tmp_qmt_outdata
                set item = "&indent_sql_expr.ͳ����",
                    value_1 = "Wilcoxon�Ⱥͼ���",
                    value_2 = strip(put((select Z_WIL from tmp_qmt_wcxtest), &t_format));
            insert into tmp_qmt_outdata
                set item = "&indent_sql_expr.Pֵ",
                    value_1 = strip(put((select P2_WIL from tmp_qmt_wcxtest), &p_format));
        quit;
    %end;
    %else %do;
        ods html close;
        ods output TTests = tmp_qmt_ttests Equality = tmp_qmt_equality;
        proc ttest data = tmp_qmt_indata plots = none;
            var %superq(VAR);
            class %superq(GROUPBY);
        run;
        ods html;

        /*�������Լ���*/
        proc sql noprint;
            select sum(ProbF < 0.05) into : homovar_reject from tmp_qmt_equality;
        quit;

        /*����룬ʹ�� Satterthwaite t ����*/
        %if &homovar_reject > 0 %then %do;
            %put NOTE: ����룬ʹ�� Satterthwaite t ���飡;
            proc sql noprint;
                %if %superq(t_format) = #AUTO %then %do;
                    select max(ceil(log10(abs(tValue))) + 6, 7) into : t_fmt_width from tmp_qmt_ttests where Variances = "������"; /*���������ʽ�Ŀ��*/
                    %let t_format = &t_fmt_width..4;
                %end;
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.ͳ����",
                        value_1 = "t����",
                        value_2 = strip(put((select tValue from tmp_qmt_ttests where Variances = "������"), &t_format));
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.Pֵ",
                        value_1 = strip(put((select Probt from tmp_qmt_ttests where Variances = "������"), &p_format));
            quit;
        %end;
        %else %do;
            proc sql noprint;
                %if %superq(t_format) = #AUTO %then %do;
                    select max(ceil(log10(abs(tValue))) + 6, 7) into : t_fmt_width from tmp_qmt_ttests where Variances = "����"; /*���������ʽ�Ŀ��*/
                    %let t_format = &t_fmt_width..4;
                %end;
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.ͳ����",
                        value_1 = "t����",
                        value_2 = strip(put((select tValue from tmp_qmt_ttests where Variances = "����"), &t_format));
                insert into tmp_qmt_outdata
                    set item = "&indent_sql_expr.Pֵ",
                        value_1 = strip(put((select Probt from tmp_qmt_ttests where Variances = "����"), &p_format));
            quit;
        %end;
    %end;
    

    /*5. ������ݼ�*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_qmt_outdata;
    run;

    /*----------------------------------------------���к���----------------------------------------------*/
    /*ɾ���м����ݼ�*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_qmt_indata
                   tmp_qmt_outdata
                   Tmp_qmt_nrmtest
                   Tmp_qmt_equality
                   Tmp_qmt_ttests
                   Tmp_qmt_wcxtest
                   ;
        quit;
    %end;

    %exit_with_error:
    %let qmt_exit_with_error = TRUE;

    %exit:
    %put NOTE: �� quantify_multi_test �ѽ������У�;
%mend;
