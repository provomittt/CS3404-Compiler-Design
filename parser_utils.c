#include "parser_utils.h"

int symbol_index = 1;
int stack_index = 1;
int arg_index = 1;

struct symbol symbol_table[MAX_TABLE_SIZE];
struct stack stack_table[MAX_STACK_SIZE];
struct arg arg_table[MAX_ARG];



// [HW3]
void add_symbol(const char *name, int scope, enum TYPE type , enum MODE mode){
    if (symbol_index >= MAX_TABLE_SIZE) { // mode 1 -> global
        printf("Error: Symbol table is full\n");
        return;
    }
    symbol_table[symbol_index].name = strdup(name);
    symbol_table[symbol_index].scope = scope;
    symbol_table[symbol_index].type = type;
    symbol_table[symbol_index].mode = mode;
    printf("add to symbol table in counter %d, name : %s, scope : %d, type : %d, mode : %d\n" , symbol_index, name, scope, type, mode);
    symbol_index++;  // Increment the index for the next symbol
}

void pop_symbol(int scope){
    symbol_index--;
    while(symbol_index >= 1){
        if(symbol_table[symbol_index].scope == scope){
            printf("freed : %s\n" , symbol_table[symbol_index].name);
            free(symbol_table[symbol_index].name);
            symbol_index--;
        }
        else{ // need to handle the original scope for the function 
            free(symbol_table[symbol_index].name);
            symbol_index--;
            printf("content : %s and scope %d\n" , symbol_table[symbol_index].name , symbol_table[symbol_index].scope);
            break;
        }
    }
    if(symbol_index <= 0){
        symbol_index = 1;
    }
}

void add_entry(const char *name, enum TYPE type , enum MODE mode){
    if(mode==MODE_ARGUMENT){
        if(arg_index >= MAX_ARG){
            printf("Error: too many arguments\n");
            return;
        }
        arg_table[arg_index].name = strdup(name);
        arg_table[arg_index].type = type;
        arg_table[arg_index].mode = mode;
        printf("add to arg_table : name : %s type : %d mode : %d in index %d\n" , arg_table[arg_index].name , arg_table[arg_index].type , arg_table[arg_index].mode , arg_index);
        arg_index++;
    } else {
        // if(stack_index >= MAX_STACK_SIZE){
        //     printf("Error: Stack is full\n");
        //     return;
        // }
        // stack_table[stack_index].name = strdup(name);
        // stack_table[stack_index].type = type;
        // stack_table[stack_index].mode = mode;
        // printf("add to stack_table : name : %s type : %d mode : %d in index %d\n" , stack_table[stack_index].name , stack_table[stack_index].type , stack_table[stack_index].mode , stack_index);
        // stack_index++;
    } 
}

void symbol_to_asm(int scope, FILE* filePointer){
    int temp = symbol_index-1;
    while(temp >= 1){
        printf("at temp = %d. symbol_table[temp].scope=%d\n", temp, symbol_table[temp].scope);
        if(symbol_table[temp].scope == scope){
            printf("handle symbol table : name : %s scope : %d type : %d mode : %d in index %d\n" , symbol_table[temp].name , scope , symbol_table[temp].type , symbol_table[temp].mode , temp);
            add_entry(symbol_table[temp].name, symbol_table[temp].type , symbol_table[temp].mode);
        } else{
            break;
        }
        //printf("name : %s" , table[temp].name);
        temp--;
    }
    asm_gen(filePointer);
}

void asm_gen(FILE* filePointer){
    // arg->asm
    int temp = 1;
    // int i = 0;
    while(temp <= arg_index-1){
        if(arg_table[temp].type==INT){
            printf("handling arg name : %s  type : %d in index %d\n" , arg_table[temp].name , arg_table[temp].type , temp);
            fprintf(filePointer , "   li a%d , %s\n", arg_index-temp-1, arg_table[temp].name);
        }
        temp++;
    }
    clear_arg();
    // stack->asm
    // temp = 1;
    // while(temp <= stack_index){
    //     printf("handling stack name : %s  type : %d in index %d\n" , stack_table[temp].name , stack_table[temp].type , temp);
    //     temp++;
    // }
    // clear_stack();
}

void clear_stack(){
    int cnt = 1;
    while(stack_table[cnt].name != NULL){
        free(stack_table[cnt].name);
        cnt++;
    }
}

void clear_arg(){
    for (int i=1; i<arg_index; i++){
        if(arg_table[i].name != NULL) free(arg_table[i].name);
    }
    arg_index = 1;
}

// [HW2]

// void type_concat(enum TYPE type , char** original){
//     // original -> <TYPE>original<\TYPE>
//     const char* prefix;
//     const char* postfix;
//     switch(type){
//         case SCLAR_DECL:
//             prefix = "<scalar_decl>";
//             postfix = "</scalar_decl>";
//             break;
//         case ARRAY_DECL:
//             prefix = "<array_decl>";
//             postfix = "</array_decl>";
//             break;
//         case FUNC_DECL:
//             prefix = "<func_decl>";
//             postfix = "</func_decl>";
//             break;
//         case FUNC_DEF:
//             prefix = "<func_def>";
//             postfix = "</func_def>";
//             break;
//         case EXPR:
//             prefix = "<expr>";
//             postfix = "</expr>";
//             break;
//         case STMT:
//             prefix = "<stmt>";
//             postfix = "</stmt>";
//             break;
//         default: 
//             prefix = "<boo>";
//             postfix = "</boo>";
//             break;
//     }
//     size_t totalLen = strlen(prefix) + strlen(*original) + strlen(postfix) + 1;
//     char* temp = (char*)malloc(totalLen * sizeof(char));
//     strcpy(temp , prefix);
//     strcat(temp , *original);
//     strcat(temp , postfix);
//     free(*original);
//     *original = temp;
// }

