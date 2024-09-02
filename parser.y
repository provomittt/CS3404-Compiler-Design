%{
    /*Headers*/
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include "y.tab.h"
    #include "parser_utils.h"

    /*Macro definitions*/
    #define LENGTH_MAX 305
    int yylex();
    void yyerror(const char *msg); 

    int scope = 0;
    enum MODE mode = MODE_GLOBAL;
    FILE *f_asm;
    char* PROLOGUE = 
    "// BEGIN PROLOGUE\n\
   sw s0, -4(sp)\n\
   addi sp, sp, -4\n\
   addi s0, sp, 0 // set new frame\n\
   sw sp, -4(s0)\n\
   sw s1, -8(s0)\n\
   sw s2, -12(s0)\n\
   sw s3, -16(s0)\n\
   sw s4, -20(s0)\n\
   sw s5, -24(s0)\n\
   sw s6, -28(s0)\n\
   sw s7, -32(s0)\n\
   sw s8, -36(s0)\n\
   sw s9, -40(s0)\n\
   sw s10, -44(s0)\n\
   sw s11, -48(s0)\n\
   addi sp, s0, -48 // update stack pointer\n\
   // END PROLOGUE\n\n";
    char* EPILOGUE = 
    "// BEGIN EPILOGUE: restore callee-saved registers\n\
   lw s11, -48(s0)\n\
   lw s10, -44(s0)\n\
   lw s9, -40(s0)\n\
   lw s8, -36(s0)\n\
   lw s7, -32(s0)\n\
   lw s6, -28(s0)\n\
   lw s5, -24(s0)\n\
   lw s4, -20(s0)\n\
   lw s3, -16(s0)\n\
   lw s2, -12(s0)\n\
   lw s1, -8(s0)\n\
   lw sp, -4(s0)\n\
   addi sp, sp, 4\n\
   lw s0, -4(sp)\n\
   // END EPILOGUE\n\n\
   jalr zero, 0(ra)// return";
   
%}

/* RISC-V calling convention: https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf */

%union { 
    // int intVal;
    char* stringValue; 
}

%token<stringValue> KEY_FOR KEY_DO KEY_WHILE KEY_BREAK KEY_CONTINUE KEY_IF KEY_ELSE KEY_RETURN KEY_SWITCH KEY_CASE KEY_DEFAULT
%token<stringValue> or_const and_const eq_const rel_const shift_const inc_const
%token<stringValue> VAL_INT VAL_FLOAT VAL_STRING VAL_CHAR ID
%token<stringValue> VAL_NULL HEADER
%token<stringValue> KEY_TYPE
/* %token<stringValue> KEY_SIGNED KEY_CONST */
/* %token<stringValue> KEY_DATA_TYPE_LONGLONG KEY_DATA_TYPE_VOID KEY_DATA_TYPE_CHAR KEY_DATA_TYPE_SHORT KEY_DATA_TYPE_INT KEY_DATA_TYPE_LONG KEY_DATA_TYPE_FLOAT KEY_DATA_TYPE_DOUBLE */

%type<stringValue> start_unit translation_unit global_define type union_state idents
%type<stringValue> ident_in_idents ident pointer_capable_ident arrays array dimenational arr_content expr_arr_list 
%type<stringValue> expr_arr function_declaration parameters type_ident_list stat stat_pre exp_stat stat_list if_stat 
%type<stringValue> switch_stat switch_clauses_list switch_clause while_stat for_stat jump_stat compound_stat
%type<stringValue> ident_stat_list assignment_exp logical_or_expr logical_and_expr  cast_expr unary_expr 
%type<stringValue> postfix_expr primary_expr exp const exp_pre argument_exp_list Scalar_Declaration Array_Declaration

%type<stringValue> inclusive_or_expr exclusive_or_expr bitwise_and_expr equality_expr relative_cmp_expr shift_expr additive_exp mult_exp

/* C operator precedence: https://en.cppreference.com/w/c/language/operator_precedence*/
%left ';'
%left ','
%right '='
%right '?' ':'
%left or_const
%left and_const
%left '|'
%left '^'
%left '&'
%left eq_const
%left '>' '<'
%left shift_const
%left '+' '-'
%left '*' '/' '%'
%left inc_const
%start start_unit

