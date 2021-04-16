#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "../Definitions.h"
#include "../y.tab.h"

/************ Global Varables ****************/
FILE* asmCode; // for asm code file 
FILE* asmData; // for asm data

extern struct Ast_node *astroot; // root of the tree
extern FILE * yyin;

int num_ifs = 0;
int num_whiles = 0;
int param_bytes = 8;

/************ Tree traversal for output ************/
/************ Required subroutines for code generation *******/
void processProgram(struct Ast_node *p, int level) {
	int offset_bytes = -8;
	if (p->child_node[0]) {
		generateCode(p->child_node[0], level + 1);  // Functions
	}


	fprintf(asmCode, "%s:\n", p->symbol_node->asm_name);
	fprintf(asmCode, "    addiu $sp,$sp,%d\n",offset_bytes);
	fprintf(asmCode, "    sw $fp,%d($sp)\n",-offset_bytes - 4);
	fprintf(asmCode, "    move $fp,$sp\n");

    generateCode(p->child_node[1], level + 1);  // Statements List
	fprintf(asmCode, "	  move $2,$0\nmove $sp,$fp\n");
	fprintf(asmCode, "    lw $fp,%d($sp)\n",-offset_bytes - 4);
	fprintf(asmCode, "    addiu $sp,$sp,%d\n",-offset_bytes);
	fprintf(asmCode, "    j $31\nnop\n");
}

void processFunctions(struct Ast_node *p, int level) {
    generateCode(p->child_node[0], level + 1);  // Next level of Functions
    generateCode(p->child_node[1], level + 1);  // Function
}

void processFunction(struct Ast_node *p, int level) {
	param_bytes = 0;

    generateCode(p->child_node[0], level + 1);  // Function Name

	// fprintf(asmCode, "%s:\n", p->SymbolNode->MIXname);
	fprintf(asmCode, "    push ebp\n");
	fprintf(asmCode, "    mov  ebp, esp\n");

    generateCode(p->child_node[1], level + 1);  // Statements List

	fprintf(asmCode, "\n; ----------------------- ;\n\n");
}

void processFunctionName(struct Ast_node *p, int level) {
    generateCode(p->child_node[1], level + 1);  // Parameters List
}

void processParamList(struct Ast_node *p, int level) {
    generateCode(p->child_node[0], level + 1);  // Parameters List
    generateCode(p->child_node[1], level + 1);  // Parameter
} 

void processStmtsList(struct Ast_node *p, int level) {
    generateCode(p->child_node[0], level + 1);  // Statement
    generateCode(p->child_node[1], level + 1);  // Statements List
} 

void processBreak() {
    fprintf(asmCode, "    jmp  EndWhile%d\n", top_while()->value.ivalue);
} 

void processContinue(struct Ast_node *p) {
    // Will need to find out a way to write asm for continue
} 

void processAssignStmt(struct Ast_node *p, int level) {
	struct Symbol *lhs, *rhs;
    generateCode(p->child_node[0], level + 1);  // Parameter
	lhs = popV();
    generateCode(p->child_node[1], level + 1);  // Assignment
	rhs = popV();
	switch (lhs->type){
		case 0:
			switch (rhs->type){
				case 0:				// ---- INT = INT ---- //
					switch (rhs->asmclass){						
						case 'm':		
							// fprintf(asmCode, "    mov  eax, [%s]\n", rhs->MIXname);
							fprintf(asmCode, "    lw  $2, $%d($fp)\n",rhs->asm_location);
							fprintf(asmCode, "    sw  $2, $%d($fp)\n",param_bytes);
							lhs->asm_location = param_bytes;
							param_bytes += 4;
						break;
						case 'c':
							fprintf(asmCode, "    li  $2, %d\n", rhs->value.ivalue);
							fprintf(asmCode, "    sw  $2, %d($fp)\n", param_bytes);
							lhs->asm_location = param_bytes;
							param_bytes += 4;
						break;
						case 'r':
							// fprintf(asmCode, "    lw  $2, [REG_INT]\n");
						break;
						case 's':
							printf("IMPOSSIBLE (LOCATION=STACK)");
						break;
					}	
					// fprintf(asmCode, "    mov  dword [%s], eax\n", lhs->MIXname);
				break;
			}
		break;
	}	
	pushV(rhs);
}

