/*
===================================
Macro Name: qualify_multi
Macro Label:�������ָ�����
Author: wtwang
Version Date: 2023-12-26 0.1
              2024-01-19 0.2
              2024-01-22 0.3
              2024-04-16 0.4
              2024-04-18 0.5
              2024-04-25 0.6
              2024-04-25 0.7
              2024-06-04 0.8
              2024-06-13 0.9
              2024-07-15 0.10
              2024-11-14 0.11
              2025-01-14 0.12
              2025-01-15 0.13
===================================
*/

%macro qualify_multi(INDATA,
                     VAR,
                     GROUP,
                     GROUPBY          = #AUTO,
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
                     debug    = false)
                     /des = "�������ָ�����" parmbuff;

    /*�򿪰����ĵ�*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify_multi/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let group                = %sysfunc(strip(%bquote(&group)));
    %let groupby              = %upcase(%sysfunc(strip(%bquote(&groupby))));
    %let debug        = %upcase(%sysfunc(strip(%bquote(&debug))));

    /*����ȫ�ֱ���*/
    %global qualify_multi_exit_with_error;
    %let qualify_multi_exit_with_error = FALSE;

    /*�����ֲ�����*/
    %local i j
           libname_in memname_in dataset_options_in
           libname_out memname_out dataset_options_out;

    /*�������*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUALIFY";
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

        filename predpc "quantify.sas";
        proc http url = "https://raw.githubusercontent.com/Snoopy1866/Descriptive-Statistics-Macro/main/&sub_folder/qualify.sas" out = predpc;
        run;
        %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
            %if &SYS_PROCHTTP_STATUS_CODE = 200 %then %do;
                %include predpc;
            %end;
            %else %do;
                %put ERROR: Զ���������ӳɹ�������δ�ɹ���ȡĿ���ļ������ֶ�����ǰ������ %nrbquote(%nrstr(%%))QUALIFY ���ٴγ������У�;
                %goto exit_with_error;
            %end;
        %end;
        %else %do;
            %put ERROR: Զ����������ʧ�ܣ������������Ӻʹ������ã����ֶ�����ǰ������ %nrbquote(%nrstr(%%))QUALIFY ���ٴγ������У�;
            %goto exit_with_error;
        %end;
    %end;


    /*----------------------------------------------�������----------------------------------------------*/
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
                %put NOTE: �������ݼ� &indata Ϊ�գ�;
            %end;
        %end;
    %end;
    %put NOTE: �������ݼ���ָ��Ϊ &libname_in..&memname_in;


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
                %let group_level_unquote_&i = %sysfunc(compress(&&group_level_&i, %nrstr(%")));

                %let group_level_freq_&i      = "&&group_level_unquote_&i(Ƶ��)";
                %let group_level_freq_fmt_&i  = "&&group_level_unquote_&i(Ƶ����ʽ��)";
                %let group_level_n_&i         = "&&group_level_unquote_&i(Ƶ��)(����)";
                %let group_level_n_fmt_&i     = "&&group_level_unquote_&i(Ƶ����ʽ��)(����)";
                %let group_level_times_&i     = "&&group_level_unquote_&i(Ƶ��)";
                %let group_level_times_fmt_&i = "&&group_level_unquote_&i(Ƶ�θ�ʽ��)";
                %let group_level_rate_&i      = "&&group_level_unquote_&i(Ƶ��)";
                %let group_level_rate_fmt_&i  = "&&group_level_unquote_&i(Ƶ�ʸ�ʽ��)";
            %end;
        %end;
    %end;
    %else %do;
        %put ERROR: ���� GROUP ��ʽ����;
        %goto exit_with_error;
    %end;

    /*GROUPBY*/
    %if %superq(groupby) = %bquote() %then %do;
        %put ERROR: ���� GROUPBY Ϊ�գ�;
        %goto exit_with_error;
    %end;
    %else %if %superq(groupby) = #AUTO %then %do;
        %put NOTE: δָ�����������ʽ�������շ�����������ֵ�������У�;
        %let groupby = &group_var(desc);
    %end;

    /*�������� by, ���Ϸ���*/
    %let reg_groupby_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)|(?:([A-Za-z_]+(?:\d+[A-Za-z_]+)?)\.))(?:\(\s*((?:DESC|ASC)(?:ENDING)?)\s*\))?$/)));
    %if %sysfunc(prxmatch(&reg_groupby_id, %superq(groupby))) %then %do;
        %let groupby_var       = %sysfunc(prxposn(&reg_groupby_id, 1, %superq(groupby)));
        %let groupby_fmt       = %sysfunc(prxposn(&reg_groupby_id, 2, %superq(groupby)));
        %let groupby_direction = %sysfunc(prxposn(&reg_groupby_id, 3, %superq(groupby)));

        %if %bquote(&groupby_var) ^= %bquote() %then %do;
            /*����������������*/
            proc sql noprint;
                select type into :type from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&groupby_var";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: �� &libname_in..&memname_in ��û���ҵ������������ &groupby_var;
                %goto exit_with_error;
            %end;
        %end;

        %if %bquote(&groupby_fmt) ^= %bquote() %then %do;
            /*��������ʽ������*/
            proc sql noprint;
                select libname, memname, source into :groupby_fmt_libname, :groupby_fmt_memname, :groupby_fmt_source from DICTIONARY.FORMATS where fmtname = "&groupby_fmt";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: ���� BY ָ���������ʽ &groupby_fmt.. �����ڣ�;
                %goto exit_with_error;
            %end;
            %else %do;
                %if &groupby_fmt_source ^= C %then %do;
                    %put ERROR: ���� BY ָ���������ʽ &groupby_fmt.. ���� CATALOG-BASED��;
                    %goto exit_with_error;
                %end;
            %end;
        %end;

        /*���������*/
        %if %bquote(&groupby_direction) = %bquote() %then %do;
            %put NOTE: δָ�������������Ĭ���������У�;
            %let groupby_direction = ASCENDING;
        %end;
        %else %if %bquote(&groupby_direction) = ASC %then %do;
            %let groupby_direction = ASCENDING;
        %end;
        %else %if %bquote(&groupby_direction) = DESC %then %do;
            %let groupby_direction = DESCENDING;
        %end;
    %end;
    %else %do;
        %put ERROR: ���� GROUPBY = %bquote(&groupby) ��ʽ����ȷ��;
        %goto exit_with_error;
    %end;

    %if %bquote(&groupby_var) ^= %bquote() %then %do;
        proc sql noprint;
            create table tmp_qualify_m_groupby_sorted as
                select
                    distinct
                    &group_var                       as group_level,
                    &groupby_var                     as group_level_by_criteria
                from %superq(indata) where not missing(&group_var) order by &groupby_var &groupby_direction, &group_var;
        quit;
    %end;
    %else %if %bquote(&groupby_fmt) ^= %bquote() %then %do;
        proc format library = &groupby_fmt_libname..&groupby_fmt_memname cntlout = tmp_qualify_m_groupby_fmt;
            select &groupby_fmt;
        run;
        proc sql noprint;
            create table tmp_qualify_m_groupby_sorted(where = (not missing(group_level))) as
                select
                    distinct
                    coalescec(a.&group_var, b.label) as group_level,
                    ifn(not missing(b.label), input(strip(b.start), 8.), constant('BIG'))
                                                     as group_level_by_criteria,
                    ifc(missing(b.label), 'Y', '')   as group_level_fmt_not_defined
                from %superq(indata) as a full join tmp_qualify_m_groupby_fmt as b on a.&group_var = b.label
                order by group_level_by_criteria &groupby_direction, group_level ascending;

            select sum(group_level_fmt_not_defined = "Y") into : groupby_fmt_not_defined_n trimmed from tmp_qualify_m_groupby_sorted where not missing(group_level);
            %if &groupby_fmt_not_defined_n > 0 %then %do;
                %put WARNING: ָ�����ڷ�������������ʽ�У����� &groupby_fmt_not_defined_n ����������δ���壬�����������Ƿ�Ԥ�ڵģ�;
            %end;
        quit;
    %end;

    /*���������������������ݼ��ı�����ǩ*/
    proc sql noprint;
        select quote(strip(group_level))                         into : group_level_1-           from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ��)')             into : group_level_freq_1-      from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ����ʽ��)')       into : group_level_freq_fmt_1-  from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ��)(����)')       into : group_level_n_1-         from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ����ʽ��)(����)') into : group_level_n_fmt_1-     from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ��)')             into : group_level_times_1-     from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ�θ�ʽ��)')       into : group_level_times_fmt_1- from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ��)')             into : group_level_rate_1-      from tmp_qualify_m_groupby_sorted;
        select quote(strip(group_level) || '(Ƶ�ʸ�ʽ��)')       into : group_level_rate_fmt_1-  from tmp_qualify_m_groupby_sorted;
        select count(distinct group_level)                       into : group_level_n            from tmp_qualify_m_groupby_sorted;
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




    /*----------------------------------------------������----------------------------------------------*/
    /*1. ��������*/
    data tmp_qualify_m_indata;
        %unquote(set %superq(indata));
    run;

    /*2. ����ͳ��*/
    %put NOTE: ===================================�ϼ�===================================;
    %qualify(INDATA      = tmp_qualify_m_indata(where = (&group_var in (%do i = 1 %to &group_level_n;
                                                                            &&group_level_&i %bquote(,)
                                                                        %end;))),
             VAR              = %superq(VAR),
             BY               = %superq(BY),
             UID              = %superq(UID),
             PATTERN          = %superq(PATTERN),
             MISSING          = %superq(MISSING),
             MISSING_NOTE     = %superq(MISSING_NOTE),
             MISSING_POSITION = %superq(MISSING_POSITION),
             OUTDATA          = tmp_qualify_m_res_sum(rename = (VALUE     = VALUE_SUM
                                                                FREQ      = FREQ_SUM
                                                                FREQ_FMT  = FREQ_SUM_FMT
                                                                N         = N_SUM
                                                                N_FMT     = N_SUM_FMT
                                                                TIMES     = TIMES_SUM
                                                                TIMES_FMT = TIMES_SUM_FMT
                                                                RATE      = RATE_SUM
                                                                RATE_FMT  = RATE_SUM_FMT)),
             STAT_FORMAT      = %superq(STAT_FORMAT),
             LABEL            = %superq(LABEL),
             INDENT           = %superq(INDENT),
             SUFFIX           = %superq(SUFFIX),
             TOTAL            = %superq(TOTAL));

    %if %bquote(&qualify_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
        %goto exit_with_error;
    %end;

    %if %sysmexecname(%sysmexecdepth - 1) = QUALIFY_MULTI_TEST %then %do; /*����� %qualify_multi_test ���ã��������ݼ� tmp_qualify_indata_unique_var*/
        proc datasets library = work noprint nowarn;
            delete tmp_qmt_indata_unique_var;
            change tmp_qualify_indata_unique_var = tmp_qmt_indata_unique_var;
        quit;
    %end;

    /*3. �����ͳ��*/
    %do i = 1 %to &group_level_n;
        %put NOTE: ===================================&&group_level_&i===================================;
        %qualify(INDATA           = tmp_qualify_m_indata(where = (&group_var = &&group_level_&i)),
                 VAR              = %superq(VAR),
                 BY               = %superq(BY),
                 UID              = %superq(UID),
                 PATTERN          = %superq(PATTERN),
                 MISSING          = %superq(MISSING),
                 MISSING_NOTE     = %superq(MISSING_NOTE),
                 MISSING_POSITION = %superq(MISSING_POSITION),
                 OUTDATA          = tmp_qualify_m_res_group_&i(rename = (VALUE     = VALUE_&i
                                                                         FREQ      = FREQ_&i
                                                                         FREQ_FMT  = FREQ_&i._FMT
                                                                         N         = N_&i
                                                                         N_FMT     = N_&i._FMT
                                                                         TIMES     = TIMES_&i
                                                                         TIMES_FMT = TIMES_&i._FMT
                                                                         RATE      = RATE_&i
                                                                         RATE_FMT  = RATE_&i._FMT)),
                 STAT_FORMAT      = %superq(STAT_FORMAT),
                 LABEL            = %superq(LABEL),
                 INDENT           = %superq(INDENT),
                 SUFFIX           = %superq(SUFFIX),
                 TOTAL            = %superq(TOTAL));

        %if %bquote(&qualify_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
            %goto exit_with_error;
        %end;
    %end;

    /*4. �ϲ��������*/
    proc sql noprint;
        create table tmp_qualify_m_outdata as
            select
                sum.idt,
                sum.seq,
                sum.item                 label = "����",
                %do i = 1 %to &group_level_n;
                    sub&i..value_&i      label = &&group_level_&i,
                    sub&i..freq_&i       label = &&group_level_freq_&i,
                    sub&i..freq_&i._fmt  label = &&group_level_freq_fmt_&i,
                    sub&i..n_&i          label = &&group_level_n_&i,
                    sub&i..n_&i._fmt     label = &&group_level_n_fmt_&i,
                    sub&i..times_&i      label = &&group_level_times_&i,
                    sub&i..times_&i._fmt label = &&group_level_times_fmt_&i,
                    sub&i..rate_&i       label = &&group_level_rate_&i,
                    sub&i..rate_&i._fmt  label = &&group_level_rate_fmt_&i,
                %end;
                sum.value_sum            label = "�ϼ�",
                sum.freq_sum             label = "�ϼ�(Ƶ��)",
                sum.freq_sum_fmt         label = "�ϼ�(Ƶ��)",
                sum.n_sum                label = "�ϼ�(Ƶ��)(����)",
                sum.n_sum_fmt            label = "�ϼ�(Ƶ����ʽ��)(����)",
                sum.times_sum            label = "�ϼ�(Ƶ��)",
                sum.times_sum_fmt        label = "�ϼ�(Ƶ�θ�ʽ��)",
                sum.rate_sum             label = "�ϼ�(Ƶ��)",
                sum.rate_sum_fmt         label = "�ϼ�(Ƶ�ʸ�ʽ��)"
            from tmp_qualify_m_res_sum as sum %do i = 1 %to &group_level_n;
                                                  left join tmp_qualify_m_res_group_&i as sub&i on sum.item = sub&i..item
                                              %end;
            order by sum.seq;

        %do i = 1 %to &group_level_n;
            update tmp_qualify_m_outdata
                set value_&i      = "%superq(VALUE_zero)",
                    freq_&i       = %superq(FREQ_zero),
                    freq_&i._fmt  = "%superq(FREQ_zero_fmt)",
                    n_&i          = %superq(N_zero),
                    n_&i._fmt     = "%superq(N_zero_fmt)",
                    times_&i      = %superq(TIMES_zero),
                    times_&i._fmt = "%superq(TIMES_zero_fmt)",
                    rate_&i       = %superq(RATE_zero),
                    rate_&i._fmt  = "%superq(RATE_zero_fmt)"
            where seq > 0 and missing(freq_&i);
        %end;
    quit;

    /*5. ������ݼ�*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item %if &uid ^= #NULL %then %do;
                                                        %do i = 1 %to &group_level_n;
                                                            times_&i._fmt value_&i
                                                        %end;
                                                        %if &group_level_n > 1 %then %do;
                                                            times_sum_fmt value_sum
                                                        %end;
                                                    %end;
                                                    %else %do;
                                                        %do i = 1 %to &group_level_n;
                                                            value_&i
                                                        %end;
                                                        %if &group_level_n > 1 %then %do;
                                                            value_sum
                                                        %end;
                                                    %end;
                                                    
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set tmp_qualify_m_outdata;
    run;

    /*----------------------------------------------���к���----------------------------------------------*/
    /*ɾ���м����ݼ�*/
    %if &debug = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_qualify_m_indata
                   tmp_qualify_m_outdata
                   tmp_qualify_m_groupby_fmt
                   tmp_qualify_m_groupby_sorted
                   tmp_qualify_m_res_sum
                   %do i = 1 %to &group_level_n;
                       tmp_qualify_m_res_group_&i
                   %end;
                   ;
        quit;
    %end;
    %goto exit;

    /*�쳣�˳�*/
    %exit_with_error:
    %let qualify_multi_exit_with_error = TRUE;

    /*�����˳�*/
    %exit:
    %put NOTE: �� qualify_multi �ѽ������У�;
%mend;
