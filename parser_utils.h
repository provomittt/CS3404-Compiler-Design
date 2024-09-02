#ifndef HELPER_H_
#define HELPER_H_
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

/*Macro definitions*/
#define LENGTH_MAX 305
#define MAX_TABLE_SIZE 1000
#define MAX_STACK_SIZE 1000
#define MAX_ARG 8

// enum TYPE{
//     SCLAR_DECL=1, ARRAY_DECL, FUNC_DECL, FUNC_DEF, EXPR, STMT
// };
enum TYPE{
    INT=1
};
enum MODE {
    MODE_ARGUMENT=1, MODE_LOCAL, MODE_GLOBAL
};

extern struct symbol {
    char *name;
    int scope;
    int type;
    int mode;
} table[MAX_TABLE_SIZE];

extern struct stack{
    char* name;
    int type;
    int mode;
} stack[MAX_STACK_SIZE];

extern struct arg{
    char* name;
    int type;
    int mode;
} arg[MAX_ARG];

// [HW3]
void add_symbol(const char *name, int scope, enum TYPE type , enum MODE mode);
void pop_symbol(int scope);
void add_entry(const char *name, enum TYPE type , enum MODE mode);
void symbol_to_asm(int scope, FILE* filePointer);
void asm_gen(FILE* filePointer);
void clear_arg();
void clear_stack();


// [HW2]
// void type_concat(enum TYPE type , char** original);
void handle_1_str(char** original, char* arg_1);
void handle_2_str(char** original, char* arg_1, char* arg_2);
void handle_3_str(char** original, char* arg_1, char* arg_2, char* arg_3);
void handle_4_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4);
void handle_5_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5);
void handle_6_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5  , char* arg_6);
void handle_7_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5, char* arg_6, char* arg_7);
void handle_8_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5, char* arg_6, char* arg_7, char* arg_8);
void special_treatment_to_expr(char** original_left , char* mid_char ,char** original_right);

#endif