void processArrayAssignStmt(struct Ast_node *p, int level) {
    generateCode(p->child_node[0], level + 1);  // Array
    generateCode(p->child_node[1], level + 1);  // Assignment
}

void processLoop(struct Ast_node *p, int level) {
    struct Symbol *lhs;
    struct Symbol *while_symbol;
    int temp_num_whiles;

    num_whiles++;
    temp_num_whiles = num_whiles;

    fprintf(asmCode, "    While%d:\n", temp_num_whiles);

    generateCode(p->child_node[0], level + 1);  // Conditions
	// lhs = pop_vs();		// after creating a vs

    switch (lhs->type)
    {
    case 0:     // INTEGER
        switch (lhs->asmclass) 
        {
            case 'm':       // MEMORY
                // while_symbol = makeSymbol("", );    // to be added later
                push_while(while_symbol);

                // fprintf(asmCode, "    mov  ecx, [%s]\n", lhs->MIXname);	// MIX Variables yet to be made
                fprintf(asmCode, "    cmp  ecx, 0\n");
                fprintf(asmCode, "    je   EndWhile%d\n", temp_num_whiles);

                generateCode(p->child_node[1], level + 1);  // Statements List

				fprintf(asmCode, "    jmp  While%d\n", temp_num_whiles);
				fprintf(asmCode, "    EndWhile%d:\n", temp_num_whiles);
				
				pop_while();
				break;
			case 'c':		// CONSTANT
				if (lhs->value.ivalue != 0) {
					// while_symbol = makeSymbol("", );    // to be added later
					push_while(while_symbol);

					generateCode(p->child_node[1], level + 1);  // Statements List

					fprintf(asmCode, "    jmp  While%d\n", temp_num_whiles);
					fprintf(asmCode, "    EndWhile%d:\n", temp_num_whiles);
					
					pop_while();
				}
				break;
			case 'r':		// REGISTER
				// while_symbol = makeSymbol("", );    // to be added later
                push_while(while_symbol);

				fprintf(asmCode, "    mov  ecx, [REG_INT]\n");
				fprintf(asmCode, "    cmp  ecx, 0\n");
				fprintf(asmCode, "    je   EndWhile%d\n", temp_num_whiles);

				generateCode(p->child_node[1], level + 1);  // Statements List

				fprintf(asmCode, "    jmp  While%d\n", temp_num_whiles);
				fprintf(asmCode, "    EndWhile%d:\n", temp_num_whiles);
				
				pop_while();
				break;
			case 's':		// STACK
				printf("STACK in loopif - Not Possible\n");
				break;
        }
        break;
    case 1:		// DOUBLE
		switch (lhs->asmclass) 
        {
            case 'm':       // MEMORY
                // while_symbol = makeSymbol("", );    // to be added later
                push_while(while_symbol);

                // fprintf(asmCode, "    fld  qword [%s]\n", lhs->MIXname);	// MIX Variables yet to be made
                fprintf(asmCode, "    fldz\n");
				fprintf(asmCode, "    fcomip\n");
				fprintf(asmCode, "    ffreep\n");
				fprintf(asmCode, "    jz   EndWhile%d\n", temp_num_whiles);

                generateCode(p->child_node[1], level + 1);  // Statements List

				fprintf(asmCode, "    jmp  While%d\n", temp_num_whiles);
				fprintf(asmCode, "    EndWhile%d:\n", temp_num_whiles);
				
				pop_while();
				break;
			case 'c':		// CONSTANT
				if (lhs->value.ivalue != 0) {
					// while_symbol = makeSymbol("", );    // to be added later
					push_while(while_symbol);

					generateCode(p->child_node[1], level + 1);  // Statements List

					fprintf(asmCode, "    jmp  While%d\n", temp_num_whiles);
					fprintf(asmCode, "    EndWhile%d:\n", temp_num_whiles);
					
					pop_while();
				}
				break;
			case 'r':		// REGISTER
				// while_symbol = makeSymbol("", );    // to be added later
                push_while(while_symbol);

				fprintf(asmCode, "    fld  qword [REG_REAL]\n");
				fprintf(asmCode, "    fldz\n");
				fprintf(asmCode, "    fcomip\n");
				fprintf(asmCode, "    ffreep\n");
				fprintf(asmCode, "    jz   EndWhile%d\n", temp_num_whiles);

				generateCode(p->child_node[1], level + 1);  // Statements List

				fprintf(asmCode, "    jmp  While%d\n", temp_num_whiles);
				fprintf(asmCode, "    EndWhile%d:\n", temp_num_whiles);
				
				pop_while();
				break;
			case 's':		// STACK
				printf("STACK in loopif - Not Possible\n");
				break;
        }
        break;
    default:
		printf("Error in semantics.c: Neither INTEGER nor DOUBLE");
        break;
    }
} 