%%
start_unit: HEADER start_unit      // handle header file 
    | translation_unit	// enter translation 
    ;
translation_unit : global_define  							
    | translation_unit global_define 		
    ;
global_define  : union_state 
    ;


/* ``type" can be either */
/* • ``[const] [signed|unsigned] [long long|long|short ] int" */
/* • ``[const] [signed|unsigned] (long long)|long|short|char" */
/* • ``[const] signed|unsigned|float|double|void" */
/* • ``const" */

// bruh where should I put type?
// check them when tokenizing? when parsing?

type: 
    KEY_TYPE

union_state : Scalar_Declaration { printf("%s\n",$$);}
    | Array_Declaration {printf("%s\n",$$);} // Array Declaration
    | type function_declaration ';' {
        handle_2_str(&($$) , $2 , ";" ); 
        // type_concat(3,&($$)) ;
        printf("%s\n",$$);} // Function Declaration
    | type function_declaration compound_stat {
        handle_2_str(&($$) , $2 , $3 ); 
        // type_concat(4,&($$));
        printf("%s\n",$$);
        } // Function Definition 
    ;


Scalar_Declaration:
    type idents  ';' {
        handle_2_str(&($$) , $2 , ";" ); 
        //type_concat(1,&($$));  
        }// Scalar Declaration -> type idents
    ;

Array_Declaration:
    type arrays ';' {
        handle_2_str(&($$) , $2 , ";" ); 
        // type_concat(2,&($$)); 
        } // Array Declaration
    ;

// bruh where should I put idents?
// check them when tokenizing? when parsing?


idents: ident_in_idents
    | idents ',' ident_in_idents  {handle_2_str(&($$) , "," , $3);}
    ;

ident_in_idents: pointer_capable_ident // "ident" in "idents" can be initialized with "ident = expr" 
    | pointer_capable_ident '=' exp_pre { handle_2_str(&($$) , "=" , $3 ); }
    ;



ident: ID // {printf("Hi ID\n");};

pointer_capable_ident: ID // {printf("Hi ID\n");};
    | '*' ID {handle_1_str(&($$) , $2 ); }
    ;

arrays: array
    | arrays ',' array {handle_2_str(&($$) , "," ,$3 );}
    ;

array: ident dimenational {handle_1_str(&($$) , $2 );}
    |   ident dimenational '=' arr_content  { handle_3_str(&($$), $2, "=", $4); }
    ;


dimenational: '[' exp_pre ']'  {  handle_2_str(&($$),  $2, "]");}
    |  dimenational '[' exp_pre ']' {  handle_3_str(&($$), "[" , $3 , "]"); }
    ;

arr_content: '{' expr_arr_list '}' { handle_2_str(&($$), $2, "}" ); }
    ;

expr_arr_list: expr_arr
    | expr_arr_list ',' expr_arr { handle_2_str(&($$), "," , $3 ); }
    ;

expr_arr: exp_pre
    | arr_content 
    ;


function_declaration : pointer_capable_ident '(' ')' { handle_2_str(&($$), "(", ")" ); } // type ident(parameters) // zero or more parameter
    | pointer_capable_ident '(' parameters ')' { handle_3_str(&($$), "(", $3 ,")" ); } 
    ;

parameters:  type_ident_list ;

type_ident_list: type pointer_capable_ident { handle_1_str(&($$), $2 ); }
    | type_ident_list ',' type pointer_capable_ident { handle_3_str(&($$), ",", $3 , $4 ); }
    ;

stat_pre:
    stat //{type_concat(6,&($$));}
    ;

stat :  exp_stat 
    | if_stat 
    | switch_stat 
    | while_stat
    | for_stat										  	
    | jump_stat
    | compound_stat 
    ;

exp_pre: 
    exp //{type_concat(5,&($$));}
    ; 

exp_stat: exp_pre ';' {  handle_1_str(&($$) , ";" ); }
    ;

stat_list : stat_pre     												
    | stat_list stat_pre  { handle_1_str(&($$), $2 ); }	
    ;

if_stat	: KEY_IF '(' exp_pre ')' compound_stat  { handle_4_str(&($$), "(" , $3 , ")" , $5); }
    | KEY_IF '(' exp_pre ')' compound_stat KEY_ELSE compound_stat { handle_6_str(&($$), "(" , $3 , ")" , $5 , $6 , $7); }
    ;

