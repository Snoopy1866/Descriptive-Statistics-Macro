/*
===================================
Macro Name: cross_table
Macro Label:����������
Author: wtwang
Version Date: 2025-04-02
===================================
*/

%macro cross_table(indata,
                   rowcat,
                   colcat,
                   outdata,
                   rowcat_by       = #auto,
                   colcat_by       = #auto,
                   n               = #auto,
                   add_cat_missing = false false,
                   add_cat_other   = false false,
                   add_cat_all     = true true,
                   pct_out         = false,
                   format          = PERCENTN9.2,
                   debug          = false) /des = "����������" parmbuff;

    /*�򿪰����ĵ�*/
    %if %qupcase(&SYSPBUFF) = %bquote((HELP)) or %qupcase(&SYSPBUFF) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/cross_table/readme.md";
        %goto exit;
    %end;


    /*ͳһ������Сд*/
    %let indata          = %sysfunc(strip(%bquote(&indata)));
    %let rowcat          = %sysfunc(strip(%bquote(&rowcat)));
    %let colcat          = %sysfunc(strip(%bquote(&colcat)));
    %let outdata         = %sysfunc(strip(%bquote(&outdata)));
    %let rowcat_by       = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&rowcat_by)))))));
    %let colcat_by       = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&colcat_by)))))));
    %let n               = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&n)))))));
    %let add_cat_missing = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&add_cat_missing)))))));
    %let add_cat_other   = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&add_cat_other)))))));
    %let add_cat_all     = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&add_cat_all)))))));
    %let pct_out         = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&pct_out)))))));
    %let format          = %upcase(%sysfunc(strip(%bquote(%sysfunc(compbl(%bquote(&format)))))));
    %let debug   = %upcase(%sysfunc(strip(%bquote(&debug))));

    /*�����ֲ�����*/
    %local i j;



    /*-------------------------------------------�������-------------------------------------------*/
    /*INDATA*/
    %if %bquote(&indata) = %bquote() %then %do;
        %put ERROR: δָ���������ݼ���;
        %goto exit;
    %end;
    %else %do;
        %let reg_indata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
        %if %sysfunc(prxmatch(&reg_indata_id, &indata)) = 0 %then %do;
            %put ERROR: ���� INDATA = &indata ��ʽ����ȷ��;
            %goto exit;
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


    /*ROWCAT*/
    %if %bquote(&rowcat) = %bquote() %then %do;
        %put ERROR: δָ��������������б�������;
        %goto exit;
    %end;

    %let IS_ROW_CAT_SPECIFIED = FALSE;
    %let reg_rowcat = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\((\s*".*"(?:[\s,]+".*")*\s*)?\))?$/);
    %let reg_rowcat_id = %sysfunc(prxparse(&reg_rowcat));
    %if %sysfunc(prxmatch(&reg_rowcat_id, &rowcat)) = 0 %then %do;
        %put ERROR: ���� ROWCAT = &rowcat ��ʽ����ȷ��;
        %goto exit;
    %end;
    %else %do;
        %let row_var = %upcase(%sysfunc(prxposn(&reg_rowcat_id, 1, &rowcat))); /*�б���*/
        %let row_val = %sysfunc(prxposn(&reg_rowcat_id, 2, &rowcat)); /*�з���*/
        proc sql noprint;
            select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&row_var";
        quit;
        %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
            %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� %upcase(&row_var);
            %goto exit;
        %end;
        %else %do;
            %if %bquote(&row_val) = %bquote() %then %do; /*δָ�������ֵ*/
                proc sql noprint;
                    select distinct cats("""", &row_var, """") into :row_val separated by "," from &indata where not missing(&row_var);
                quit;
            %end;
            %else %do; /*ָ���˷����ֵ*/
                %let IS_ROW_CAT_SPECIFIED = TRUE;
            %end;
        %end;
    %end;



    /*COLCAT*/
    %if %bquote(&colcat) = %bquote() %then %do;
        %put ERROR: δָ��������������б�������;
        %goto exit;
    %end;

    %let IS_COL_CAT_SPECIFIED = FALSE;
    %let reg_colcat = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\((\s*".*"(?:[\s,]+".*")*\s*)?\))?$/);
    %let reg_colcat_id = %sysfunc(prxparse(&reg_colcat));
    %if %sysfunc(prxmatch(&reg_colcat_id, &colcat)) = 0 %then %do;
        %put ERROR: ���� COLCAT = &colcat ��ʽ����ȷ��;
        %goto exit;
    %end;
    %else %do;
        %let col_var = %upcase(%sysfunc(prxposn(&reg_colcat_id, 1, &colcat))); /*�б���*/
        %let col_val = %sysfunc(prxposn(&reg_colcat_id, 2, &colcat)); /*�з���*/
        %if &row_var = &col_var %then %do;
            %put WARNING: ����������б�����ͬ�������������Ƿ�Ԥ�ڵģ�;
        %end;
        proc sql noprint;
            select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&col_var";
        quit;
        %if &SQLOBS = 0 %then %do; /*���ݼ���û���ҵ�����*/
            %put ERROR: �� &libname_in..&memname_in ��û���ҵ����� %upcase(&col_var);
            %goto exit;
        %end;
        %else %do;
            %if %bquote(&col_val) = %bquote() %then %do; /*δָ�������ֵ*/
                proc sql noprint;
                    select distinct cats("""", &col_var, """") into :col_val separated by "," from &indata where not missing(&col_var);
                quit;
            %end;
            %else %do; /*ָ���˷����ֵ*/
                %let IS_COL_CAT_SPECIFIED = TRUE;
            %end;
        %end;
    %end;


    /*OUTDATA*/
    %if %bquote(&outdata) = %bquote() %then %do;
        %put ERROR: ��ͼָ�� OUTDATA Ϊ�գ�;
        %goto exit;
    %end;
    %else %if %bquote(&outdata) = #AUTO %then %do;
        %let outdata = RES_&VAR_1;
    %end;

    %let reg_outdata_id = %sysfunc(prxparse(%bquote(/^(?:([A-Za-z_][A-Za-z_\d]*)\.)?([A-Za-z_][A-Za-z_\d]*)(?:\((.*)\))?$/)));
    %if %sysfunc(prxmatch(&reg_outdata_id, &outdata)) = 0 %then %do;
        %put ERROR: ���� OUTDATA = &outdata ��ʽ����ȷ��;
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


    /*ROWCAT_BY*/
    %if &IS_ROW_CAT_SPECIFIED = TRUE %then %do; /*������ͻ�ж�*/
        %if %bquote(&rowcat_by) ^= #AUTO %then %do;
            %put WARNING: ��ͨ������ ROWCAT ָ�����з���ĳ���˳�򣬲��� ROWCAT_BY ��ֵ�ѱ����ԣ�;
        %end;
    %end;
    %else %do;
        %if %bquote(&rowcat_by) = %bquote() %then %do; /*��ֵ�ж�*/
            %put ERROR: ��ͼָ������ ROWCAT_BY Ϊ�գ�;
            %goto exit;
        %end;
        %else %if %bquote(&rowcat_by) ^= #AUTO %then %do;
            %let reg_rowcat_by = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:ASC|DESC)(?:ENDING)?)?\))?$/);
            %let reg_rowcat_by_id = %sysfunc(prxparse(&reg_rowcat_by));
            %if %sysfunc(prxmatch(&reg_rowcat_by_id, &rowcat_by)) = 0 %then %do; /*�﷨��ʽ�ж�*/
                %put ERROR: ���� ROWCAT_BY ��ʽ����ȷ��;
                %goto exit;
            %end;
            %else %do;
                %let rowcat_by_var = %sysfunc(prxposn(&reg_rowcat_by_id, 1, &rowcat_by));
                %let rowcat_by_direction = %sysfunc(prxposn(&reg_rowcat_by_id, 2, &rowcat_by));
                
                %if &rowcat_by_var = &row_var %then %do; /*�б���������Ϊ�������������warning*/
                    %put WARNING: Ϊ�б��� &row_var ָ����������Ϊ��������ı�����;
                %end;
                %else %do;
                    proc sql noprint;
                        select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&rowcat_by_var";
                    quit;
                    %if &SQLOBS = 0 %then %do; /*�����������ж�*/
                        %put ERROR: �� &libname_in..&memname_in ��û���ҵ����ڶ��з�������ı��� &rowcat_by_var;
                        %goto exit;
                    %end;
                    %else %do;
                        %if &rowcat_by_direction = %bquote() %then %do;
                            %put NOTE: δָ���з����������Ĭ���������У�;
                            %let rowcat_by_direction = ASC;
                        %end;
                        %else %if &rowcat_by_direction = ASCENDING %then %do;
                            %let rowcat_by_direction = ASC;
                        %end;
                        %else %if &rowcat_by_direction = DESCENDING %then %do;
                            %let rowcat_by_direction = DESC;
                        %end;
                    %end;
                %end;
            %end;
        %end;
    %end;



    /*COLCAT_BY*/
    %if &IS_COL_CAT_SPECIFIED = TRUE %then %do; /*������ͻ�ж�*/
        %if %bquote(&colcat_by) ^= #AUTO %then %do;
            %put WARNING: ��ͨ������ COLCAT ָ�����з���ĳ���˳�򣬲��� COLCAT_BY ��ֵ�ѱ����ԣ�;
        %end;
    %end;
    %else %do;
        %if %bquote(&colcat_by) = %bquote() %then %do; /*��ֵ�ж�*/
            %put ERROR: ��ͼָ������ COLCAT_BY Ϊ�գ�;
            %goto exit;
        %end;
        %else %if %bquote(&colcat_by) ^= #AUTO %then %do;
            %let reg_colcat_by = %bquote(/^([A-Za-z_][A-Za-z_\d]*)(?:\(((?:ASC|DESC)(?:ENDING)?)?\))?$/);
            %let reg_colcat_by_id = %sysfunc(prxparse(&reg_colcat_by));
            %if %sysfunc(prxmatch(&reg_colcat_by_id, &colcat_by)) = 0 %then %do; /*�﷨��ʽ�ж�*/
                %put ERROR: ���� COLCAT_BY ��ʽ����ȷ��;
                %goto exit;
            %end;
            %else %do;
                %let colcat_by_var = %sysfunc(prxposn(&reg_colcat_by_id, 1, &colcat_by));
                %let colcat_by_direction = %sysfunc(prxposn(&reg_colcat_by_id, 2, &colcat_by));
                
                %if &colcat_by_var = &col_var %then %do; /*�б���������Ϊ�������������warning*/
                    %put WARNING: Ϊ�б��� &col_var ָ����������Ϊ��������ı�����;
                %end;
                %else %do;
                    proc sql noprint;
                        select * from DICTIONARY.COLUMNS where libname = "&libname_in" and memname = "&memname_in" and upcase(name) = "&colcat_by_var";
                    quit;
                    %if &SQLOBS = 0 %then %do; /*�����������ж�*/
                        %put ERROR: �� &libname_in..&memname_in ��û���ҵ����ڶ��з�������ı��� &colcat_by_var;
                        %goto exit;
                    %end;
                    %else %do;
                        %if &colcat_by_direction = %bquote() %then %do;
                            %put NOTE: δָ���з����������Ĭ���������У�;
                            %let colcat_by_direction = ASC;
                        %end;
                        %else %if &colcat_by_direction = ASCENDING %then %do;
                            %let colcat_by_direction = ASC;
                        %end;
                        %else %if &colcat_by_direction = DESCENDING %then %do;
                            %let colcat_by_direction = DESC;
                        %end;
                    %end;
                %end;
            %end;
        %end;
    %end;



    /*ADD_CAT_MISSING*/
    %if %bquote(&add_cat_missing) = %bquote() %then %do;
        %put ERROR: ��ͼָ������ ADD_CAT_MISSING Ϊ�գ�;
        %goto exit;
    %end;

    %let reg_add_cat_missing = %bquote(/^(TRUE|FALSE)(?:\s(TRUE|FALSE))?$/);
    %let reg_add_cat_missing_id = %sysfunc(prxparse(&reg_add_cat_missing));
    %if %sysfunc(prxmatch(&reg_add_cat_missing_id, &add_cat_missing)) = 0 %then %do;
        %put ERROR: ���� ADD_CAT_MISSING ��ʽ����ȷ��;
        %goto exit;
    %end;
    %else %do;
        %let add_cat_missing_row = %sysfunc(prxposn(&reg_add_cat_missing_id, 1, &add_cat_missing));
        %let add_cat_missing_col = %sysfunc(prxposn(&reg_add_cat_missing_id, 2, &add_cat_missing));

        %if %bquote(&add_cat_missing_col) = %bquote() %then %do;
            %let add_cat_missing_col = &add_cat_missing_row;
            %put NOTE: ���� ADD_CAT_MISSING δָ���б����Ƿ���㡰ȱʧ�����࣬Ĭ�����б���һ�£�;
        %end;
    %end;


    /*ADD_CAT_OTHER*/
    %if %bquote(&add_cat_other) = %bquote() %then %do;
        %put ERROR: ��ͼָ������ ADD_CAT_OTHER Ϊ�գ�;
        %goto exit;
    %end;

    %let reg_add_cat_other = %bquote(/^(TRUE(?:\((?:\s?TYPE\s?=\s?([12])\s?)?\))?|FALSE)(?:\s(TRUE(?:\((?:\s?TYPE\s?=\s?([12])\s?)?\))?|FALSE))?$/);
    %let reg_add_cat_other_id = %sysfunc(prxparse(&reg_add_cat_other));
    %if %sysfunc(prxmatch(&reg_add_cat_other_id, &add_cat_other)) = 0 %then %do;
        %put ERROR: ���� ADD_CAT_OTHER ��ʽ����ȷ��;
        %goto exit;
    %end;
    %else %do;
        %let add_cat_other_row = %sysfunc(prxposn(&reg_add_cat_other_id, 1, &add_cat_other));
        %let add_cat_other_row_type = %sysfunc(prxposn(&reg_add_cat_other_id, 2, &add_cat_other));
        %let add_cat_other_col = %sysfunc(prxposn(&reg_add_cat_other_id, 3, &add_cat_other));
        %let add_cat_other_col_type = %sysfunc(prxposn(&reg_add_cat_other_id, 4, &add_cat_other));

        %if %bquote(&add_cat_other_row) ^= %bquote() and %bquote(&add_cat_other_row) ^= FALSE %then %do;
            %let add_cat_other_row = TRUE;
        %end;
        %if %bquote(&add_cat_other_col) ^= %bquote() and %bquote(&add_cat_other_col) ^= FALSE %then %do;
            %let add_cat_other_col = TRUE;
        %end;

        %if %bquote(&add_cat_other_row) = TRUE and %bquote(&add_cat_other_row_type) = %bquote() %then %do;
            %let add_cat_other_row_type = 1;
            %put NOTE: ���� ADD_CAT_OTHER δָ���б������㡰����������ľ������ͣ�Ĭ��ָ�� TYPE = 1��ȱʧֵ�������б����ġ����������࣡;
        %end;

        %if %bquote(&add_cat_other_col) = %bquote() %then %do;
            %let add_cat_other_col = &add_cat_other_row;
            %let add_cat_other_col_type = &add_cat_other_row_type;
            %put NOTE: ���� ADD_CAT_OTHER δָ���б����Ƿ���㡰���������༰�������ͣ�Ĭ�����б���һ�£�;
        %end;

        %if %bquote(&add_cat_other_col) = TRUE and %bquote(&add_cat_other_col_type) = %bquote() %then %do;
            %let add_cat_other_col_type = 1;
            %put NOTE: ���� ADD_CAT_OTHER δָ���б������㡰����������ľ������ͣ�Ĭ��ָ�� TYPE = 1��ȱʧֵ�������б����ġ����������࣡;
        %end;
    %end;


    /*ADD_CAT_ALL*/
    %if %bquote(&add_cat_all) = %bquote() %then %do;
        %put ERROR: ��ͼָ������ ADD_CAT_ALL Ϊ�գ�;
        %goto exit;
    %end;

    %let reg_add_cat_all = %bquote(/^(TRUE|FALSE)(?:\s(TRUE|FALSE))?$/);
    %let reg_add_cat_all_id = %sysfunc(prxparse(&reg_add_cat_all));
    %if %sysfunc(prxmatch(&reg_add_cat_all_id, &add_cat_all)) = 0 %then %do;
        %put ERROR: ���� ADD_CAT_ALL ��ʽ����ȷ��;
        %goto exit;
    %end;
    %else %do;
        %let add_cat_all_row = %sysfunc(prxposn(&reg_add_cat_all_id, 1, &add_cat_all));
        %let add_cat_all_col = %sysfunc(prxposn(&reg_add_cat_all_id, 2, &add_cat_all));

        %if %bquote(&add_cat_all_col) = %bquote() %then %do;
            %let add_cat_all_col = &add_cat_all_row;
            %put NOTE: ���� ADD_CAT_ALL δָ���б����Ƿ���㡰�ϼơ����࣬Ĭ�����б���һ�£�;
        %end;
    %end;



    /*N*/
    proc sql noprint;
        select count(*) into :n_obs from &indata
        %if &add_cat_missing_row = FALSE and &add_cat_missing_col = FALSE %then %do;
            where not (missing(&row_var) and missing(&col_var))
        %end;
        ; /*�۲���*/
    quit;
    %if %bquote(&n) = #AUTO %then %do;
        %let n = &n_obs;
    %end;
    %else %do;
        %if %bquote(&n) = %bquote() %then %do;
            %put ERROR: ��ͼָ������ N Ϊ�գ�;
            %goto exit;
        %end;
        %else %do;
            %let reg_n = %bquote(/^(?:\d*\.?\d*|-(?:\d+(?:\.\d*)?|\.\d*))$/);
            %let reg_n_id = %sysfunc(prxparse(&reg_n));
            %if %sysfunc(prxmatch(&reg_n_id, &n)) = 0 %then %do;
                %put ERROR: ���� N ��ʽ����ȷ��;
                %goto exit;
            %end;
            %else %do;
                %if %sysevalf(&n < 0) %then %do;
                    %put WARNING: ���� N ָ����һ��������Ϊ�ϼ�Ƶ����;
                %end;
                %else %if %sysevalf(&n = 0) %then %do;
                    %put WARNING: ���� N ָ����ֵ 0 ��Ϊ�ϼ�Ƶ����;
                %end;
                %else %if %sysevalf(%sysfunc(mod(&n, 1)) ^= 0) %then %do;
                    %put WARNING: ���� N ָ����һ����������Ϊ�ϼ�Ƶ����;
                %end;
                %else %if %sysevalf(&n < &n_obs) %then %do;
                    %put WARNING: ���� N ָ���ĺϼ�Ƶ��С�����ݼ� &libname_in..&memname_in �Ĺ۲�����;
                %end;
            %end;
        %end;
    %end;


    /*PCT_OUT*/
    %if %bquote(&pct_out) = %bquote() %then %do;
        %put ERROR: ��ͼָ������ PCT_OUT Ϊ�գ�;
        %goto exit;
    %end;
    %else %if %bquote(&pct_out) ^= TRUE and %bquote(&pct_out) ^= FALSE %then %do;
        %put ERROR: ���� PCT_OUT ������ TRUE �� FALSE ����֮һ��;
        %goto exit;
    %end;

    


    /*FORMAT*/
    %if %bquote(&pct_out) = FALSE %then %do;
        %if %bquote(&format) ^= PERCENTN9.2 %then %do;
            %put WARNING: ���� PCT_OUT �ѱ�ָ��Ϊ FALSE, ���� FORMAT ��ֵ�������ԣ�;
        %end;
    %end;
    %else %do;
        %if %bquote(&format) = %bquote() %then %do;
            %put ERROR: ��ͼָ������ FORMAT Ϊ�գ�;
            %goto exit;
        %end;
        %else %do;
            %let reg_format = %bquote(/^((\$?[A-Za-z_]+(?:\d+[A-Za-z_]+)?)(?:\.|\d+\.\d*)|\$\d+\.|\d+\.\d*)$/);
            %let reg_format_id = %sysfunc(prxparse(&reg_format));
            %if %sysfunc(prxmatch(&reg_format_id, &format)) = 0 %then %do;
                %put ERROR: ���� FORMAT ��ʽ����ȷ��;
                %goto exit;
            %end;
            %else %do;
                %let format_base = %sysfunc(prxposn(&reg_format_id, 2, &format));
                %if %bquote(&format_base) ^= %bquote() %then %do;
                    proc sql noprint;
                        select * from DICTIONARY.FORMATS where fmtname = "&format_base" and fmttype = "F";
                    quit;
                    %if &SQLOBS = 0 %then %do;
                        %put ERROR: �����ʽ &format �����ڣ�;
                        %goto exit;
                    %end;
                %end;
            %end;
        %end;
    %end;

    
    /*debug*/
    %if %bquote(&debug) ^= TRUE and %bquote(&debug) ^= FALSE %then %do;
        %put ERROR: ����debugA ������ TRUE �� FALSE��;
        %goto exit;
    %end;

    /*-------------------------------------------������-------------------------------------------*/
    
    /*1. �з��������������*/
    %if &IS_ROW_CAT_SPECIFIED = FALSE and %bquote(&rowcat_by) ^= #AUTO %then %do;
        /*ָ��������������з����˳�����*/
        proc sql noprint;
            create table temp_rowcat as
                select
                    distinct
                    &row_var as ROWCAT,
                    &rowcat_by_var as ROWCAT_BY
                from &indata where not missing(&row_var)
                order by &rowcat_by_var &rowcat_by_direction, &row_var;

            %let row_cat_n = &SQLOBS;
            %do i = 1 %to &row_cat_n;
                select distinct cats("""", ROWCAT, """") into :row_&i separated by " " from temp_rowcat(firstobs = &i obs = &i);
            %end;
        quit;
    %end;
    %else %do;
        /*ֱ��ָ������ֵ�����rowval�ķ���*/
        %let row_cat_n = %sysfunc(kcountw(%bquote(&row_val), %bquote(,), qs));
        %do i = 1 %to &row_cat_n;
            %let row_&i = %sysfunc(kscanx(%bquote(&row_val), &i, %bquote(,), qs));
        %end;
    %end;
    
    /*row_cat_n:�����������row_n:�������������*/
    %let row_n = &row_cat_n;
    %if &add_cat_missing_row = TRUE %then %do;
        %let row_n = %eval(&row_n + 1);
        %let row_&row_n = #MISSING;
    %end;
    %if &add_cat_other_row = TRUE %then %do;
        %let row_n = %eval(&row_n + 1);
        %if &add_cat_other_row_type = 1 %then %do;
            %let row_&row_n = #OTHER#1;
        %end;
        %else %if &add_cat_other_row_type = 2 %then %do;
            %let row_&row_n = #OTHER#2;
        %end;
    %end;
    %if &add_cat_all_row = TRUE %then %do;
        %let row_n = %eval(&row_n + 1);
        %let row_&row_n = #ALL;
    %end;


    /*2. �з��������������*/
    %if &IS_COL_CAT_SPECIFIED = FALSE and %bquote(&colcat_by) ^= #AUTO %then %do;
        /*ָ��������������з����˳�����*/
        proc sql noprint;
            create table temp_colcat as
                select
                    distinct
                    &col_var as COLCAT,
                    &colcat_by_var as COLCAT_BY
                from &indata where not missing(&col_var)
                order by &colcat_by_var &colcat_by_direction, &col_var;

            %let col_cat_n = &SQLOBS;
            %do i = 1 %to &col_cat_n;
                select distinct cats("""", COLCAT, """") into :col_&i separated by " " from temp_colcat(firstobs = &i obs = &i);
            %end;
        quit;
    %end;
    %else %do;
        /*ֱ��ָ������ֵ�����colval�ķ���*/
        %let col_cat_n = %sysfunc(kcountw(%bquote(&col_val), %bquote(,), qs));
        %do i = 1 %to &col_cat_n;
            %let col_&i = %sysfunc(kscanx(%bquote(&col_val), &i, %bquote(,), qs));
        %end;
    %end;

    /*col_cat_n:�����������col_n:�������������*/
    %let col_n = &col_cat_n;
    %if &add_cat_missing_col = TRUE %then %do;
        %let col_n = %eval(&col_n + 1);
        %let col_&col_n = #MISSING;
    %end;
    %if &add_cat_other_col = TRUE %then %do;
        %let col_n = %eval(&col_n + 1);
        %if &add_cat_other_col_type = 1 %then %do;
            %let col_&col_n = #OTHER#1;
        %end;
        %else %if &add_cat_other_col_type = 2 %then %do;
            %let col_&col_n = #OTHER#2;
        %end;
    %end;
    %if &add_cat_all_col = TRUE %then %do;
        %let col_n = %eval(&col_n + 1);
        %let col_&col_n = #ALL;
    %end;


    /*3. ����������*/
    %if &pct_out = TRUE %then %do;
        proc sql noprint;
            create table temp_crosstable as
                %do i = 1 %to &row_n;
                    select
                        /*��1��*/
                        %if &i <= &row_cat_n %then %do;
                            &&row_&i
                        %end;
                        %else %do;
                            %if &&row_&i = #MISSING %then %do;
                                "ȱʧ"
                            %end;
                            %else %if &&row_&i = #OTHER#1 or &&row_&i = #OTHER#2 %then %do;
                                "����"
                            %end;
                            %else %if &&row_&i = #ALL %then %do;
                                "�ϼ�"
                            %end;
                        %end;
                            as COL_0 label = "�з���",

                        /*��2~��*/
                        %do j = 1 %to &col_n;
                            /*%put NOTE: %bquote(�� &i �У��� &j �У�&row_var = &&row_&i and &col_var = &&col_&j);*/
                            %if &i <= &row_cat_n and &j <= &col_cat_n %then %do; /*��<=������, ��<=������*/
                                cats(sum(&row_var = &&row_&i and &col_var = &&col_&j), "(", put(sum(&row_var = &&row_&i and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                            %end;
                            %else %do;
                                %if &i <= &row_cat_n %then %do;
                                    %if &&col_&j = #MISSING %then %do; /*��<=������, ��=ȱʧ*/
                                        cats(sum(&row_var = &&row_&i and missing(&col_var)), "(", put(sum(&row_var = &&row_&i and missing(&col_var))/&N, &format), ")") as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��<=������, ��=����, ����1*/
                                        cats(sum(&row_var = &&row_&i and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(&row_var = &&row_&i and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��<=������, ��=����, ����2*/
                                        cats(sum(&row_var = &&row_&i and &col_var not in (&col_val)), "(", put(sum(&row_var = &&row_&i and &col_var not in (&col_val))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��<=������, ��=�ϼ�*/
                                        cats(sum(&row_var = &&row_&i), "(", put(sum(&row_var = &&row_&i)/&N, &format), ")") as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #MISSING %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=ȱʧ, ��<=������*/
                                        cats(sum(missing(&row_var) and &col_var = &&col_&j), "(", put(sum(missing(&row_var) and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=ȱʧ, ��=ȱʧ*/
                                        cats(&N - sum(not (missing(&row_var) and missing(&col_var))), "(", put((&N - sum(not (missing(&row_var) and missing(&col_var))))/&N, &format), ")") as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=ȱʧ, ��=����, ����1*/
                                        cats(sum(missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=ȱʧ, ��=����, ����2*/
                                        cats(&N - sum(not (missing(&row_var) and &col_var not in (&col_val))), "(", put((&N - sum(not (missing(&row_var) and &col_var not in (&col_val))))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=ȱʧ, ��=�ϼ�*/
                                        cats(&N - sum(not missing(&row_var)), "(", put((&N - sum(not missing(&row_var)))/&N, &format), ")") as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#1 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=����, ����1, ��<=������*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var = &&col_&j), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=����, ����1, ��=ȱʧ*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and missing(&col_var)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and missing(&col_var))/&N, &format), ")") as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=����, ����1, ��=����, ����1*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=����, ����1, ��=����, ����2*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=����, ����1, ��=�ϼ�*/
                                        cats(sum(&row_var not in (&row_val) and not missing(&row_var)), "(", put(sum(&row_var not in (&row_val) and not missing(&row_var))/&N, &format), ")") as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#2 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=����, ����2, ��<=������*/
                                        cats(sum(&row_var not in (&row_val) and &col_var = &&col_&j), "(", put(sum(&row_var not in (&row_val) and &col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=����, ����2, ��=ȱʧ*/
                                        cats(&N - sum(not (&row_var not in (&row_val) and missing(&col_var))), "(", put((&N - sum(not (&row_var not in (&row_val) and missing(&col_var))))/&N, &format), ")") as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=����, ����2, ��=����, ����1*/
                                        cats(sum(&row_var not in (&row_val) and &col_var not in (&col_val) and not missing(&col_var)), "(", put(sum(&row_var not in (&row_val) and &col_var not in (&col_val) and not missing(&col_var))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=����, ����2, ��=����, ����2*/
                                        cats(&N - sum(not (&row_var not in (&row_val) and &col_var not in (&col_val))), "(", put((&N - sum(not (&row_var not in (&row_val) and &col_var not in (&col_val))))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=����, ����2, ��=�ϼ�*/
                                        cats(&N - sum(&row_var in (&row_val)), "(", put((&N - sum(&row_var in (&row_val)))/&N, &format), ")") as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #ALL %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=�ϼ�, ��<=������*/
                                        cats(sum(&col_var = &&col_&j), "(", put(sum(&col_var = &&col_&j)/&N, &format), ")") as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=�ϼ�, ��=ȱʧ*/
                                        cats(&N - sum(not missing(&col_var)), "(", put((&N - sum(not missing(&col_var)))/&N, &format), ")") as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=�ϼ�, ��=����, ����1*/
                                        cats(sum(&col_var not in (&col_val) and not missing(&col_var)), "(", put((sum(&col_var not in (&col_val) and not missing(&col_var)))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=�ϼ�, ��=����, ����2*/
                                        cats(&N - sum(&col_var in (&col_val)), "(", put((&N - sum(&col_var in (&col_val)))/&N, &format), ")") as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=�ϼ�, ��=�ϼ�*/
                                        cats(&N, "(", put(1, &format), ")") as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                            %end;
                            %if &j < &col_n %then %do; %str(,) %end;
                        %end;
                    from &indata
                    %if &i < &row_n %then %do;
                        outer union corr
                    %end;
                %end;
                ;
        quit;
    %end;
    %else %do;
        proc sql noprint;
            create table temp_crosstable as
                %do i = 1 %to &row_n;
                    select
                        /*��1��*/
                        %if &i <= &row_cat_n %then %do;
                            &&row_&i
                        %end;
                        %else %do;
                            %if &&row_&i = #MISSING %then %do;
                                "ȱʧ"
                            %end;
                            %else %if &&row_&i = #OTHER#1 or &&row_&i = #OTHER#2 %then %do;
                                "����"
                            %end;
                            %else %if &&row_&i = #ALL %then %do;
                                "�ϼ�"
                            %end;
                        %end;
                            as COL_0 label = "�з���",

                        /*��2~��*/
                        %do j = 1 %to &col_n;
                            /*%put NOTE: %bquote(�� &i �У��� &j �У�&row_var = &&row_&i and &col_var = &&col_&j);*/
                            %if &i <= &row_cat_n and &j <= &col_cat_n %then %do; /*��<=������, ��<=������*/
                                sum(&row_var = &&row_&i and &col_var = &&col_&j) as COL_&j label = &&col_&j
                            %end;
                            %else %do;
                                %if &i <= &row_cat_n %then %do;
                                    %if &&col_&j = #MISSING %then %do; /*��<=������, ��=ȱʧ*/
                                        sum(&row_var = &&row_&i and missing(&col_var)) as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��<=������, ��=����, ����1*/
                                        sum(&row_var = &&row_&i and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��<=������, ��=����, ����2*/
                                        sum(&row_var = &&row_&i and &col_var not in (&col_val)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��<=������, ��=�ϼ�*/
                                        sum(&row_var = &&row_&i) as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #MISSING %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=ȱʧ, ��<=������*/
                                        sum(missing(&row_var) and &col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=ȱʧ, ��=ȱʧ*/
                                        &N - sum(not (missing(&row_var) and missing(&col_var))) as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=ȱʧ, ��=����, ����1*/
                                        sum(missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=ȱʧ, ��=����, ����2*/
                                        &N - sum(not (missing(&row_var) and &col_var not in (&col_val))) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=ȱʧ, ��=�ϼ�*/
                                        &N - sum(not missing(&row_var)) as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#1 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=����, ����1, ��<=������*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=����, ����1, ��=ȱʧ*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and missing(&col_var)) as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=����, ����1, ��=����, ����1*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=����, ����1, ��=����, ����2*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var) and &col_var not in (&col_val)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=����, ����1, ��=�ϼ�*/
                                        sum(&row_var not in (&row_val) and not missing(&row_var)) as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #OTHER#2 %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=����, ����2, ��<=������*/
                                        sum(&row_var not in (&row_val) and &col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=����, ����2, ��=ȱʧ*/
                                        &N - sum(not (&row_var not in (&row_val) and missing(&col_var))) as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=����, ����2, ��=����, ����1*/
                                        sum(&row_var not in (&row_val) and &col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=����, ����2, ��=����, ����2*/
                                        &N - sum(not (&row_var not in (&row_val) and &col_var not in (&col_val))) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=����, ����2, ��=�ϼ�*/
                                        &N - sum(&row_var in (&row_val)) as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                                %else %if &&row_&i = #ALL %then %do;
                                    %if &j <= &col_cat_n %then %do; /*��=�ϼ�, ��<=������*/
                                        sum(&col_var = &&col_&j) as COL_&j label = &&col_&j
                                    %end;
                                    %else %if &&col_&j = #MISSING %then %do; /*��=�ϼ�, ��=ȱʧ*/
                                        &N - sum(not missing(&col_var)) as COL_MISSING label = "ȱʧ"
                                    %end;
                                    %else %if &&col_&j = #OTHER#1 %then %do; /*��=�ϼ�, ��=����, ����1*/
                                        sum(&col_var not in (&col_val) and not missing(&col_var)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #OTHER#2 %then %do; /*��=�ϼ�, ��=����, ����2*/
                                        &N - sum(&col_var in (&col_val)) as COL_OTHER label = "����"
                                    %end;
                                    %else %if &&col_&j = #ALL %then %do; /*��=�ϼ�, ��=�ϼ�*/
                                        &N as COL_ALL label = "�ϼ�"
                                    %end;
                                %end;
                            %end;
                            %if &j < &col_n %then %do; %str(,) %end;
                        %end;
                    from &indata
                    %if &i < &row_n %then %do;
                        outer union corr
                    %end;
                %end;
                ;
        quit;
    %end;

    /*4. ������ݼ�*/
    data &libname_out..&memname_out(&dataset_options_out);
        set temp_crosstable;
    run;

    /*----------------------------------------------���к���----------------------------------------------*/

    %if &debug = false %then %do;
        /*ɾ���м����ݼ�*/
        proc datasets noprint nowarn;
            delete temp_rowcat
                   temp_colcat
                   temp_crosstable
                   ;
        quit;
    %end;

    /*�˳������*/
    %exit:
    %put NOTE: �� cross_table �ѽ������У�;
%mend;