void processConditional(struct Ast_node *p, int level) {
	struct Symbol* lhs;
	generateCode(p->child_node[0], level + 1);	// Conditions for if condition
	lhs = pop_while();
	int temp_ifs = 0;
	switch (lhs->type){
		// Integer type
		case 0:
			switch (lhs->asmclass){
				case 'm':
					num_ifs++;
					temp_ifs = num_ifs;
					fprintf(asmCode, "    mov  ecx, [%s]\n",lhs->asm_name);
					fprintf(asmCode, "    cmp  ecx, 0\n");
					fprintf(asmCode, "    je   EndIf%d\n", temp_ifs);
					generateCode(p->child_node[1], level + 1);	// Statements List for if condition
					break;
				case 'r':
					num_ifs++;
					temp_ifs = num_ifs;
					fprintf(asmCode, "    mov  ecx, [REG_INT]\n");
					fprintf(asmCode, "    cmp  ecx, 0\n");
					fprintf(asmCode, "    je   EndIf%d\n", temp_ifs);
					generateCode(p->child_node[1], level + 1);	// Statements List for if condition
					break;
				case 'c':
					generateCode(p->child_node[1], level + 1);	// Statements List for if condition
					break;
				case 's':
					printf("\nStack call not possible for if statement\n");
					break;
			}
			break;
		// Double Type
		case 1:
			break;
		// String Type
		case 2:
			break;
		// Boolean Type
		case 3:
			break;
		default:
			break;
	}
	generateCode(p->child_node[2], level + 1);	// Remaining Conditions
	fprintf(asmCode, "    EndIf%d:\n", temp_ifs); // Ending the if caluse
}

void processRemaiCond(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Elif Statements
	generateCode(p->child_node[1], level + 1);	// Else Statement
} 

void processElifStmts(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Elif Statements
	generateCode(p->child_node[1], level + 1);	// Conditions
	generateCode(p->child_node[2], level + 1);	// Statements List
} 

void processElifStmt(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Conditions
	generateCode(p->child_node[1], level + 1);	// Statements List
}

void processElseStmt(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Statements List
} 

void processConditions(struct Ast_node *p, int level) {
	printf("ConditionsCheck1\n");
	generateCode(p->child_node[0], level + 1);	// Boolean
	printf("ConditionsCheck2\n");
	generateCode(p->child_node[1], level + 1);	// Bi-logic Conditions
	printf("ConditionsCheck3\n");
	generateCode(p->child_node[2], level + 1);	// Conditions
	printf("ConditionsCheck4\n");
	
}

void processNotConditions(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Conditions
}

void processBoolean(struct Ast_node *p, int level) {
	printf("BooleanCheck1\n");
	generateCode(p->child_node[0], level + 1);	// Boolean
	printf("BooleanCheck2\n");
	generateCode(p->child_node[1], level + 1);	// Relational Operators
	printf("BooleanCheck3\n");
	generateCode(p->child_node[2], level + 1);	// Expression
	printf("BooleanCheck4\n");
	
}