switch_stat: KEY_SWITCH '(' exp_pre ')' '{' '}'  { handle_5_str(&($$), "(" , $3 , ")" , "{" , "}"); } // "switch_clauses" consists of 0 or more "switch_clause" seperated by space / tab / newline / nothing
    | KEY_SWITCH '(' exp_pre ')' '{' switch_clauses_list '}' { handle_6_str(&($$), "(" , $3 , ")" ,"{" , $6 , "}"); }
    ;

switch_clauses_list: switch_clause
    | switch_clauses_list switch_clause  { handle_1_str(&($$), $2 ); }
    ;

switch_clause: KEY_CASE exp_pre ':' stat_list  { handle_3_str(&($$), $2 , ":" , $4 ); }	
    | KEY_CASE exp_pre ':' { handle_2_str(&($$), $2 , ":" ); }	
    | KEY_DEFAULT ':' stat_list  { handle_2_str(&($$), ":" , $3 ); }	
    | KEY_DEFAULT ':'  { handle_1_str(&($$), ":" ); }	
    ;

while_stat: KEY_WHILE '(' exp_pre ')' stat_pre { handle_4_str(&($$), "(" , $3 , ")" , $5); }
    | KEY_DO stat_pre KEY_WHILE '(' exp_pre ')' ';' { handle_6_str(&($$), $2 , $3 , "(" , $5 , ")" , ";" ); }
    ;

for_stat: KEY_FOR '(' exp_pre ';' exp_pre ';' exp_pre ')' stat_pre { handle_8_str(&($$), "(" , $3 , ";" , $5 , ";" , $7 , ")" ,  $9 ); }
    | KEY_FOR '(' exp_pre ';' exp_pre ';'	')' stat_pre { handle_7_str(&($$), "(" , $3 , ";" , $5 , ";" , ")" , $8 ); }
    | KEY_FOR '(' exp_pre ';' ';' exp_pre ')' stat_pre { handle_7_str(&($$), "(" , $3 , ";" , ";" , $6 , ")" , $8 ); }
    | KEY_FOR '(' exp_pre ';' ';' ')' stat_pre { handle_6_str(&($$), "(" , $3 , ";" , ";" , ")" , $7 ); }
    | KEY_FOR '(' ';' exp_pre ';' exp_pre ')' stat_pre { handle_7_str(&($$), "(" , ";" , $4 , ";" , $6 , ")" , $8 ); }
    | KEY_FOR '(' ';' exp_pre ';' ')' stat_pre { handle_6_str(&($$), "(" , ";" , $4 , ";" , ")" , $7 ); }
    | KEY_FOR '(' ';' ';' exp_pre ')' stat_pre { handle_6_str(&($$), "(" , ";" , ";" , $5 , ")" , $7 ); }
    | KEY_FOR '(' ';' ';' ')' stat_pre { handle_5_str(&($$), "(" , ";" , ";" , ")" , $6 ); }
    ;

jump_stat	: KEY_CONTINUE ';' { handle_1_str(&($$), ";" ); }
    | KEY_BREAK ';' { handle_1_str(&($$),  ";" ); }
    | KEY_RETURN exp_pre ';' { handle_2_str(&($$), $2 , ";" ); }
    | KEY_RETURN ';' { handle_1_str(&($$), ";" ); }
    ;

compound_stat	: '{' ident_stat_list '}'  { handle_2_str(&($$), $2 , "}" ); }	// 0 stmt 0 var_declaration
    | '{' '}' { handle_1_str(&($$), "}" ); }	// 0 stmt 0 var_declaration							
    ;

ident_stat_list: stat_pre
    | ident_stat_list stat_pre { handle_1_str(&($$), $2 ); }
    | Scalar_Declaration
    | ident_stat_list Scalar_Declaration { handle_1_str(&($$), $2 ); }
    | Array_Declaration
    | ident_stat_list Array_Declaration { handle_1_str(&($$), $2 ); }
    ;
/*

+ - * / % ++ -- < <= > >= == != = && || ! ~ ^ & | >> << [ ] ( )

Includes (post / pre-fix) (``++" / ``--"), unary (`+' / `-'), function invocation `(params...)`,
array subscription, dereference (`*'), address-of (`&'), type-casting (``(type)", including
single-level pointer types)

– ``variable": ``ident" or ``ident[expr]\[[expr]...\]"
– ``literal": single signless integer / signless floating-point number / char / string
literal
– ``NULL": Equals to integer ``0"

*/

