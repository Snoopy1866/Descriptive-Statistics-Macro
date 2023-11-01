/*
===================================
Macro Name: desc_coun
Macro Label:�������������Է���
Author: wtwang
Version Date: 2023-02-09 V1.11
===================================
*/


%macro desc_coun(INDATA, VAR, FORMAT = PERCENTN9.2, BY = &VAR, MISSING = FALSE, DENOMINATOR = #AUTO,
                 INDENT = %bquote(    ), LABEL = #AUTO, IS_LABEL_INDENT = FALSE, IS_LABEL_DISPLAY = TRUE,
                 OUTDATA = #AUTO, DEL_TEMP_DATA = TRUE, DEL_DUP_BY_VAR = #NULL,
                 SKIP_PARAM_CHECK = FALSE, SKIP_MAIN_PROG = FALSE, PARAM_VALID_FLAG_VAR = #NULL,
                 PARAM_LIST_BUFFER = #NULL) /des = "����������������" parmbuff;
/*
----Required Argument----
INDATA               ���������ݼ�
VAR                  ����������

----Optional Argument----
FORMAT               �ٷֱ������ʽ
BY                   ��������(ASC, DESC, VARIABLE)
MISSING              �Ƿ�ȱʧֵ��Ϊһ��(����ռ����һ�㼶�µ�һ������)
DENOMINATOR          ����ٷֱȻ��ڵı�������ֵ(#ALL, ��ʾ���ںϼ�Ƶ�����м���
                                                #LAST����ʾ������һ�㼶��Ƶ�����м���)
INDENT               ���ڲ㼶֮��������ַ�(��)
LABEL                ������ݼ��ı�ͷ��ǩ(����: �Ա�-n(%))
IS_LABEL_INDENT      ��ͷ��ǩ�Ƿ�����
IS_LABEL_DISPLAY     ��ͷ��ǩ�Ƿ�չʾ(IS_LABEL_DISPLAY = FALSEʱ, ����LABEL, IS_LABEL_INDENT��Ȼ��Ч)
OUTDATA              ������ݼ�����

----Developer Argument----
DEL_TEMP_DATA        �Ƿ�ɾ���м����ݼ�
DEL_DUP_BY_VAR       ɾ���ظ��۲���ڵı��������磺ͳ��ĳ��SOC�µ�AE����ʱ����ָ�� DEL_DUP_BY_VAR = USUBJID��
SKIP_PARAM_CHECK     �Ƿ������������
SKIP_MAIN_PROG       �Ƿ�����������
PARAM_VALID_FLAG_VAR �����Ϸ��Ա�ʶ����
PARAM_LIST_BUFFER    �����б����
*/

    /*�򿪰����ĵ�*/
    %if %bquote(%upcase(&SYSPBUFF)) = %bquote((HELP)) or %bquote(%upcase(&SYSPBUFF)) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/desc_coun/readme.md";
        %goto exit;
    %end;

    /*ͳһ������Сд*/
    %let indata               = %sysfunc(strip(%bquote(&indata)));
    %let var                  = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&var)))))));
    %let format               = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&format)))))));
    %let by                   = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&by)))))));
    %let missing              = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&missing)))))));
    %let denominator          = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&denominator)))))));
    %let label                = %sysfunc(strip(%bquote(&label)));
    %let is_label_indent      = %upcase(%sysfunc(strip(%bquote(&is_label_indent))));
    %let is_label_display     = %upcase(%sysfunc(strip(%bquote(&is_label_display))));
    %let outdata              = %sysfunc(strip(%bquote(&outdata)));
    %let del_temp_data        = %upcase(%sysfunc(strip(%bquote(&del_temp_data))));
    %let del_dup_by_var       = %upcase(%sysfunc(strip(%bquote(&del_dup_by_var))));
    %let skip_param_check     = %upcase(%sysfunc(strip(%bquote(&skip_param_check))));
    %let skip_main_prog       = %upcase(%sysfunc(strip(%bquote(&skip_main_prog))));
    %let param_valid_flag_var = %upcase(%sysfunc(strip(%bquote(&param_valid_flag_var))));
    %let param_list_buffer    = %upcase(%sysfunc(strip(%bquote(&param_list_buffer))));


    /*�����ֲ�����*/
    %local i j;

    

    /*----------------------------------------------�������----------------------------------------------*/
    /*SKIP_PARAM_CHECK*/
    %if %bquote(&SKIP_PARAM_CHECK) ^= TRUE and %bquote(&SKIP_PARAM_CHECK) ^= FALSE %then %do;
        %put ERROR: ���� SKIP_PARAM_CHECK ������ TRUE �� FALSE��;
        %goto exit;
    %end;
    %else %if %bquote(&SKIP_PARAM_CHECK) = TRUE %then %do;
        %put NOTE: ���ú���� %nrstr(%%desc_coun) ʱʹ�ò��� SKIP_PARAM_CHECK = TRUE �����˲�����鲽�裡;
        %goto prog;
    %end;

    /*INDATA*/
    %if %bquote(&indata) = %bquote() %then %do;
        %put ERROR: δָ���������ݼ���;
        %goto exit_err;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, &indata)) = 0 %then %do;
            %put ERROR: ���� INDATA = &indata ��ʽ����ȷ��;
            %goto exit_err;
        %end;
        %else %do;
            %let libname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 1, &indata)));
            %let memname_in = %upcase(%sysfunc(prxposn(&reg_indata_id, 2, &indata)));
            %let dataset_options_in = %sysfunc(prxposn(&reg_indata_id, 3, &indata));
            %if &libname_in = %bquote() %then %let libname_in = WORK; /*δָ���߼��⣬Ĭ��ΪWORKĿ¼*/
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: &libname_in �߼��ⲻ���ڣ�;
                %goto exit_err;
            %end;
            proc sql noprint;
                select * from DICTIONARY.MEMBERS where libname = "&libname_in" and memname = "&memname_in";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: �� &libname_in �߼�����û���ҵ� &memname_in ���ݼ���;
                %goto exit_err;
            %end;
        %end;
    %end;
    %put NOTE: �������ݼ���ָ��Ϊ &libname_in..&memname_in;

    /*VAR*/
    %if %bquote(&var) = %bquote() %then %do;
        %put ERROR: δָ������������;
        %goto exit_err;
    %end;
    %else %do;
        %let var_n = %eval(%sysfunc(count(&var, %bquote( ))) + 1);
        %if &var_n = 1 %then %do;
            %let reg_var_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*)$/);
        %end;
        %else %do;
            %let reg_var_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*)%sysfunc(repeat(\s+([A-Za-z_][A-Za-z_\d]*), %eval(&var_n - 2)))$/);
        %end;
        %let reg_var_id = %sysfunc(prxparse(&reg_var_expr));
        %if %sysfunc(prxmatch(&reg_var_id, &var)) = 0 %then %do;
            %put ERROR: ���� VAR = &var ��ʽ����ȷ��;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_VAR = TRUE;
            /*�жϷ��������Ƿ��ظ�*/
            %do i = 1 %to &var_n;
                %let VAR_&i = %sysfunc(prxposn(&reg_var_id, &i, &var));
                %if &i < &var_n %then %do;
                    %do j = %eval(&i + 1) %to &var_n;
                        %let VAR_&j = %sysfunc(prxposn(&reg_var_id, &j, &var));
                        %if %bquote(&&VAR_&i) = %bquote(&&VAR_&j) %then %do;
                            %put ERROR: �������ظ�ָ���������� &&VAR_&i ��;
                            %goto exit_err;
                        %end;
                    %end;
                %end;
            %end;
            /*�жϷ��������Ƿ����*/
            %do i = 1 %to &var_n;
                %let VAR_&i = %sysfunc(prxposn(&reg_var_id, &i, &var));
                proc sql noprint;
                    select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&&VAR_&i";
                quit;
                %if &SQLOBS = 0 %then %do;
                    %put ERROR: �� &libname_in..&memname_in ��û���ҵ��������� &&VAR_&i;
                    %let IS_VALID_VAR = FALSE;
                %end;
            %end;
            %if &IS_VALID_VAR = FALSE %then %goto exit_err;
        %end;
    %end;

    /*FORMAT*/
    %if %bquote(&format) = %bquote() %then %do;
        %put ERROR: ���� FORMAT Ϊ�գ�;
        %goto exit_err;
    %end;
    %else %do;
        %let format_n = %eval(%sysfunc(count(&format, %bquote( ))) + 1);
        %if &format_n < &var_n %then %do; /*��ʽ�����ڱ�������*/
            %if &format_n = 1 %then %do;
                %put NOTE: ָ�������ʽͳһΪ &format ��;
                %let format = %bquote(&format%sysfunc(repeat(%bquote( &format), %eval(&var_n - 2))));
            %end;
            %else %do;
                %let format = %bquote(&format%sysfunc(repeat(%bquote( %scan(&format, -1, %bquote( ))), %eval(&var_n - &format_n - 1))));
                %put WARNING: ָ���������ʽ�������ڱ���������δƥ��ı�����ʹ�ò��� FORMAT �����һ�������ʽ��;
            %end;
        %end;
        %else %if &format_n > &var_n %then %do;
            %let temp_format = %scan(&format, 1, %bquote( ));
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_format = &temp_format %scan(&format, &i, %bquote( ));
                %end;
            %end;
            %let format = &temp_format;
            %put WARNING: ָ���������ʽ�������ڱ�������������������ʽ�������ԣ�;
        %end;

        %let format_n = %eval(%sysfunc(count(&format, %bquote( ))) + 1);
        %if &format_n = 1 %then %do;
            %let reg_format_expr = %bquote(/^((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)$/);
        %end;
        %else %do;
            %let reg_format_expr = %bquote(/^((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)%sysfunc(repeat(\s+((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*), %eval(&format_n - 2)))$/);
        %end;
        %let reg_format_id = %sysfunc(prxparse(&reg_format_expr));
        %if %sysfunc(prxmatch(&reg_format_id, &format)) = 0 %then %do;
            %put ERROR: ���� FORMAT = &format ��ʽ����ȷ��;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_FORMAT = TRUE;
            %do i = 1 %to &format_n;
                %let FORMAT_&i = %sysfunc(prxposn(&reg_format_id, %eval(2 * &i - 1), &format));
                %let FORMAT_BASE_&i = %sysfunc(prxposn(&reg_format_id, %eval(2 * &i), &format));
                %if %bquote(&&FORMAT_BASE_&i) ^= %bquote() %then %do; /*�����ʽ��������*/
                    proc sql noprint;
                        select * from DICTIONARY.FORMATS where fmtname = "&&FORMAT_BASE_&i" and fmttype = "F";
                    quit;
                    %if &SQLOBS = 0 %then %do;
                        %put ERROR: �����ʽ &&FORMAT_&i �����ڣ�;
                        %let IS_VALID_FORMAT = FALSE;
                    %end;
                %end;
            %end;
        %end;
        %if &IS_VALID_FORMAT = FALSE %then %goto exit_err;
    %end;

    /*BY*/
    %if %bquote(&by) = %bquote() %then %do;
        %put ERROR: ���� BY Ϊ�գ�;
        %goto exit_err;
    %end;
    %else %do;
        %let by_n = %eval(%sysfunc(count(&by, %bquote( ))) + 1);
        %if &by_n < &var_n %then %do; /*����׼�������ڱ�������*/
            %if %bquote(&by) = #FREQ_MIN %then %do;
                %put NOTE: ָ������׼��ͳһΪ &by (��С��������)��;
                %let by = %bquote(&by%sysfunc(repeat(%bquote( &by), %eval(&var_n - 2))));
            %end;
            %else %if %bquote(&by) = #FREQ_MAX %then %do;
                %put NOTE: ָ������׼��ͳһΪ &by (�Ӵ�С����)��;
                %let by = %bquote(&by%sysfunc(repeat(%bquote( &by), %eval(&var_n - 2))));
            %end;
            %else %do;
                %unquote(%nrstr(%%let by =)) %sysfunc(compbl(&by
                                                                %do i = %eval(&by_n + 1) %to &var_n;
                                                                    %bquote( )%scan(&var, &i, %bquote( ))
                                                                %end;
                                                            )
                                                     );
                %put NOTE: ָ�����������(׼��)�������ڷ�������������δƥ��ı��������������ֵ��������;
            %end;
        %end;
        %else %if &by_n > &var_n %then %do; /*����׼�������ڱ�������*/
            %let temp_by = %scan(&by, 1, %bquote( ));
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_by = &temp_by %scan(&by, &i, %bquote( ));
                %end;
            %end;
            %let by = &temp_by;
            %put WARNING: ָ�����������(׼��)�������ڷ�������������������������(׼��)�������ԣ�;
        %end;

        %let by_n = %eval(%sysfunc(count(&by, %bquote( ))) + 1);
        %if &by_n = 1 %then %do;
            %let reg_by_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*(?:\((?:(?:DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?|#FREQ_MIN|#FREQ_MAX)$/);
        %end;
        %else %do;
            %let reg_by_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*(?:\((?:(?:DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?|#FREQ_MIN|#FREQ_MAX)%sysfunc(repeat(\s+([A-Za-z_][A-Za-z_\d]*(?:\((?:(?:DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?|#FREQ_MIN|#FREQ_MAX), %eval(&by_n - 2)))$/);
        %end;
        %let reg_by_id = %sysfunc(prxparse(&reg_by_expr));
        %if %sysfunc(prxmatch(&reg_by_id, &by)) = 0 %then %do;
            %put ERROR: ���� BY = &by ��ʽ����ȷ��;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_BY = TRUE;
            %do i = 1 %to &by_n; /*����������ݵĽ�������������ʹ�õı���������ķ���*/
                %let BY_&i = %sysfunc(prxposn(&reg_by_id, &i, &by));
                %if %bquote(&&BY_&i) ^= #FREQ_MIN and %bquote(&&BY_&i) ^= #FREQ_MAX %then %do;
                    %let reg_by_var_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\((?:(DESC(?:ENDING)?|ASC(?:ENDING)?))?\))?$/);
                    %let reg_by_var_expr_id = %sysfunc(prxparse(&reg_by_var_expr));
                    %if %sysfunc(prxmatch(&reg_by_var_expr_id, &&BY_&i)) %then %do;
                        %let SCEND_BASE_&i = %sysfunc(prxposn(&reg_by_var_expr_id, 1, &&BY_&i)); /*�������ݵı���*/
                        %let SCEND_DIRECTION_&i = %sysfunc(prxposn(&reg_by_var_expr_id, 2, &&BY_&i)); /*������*/
                        
                        %if %bquote(&&SCEND_DIRECTION_&i) = %bquote() %then %do;
                            %put NOTE: δָ��������� &&SCEND_BASE_&i ��������Ĭ���������У�;
                            %let SCEND_DIRECTION_&i = ASC;
                        %end;
                        %else %if %bquote(&&SCEND_DIRECTION_&i) = DESCENDING %then %let SCEND_DIRECTION_&i = DESC;
                        %else %if %bquote(&&SCEND_DIRECTION_&i) = ASCENDING %then %let SCEND_DIRECTION_&i = ASC;
                    %end;
                %end;
                %else %if %bquote(&&BY_&i) = #FREQ_MAX %then %do;
                    %let SCEND_DIRECTION_&i = DESC;
                    %let SCEND_BASE_&i = #FREQ;
                %end;
                %else %if %bquote(&&BY_&i) = #FREQ_MIN %then %do;
                    %let SCEND_DIRECTION_&i = ASC;
                    %let SCEND_BASE_&i = #FREQ;
                %end;
            %end;
            
            %do i = 1 %to &by_n;
                /*�ж���������Ƿ��ظ�*/
                %if &i < &by_n %then %do;
                    %do j = %eval(&i + 1) %to &by_n;
                        %if %bquote(&&SCEND_BASE_&i) ^= #FREQ and %bquote(&&SCEND_BASE_&j) ^= #FREQ and %bquote(&&SCEND_BASE_&i) = %bquote(&&SCEND_BASE_&j) %then %do;
                            %put ERROR: �������ظ�ָ��������� &&SCEND_BASE_&i ��;
                            %let IS_VALID_BY = FALSE;
                        %end;
                    %end;
                %end;
                
                %if %bquote(&&SCEND_BASE_&i) ^= #FREQ %then %do;
                    /*�ж���������Ƿ������������ͻ*/
                    %if %sysfunc(whichc(&&SCEND_BASE_&i, %unquote(%sysfunc(transtrn(&VAR, %bquote( ), %bquote(,)))))) and &&SCEND_BASE_&i ^= &&VAR_&i %then %do;
                        %put ERROR: ������Է������� &&VAR_&i ָ����һ���������� &&SCEND_BASE_&i ��Ϊ���������;
                        %let IS_VALID_BY = FALSE;
                    %end;
                    %else %do;
                        /*�ж���������Ƿ����*/
                        proc sql noprint;
                            select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&&SCEND_BASE_&i";
                        quit;
                        %if &SQLOBS = 0 %then %do;
                            %put ERROR: �� &libname_in..&memname_in ��û���ҵ�������� &&SCEND_BASE_&i;
                            %let IS_VALID_BY = FALSE;
                        %end;
                    %end;
                %end;
            %end;
        %end;
        %if &IS_VALID_BY = FALSE %then %goto exit_err;
    %end;

    /*MISSING*/
    %if %bquote(&missing) = %bquote() %then %do;
        %put ERROR: ���� MISSING Ϊ�գ�;
        %goto exit_err;
    %end;
    %else %do;
        %let missing_n = %eval(%sysfunc(count(&missing, %bquote( ))) + 1);
        %if &missing_n < &var_n %then %do; /*ָ���ġ��Ƿ�ȱʧֵ����Ϊһ�����ͳ�ơ���ʶ�������ڱ�������*/
            %if &missing_n = 1 %then %do;
                %put NOTE: ָ�����Ƿ�ȱʧֵ����Ϊһ�����ͳ�ơ���ʶͳһΪ &missing ��;
                %let missing = %bquote(&missing%sysfunc(repeat(%bquote( &missing), %eval(&var_n - 2))));
            %end;
            %else %do;
                %let missing = %bquote(&missing%sysfunc(repeat(%bquote( %scan(&missing, -1, %bquote( ))), %eval(&var_n - &missing_n - 1))));
                %put WARNING: ָ���ġ��Ƿ�ȱʧֵ����Ϊһ�����ͳ�ơ���ʶ�������ڷ�������������δƥ��ı�����ʹ�ò��� MISSING �����һ����ʶ��ֵ��;
            %end;
        %end;
        %else %if &missing_n > &var_n %then %do; /*ָ���ġ��Ƿ�ȱʧֵ����Ϊһ�����ͳ�ơ���ʶ�������ڱ�������*/
            %let temp_missing = %scan(&missing, 1, %bquote( ));
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_missing = &temp_missing %scan(&missing, &i, %bquote( ));
                %end;
            %end;
            %let missing = &temp_missing;
            %put WARNING: ָ���ġ��Ƿ�ȱʧֵ����Ϊһ�����ͳ�ơ���ʶ�������ڷ�����������������ı�ʶ�������ԣ�;
        %end;

        %let missing_n = %eval(%sysfunc(count(&missing, %bquote( ))) + 1);
        %if &missing_n = 1 %then %do;
            %let reg_missing_expr = %bquote(/^(TRUE|FALSE)$/);
        %end;
        %else %do;
            %let reg_missing_expr = %bquote(/^(TRUE|FALSE)%sysfunc(repeat(\s+(TRUE|FALSE), %eval(&by_n - 2)))$/);
        %end;
        %let reg_missing_id = %sysfunc(prxparse(&reg_missing_expr));
        %if %sysfunc(prxmatch(&reg_missing_id, &missing)) = 0 %then %do;
            %put ERROR: ���� MISSING = &missing ��ʽ����ȷ��;
            %goto exit_err;
        %end;
        %else %do;
            %let IS_VALID_MISSING = TRUE;
            %do i = 1 %to &missing_n;
                %let MISSING_&i = %sysfunc(prxposn(&reg_missing_id, &i, &missing));
            %end;
        %end;
        %if &IS_VALID_MISSING = FALSE %then %goto exit_err;
    %end;

    /*DENOMINATOR*/
    %if %bquote(&denominator) = #AUTO %then %do;
        %if &var_n = 1 %then %do;
            %let denominator = %bquote();
        %end;
        %else %do;
            %let denominator = %sysfunc(strip(%sysfunc(repeat(%bquote( #ALL), %eval(&var_n - 2)))));
        %end;
    %end;
    %if %bquote(&denominator) = %bquote() %then %do;
        %if &var_n = 1 %then %do;
            %let denominator = #ALL;
        %end;
        %else %do;
            %put ERROR: ���� DENOMINATOR Ϊ�գ�;
            %goto exit_err;
        %end;
    %end;
    %else %do;
        %if %bquote(&denominator) = %bquote() %then %do;
            %let denominator_n = 0;
        %end;
        %else %do;
            %let denominator_n = %eval(%sysfunc(count(&denominator, %bquote( ))) + 1);
        %end;
        %if %sysfunc(prxmatch(%bquote(/^\d*(?:\.\d+)?$/), &denominator)) %then %do; /*���� DENOMINATOR ��ָ��Ϊһ����ֵ������������������ʱʹ��*/
            %let denominator = %sysfunc(strip(%sysfunc(repeat(%bquote( &denominator), %eval(&var_n - 1)))));
            %put NOTE: ָ������Ƶ�ʵķ�ĸͳһΪ��ֵ��;
        %end;
        %else %if %eval(&denominator_n + 1) < &var_n %then %do; /*���� DENOMINATOR ָ����ֵ������+1���ڱ�������*/
            %if &denominator = #ALL %then %do;
                %let denominator = %bquote(&denominator%sysfunc(repeat(%bquote( &denominator), %eval(&var_n - 2))));
                %put NOTE: ָ������Ƶ�ʵķ�ĸͳһΪ�ϼ�Ƶ����;
            %end;
            %else %if &denominator = #LAST %then %do;
                %let denominator = %bquote(#ALL%sysfunc(repeat(%bquote( &denominator), %eval(&var_n - 2))));
                %put NOTE: ָ�����ײ��������֮�⣬��������������ڼ���Ƶ�ʵķ�ĸͳһΪ��һ�����������Ƶ����;
            %end;
            %else %do;
                %let denominator = %bquote(#ALL &denominator%sysfunc(repeat(%bquote( #ALL), %eval(&var_n - &denominator_n - 2))));
                %put NOTE: ָ�������ڼ���Ƶ�ʵķ�ĸ�ı���(����)�������ڷ�����������������δƥ��ķ���������ʹ�úϼ�Ƶ����ΪƵ�ʼ���ķ�ĸ��;
            %end;
        %end;
        %else %if %eval(&denominator_n + 1) > &var_n %then %do; /*���� DENOMINATOR ָ����ֵ������+1���ڱ�������*/
            %let temp_denominator = #ALL;
            %if &var_n > 1 %then %do;
                %do i = 2 %to &var_n;
                    %let temp_denominator = &temp_denominator %scan(&denominator, %eval(&i - 1), %bquote( ));
                %end;
            %end;
            %let denominator = &temp_denominator;
            %put WARNING: ָ�������ڼ���Ƶ�ʵķ�ĸ�ı���(����)�������ڷ���������������������ı����������ԣ�;
        %end;
        %else %do; /*���� DENOMINATOR ָ����ֵ������+1���ڱ�������*/
            %let denominator = %sysfunc(strip(%bquote(#ALL &denominator)));
        %end;
    %end;

    %let denominator_n = %eval(%sysfunc(count(&denominator, %bquote( ))) + 1);
    %if &denominator_n = 1 %then %do;
        %let reg_denominator_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*|(\d*(?:\.\d+)?)|#ALL|#LAST)$/);
    %end;
    %else %do;
        %let reg_denominator_expr = %bquote(/^([A-Za-z_][A-Za-z_\d]*|(\d*(?:\.\d+)?)|#ALL|#LAST)%sysfunc(repeat(\s+([A-Za-z_][A-Za-z_\d]*|(\d*(?:\.\d+)?)|#ALL|#LAST), %eval(&denominator_n - 2)))$/);
    %end;
    %let reg_denominator_id = %sysfunc(prxparse(&reg_denominator_expr));
    %if %sysfunc(prxmatch(&reg_denominator_id, &denominator)) = 0 %then %do;
        %put ERROR: ���� DENOMINATOR = &denominator ��ʽ����ȷ��;
        %goto exit_err;
    %end;
    %else %do;
        %let IS_VALID_DENOMINATOR = TRUE;
        %do i = 1 %to &denominator_n;
            %let DENOMINATOR_&i = %sysfunc(prxposn(&reg_denominator_id, %eval(2 * &i - 1), &denominator));
            %let DENOMINATOR_NUM_&i = %sysfunc(prxposn(&reg_denominator_id, %eval(2 * &i), &denominator));
            %if %bquote(&&DENOMINATOR_NUM_&i) ^= %bquote() %then %do; /*ָ��������ĸ����һ����ֵ*/
                %let DENOMINATOR_&i = #NUM;
            %end;
            %else %if &&DENOMINATOR_&i ^= #ALL and &&DENOMINATOR_&i ^= #LAST %then %do; /*ָ��������ĸ����һ������*/
                %if %sysfunc(count(&var, &&DENOMINATOR_&i)) = 0 %then %do;
                    %put ERROR: ������ָ���������� &var ֮��ı��� &&DENOMINATOR_&i ��Ϊ����������� &&VAR_&i ��Ƶ�ʵķ�ĸ��;
                    %let IS_VALID_DENOMINATOR = FALSE;
                %end;
                %else %do;
                    %let DENOMINATOR_LEVEL = %sysfunc(whichc(&&DENOMINATOR_&i, %unquote(%sysfunc(transtrn(&var, %bquote( ), %bquote(,)))))); /*ָ����������ĸ�ı����ڲ��� VAR ��λ��*/
                    %if &DENOMINATOR_LEVEL > &i %then %do;
                        %put ERROR: ������ָ���ϵͲ㼶�ķ������� &&DENOMINATOR_&i ��Ϊ����ϸ߲㼶�ķ������� &&VAR_&i ��Ƶ�ʵķ�ĸ��;
                        %let IS_VALID_DENOMINATOR = FALSE;
                    %end;
                    %else %if &DENOMINATOR_LEVEL = &i %then %do;
                        %put ERROR: ������ָ���������� &&DENOMINATOR_&i ������Ϊ����������� &&VAR_&i ��Ƶ�ʵķ�ĸ��;
                        %let IS_VALID_DENOMINATOR = FALSE;
                    %end;
                %end;
            %end;
        %end;
        %if &IS_VALID_DENOMINATOR = FALSE %then %do;
            %goto exit_err;
        %end;
    %end;


    /*LABEL*/
    %if %bquote(&label) = %bquote() %then %do;
        %put ERROR: ��ͼָ������ LABEL Ϊ�գ�;
        %goto exit_err;
    %end;
    %else %if %nrbquote(%upcase(&label)) = #AUTO %then %do;
        proc sql noprint;
            select
                (case when label ^= "" then cats(label, "-n(%)")
                      else cats(name, "-n(%)") end)
                into: label from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&VAR_1";
        quit;
    %end;
    
    /*IS_LABEL_INDENT*/
    %if %bquote(&IS_LABEL_INDENT) ^= TRUE and %bquote(&IS_LABEL_INDENT) ^= FALSE %then %do;
        %put ERROR: ���� IS_LABEL_INDENT ������ TRUE �� FALSE��;
        %goto exit_err;
    %end;

    /*IS_LABEL_DISPLAY*/
    %if %bquote(&IS_LABEL_DISPLAY) ^= TRUE and %bquote(&IS_LABEL_DISPLAY) ^= FALSE %then %do;
        %put ERROR: ���� IS_LABEL_DISPLAY ������ TRUE �� FALSE��;
        %goto exit_err;
    %end;

    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: ��ͼָ�� OUTDATA Ϊ�գ�;
        %goto exit_err;
    %end;
    %else %if %bquote(&outdata) = #NULL %then %do;
        %put NOTE: ���� OUTDATA ��ָ��Ϊ #NULL����������ᱻ�����;
    %end;
    %else %do;
        %if %bquote(&outdata) = #AUTO %then %do;
            %let outdata = RES_&VAR_1;
        %end;

        %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_outdata_id, &outdata)) = 0 %then %do;
            %put ERROR: ���� OUTDATA = &outdata ��ʽ����ȷ��;
            %goto exit_err;
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
                %goto exit_err;
            %end;
        %end;
        %put NOTE: ������ݼ���ָ��Ϊ &libname_out..&memname_out;
    %end;


    /*DEL_TEMP_DATA*/
    %if %bquote(&DEL_TEMP_DATA) ^= TRUE and %bquote(&DEL_TEMP_DATA) ^= FALSE %then %do;
        %put ERROR: ���� DEL_TEMP_DATA ������ TRUE �� FALSE��;
        %goto exit_err;
    %end;


    /*DEL_DUP_BY_VAR*/
    %if %bquote(&DEL_DUP_BY_VAR) = %bquote() %then %do;
        %put ERROR: ���� DEL_DUP_BY_VAR Ϊ�գ�;
        %goto exit_err;
    %end;
    %else %if %bquote(&DEL_DUP_BY_VAR) ^= #NULL %then %do;
        %if %sysfunc(prxmatch(%bquote(/^[A-Za-z_][A-Za-z_\d]*$/), &DEL_DUP_BY_VAR)) %then %do;
            proc sql noprint;
                select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&DEL_DUP_BY_VAR";
            quit;
            %if &SQLOBS = 0 %then %do;
                %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� &DEL_DUP_BY_VAR;
                %goto exit_err;
            %end;
            %else %if %sysfunc(count(&var, &DEL_DUP_BY_VAR)) > 0 %then %do;
                %put ERROR: ������ָ���������� &DEL_DUP_BY_VAR ��Ϊ����ȥ�صı�����;
                %goto exit_err;
            %end;
        %end;
        %else %do;
            %put ERROR: ���� DEL_DUP_BY_VAR ������һ����������;
            %goto exit_err;
        %end;
    %end;

    /*----------�������в���----------*/
    %if %bquote(&PARAM_LIST_BUFFER) ^= #NULL %then %do;
        %if %symexist(&PARAM_LIST_BUFFER) %then %do;
            %unquote(%nrstr(%%let)) &PARAM_LIST_BUFFER =
                                                        %nrstr(%%let) libname_in = &libname_in%str(;)
                                                        %nrstr(%%let) memname_in = &memname_in%str(;)
                                                        %nrstr(%%let) dataset_options_in = &dataset_options_in%str(;)
                                                        %nrstr(%%let) var_n = &var_n%str(;)
                                                        %do i = 1 %to &var_n;
                                                            %nrstr(%%let) VAR_&i = &&VAR_&i%str(;)
                                                            %nrstr(%%let) FORMAT_&i = &&FORMAT_&i%str(;)
                                                            %nrstr(%%let) SCEND_BASE_&i = &&SCEND_BASE_&i%str(;)
                                                            %nrstr(%%let) SCEND_DIRECTION_&i = &&SCEND_DIRECTION_&i%str(;)
                                                            %nrstr(%%let) MISSING_&i = &&MISSING_&i%str(;)
                                                            %nrstr(%%let) DENOMINATOR_&i = &&DENOMINATOR_&i%str(;)
                                                            %nrstr(%%let) DENOMINATOR_NUM_&i = &&DENOMINATOR_NUM_&i%str(;)
                                                        %end;
                                                        %nrstr(%%let) libname_out = &libname_out%str(;)
                                                        %nrstr(%%let) memname_out = &memname_out%nrstr(;)
                                                        %nrstr(%%let) dataset_options_out = &dataset_options_out%str(;)
                                                        ;
        %end;
        %else %do;
            %put ERROR: δ�������ڽ��մ���֮��Ĳ����б�ĺ������;
            %goto exit_err;
        %end;
    %end;
                           

    /*������ǰ����*/
    %prog:
    /*SKIP_MAIN_PROG*/
    %if %bquote(&SKIP_MAIN_PROG) ^= TRUE and %bquote(&SKIP_MAIN_PROG) ^= FALSE %then %do;
        %put ERROR: ���� SKIP_MAIN_PROG ������ TRUE �� FALSE��;
        %goto exit_err;
    %end;
    %else %if %bquote(&SKIP_MAIN_PROG) = TRUE %then %do;
        %put NOTE: ���ú���� %nrstr(%%desc_coun) ʱʹ�ò��� SKIP_MAIN_PROG = TRUE �������������裡;
        %goto exit;
    %end;

    /*----------�ͷ����в���----------*/
    %if %bquote(&PARAM_LIST_BUFFER) ^= #NULL %then %do;
        %unquote(&&&PARAM_LIST_BUFFER)
    %end;

    /*----------------------------------------------������----------------------------------------------*/
    /*0.�ظ�ֵ�޳�*/
    %if &DEL_DUP_BY_VAR ^= #NULL %then %do;
        %do i = 1 %to &var_n;
            proc sort data = &libname_in..&memname_in%if %bquote(&dataset_options_in) ^= %bquote() %then %do;(&dataset_options_in)%end;
                      out = temp_nodup_&&VAR_&i nodupkey;
                by &DEL_DUP_BY_VAR %do j = 1 %to &i; %bquote( &&VAR_&j) %end;;
            run;
        %end;
    %end;


    /*1.���ɸ��㼶��Ƶ����*/
    proc sql noprint;
        %do i = 1 %to &var_n;
            %unquote(%nrstr(%%let MISSING_STRATA_CAT =)) %sysfunc(catx(%bquote( ) %unquote(%do j = 1 %to &i; %bquote(,)%bquote(&&MISSING_&j) %end;))); /*ǰi��MISSING��ֵ*/
            create table temp_strata_freq_&&VAR_&i as
                select
                    distinct
                    &i as STRATA label = "�㼶", /*�ñ�����������*/
                    %do j = 1 %to &i;
                        (case when &j = &i then 1 else 0 end) as &&VAR_&j.._LV label = "&&VAR_&j.._LV", /*�ñ�����������ȷ������ĺϼƽ������ϸ�������ǰ��*/
                    %end;
                    %sysfunc(catx(%bquote(, ) %unquote(%do j = 1 %to &i; %bquote(, &&VAR_&j) %end;))),
                    %do j = 1 %to &i;
                        %if &&SCEND_BASE_&j ^= #FREQ and &&SCEND_BASE_&j ^= &&VAR_&j %then %do;
                            %bquote(&&SCEND_BASE_&j,)
                        %end;
                    %end;
                    count(*)    as FREQ    label = "Ƶ��"
                from %if &DEL_DUP_BY_VAR = #NULL %then %do;
                         &libname_in..&memname_in%if %bquote(&dataset_options_in) ^= %bquote() %then %do;(&dataset_options_in)%end;
                     %end;
                     %else %do;
                         temp_nodup_&&VAR_&i
                     %end;
                %if %sysfunc(count(&MISSING_STRATA_CAT, FALSE)) > 0 %then %do;
                    where
                        %sysfunc(catx(%bquote( and ) %unquote(
                                                              %do j = 1 %to &var_n;
                                                                  %if &&MISSING_&j = FALSE %then %do;
                                                                      %bquote(,)%bquote(not missing(&&VAR_&j))
                                                                  %end;
                                                              %end;
                                                             )
                                     )
                                )
                %end;
                group by %sysfunc(catx(%bquote(, ) %unquote(%do j = 1 %to &i; %bquote(,)%bquote(&&VAR_&j) %end;)))
                ;
        %end;
    quit;

    /*2. ������㼶��Ƶ�ʣ�Ӧ��format*/
    proc sql noprint;
        select sum(FREQ) into: GRN_ALL from temp_strata_freq_&VAR_1; /*Ƶ���ϼ�*/
        %do i = 1 %to &var_n;
            %if &&DENOMINATOR_&i ^= #ALL and &&DENOMINATOR_&i ^= #NUM %then %do;
                %if &&DENOMINATOR_&i = #LAST %then %do;
                    %let DENOMINATOR_SRTATA_N = %eval(&i - 1); /*���ڵķ�ĸ�Ĳ���*/
                %end;
                %else %do;
                    %let DENOMINATOR_SRTATA_N = %sysfunc(whichc(&&DENOMINATOR_&i, %unquote(%sysfunc(transtrn(&VAR, %bquote( ), %bquote(,)))))); /*���ڵķ�ĸ�Ĳ���*/
                %end;
                %do j = 1 %to &DENOMINATOR_SRTATA_N;
                    %let DENOMINATOR_SRTATA_&j = &&VAR_&j; /*���ڵķ�ĸ�Ĳ㼶*/
                %end;
            %end;
            create table temp_strata_pct_&&VAR_&i as
                select
                    a.*,
                    %if &&DENOMINATOR_&i = #ALL %then %do;
                        a.FREQ/&GRN_ALL as FREQPCT label = "�ٷֱ�",
                        put(a.FREQ/&GRN_ALL, &&FORMAT_&i) as FREQPCTC label = "�ٷֱȣ�C��"
                    %end;
                    %else %if &&DENOMINATOR_&i = #NUM %then %do;
                        a.FREQ/&&DENOMINATOR_NUM_&i as FREQPCT label = "�ٷֱ�",
                        put(a.FREQ/&&DENOMINATOR_NUM_&i, &&FORMAT_&i) as FREQPCTC label = "�ٷֱȣ�C��"
                    %end;
                    %else %if &&DENOMINATOR_&i = #LAST %then %do;
                        a.FREQ/b.FREQ as FREQPCT label = "�ٷֱ�",
                        put(a.FREQ/b.FREQ, &&FORMAT_&i) as FREQPCTC label = "�ٷֱȣ�C��"
                    %end;
                    %else %do;
                        a.FREQ/b.FREQ as FREQPCT label = "�ٷֱ�",
                        put(a.FREQ/b.FREQ, &&FORMAT_&i) as FREQPCTC label = "�ٷֱȣ�C��"
                    %end;
                from temp_strata_freq_&&VAR_&i as a %if &&DENOMINATOR_&i ^= #ALL  and &&DENOMINATOR_&i ^= #NUM %then %do;
                                                        left join %if &&DENOMINATOR_&i = #LAST %then %do;
                                                                      %unquote(temp_strata_freq_%nrbquote(&&)VAR_%eval(&i - 1)) as b
                                                                  %end;
                                                                  %else %do;
                                                                      temp_strata_freq_&&DENOMINATOR_&i as b
                                                                  %end;
                                                                  on %do j = 1 %to &DENOMINATOR_SRTATA_N;
                                                                         %if &j < &DENOMINATOR_SRTATA_N %then %do;
                                                                             a.&&DENOMINATOR_SRTATA_&j = b.&&DENOMINATOR_SRTATA_&j and 
                                                                         %end;
                                                                         %else %do;
                                                                             a.&&DENOMINATOR_SRTATA_&j = b.&&DENOMINATOR_SRTATA_&j
                                                                         %end;
                                                                     %end;
                                                    %end;
                ;
        %end;
    quit;

    /*3. �ϲ����㼶��Ƶ��Ƶ�ʱ�*/
    proc sql noprint;
        create table temp_union as
            %sysfunc(catx(%bquote( outer union corr ) %unquote(
                                                               %do i = 1 %to &var_n;
                                                                   %bquote(,)%bquote(select * from temp_strata_pct_&&VAR_&i)
                                                               %end;
                                                               )
                         )
                    );
    quit;

    /*4. �����㼶��Ƶ����������������ĵ�������*/
    /*���磺����ĳ���۲��ĳһ������������Ӧ����������ֵΪ�ù۲�����һ����������ˮƽ�ϵ�Ƶ�������۸ù۲��ʱ������һ�㼶��*/
    proc sql noprint;
        create table temp_union_freq as
            select
                temp_union.*,
                %do i = 1 %to &var_n;
                    %if &i < &var_n %then %do;
                        temp_strata_freq_&&VAR_&i...FREQ as &&VAR_&i.._FQ label = "&&VAR_&i.._FQ",
                    %end;
                    %else %do;
                        temp_strata_freq_&&VAR_&i...FREQ as &&VAR_&i.._FQ label = "&&VAR_&i.._FQ"
                    %end;
                %end;
            from temp_union %do i = 1 %to &var_n;
                                left join temp_strata_freq_&&VAR_&i on 
                                %do j = 1 %to &i;
                                    %if &j < &i %then %do;
                                        temp_union.&&VAR_&j = temp_strata_freq_&&VAR_&i...&&VAR_&j and 
                                    %end;
                                    %else %do;
                                        temp_union.&&VAR_&j = temp_strata_freq_&&VAR_&i...&&VAR_&j
                                    %end;
                                %end;
                            %end;
            ;
    quit;

    /*5. �����㼶��ˮƽ���Ƹ��ݲ���INDENT��IS_LABEL_INDENT���룬�����������(����)�����Ƶ����Ƶ��*/
    proc sql noprint;
        create table temp_align as
            select
                *,
                (case
                    %if &IS_LABEL_INDENT = TRUE %then %do; /*�ײ�����*/
                        %do i = 1 %to &var_n;
                            when strata = &i then cat(repeat("&INDENT", %eval(&i - 1)), cats(&&VAR_&i))
                        %end;
                    %end;
                    %else %do; /*�ײ㲻����*/
                        when strata = 1 then cats(&VAR_1)
                        %do i = 2 %to &var_n;
                            when strata = &i then cat(repeat("&INDENT", %eval(&i - 2)), cats(&&VAR_&i))
                        %end;
                    %end;
                end)                           as ITEM  label = "ָ��",
                cats(FREQ, "(", FREQPCTC, ")") as VALUE label = "ָ��ֵ"
            from temp_union_freq;
    quit;
    

    /*6. ��ָ��˳������*/
    proc sql noprint;
        create table temp_sort as
            select * from temp_align
                order by %sysfunc(catx(%bquote(, ) %unquote(
                                                               %do i = 1 %to &var_n;
                                                                   %if &&SCEND_BASE_&i = #FREQ %then %do;
                                                                       %bquote(,)%bquote(&&VAR_&i.._FQ &&SCEND_DIRECTION_&i)
                                                                   %end;
                                                                   %else %do;
                                                                       %bquote(,)%bquote(&&SCEND_BASE_&i &&SCEND_DIRECTION_&i)
                                                                   %end;
                                                                       %bquote(,)%bquote(&&VAR_&i)%bquote(,)%bquote(&&VAR_&i.._LV DESC)
                                                               %end;
                                                           )
                                      )
                                 );
    quit;

    /*7. ��ӻ���� LABEL */
    %if &IS_LABEL_DISPLAY = TRUE %then %do; /*����ʾ��ǩ, ����������� TEMP_LABEL ���ݼ�, ��ʡ��Դ*/
        data temp_label;
            ITEM = "&label";
        run;
    %end;
    proc sql noprint;
        create table temp_add_label as
            %if &IS_LABEL_DISPLAY = TRUE %then %do; /*����ʾ��ǩ*/
                select * from temp_label
                outer union corr
            %end;
            select
                *
            from temp_sort;
    quit;

    /*8. ������ݼ�*/
    %if %bquote(&outdata) ^= #NULL %then %do;
        %if &libname_in = &libname_out and &memname_in = &memname_out %then %do;
            %put WARNING: ָ����������ݼ���������ݼ�һ�£�&libname_in..&memname_in �������ǣ�;
        %end;
        data &libname_out..&memname_out(%if %bquote(&dataset_options_out) = %bquote() %then %do;
                                            keep = item value
                                        %end;
                                        %else %do;
                                            &dataset_options_out
                                        %end;);
            set temp_add_label;
        run;
    %end;

    /*----------------------------------------------���к���----------------------------------------------*/
    %if &DEL_TEMP_DATA = TRUE %then %do;
        proc datasets noprint nowarn; /*ɾ����ʱ���ݼ�*/
            delete %do i = 1 %to &var_n;
                       temp_nodup_&&VAR_&i
                       temp_strata_freq_&&VAR_&i
                       temp_strata_pct_&&VAR_&i
                   %end;
                   temp_union
                   temp_union_freq
                   temp_align
                   temp_sort
                   temp_label
                   temp_add_label
                   ;
        quit;
    %end;
    %goto exit;


    /*�쳣�˳�*/
    %exit_err:
    %if &PARAM_VALID_FLAG_VAR ^= #NULL %then %do;
        %if %symexist(&PARAM_VALID_FLAG_VAR) %then %do;
            %let &PARAM_VALID_FLAG_VAR = FALSE;
        %end;
        %else %do;
            %put ERROR: δ�������ڱ�ʾ������Ϸ��Եĺ������;
            %goto exit;
        %end;
    %end;

    /*�����˳�*/
    %exit:
    %put NOTE: �� desc_coun �ѽ������У�;
%mend;
