/*
===================================
Macro Name: quantify
Macro Label:�������ָ�����
Author: wtwang
Version Date: 2023-12-21 0.1.0

===================================
*/

%macro quantify_multi(INDATA, VAR, GROUP, GROUPBY = #AUTO, OUTDATA = RES_&VAR, PATTERN = %nrstr(#N(#NMISS)|#MEAN��#STD|#MEDIAN(#Q1, #Q3)|#MIN, #MAX), 
                      STAT_FORMAT = #AUTO, STAT_NOTE = #AUTO, LABEL = #AUTO, INDENT = #AUTO, DEL_TEMP_DATA = TRUE) /des = "�������ָ�����" parmbuff;

    /*�򿪰����ĵ�*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/quantify_multi/readme.md";
        %goto exit;
    %end;

    /*----------------------------------------------��ʼ��----------------------------------------------*/
    /*ͳһ������Сд*/
    %let group                = %sysfunc(strip(%bquote(&group)));
    %let groupby              = %upcase(%sysfunc(strip(%bquote(&groupby))));

    /*����ȫ�ֱ���*/
    %global quantify_multi_exit_with_error;

    /*�����ֲ�����*/
    %local i j;

    /*�������*/
    proc sql noprint;
        select * from DICTIONARY.CATALOGS where libname = "WORK" and memname = "SASMACR" and objname = "QUANTIFY";
    quit;
    %if &SQLOBS = 0 %then %do;
        %put ERROR: ����������ǰ���������������� %nrbquote(%nrstr(%%))QUANTIFY ���ٴγ������У�;
        %goto exit;
    %end;


    /*----------------------------------------------�������----------------------------------------------*/
    /*GROUP*/
    %if %superq(group) = %bquote() %then %do;
        %put ERROR: δָ�����������;
        %goto exit;
    %end;

    %let reg_group_id = %sysfunc(prxparse(%bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:[\s,]*(?:\x22[^\x22]*?\x22|\x27[^\x27]*?\x27)\s*)+)?\))?$/)));
    %if %sysfunc(prxmatch(&reg_group_id, %superq(group))) %then %do;
        %let group_var = %sysfunc(prxposn(&reg_group_id, 1, %superq(group)));
        %let group_level = %sysfunc(prxposn(&reg_group_id, 2, %superq(group)));

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
        %goto exit;
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
            %goto exit;
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

                proc sql noprint;
                    create table temp_groupby_sorted_indata as
                        select
                            distinct
                            &group_var,
                            &groupby_var
                        from %superq(indata) order by &groupby_var &groupby_direction, &group_var;
                    select quote(strip(&group_var)) into : group_level_1- from temp_groupby_sorted_indata;
                    select count(distinct &group_var) into : group_level_n from temp_groupby_sorted_indata;
                quit;
            %end;
            %else %do;
                %put ERROR: ���� GROUPBY ������һ���Ϸ��ı�������;
                %goto exit;
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
    data temp_indata;
        %unquote(set %superq(indata));
    run;

    /*2. ����ͳ��*/
    %quantify(INDATA = temp_indata, VAR = %superq(VAR), OUTDATA = temp_res_sum(rename = (value = value_sum)), PATTERN = %superq(PATTERN),
              STAT_FORMAT = %superq(STAT_FORMAT), STAT_NOTE = %superq(STAT_NOTE), LABEL = %superq(LABEL), INDENT = %superq(INDENT));

    %if %bquote(&quantify_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
        %goto exit_with_error;
    %end;

    /*3. �����ͳ��*/
    %do i = 1 %to &group_level_n;
        %quantify(INDATA = temp_indata(where = (&group_var = &&group_level_&i)), VAR = %superq(VAR), OUTDATA = temp_res_group_level_&i(rename = (value = value_&i)), PATTERN = %superq(PATTERN),
                  STAT_FORMAT = %superq(STAT_FORMAT), STAT_NOTE = %superq(STAT_NOTE), LABEL = %superq(LABEL), INDENT = %superq(INDENT));

        %if %bquote(&quantify_exit_with_error) = TRUE %then %do; /*�ж��ӳ�������Ƿ��������*/
            %goto exit_with_error;
        %end;
    %end;

    /*4. �ϲ��������*/
    data temp_outdata;
        merge %do i = 1 %to &group_level_n;
                  temp_res_group_level_&i
              %end;
              temp_res_sum;
        label %do i = 1 %to &group_level_n;
                  value_&i = &&group_level_&i
              %end;
              value_sum = "�ϼ�"
              item = "ͳ����";
    run;

    /*4. ������ݼ�*/
    data &libname_out..&memname_out(%if %superq(dataset_options_out) = %bquote() %then %do;
                                        keep = item %do i = 1 %to &group_level_n;
                                                        value_&i
                                                    %end;
                                                    value_sum
                                    %end;
                                    %else %do;
                                        &dataset_options_out
                                    %end;);
        set temp_outdata;
    run;

    /*----------------------------------------------���к���----------------------------------------------*/
    /*ɾ���м����ݼ�*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn;
            delete temp_indata
                   temp_outdata
                   temp_groupby_sorted_indata
                   temp_res_sum
                   %do i = 1 %to &group_level_n;
                       temp_res_group_level_&i
                   %end;
                   ;
        quit;
    %end;

    %exit_with_error:
    %let quantify_multi_exit_with_error = TRUE;

    %exit:
    %put NOTE: �� quantify_multi �ѽ������У�;
%mend;