exp	: assignment_exp // doesn't include comma expression
    ;

/* ================= begin right to left ====================================*/

assignment_exp  : logical_or_expr
    | logical_or_expr '=' assignment_exp {special_treatment_to_expr(&($$) , "=" , &($3)); handle_2_str(&($$), "=" , $3 );}
    ;

/* =================  end  right to left ====================================*/

/* ================= begin left to right ====================================*/

logical_or_expr				: logical_and_expr
							| logical_or_expr or_const logical_and_expr { special_treatment_to_expr(&($$) , $2 , &($3)); handle_2_str(&($$), $2 , $3 );} // 
							;
logical_and_expr			: inclusive_or_expr
							| logical_and_expr and_const inclusive_or_expr { special_treatment_to_expr(&($$) , $2 , &($3)); handle_2_str(&($$), $2 , $3 );}
							;
inclusive_or_expr			: exclusive_or_expr
							| inclusive_or_expr '|' exclusive_or_expr {char* temp = "|" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							;
exclusive_or_expr			: bitwise_and_expr
							| exclusive_or_expr '^' bitwise_and_expr {char* temp = "^" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							;
bitwise_and_expr			: equality_expr
							| bitwise_and_expr '&' equality_expr {char* temp = "&" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							;
equality_expr				: relative_cmp_expr
							| equality_expr eq_const relative_cmp_expr { special_treatment_to_expr(&($$) , $2 , &($3)); handle_2_str(&($$), $2 , $3 );}
							;
relative_cmp_expr			: shift_expr
							| relative_cmp_expr '<' shift_expr {char* temp = "<" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							| relative_cmp_expr '>' shift_expr {char* temp = ">" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							| relative_cmp_expr rel_const shift_expr { special_treatment_to_expr(&($$) , $2 , &($3)); handle_2_str(&($$), $2 , $3 );}
							;
shift_expr			        : additive_exp
							| shift_expr shift_const additive_exp { special_treatment_to_expr(&($$) , $2 , &($3)); handle_2_str(&($$), $2 , $3 );}
							;
additive_exp				: mult_exp
							| additive_exp '+' mult_exp {char* temp = "+" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							| additive_exp '-' mult_exp {char* temp = "-" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							;
mult_exp					: cast_expr
							| mult_exp '*' cast_expr {char* temp = "*" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							| mult_exp '/' cast_expr {char* temp = "/" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							| mult_exp '%' cast_expr {char* temp = "%" ; special_treatment_to_expr(&($$) , temp , &($3)); handle_2_str(&($$), temp , $3 );}
							;
                            

/* ================= end left to right ====================================*/

/* ================= begin right to left ====================================*/

cast_expr   : unary_expr // type casting
    | '(' type ')' cast_expr {
        // type_concat(5,&($4)); 
        handle_3_str(&($$), $2 , ")" , $4 );
        }
    | '(' type '*' ')' cast_expr  {
        // type_concat(5,&($5)); 
        char* temp = "*" ; 
        handle_4_str(&($$), $2 , temp , ")" , $5 );
        } // single-level pointer types 
    ;


unary_expr   : postfix_expr
    | inc_const unary_expr {
        // type_concat(5,&($2)); 
        handle_1_str(&($$), $2);
        }
    //| unary_operator cast_expr
    | '&' cast_expr {
        // type_concat(5,&($2)); 
        handle_1_str(&($$),  $2 );
        }
    | '*' cast_expr {
        // type_concat(5,&($2)); 
        handle_1_str(&($$),  $2 );
        }
    | '~' cast_expr {
        // type_concat(5,&($2)); 
        handle_1_str(&($$),  $2 );
        }
    | '!' cast_expr {
        // type_concat(5,&($2)); 
        handle_1_str(&($$),  $2 );
        }
    | '+' cast_expr {
        // type_concat(5,&($2)); 
        handle_1_str(&($$),  $2 );
        }
    | '-' cast_expr {
        // type_concat(5,&($2)); 
        handle_1_str(&($$),  $2 );
        }
    ;

//unary_operator : '&' | '*' | '~' | '!' | '+' | '-' ;


/* =================  end  right to left ====================================*/

postfix_expr	:  primary_expr 											
    | postfix_expr '(' {
        scope++ ; 
        mode = MODE_ARGUMENT; 
        printf("scope++ and scope = %d\n" , scope);
    } argument_exp_list {
        // function(arg, arg, ...)
        // start dealing with args
        symbol_to_asm(scope, f_asm);
    } ')' {
        pop_symbol(scope);
        scope--;
        mode = MODE_GLOBAL; 
        printf("scope++ and scope = %d\n" , scope);
        // end dealing with arg

        // jumping to function and return
        fprintf(f_asm , "   sw ra, -4(sp)\n   addi sp, sp, -4 \n");
        fprintf(f_asm , "   jal ra, %s\n   lw ra, 0(sp)\n   addi sp, sp, 4\n\n" , $1) ; 
        printf("function called \n");

        // [HW2]
        // type_concat(5,&($$)); 
        // handle_3_str(&($$), "(" , $3 , ")" );
    }
    | postfix_expr '(' ')' {
        // type_concat(5,&($$)); 
        handle_2_str(&($$), "(" , ")" );
        }
    | postfix_expr inc_const {
        // type_concat(5,&($$)); 
        handle_1_str(&($$), $2 );
        }
    ;

primary_expr	: const
    | ident
    | ident dimenational {handle_1_str(&($$), $2 );}
    | VAL_STRING
    | '(' exp_pre ')' {handle_2_str(&($$), $2 , ")" );}
    ;

argument_exp_list	: exp_pre {}
    | argument_exp_list ',' exp_pre {handle_2_str(&($$), "," , $3 );}
    ;

const : VAL_INT {
            add_symbol($$, scope, INT, mode);
        }
    | VAL_CHAR
    | VAL_FLOAT
    | VAL_NULL
    ;

%%

int main (void) {
    f_asm = fopen("codegen.S", "w");
    fprintf(f_asm , ".global codegen");
    fprintf(f_asm , "\ncodegen:\n");
    fprintf(f_asm , "   %s", PROLOGUE);
	yyparse();
    fprintf(f_asm , "   %s", EPILOGUE);
    fclose(f_asm);
    return 0;
}

/* 
./parser < ../testcase/array_decl_wo_init.txt > array_decl_wo_init.out
./parser < ../testcase/scalar_decl_wo_init.txt > scalar_decl_wo_init.out
./parser < ../testcase/expr_1.txt > expr_1.out
./parser < ../testcase/func_decl.txt > func_decl.out
golden_parser < ../testcase/scalar_decl_wo_init.txt > g_scalar_decl_wo_init.out
golden_parser < ../testcase/array_decl_wo_init.txt > g_array_decl_wo_init.out
golden_parser < ../testcase/expr_1.txt > g_expr_1.out
golden_parser < ../testcase/func_decl.txt > g_func_decl.out
diff array_decl_wo_init.out g_array_decl_wo_init.out
diff scalar_decl_wo_init.out g_scalar_decl_wo_init.out
diff expr_1.out g_expr_1.out
diff func_decl.out g_func_decl.out


./parser < ./testcase/expr_3/input.txt > ./testcase/expr_3/output.txt
diff ./testcase/expr_3/answer_0.txt ./testcase/expr_3/output.txt
./parser < ./testcase/func_decl/input.txt > ./testcase/func_decl/output.txt
diff ./testcase/func_decl/answer_0.txt ./testcase/func_decl/output.txt
./parser < ./testcase/stmt/input.txt > ./testcase/stmt/output.txt
diff ./testcase/stmt/answer_0.txt ./testcase/stmt/output.txt
./parser < ./testcase/expr_2/input.txt > ./testcase/expr_2/output.txt
diff ./testcase/expr_2/answer_0.txt ./testcase/expr_2/output.txt
./parser < ./testcase/func_def/input.txt > ./testcase/func_def/output.txt
diff ./testcase/func_def/answer_0.txt ./testcase/func_def/output.txt
./parser < ./testcase/var_decl/input.txt > ./testcase/var_decl/output.txt
diff ./testcase/var_decl/answer_0.txt ./testcase/var_decl/output.txt


*/