void processReturnStmt(struct Ast_node *p, int level) {
	struct Symbol *current_method;
	struct Symbol *lhs;

	generateCode(p->child_node[0], level + 1);
	// lhs = pop_vs();		// after creating a vs

	current_method = p->symbol_node;

	switch (current_method->type)
	{
	case 0:		// INTEGER
		switch (lhs->type) {
			case 0:		// return INTEGER on INTEGER method
				switch(lhs->asmclass){
					case 'm':		// MEMORY
						// fprintf(asmCode, "    mov  eax, [%s]\n", lhs->MIXname);	// after creating MIX Variables
						break;
					case 'c':		// CONSTANT
						fprintf(asmCode, "    mov  eax, %d\n", lhs->value.ivalue);
						break;
					case 'r':		// REGISTER
						fprintf(asmCode, "    mov  eax, [REG_INT]\n");
						break;
					case 's':		// STACK
						printf("STACK in return - Not Possible\n");
						break;
				}
				break;
			case 1:		// return INTEGER on INTEGER method
				switch(lhs->asmclass){
					case 'm':						
						// fprintf(asmCode, "    fld  qword [%s]\n", lhs->MIXname);
						// fprintf(asmData, "int_for_conversion_%d dd 0\n", ++countIntForConversions);
						// fprintf(asmCode, "    fistp dword [int_for_conversion_%d]\n", countIntForConversions);			
						// fprintf(asmCode, "    mov  eax, [int_for_conversion_%d]\n", countIntForConversions);	
						break;
					case 'c':
						// fprintf(asmData, "real_constant_%d dq %lf\n", ++countRealConsts, lhs->value.dvalue);
						// fprintf(asmCode, "    fld  qword [real_constant_%d]\n", countRealConsts);
						// fprintf(asmData, "int_for_conversion_%d dd 0\n", ++countIntForConversions);
						// fprintf(asmCode, "    fistp dword [int_for_conversion_%d]\n", countIntForConversions);			
						// fprintf(asmCode, "    mov  eax, [int_for_conversion_%d]\n", countIntForConversions);	
						break;
					case 'r':
						fprintf(asmCode, "    fld  qword [REG_REAL]\n");
						// fprintf(asmData, "int_for_conversion_%d dd 0\n", ++countIntForConversions);
						// fprintf(asmCode, "    fistp dword [int_for_conversion_%d]\n", countIntForConversions);			
						// fprintf(asmCode, "    mov  eax, [int_for_conversion_%d]\n", countIntForConversions);	
						break;
					case 's':
						printf("STACK in return - Not Possible\n");
						break;
				}
				break;
		}
		break;
	case 1:		// DOUBLE
		switch (lhs->type){
			case 0:		// return INTEGER on DOUBLE method
				switch(lhs->asmclass){
					case 'm':	
						// fprintf(asmCode, "    fild dword [%s]\n", lhs->MIXname);
						break;
					case 'c':
						// fprintf(asmData, "int_for_conversion_%d dd %d\n", ++countIntForConversions, lhs->value.ivalue);
						// fprintf(asmCode, "    fild dword [int_for_conversion_%d]\n", countIntForConversions);
						break;
					case 'r':
						fprintf(asmCode, "    fild dword [REG_INT]\n");
						break;
					case 's':
						printf("STACK in return - Not Possible\n");
						break;
				}
				break;
			case 1:		// return DOUBLE on DOUBLE method
				switch(lhs->asmclass){
					case 'm':	
						// fprintf(asmCode, "    fld  qword [%s]\n", lhs->MIXname);
						break;
					case 'c':
						// fprintf(asmData, "real_constant_%d dq %lf\n", ++countRealConsts, lhs->value.dvalue);
						// fprintf(asmCode, "    fld  qword [real_constant_%d]\n", countRealConsts);
						break;
					case 'r':
						fprintf(asmCode, "    fld  qword [REG_REAL]\n");
						break;
					case 's':
						printf("STACK in return - Not Possible\n");
						break;
				}
				break;
		}
		break;
	default:
		printf("Error in semantics.c: Neither INTEGER nor DOUBLE");
		break;
	}

	fprintf(asmCode, "    mov  esp, ebp\n");
	fprintf(asmCode, "    pop  ebp\n");
	// fprintf(asmCode, "    ret  %d\n", bytesForParams);	

}

void processArrayDecl(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Array Type
	generateCode(p->child_node[1], level + 1);	// Data
	generateCode(p->child_node[2], level + 1);	// Array Assignment
} 


void processArrayType(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Array Type
	generateCode(p->child_node[1], level + 1);	// Data
}

void processFuncCall(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Function Type
	generateCode(p->child_node[1], level + 1);	// Arguments List
}

void processCustomFunc(struct Ast_node *p) {

}

void processFuncShow(struct Ast_node *p) {

} 

void processFuncTake(struct Ast_node *p) {

} 

