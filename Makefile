start:
	flex ./LexicalAnalysis/lexer.l
	gcc lex.yy.c -o l
	
clean:
	rm -f lex.yy.c l
