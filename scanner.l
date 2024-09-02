%{
/*Included headers*/
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "y.tab.h"
/*Macro definitions*/

/*Global variable definitions*/
int line_count = 0;
bool pragma_token_on = true;
bool pragma_source_on = true;

/*Function definitions*/

void newLine(bool eof){
    line_count++;
}

void remove_spaces(char* s) {
    char* d = s;
    do {
        while (*d == ' ') {
            ++d;
        }
    } while (*s++ = *d++);
}

// "void" {yylval.stringValue = strdup(yytext); return KEY_DATA_TYPE_VOID;}
// "char" {yylval.stringValue = strdup(yytext); return KEY_DATA_TYPE_CHAR;}
// "short" {yylval.stringValue = strdup(yytext); return KEY_DATA_TYPE_SHORT;}
// "int" {yylval.stringValue = strdup(yytext); return KEY_DATA_TYPE_INT;}
// "long" {yylval.stringValue = strdup(yytext); return KEY_DATA_TYPE_LONG;}
// "float" {yylval.stringValue = strdup(yytext); return KEY_DATA_TYPE_FLOAT;}
// "double" {yylval.stringValue = strdup(yytext); return KEY_DATA_TYPE_DOUBLE;}

// "const" {
    // yylval.stringValue = strdup(yytext); return KEY_CONST;
// }
// "signed"|"unsigned" { 
    // yylval.stringValue = strdup(yytext); return KEY_SIGNED;
// }

%}

%x	BLOCK_COMMENT


/* Auxiliary declarations end & Regular definitions start here */
/* ref:https://www.ibm.com/docs/en/zos/2.5.0?topic=lex-definitions */
underscore _
alpha [[:alpha:]]
digit [[:digit:]]
space [[:space:]]


type_1 ((const{space})?(signed{space}|unsigned{space})?(long{space}long{space}|long{space}|short{space})?(int){space}*)
type_2 ((const{space})?(signed{space}|unsigned{space})?((long{space}long)|long|short|char){space}*)
type_3 ((const{space})?(signed|unsigned|float|double|void)){space}*
type ({type_3}|{type_2}|{type_1}|const)


identifiers ({underscore}|{alpha})({underscore}|{alpha}|{digit})*
/* identifier (\*)?([ \t])*({underscore}|{alpha})({underscore}|{alpha}|{digit})* */
/* identifiers ({identifier}([ \t])*(,([ \t])*{identifier})*) */
/* Auxiliary declarations end & Regular definitions end here */

/* punctuations (:|;|,|\(|\)|\{|\}|\[|\]|\.|,) */