void processArgs(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Arguments
	generateCode(p->child_node[1], level + 1);	// Expression
}

void processArrayAssign(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Identifiers List
}

void processIdList(struct Ast_node *p, int level) { 
	generateCode(p->child_node[0], level + 1);	// Identifiers List
	generateCode(p->child_node[1], level + 1);	// Constant
} 

void processParam(struct Ast_node *p, int level) {
	printf("processParam - %d\n", p->symbol_node->type);
	switch (p->symbol_node->type)
	{
	case 0:
		param_bytes += 4;
		break;
	
	case 1:
		param_bytes += 8;
		break;
	
	default:
		break;
	}
	pushV(p->symbol_node);
} 

void processAssignment(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Expression
}

void processExpr(struct Ast_node *p, int level) {
	printf("ExprCheck1\n");
	generateCode(p->child_node[0], level + 1);	// Expression
	printf("ExprCheck2\n");
	generateCode(p->child_node[1], level + 1);	// Operator
	printf("ExprCheck3\n");
	generateCode(p->child_node[2], level + 1);	// Value
	printf("ExprCheck4\n");
}

void processArr(struct Ast_node *p, int level) {
	generateCode(p->child_node[0], level + 1);	// Array
	generateCode(p->child_node[1], level + 1);	// Data
}

void processData(struct Ast_node *p) {

}

void processIntConst(struct Ast_node *p) {
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
	printf("processIntConst - %d\n", p->node_type);
	p->symbol_node->asmclass = 'c';
	// push_vs(p->symbol_node);
}

void processStrConst(struct Ast_node *p) {
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
	// push_vs(p->symbol_node);
}

void processBoolConst(struct Ast_node *p) {
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
	// push_vs(p->symbol_node);
}

void processFloatConst(struct Ast_node *p) {
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
	// push_vs(p->symbol_node);
}

void processId(struct Ast_node *p) {
	p->symbol_node->asmclass = 'r';
	pushV(p->symbol_node);
	printf("Checking %d----->\n",p->symbol_node->type);
	// Not clear what to write here, to be discussed
}



/************ Initializer of asm files ****************/
void enterInitCode() {
    fprintf(asmData, "section .data\n\n");
	fprintf(asmData, "cw dw 057fH\n");
	fprintf(asmData, "integer_1 dd 1\n");
	fprintf(asmData, "REG_INT  dd 0\n");
	fprintf(asmData, "REG_REAL dq 0.0\n");
	fprintf(asmData, "format_read_int db \"%%d\", 0\n");
	fprintf(asmData, "format_read_char db \"%%c\", 0\n");
	fprintf(asmData, "format_read_real db \"%%lf\", 0\n");
	fprintf(asmCode, "\nsection .text\n\n");
	fprintf(asmCode, "extern _printf\n");
	fprintf(asmCode, "extern _scanf\n");
	fprintf(asmCode, "global _main\n");
	fprintf(asmCode, "_main:\n");
	fprintf(asmCode, "    fldcw [cw]\n");
	fprintf(asmCode, "    call _source_start\n");
	fprintf(asmCode, "    ret\n");
	
	fprintf(asmCode, "\n; ----------------------- ;\n\n");
}


