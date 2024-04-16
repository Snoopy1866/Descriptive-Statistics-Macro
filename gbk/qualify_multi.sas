/*
===================================
Macro Name: qualify_multi
Macro Label:�������ָ�����
Author: wtwang
Version Date: 2023-12-26 0.1
              2024-01-19 0.2
              2024-01-22 0.3
              2024-04-16 0.4
===================================
*/

%macro qualify_multi(INDATA,
                     VAR,
                     GROUP,
                     GROUPBY = #AUTO,
                     OUTDATA = RES_&VAR,
                     PATTERN = %nrstr(#N(#RATE)),
                     BY = #AUTO,
                     STAT_FORMAT = (#N = BEST., #RATE = PERCENTN9.2),
                     LABEL = #AUTO,
                     INDENT = #AUTO,
                     SUFFIX = #AUTO,
                     PROCHTTP_PROXY = 127.0.0.1:7890,
                     DEL_TEMP_DATA = TRUE)
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
                %put ERROR: �������ݼ� &indata Ϊ�գ�;
                %goto exit_with_error;
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
            %end;
        %end;
    %end;
    %else %do;
        %put ERROR: ���� GROUP ��ʽ����;
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
                select distinct quote(strip(&group_var)) into : group_level_1- from %superq(indata) where not missing(&group_var);
                select count(distinct &group_var) into : group_level_n from %superq(indata);
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
                    select quote(strip(&group_var))                   into : group_level_1-          from tmp_qualify_m_groupby_sorted;
                    select quote(strip(&group_var) || '(Ƶ��)')       into : group_level_freq_1-     from tmp_qualify_m_groupby_sorted;
                    select quote(strip(&group_var) || '(Ƶ����ʽ��)') into : group_level_freq_fmt_1- from tmp_qualify_m_groupby_sorted;
                    select quote(strip(&group_var) || '(Ƶ��)')       into : group_level_rate_1-     from tmp_qualify_m_groupby_sorted;
                    select quote(strip(&group_var) || '(Ƶ�ʸ�ʽ��)') into : group_level_rate_fmt_1- from tmp_qualify_m_groupby_sorted;
                    select count(distinct &group_var)                 into : group_level_n           from tmp_qualify_m_groupby_sorted;
                quit;
            %end;
            %else %do;
                %put ERROR: ���� GROUPBY ����ָ��һ���Ϸ��ı�������;
                %goto exit_with_error;
            %end;
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




    /*----------------------------------------------������----------------------------------------------*/
    /*1. ��������*/
    data tmp_qualify_m_indata;
        %unquote(set %superq(indata));
    run;

    /*2. ����ͳ��*/
    %put NOTE: ===================================�ϼ�===================================;
    %qualify(INDATA = tmp_qualify_m_indata(where = (&group_var in (%do i = 1 %to &group_level_n;
                                                                       &&group_level_&i %bquote(,)
                                                                   %end;))),
             VAR = %superq(VAR),
             OUTDATA = tmp_qualify_m_res_sum(rename = (value = value_sum
                                                       n = n_sum
                                                       n_fmt = n_sum_fmt
                                                       rate = rate_sum
                                                       rate_fmt = rate_sum_fmt)),
             PATTERN = %superq(PATTERN),
             BY = %superq(BY),
             STAT_FORMAT = %superq(STAT_FORMAT),
             LABEL = %superq(LABEL),
             INDENT = %superq(INDENT),
             SUFFIX = %superq(SUFFIX));

    %if %bquote(&qualify_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
        %goto exit_with_error;
    %end;

    /*3. �����ͳ��*/
    %do i = 1 %to &group_level_n;
        %put NOTE: ===================================&&group_level_&i===================================;
        %qualify(INDATA = tmp_qualify_m_indata(where = (&group_var = &&group_level_&i)),
                 VAR = %superq(VAR),
                 OUTDATA = temp_res_group_level_&i(rename = (value = value_&i
                                                             n = n_&i
                                                             n_fmt = n_&i._fmt
                                                             rate = rate_&i
                                                             rate_fmt = rate_&i._fmt)),
                 PATTERN = %superq(PATTERN),
                 BY = %superq(BY),
                 STAT_FORMAT = %superq(STAT_FORMAT),
                 LABEL = %superq(LABEL),
                 INDENT = %superq(INDENT),
                 SUFFIX = %superq(SUFFIX));

        %if %bquote(&qualify_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
            %goto exit_with_error;
        %end;
    %end;

    /*4. �ϲ��������*/
    proc sql noprint;
        create table tmp_qualify_m_outdata as
            select
                sum.seq,
                sum.item                label = "����",
                %do i = 1 %to &group_level_n;
                    sub&i..value_&i     label = &&group_level_&i,
                    sub&i..n_&i         label = &&group_level_freq_&i,
                    sub&i..n_&i._fmt    label = &&group_level_freq_fmt_&i,
                    sub&i..rate_&i      label = &&group_level_rate_&i,
                    sub&i..rate_&i._fmt label = &&group_level_rate_fmt_&i,
                %end;
                sum.value_sum           label = "�ϼ�",
                sum.n_sum               label = "�ϼ�(Ƶ��)",
                sum.n_sum_fmt           label = "�ϼ�(Ƶ����ʽ��)",
                sum.rate_sum            label = "�ϼ�(Ƶ��)",
                sum.rate_sum_fmt        label = "�ϼ�(Ƶ�ʸ�ʽ��)"
            from tmp_qualify_m_res_sum as sum %do i = 1 %to &group_level_n;
                                                  left join temp_res_group_level_&i as sub&i on sum.item = sub&i..item
                                              %end;
            order by sum.seq;
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
        set tmp_qualify_m_outdata;
    run;

    /*----------------------------------------------���к���----------------------------------------------*/
    /*ɾ���м����ݼ�*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete tmp_qualify_m_indata
                   tmp_qualify_m_outdata
                   tmp_qualify_m_groupby_sorted
                   tmp_qualify_m_res_sum
                   %do i = 1 %to &group_level_n;
                       temp_res_group_level_&i
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
