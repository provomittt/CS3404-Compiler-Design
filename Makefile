parser: lex.yy.c y.tab.c parser_utils.c
	gcc -g lex.yy.c y.tab.c parser_utils.c -o parser

lex.yy.c: y.tab.c scanner.l
	lex scanner.l

y.tab.c: parser.y
	yacc -d parser.y

clean: 
	rm -rf lex.yy.c y.tab.c y.tab.h parser parser.dSYM