integer {digit}+
float_digit_before_dot {digit}+\.{digit}*
/* The number, if it's 0, before or after the decimal point can be missing */
float_no_digit_after_dot {digit}*\.{digit}+
float_val ({float_digit_before_dot}|{float_no_digit_after_dot})
octal (\\[0-7]{1,3})
hex (\\x[a-fA-F0-9]+)
u4h (\\u[a-fA-F0-9]{4})
U8h (\\U[a-fA-F0-9]{8})
escaped_sequences ((\\[abefnrtv])|(\\\\)|(\')|(\")|(\?)|{octal}|{hex}|{u4h}|{U8h})
string (\"(?:[^\"\n]|\\.)*\")
character (\'({escaped_sequences}|.)\')
line_comment (\/\/([^\n]*))
block_comment_begin (\/\*)

source_on ([ \t]*#pragma[ \t]+source[ \t]+on)
source_off ([ \t]*#pragma[ \t]+source[ \t]+off)
token_on ([ \t]*#pragma[ \t]+token[ \t]+on)
token_off ([ \t]*#pragma[ \t]+token[ \t]+off)

%%

<BLOCK_COMMENT>"*/"	{ BEGIN INITIAL; }
<BLOCK_COMMENT>\n		{ newLine(true); }
<BLOCK_COMMENT>.		{ }


\n { newLine(true);}

"for" {yylval.stringValue = strdup(yytext); return KEY_FOR; };
"do" {yylval.stringValue = strdup(yytext); return KEY_DO; };
"while" {yylval.stringValue = strdup(yytext); return KEY_WHILE; };
"break" {yylval.stringValue = strdup(yytext); return KEY_BREAK; };
"continue" {yylval.stringValue = strdup(yytext); return KEY_CONTINUE; };
"if" {yylval.stringValue = strdup(yytext); return KEY_IF; };
"else" {yylval.stringValue = strdup(yytext); return KEY_ELSE; };
"return" {yylval.stringValue = strdup(yytext); return KEY_RETURN; };
"switch" {yylval.stringValue = strdup(yytext); return KEY_SWITCH; };
"case" {yylval.stringValue = strdup(yytext); return KEY_CASE; };
"default" {yylval.stringValue = strdup(yytext); return KEY_DEFAULT; };


"LOW" {yylval.stringValue = strdup("0"); return VAL_INT; }
"HIGH" {yylval.stringValue = strdup("1"); return VAL_INT; }



"NULL" {yylval.stringValue = strdup("0"); return VAL_NULL; }
"||" {
    yylval.stringValue = strdup(yytext); 
    return or_const;
}
"&&" {
    yylval.stringValue = strdup(yytext); 
    return and_const;
}
"=="|"!=" {
    yylval.stringValue = strdup(yytext); 
    return eq_const;
}
"<="|">=" {
    yylval.stringValue = strdup(yytext); 
    return rel_const;
}
">>"|"<<" {
    yylval.stringValue = strdup(yytext);
    return shift_const;
}
"++"|"--" {
    yylval.stringValue = strdup(yytext); 
    return inc_const;
}
";"|"="|","|"{"|"}"|"("|")"|"["|"]"|"*"|"+"|"-"|"/"|"?"|":"|"&"|"|"|"^"|"!"|"~"|"%"|"<"|">"|"." {
    yylval.stringValue = strdup(yytext); 
    // printf("[info] At line %d, \"=\" detected: %s\n", line_count, yylval.stringValue);
    return yytext[0];
}

{type} {
    char* tmp = strdup(yytext);
    remove_spaces(tmp);
    yylval.stringValue = strdup(tmp);
    // printf("[info] At line %d, TYPE detected: %s\n", line_count, yylval.stringValue);
    return KEY_TYPE;
}


{space} { }
<<EOF>> { newLine(false); return 0; }

{identifiers} { 
    char* tmp = strdup(yytext);
    remove_spaces(tmp);
    yylval.stringValue = strdup(tmp);
    // printf("[info] At line %d, ID detected: %s\n", line_count, yylval.stringValue);
    return ID; 
}

{integer} { 
    int intValue = atoi(yytext);
    char* convertedString = (char*)malloc(40 * sizeof(char));
    sprintf(convertedString, "%d", intValue);
    yylval.stringValue = strdup(convertedString);
    free(convertedString);
    // printf("[info] At line %d, INT detected: %s\n", line_count, yylval.stringValue);
    return VAL_INT;
}
{float_val} {
    // Convert yytext to float using atof
    double floatValue = atof(yytext);
    // Convert the float back to char*
    char* convertedString = (char*)malloc(40 * sizeof(char));
    sprintf(convertedString, "%f", floatValue);
    yylval.stringValue = strdup(convertedString);
    free(convertedString);
    // printf("[info] At line %d, float detected: %s\n", line_count, yylval.stringValue);
    return VAL_FLOAT;
 }
{string} { 
    yylval.stringValue = strdup(yytext); 
    return VAL_STRING;
}
{character} { 
    yylval.stringValue = strdup(yytext); 
    return VAL_CHAR;
}
{line_comment} { }
{source_off} { pragma_source_on = false; }
{source_on} { pragma_source_on = true; }
{token_off} { pragma_token_on = false; }
{token_on} {  pragma_token_on = true; }
{block_comment_begin} { BEGIN BLOCK_COMMENT;}
%%
int yywrap (void) {return 1;}

void yyerror(const char *msg) {
    fprintf(stderr, "Error at line %d: %s\n", line_count , yylval.stringValue);
    exit(-1);
}  
