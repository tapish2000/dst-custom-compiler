start:
	flex ./LexicalAnalysis/lexer.l
	gcc lex.yy.c -o l
	./l