void handle_1_str(char** original, char* arg_1) {
    char* temp = malloc(sizeof(char) * (strlen(*original) + strlen(arg_1) + 1)); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    free(*original); 
    *original = temp; 
}

void handle_2_str(char** original, char* arg_1, char* arg_2) {
    char* temp = malloc(sizeof(char) * (strlen(*original) + strlen(arg_1) + strlen(arg_2) + 1)); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    strcat(temp, arg_2); 
    //printf("[info] %s,%s,%s -> after: %s\n",*original , arg_1 , arg_2 , temp);
    free(*original); 
    *original = temp; 
}

void handle_3_str(char** original, char* arg_1, char* arg_2, char* arg_3) {
    size_t length = strlen(*original) + strlen(arg_1) + strlen(arg_2) + strlen(arg_3) + 1;
    char* temp = malloc(sizeof(char) * length); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    strcat(temp, arg_2); 
    strcat(temp, arg_3); 
    // printf("[info] %s,%s,%s,%s -> after: %s\n",*original , arg_1 , arg_2 ,arg_3 , temp);
    free(*original); 
    *original = temp; 
}

void handle_4_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4) {
    size_t length = strlen(*original) + strlen(arg_1) + strlen(arg_2) + strlen(arg_3) + strlen(arg_4) + 1;
    char* temp = malloc(sizeof(char) * length); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    strcat(temp, arg_2); 
    strcat(temp, arg_3); 
    strcat(temp, arg_4); 
    free(*original); 
    *original = temp; 
}

void handle_5_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5) {
    size_t length = strlen(*original) + strlen(arg_1) + strlen(arg_2) + strlen(arg_3) + strlen(arg_4) + strlen(arg_5) + 1;
    char* temp = malloc(sizeof(char) * length); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    strcat(temp, arg_2); 
    strcat(temp, arg_3); 
    strcat(temp, arg_4); 
    strcat(temp, arg_5); 
    free(*original); 
    *original = temp; 
}

void handle_6_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5  , char* arg_6) {
    size_t length = strlen(*original) + strlen(arg_1) + strlen(arg_2) + strlen(arg_3) + strlen(arg_4) + strlen(arg_5) + strlen(arg_6) + 1;
    char* temp = malloc(sizeof(char) * length); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    strcat(temp, arg_2); 
    strcat(temp, arg_3); 
    strcat(temp, arg_4); 
    strcat(temp, arg_5); 
    strcat(temp, arg_6); 
    free(*original); 
    *original = temp; 
}

void handle_7_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5, char* arg_6, char* arg_7) {
    size_t length = strlen(*original) + strlen(arg_1) + strlen(arg_2) + strlen(arg_3) + strlen(arg_4) + strlen(arg_5) + strlen(arg_6) + strlen(arg_7) + 1;
    char* temp = malloc(sizeof(char) * length); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    strcat(temp, arg_2); 
    strcat(temp, arg_3); 
    strcat(temp, arg_4); 
    strcat(temp, arg_5); 
    strcat(temp, arg_6); 
    strcat(temp, arg_7); 
    free(*original); 
    *original = temp; 
}

void handle_8_str(char** original, char* arg_1, char* arg_2, char* arg_3, char* arg_4, char* arg_5, char* arg_6, char* arg_7, char* arg_8) {
    size_t length = strlen(*original) + strlen(arg_1) + strlen(arg_2) + strlen(arg_3) + strlen(arg_4) + strlen(arg_5) + strlen(arg_6) + strlen(arg_7) + strlen(arg_8) + 1;
    char* temp = malloc(sizeof(char) * length); 
    strcpy(temp, *original); 
    strcat(temp, arg_1); 
    strcat(temp, arg_2); 
    strcat(temp, arg_3); 
    strcat(temp, arg_4); 
    strcat(temp, arg_5); 
    strcat(temp, arg_6); 
    strcat(temp, arg_7); 
    strcat(temp, arg_8); 
    free(*original); 
    *original = temp; 
}

void special_treatment_to_expr(char** original_left , char* mid_char ,char** original_right){
    const char* prefix = "<expr>";
    const char* postfix = "</expr>";
    size_t left_totalLen = strlen(*original_left)  + strlen(prefix) + strlen(postfix) + 1;
    char* temp_left = (char*)malloc(left_totalLen * sizeof(char));
    strcpy(temp_left , prefix);
    strcat(temp_left , *original_left);
    strcat(temp_left , postfix);
    free(*original_left);
    *original_left = temp_left;
    size_t right_totalLen = strlen(*original_right)  + strlen(prefix) + strlen(postfix) + 1;
    char* temp_right = (char*)malloc(right_totalLen * sizeof(char));
    strcpy(temp_right , prefix);
    strcat(temp_right , *original_right);
    strcat(temp_right , postfix);
    free(*original_right);
    *original_right = temp_right;
}