/************ Code generation by traversing Tree ***************/
void generateCode(struct Ast_node *p, int level) {
	printf("Check1:Shubh\n");
	if (p == NULL) {
		return;
	}
	printf("Check2:Shubh\n");
    printf("%d\n", p->node_type);
	printf("Check3:Shubh\n");
    switch (p->node_type){
        case astEmptyProgram:
            break;
        case astProgram:
            processProgram(p, level);
            break;
        case astFunctions: 
            processFunctions(p, level);
            break;
        case astFunction: 
            processFunction(p, level);
            break;
        case astFunctionName: 
            processFunctionName(p, level);
            break;
        case astParamList:
            processParamList(p, level);
            break;
        case astStmtsList:
            processStmtsList(p, level);
            break;
        case astBreak:
            processBreak();
            break;
        case astContinue:
            processContinue(p);
            break;
        case astAssignStmt:
            processAssignStmt(p, level);
            break;
        case astArrayAssignStmt:
            processArrayAssignStmt(p, level);
            break;
        case astLoop:
            processLoop(p, level);
            break;  
        case astConditional:
            processConditional(p, level); 
            break;   
        case astRemaiCond:
            processRemaiCond(p, level);
            break;
        case astElifStmts:
            processElifStmts(p, level);
            break;
		case astElifStmt:
			processElifStmt(p, level);
			break;
        case astElseStmt:
            processElseStmt(p, level);
            break;
        case astConditions:
            processConditions(p, level);
            break;
		case astNotConditions:
			processNotConditions(p, level);
			break;
        case astBoolean:
            processBoolean(p, level);
            break;
        case astReturnStmt: 
            processReturnStmt(p, level);
            break;
        case astArrayDecl: 
            processArrayDecl(p, level);
            break;
        case astArrayType:
            processArrayType(p, level);
            break;
        case astFuncCall:
            processFuncCall(p, level);
            break;
        case astCustomFunc:
            processCustomFunc(p);
            break;
        case astFuncShow:
            processFuncShow(p);
            break;
        case astFuncTake:
            processFuncTake(p);
            break;
        case astArgs:
            processArgs(p, level);
            break;
        case astArrayAssign:
            processArrayAssign(p, level);
            break;
        case astIdList: 
            processIdList(p, level);
            break;
        case astParam:
            processParam(p, level);
            break;
        case astAssignment:
            processAssignment(p, level);
            break;
        case astExpr:
            processExpr(p, level);
            break;
        case astArr:
            processArr(p, level);
            break;
        case astData:
            processData(p);
            break;
        case astInt:
            
            break;
        case astBool:
            
            break;
        case astStr:
            
            break;
        case astDouble:
            
            break;
        case astVoid:
            
            break;
        case astAdd:
            
            break;
        case astSub: 
            
            break;
        case astMul:
            
            break;
        case astDiv: 
            
            break;
        case astLte:
            
            break;
        case astGte:
            
            break;
        case astLt:
            
            break;
        case astGt:
            
            break;
        case astEq:
            
            break;
        case astNeq:
            
            break;
        case astAnd:
            
            break;
        case astOr:
            
            break;
        case astXor:
            
            break;
        case astIntConst:
            processIntConst(p);
            break;
        case astStrConst:
            processStrConst(p);
            break;
        case astBoolConst:
            processBoolConst(p);
            break;
        case astFloatConst:
            processFloatConst(p);
            break;
        case astId:
            processId(p);
            break;
        default:
            printf("Error in semantics.c: No such Node Type found");
            break;
    }
}

void enterEmptyProgramCode() {
    fprintf(asmCode, "\nsection .text\n");
	fprintf(asmCode, "global _main\n");
	fprintf(asmCode, "_main:\n");
	fprintf(asmCode, "    ret\n");
}


/************ Starter Functions *************/
void main(int argc, char *argv[]) {
	if (argc != 2) {
		printf("\nUsage: <exefile> <inputfile>\n\n");
		exit(0);
	}
	// Initialize_Tables();
    Initialize_Tables();
    Init_While_Stack();
	yyin = fopen(argv[1], "r");
	yyparse();
	traverse(astroot, -3);
	// Print_Tables();

    asmData = fopen("./Compiler/AssemblyData.asm", "w+");
    asmCode = fopen("./Compiler/AssemblyCode.asm", "w+");

	printf("Debug1\n");
    if (astroot->node_type != astEmptyProgram) {
		printf("Debug2\n");
        enterInitCode();
		printf("Debug3\n");
        generateCode(astroot, 0);
		printf("Debug4\n");
    }
    else {
        enterEmptyProgramCode();
    }
    fclose(asmData);
    fclose(asmCode);
}

void spacing(int n)
{  
	int i;   
	for(i=0; i<n; i++) printf(" ");
}

