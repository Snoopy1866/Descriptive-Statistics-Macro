/*
详细文档请前往 Github 查阅: https://github.com/Snoopy1866/Descriptive-Statistics-Macro
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
%macro qualify_strata(struct,
                      indata = NULL,
                      var = NULL,
                      varby = NULL,
                      group = NULL,
                      groupby = NULL,
                      format = NULL,
                      unique_var = NULL,
                      outdata = NULL,
                      del_temp_data = NULL) /des = "定性资料分层描述分析" parmbuff;

    /*打开帮助文档*/
    %if %bquote(%upcase(&SYSPBUFF)) = %bquote((HELP)) or %bquote(%upcase(&SYSPBUFF)) = %bquote(()) %then %do;
        X explorer "https://github.com/Snoopy1866/Descriptive-Statistics-Macro/blob/main/docs/qualify_strata/readme.md";
        %goto exit;
    %end;

    /*统一参数大小写*/


    /*声明局部变量*/
    %local i j;

    

    /*----------------------------------------------参数检查----------------------------------------------*/
    
    /*----------------------------------------------主程序----------------------------------------------*/
    %let reg_struct_unit_id = %sysfunc(prxparse(%bquote(/(?:([A-Za-z_][A-Za-z0-9_]*)|(,)|(\()|(\))|(\|))/)));
    %let strata_point_index = 1; /*层指针索引*/
    %let column_point_index = 1; /*列指针索引*/
    %let start = 1;
    %let stop = %length(&struct);
    %let position = 1;
    %let length = 1;
    %syscall prxnext(reg_struct_unit_id, start, stop, struct, position, length);
    %do %until(&position = 0); /*连续匹配正则表达式*/
        %let tmp_struct_unit = %substr(%bquote(&struct), &position, &length);
        %put NOTE: &=position &=length &=tmp_struct_unit;
        %if 1 < 2 %then %do;
            %if %bquote(tmp_struct_unit) = %bquote(,) %then %do;
                %let strata_point_index = %eval(strata_point_index + 1);
                %let column_point_index = &strata_point_index;
            %end;
            %else %if %bquote(tmp_struct_unit) = %bquote(%str(%()) %then %do;
            %end;
        %end;

        %syscall prxnext(reg_struct_unit_id, start, stop, struct, position, length);
    %end;

    /*----------------------------------------------运行后处理----------------------------------------------*/
   

    /*正常退出*/
    %exit:
    %put NOTE: 宏 desc_coun 已结束运行！;
%mend;
