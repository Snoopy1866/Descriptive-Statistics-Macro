/*
===================================
Macro Name: qualify_multi_test
Macro Label:�������ָ�����ͳ��
Author: wtwang
Version Date: 2024-01-08 0.1
              2024-01-18 0.2
              2024-01-22 0.3
              2024-01-23 0.4
              2024-04-18 0.5
              2024-04-28 0.6
              2024-06-03 0.7
              2024-06-04 0.8
              2024-06-13 0.9
===================================
*/

%macro qualify_multi_test(INDATA,
                          VAR,
                          GROUP,
                          GROUPBY,
                          BY               = #AUTO,
                          UID              = #NULL,
                          PATTERN          = %nrstr(#FREQ(#RATE)),
                          MISSING          = FALSE,
                          MISSING_NOTE     = "ȱʧ",
                          MISSING_POSITION = LAST,
                          OUTDATA          = RES_&VAR,
                          STAT_FORMAT      = #AUTO,
                          LABEL            = #AUTO,
                          INDENT           = #AUTO,
                          SUFFIX           = #AUTO,
                          TOTAL            = FALSE,
                          PROCHTTP_PROXY   = 127.0.0.1:7890,
                          DEL_TEMP_DATA    = TRUE)
                          /des = "�������ָ�����ͳ��" parmbuff;

    /*�򿪰����ĵ�*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify_multi_test/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let group                = %sysfunc(strip(%bquote(&group)));
    %let groupby              = %upcase(%sysfunc(strip(%bquote(&groupby))));
    %let del_temp_data        = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));

    /*����ȫ�ֱ���*/
    %global qlmt_exit_with_error
            group_level_n
            group_var;

    /*�����ֲ�����*/
    %local i j
           libname_in  memname_in  dataset_options_in
           libname_out memname_out dataset_options_out;

    /*�������*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUALIFY_MULTI";
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

        filename predpc "qualify_multi.sas";
        proc http url = "https://raw.githubusercontent.com/Snoopy1866/Descriptive-Statistics-Macro/main/&sub_folder/qualify_multi.sas" out = predpc;
        run;
        %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
            %if &SYS_PROCHTTP_STATUS_CODE = 200 %then %do;
                %include predpc;
            %end;
            %else %do;
                %put ERROR: Զ���������ӳɹ�������δ�ɹ���ȡĿ���ļ������ֶ�����ǰ������ %nrbquote(%nrstr(%%))QUALIFY_MULTI ���ٴγ������У�;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: Զ����������ʧ�ܣ������������Ӻʹ������ã����ֶ�����ǰ������ %nrbquote(%nrstr(%%))QUALIFY_MULTI ���ٴγ������У�;
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
    /*1. ��������*/
    data tmp_qmt_indata;
        %unquote(set %superq(indata));
    run;

    /*2. ͳ������*/
    %let p_format  = #AUTO;
    %let ts_format = #AUTO;
    %qualify_multi(INDATA           = tmp_qmt_indata,
                   VAR              = %superq(VAR),
                   GROUP            = %superq(GROUP),
                   GROUPBY          = %superq(GROUPBY),
                   BY               = %superq(BY),
                   UID              = %superq(UID),
                   PATTERN          = %superq(PATTERN),
                   MISSING          = %superq(MISSING),
                   MISSING_NOTE     = %superq(MISSING_NOTE),
                   MISSING_POSITION = %superq(MISSING_POSITION),
                   OUTDATA          = tmp_qmt_desc(keep = _all_),
                   STAT_FORMAT      = %superq(STAT_FORMAT),
                   LABEL            = %superq(LABEL),
                   INDENT           = %superq(INDENT),
                   SUFFIX           = %superq(SUFFIX),
                   TOTAL            = %superq(TOTAL));

    %if %bquote(&qualify_multi_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
        %goto exit_with_error;
    %end;

    /*3. ͳ���ƶ�*/
    %if &p_format = #AUTO %then %do;
        /*Pֵ�����ʽ*/
        proc format;
            picture qlmt_pvalue(round  max = 7)
                    low - < 0.0001 = "<0.0001"(noedit)
                    other = "9.9999";
        run;
        %let p_format = qlmt_pvalue.;
    %end;

    /*������Fisher��ȷ����*/
    proc freq data = tmp_qmt_indata_unique_var noprint;
        tables &var_name*&group_var /chisq(warn = (output nolog)) fisher;
        output out = tmp_qmt_chisq chisq;
    run;

    /*�����������洢˵������*/
    %let note_stat    = %unquote(%superq(indent_sql_expr)) || "ͳ����";
    %let note_pvalue  = %unquote(%superq(indent_sql_expr)) || "Pֵ";

    proc sql noprint;
        select * from DICTIONARY.COLUMNS where libname = "WORK" and memname = "TMP_QMT_CHISQ";
        %if &SQLOBS = 0 %then %do; /*�л��еķ�ȱʧ�۲�����2���޷�����ͳ����*/
            create table tmp_qmt_stat
                (item char(%eval(%length(%bquote(&indent_sql_expr)) + 12)), value_1 char(10), value_2 char(10));
            insert into tmp_qmt_stat
                set item    = &note_stat,
                    value_1 = "-",
                    value_2 = "-";
            insert into tmp_qmt_stat
                set item    = &note_pvalue,
                    value_1 = "-";
        %end;
        %else %do;
            select WARN_PCHI into : chisq_warn from tmp_qmt_chisq;
            %if &chisq_warn = 1 %then %do; /*�������鲻����*/
                create table tmp_qmt_stat as
                    select
                        &note_stat       as item,
                        "Fisher��ȷ����" as value_1,
                        "-"              as value_2
                    from tmp_qmt_chisq
                    outer union corr
                    select
                        &note_pvalue                    as item,
                        strip(put(XP2_FISH, &p_format)) as value_1
                    from tmp_qmt_chisq;
            %end;
            %else %do; /*������������*/
                %if &ts_format = #AUTO %then %do;
                    select max(ceil(log10(abs(_PCHI_))) + 6, 7) into : ts_fmt_width from tmp_qmt_chisq; /*���������ʽ�Ŀ��*/
                    %let ts_format = &ts_fmt_width..4;
                %end;
                create table tmp_qmt_stat as
                    select
                        &note_stat                     as item,
                        "��������"                     as value_1,
                        strip(put(_PCHI_, &ts_format)) as value_2
                    from tmp_qmt_chisq
                    outer union corr
                    select
                        &note_pvalue                  as item,
                        strip(put(P_PCHI, &p_format)) as value_1
                    from tmp_qmt_chisq;
            %end;
        %end;
    quit;

    /*4. �ϲ����*/
    proc sql noprint;
        create table tmp_qmt_outdata as
            select * from tmp_qmt_desc outer union corr
            select * from tmp_qmt_stat;
    quit;

    /*5. ������ݼ�*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item %do i = 1 %to &group_level_n;
                                                        value_&i
                                                    %end;
                                                    %if &group_level_n > 1 %then %do;
                                                        value_sum
                                                    %end;
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
                   tmp_qmt_indata_unique_var
                   tmp_qmt_desc
                   tmp_qmt_stat
                   tmp_qmt_outdata
                   tmp_qmt_chisq

                   tmp_qualify_indata_unique_var /*%qualify_multi ��� group ��ˮƽ���� %qualify ���������ݼ�*/
                   ;
        quit;
    %end;
    %goto exit;

    /*�쳣�˳�*/
    %exit_with_error:
    %let qlmt_exit_with_error = TRUE;

    /*�����˳�*/
    %exit:
    %put NOTE: �� qualify_multi_test �ѽ������У�;
%mend;