void traverse(struct Ast_node *p, int n)
{  
	int i;

    n=n+3;
    if(p)
    {
		switch (p->node_type)
		{
			case astProgram: 
				spacing(n); printf("astProgram\n"); 
				break;
			case astFunctions: 
				spacing(n); printf("astFunctions\n"); 
				break;
			case astFunction: 
				spacing(n); printf("astFunction\n"); 
				break;
			case astFunctionName: 
				spacing(n); printf("astFunctionName\n"); 
				break;
			case astParamList: 
				spacing(n); printf("astParamList\n"); 
				break;
			case astStmtsList: 
				spacing(n); printf("astStmtsList\n"); 
				break;
			case astBreak: 
				spacing(n); printf("astBreak\n"); 
				break;
			case astContinue: 
				spacing(n); printf("astContinue\n"); 
				break;
			case astAssignStmt: 
				spacing(n); printf("astAssignStmt\n"); 
				break;
			case astLoop: 
				spacing(n); printf("astLoop\n"); 
				break;  
			case astConditional: 
				spacing(n); printf("astConditional\n"); 
				break;   
			case astRemaiCond: 
				spacing(n); printf("astRemaiCond\n"); 
				break;
			case astElifStmts: 
				spacing(n); printf("astElifStmts\n"); 
				break;
			case astElseStmt: 
				spacing(n); printf("astElseStmt\n"); 
				break;
			case astConditions: 
				spacing(n); printf("astConditions\n"); 
				break;
			case astBoolean:
				spacing(n); printf("astBoolean\n"); 
				break;
			case astReturnStmt: 
				spacing(n); printf("astReturnStmt\n"); 
				break;
			case astArrayDecl: 
				spacing(n); printf("astArrayDecl\n"); 
				break;
			case astFuncCall: 
				spacing(n); printf("astFuncCall\n"); 
				break;
			case astCustomFunc: 
				spacing(n); printf("astCustomFunc\n"); 
				break;
			case astFuncShow: 
				spacing(n); printf("astFuncShow\n"); 
				break;
			case astFuncTake: 
				spacing(n); printf("astFuncTake\n"); 
				break;
			case astArgs:
				spacing(n); printf("astArgs\n"); 
				break;
			case astArrayAssign: 
				spacing(n); printf("astArrayAssign\n"); 
				break;
			case astIdList: 
				spacing(n); printf("astIdList\n"); 
				break;
			case astParam: 
				spacing(n); printf("astParam\n"); 
				break;
			case astAssignment: 
				spacing(n); printf("astAssignment\n"); 
				break;
			case astExpr: 
				spacing(n); printf("astExpr\n"); 
				break;
			case astArr: 
				spacing(n); printf("astArr\n"); 
				break;
			case astData: 
				spacing(n); printf("astData\n"); 
				break;
			case astInt: 
				spacing(n); printf("astInt\n"); 
				break;
			case astBool: 
				spacing(n); printf("astBool\n"); 
				break;
			case astStr: 
				spacing(n); printf("astStr\n"); 
				break;
			case astDouble: 
				spacing(n); printf("astDouble\n"); 
				break;
			case astVoid: 
				spacing(n); printf("astVoid\n"); 
				break;
			case astAdd: 
				spacing(n); printf("astAdd\n"); 
				break;
			case astSub: 
				spacing(n); printf("astSub\n"); 
				break;
			case astMul: 
				spacing(n); printf("astMul\n"); 
				break;
			case astDiv: 
				spacing(n); printf("astDiv\n"); 
				break;
			case astLte:
				spacing(n); printf("astLte\n"); 
				break;
			case astGte:
				spacing(n); printf("astGte\n"); 
				break;
			case astLt:
				spacing(n); printf("astLt\n"); 
				break;
			case astGt: 
				spacing(n); printf("astGt\n"); 
				break;
			case astEq: 
				spacing(n); printf("astEq\n"); 
				break;
			case astNeq: 
				spacing(n); printf("astNeq\n"); 
				break;
			case astAnd: 
				spacing(n); printf("astAnd\n");
				break;
			case astOr: 
				spacing(n); printf("astOr\n"); 
				break;
			case astXor: 
				spacing(n); printf("astXor\n"); 
				break;
			case astIntConst: 
				spacing(n); printf("astIntConst\n"); 
				break;
			case astStrConst: 
				spacing(n); printf("astStrConst\n"); 
				break;
			case astBoolConst: 
				spacing(n); printf("astBoolConst\n"); 
				break;
			case astFloatConst: 
				spacing(n); printf("astFloatConst\n"); 
				break;
			case astId:
				spacing(n); printf("astId\n"); 
				break;
			default: 
				printf("AGNOSTO=%d\n",p->node_type);
		}
		for(i=0; i<4; i++) traverse(p->child_node[i],n);
	}
}