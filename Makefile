start: y.tab.c lex.yy.c y.tab.h
	gcc y.tab.c lex.yy.c -o myparser
lex.yy.c: LexicalAnalysis/lexer.l
	lex ./LexicalAnalysis/lexer.l
y.tab.c: SemanticAnalysis/parser.y
	yacc -dv ./SemanticAnalysis/parser.y
	
clean:
	rm -f lex.yy.c y.tab.c y.tab.h myparser y.output
