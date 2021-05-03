#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "../Definitions.h"
#include "../y.tab.h"

/************ Global Varables ****************/
FILE *asmCode; // for asm code file

extern struct Ast_node *astroot; // root of the tree
extern FILE *yyin;

struct Symbol *iq[30];
int start = 0, end = 0;

int num_ifs = 0;
int num_loops = 0;
int param_bytes = 8;
int registers[20] = {0}; // 0 means registers are free

/************ Required subroutines for code generation *******/
int freeregister()
{
	for (int i = 0; i < 20; i++)
	{
		if (registers[i] == 0)
		{
			return i + 2;
		}
	}
	return -1;
}

void processProgram(struct Ast_node *p, int level)
{
	int offset_bytes = -(8 + int_stack_index * 4);
	if (p->child_node[0])
	{
		generateCode(p->child_node[0], level + 1); // Functions
	}

	fprintf(asmCode, "main:\n");
	fprintf(asmCode, "    addiu $sp,$sp,%d\n", offset_bytes);
	fprintf(asmCode, "    sw $fp,%d($sp)\n", -offset_bytes - 4);
	fprintf(asmCode, "    move $fp,$sp\n");

	generateCode(p->child_node[1], level + 1); // Statements List
	fprintf(asmCode, "    move $2,$0\n    move $sp,$fp\n");
	fprintf(asmCode, "    lw $fp,%d($sp)\n", -offset_bytes - 4);
	fprintf(asmCode, "    addiu $sp,$sp,%d\n", -offset_bytes);
	fprintf(asmCode, "    j $31\nnop\n");
}

void processFunctions(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Next level of Functions
	generateCode(p->child_node[1], level + 1); // Function
}

void processFunction(struct Ast_node *p, int level)
{
	// Not invoked
}

void processFunctionName(struct Ast_node *p, int level)
{
	generateCode(p->child_node[1], level + 1); // Parameters List
}

void processParamList(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Parameters List
	generateCode(p->child_node[1], level + 1); // Parameter
}

void processStmtsList(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Statement
	generateCode(p->child_node[1], level + 1); // Statements List
}

void processBreak()
{
	fprintf(asmCode, "    jmp  endloop%d\n", top_while()->value.ivalue);
}

void processContinue(struct Ast_node *p)
{
	fprintf(asmCode, "    jmp  While%d\n", top_while()->value.ivalue);
}

void processAssignStmt(struct Ast_node *p, int level)
{
	struct Symbol *lhs, *rhs;
	generateCode(p->child_node[0], level + 1); // Parameter
	lhs = popV();
	generateCode(p->child_node[1], level + 1); // Assignment
	rhs = popV();
	int l = freeregister();
	switch (lhs->type)
	{
	case 0:
		switch (rhs->type)
		{
		case 0: // ---- INT = INT ---- //
			switch (rhs->asmclass)
			{
			case 'm':
				fprintf(asmCode, "    lw  $%d, %d($fp)\n", l, rhs->asm_location);
				fprintf(asmCode, "    sw  $%d, %d($fp)\n", l, lhs->asm_location);
				break;
			case 'c':
				fprintf(asmCode, "    li  $%d, %d\n", l, rhs->value.ivalue);
				fprintf(asmCode, "    sw  $%d, %d($fp)\n", l, lhs->asm_location);
				break;
			case 'r':
				fprintf(asmCode, "    sw $%d, %d($fp)\n", rhs->reg, lhs->asm_location);
				registers[rhs->reg - 2] = 0;
				break;
			case 's':
				printf("IMPOSSIBLE (LOCATION=STACK)");
				break;
			}
			break;
		}
		break;
	}
	lhs->value.ivalue = rhs->value.ivalue;

	pushV(lhs);
}

void processArrayAssignStmt(struct Ast_node *p, int level)
{
	struct Symbol *lhs, *data, *rhs;
	generateCode(p->child_node[0], level + 1); // Array
	generateCode(p->child_node[1], level + 1); // Assignment
	rhs = popV();
	lhs = popV();
	int fr = freeregister();
	if (p->child_node[0]->node_type == astArr)
	{
		data = popV();
		switch (lhs->type)
		{
		case 0:
			switch (rhs->type)
			{
			case 0:
				fprintf(asmCode, "    sll  $%d, $%d, 2\n", data->reg, data->reg);
				fprintf(asmCode, "    add  $%d, $%d, $fp\n", data->reg, data->reg);
				fprintf(asmCode, "    sw $%d, %d($%d)\n", rhs->reg, lhs->asm_location, data->reg);
				registers[data->reg - 2] = 0;
				break;
			}
			break;
		}
	}
	else
	{
		switch (lhs->type)
		{
		case 0:
			switch (rhs->type)
			{
			case 0:
				fprintf(asmCode, "    sw  $%d, %d($fp)\n", rhs->reg, lhs->asm_location);
				break;
			}
			break;
		}
	}
	registers[rhs->reg - 2] = 0;
}
void processLoop(struct Ast_node *p, int level)
{
	struct Symbol *lhs;
	struct Symbol *while_symbol;
	int temp_num_loops;

	num_loops++;
	temp_num_loops = num_loops;

	fprintf(asmCode, "loopif%d:\n", temp_num_loops);

	generateCode(p->child_node[0], level + 1); // Conditions
	lhs = popV();

	fprintf(asmCode, "    beq $%d, $0, endloopif%d\n", lhs->reg, temp_num_loops);
	fprintf(asmCode, "    nop\n");

	generateCode(p->child_node[1], level + 1); // Statement List

	fprintf(asmCode, "    b loopif%d\n", temp_num_loops);
	fprintf(asmCode, "endloopif%d:\n", temp_num_loops);
}

void processConditional(struct Ast_node *p, int level)
{
	num_ifs++;
	int temp = num_ifs;
	struct Symbol *lhs;
	generateCode(p->child_node[0], level + 1); // Conditions for if condition or boolean called directly
	lhs = popV();
	fprintf(asmCode, "	beq $%d $0 endif%d\n", lhs->reg, temp);
	generateCode(p->child_node[1], level + 1); // statements list
	fprintf(asmCode, "	b endelse%d\n", temp);
	fprintf(asmCode, "endif%d:\n", temp);
	generateCode(p->child_node[2], level + 1); // remaining conditions
	fprintf(asmCode, "endelse%d:\n", temp);
}

void processElseStmt(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Statements List
}

void processConditions(struct Ast_node *p, int level)
{
	struct Symbol *lhs, *bc, *rhs;
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));

	generateCode(p->child_node[0], level + 1); // Boolean
	lhs = popV();
	generateCode(p->child_node[1], level + 1); // Bi-logic Conditions
	bc = popV();
	generateCode(p->child_node[2], level + 1); // Conditions
	rhs = popV();

	int l = freeregister();
	registers[l - 2] = 1;
	int x;
	if (strcmp(bc->asm_name, "astAnd") == 0)
	{
		x = rhs->value.ivalue && lhs->value.ivalue;
		registers[rhs->reg - 2] = 0;
		registers[lhs->reg - 2] = 0;
		fprintf(asmCode, "	li $%d %d\n", l, x);
	}
	else if (strcmp(bc->asm_name, "astOr") == 0)
	{
		x = rhs->value.ivalue || lhs->value.ivalue;
		registers[rhs->reg - 2] = 0;
		registers[lhs->reg - 2] = 0;
		fprintf(asmCode, "	li $%d %d\n", l, x);
	}
	else if (strcmp(bc->asm_name, "astXor") == 0)
	{
		x = rhs->value.ivalue ^ lhs->value.ivalue;
		registers[rhs->reg - 2] = 0;
		registers[lhs->reg - 2] = 0;
		fprintf(asmCode, "	li $%d %d\n", l, x);
	}
	sym->reg = l;
	sym->value.ivalue = x;
	pushV(sym);
}

void processNotConditions(struct Ast_node *p, int level)
{
	struct Symbol *lhs;
	generateCode(p->child_node[0], level + 1); // Conditions
	lhs = popV();
	fprintf(asmCode, "	li $%d %d\n", lhs->reg, !lhs->value.ivalue);
	lhs->value.ivalue = !lhs->value.ivalue;
	pushV(lhs);
}

void processBoolean(struct Ast_node *p, int level)
{
	struct Symbol *left, *op, *right;
	generateCode(p->child_node[0], level + 1); // Boolean
	left = popV();
	generateCode(p->child_node[1], level + 1); // Relational Operators
	op = popV();
	generateCode(p->child_node[2], level + 1); // Expression
	right = popV();
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	int l, r;
	if (strcmp(op->asm_name, "astLt") == 0)
	{
		if (left->value.ivalue < right->value.ivalue)
		{
			sym->value.ivalue = 1;
		}
		else
		{
			sym->value.ivalue = 0;
		}
		switch (left->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	lw $%d %d($fp)\n", l, left->asm_location);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'r':
			l = left->reg;
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'c':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	li $%d %d\n", l, left->value.ivalue);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		}
		fprintf(asmCode, "	slt $%d $%d $%d\n", l, l, r);
		sym->reg = l;
	}
	else if (strcmp(op->asm_name, "astGt") == 0)
	{
		if (left->value.ivalue > right->value.ivalue)
		{
			sym->value.ivalue = 1;
		}
		else
		{
			sym->value.ivalue = 0;
		}
		switch (left->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	lw $%d %d($fp)\n", l, left->asm_location);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'r':
			l = left->reg;
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'c':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	li $%d %d\n", l, left->value.ivalue);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		}
		fprintf(asmCode, "	slt $%d $%d $%d\n", l, r, l);
		sym->reg = l;
	}
	else if (strcmp(op->asm_name, "astEq") == 0)
	{
		if (left->value.ivalue == right->value.ivalue)
		{
			sym->value.ivalue = 1;
		}
		else
		{
			sym->value.ivalue = 0;
		}
		switch (left->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	lw $%d %d($fp)\n", l, left->asm_location);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'r':
			l = left->reg;
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'c':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	li $%d %d\n", l, left->value.ivalue);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		}
		int k = freeregister();
		fprintf(asmCode, "	slt $%d $%d $%d\n", k, r, l);
		fprintf(asmCode, "	slt $%d $%d $%d\n", k, l, r);
		fprintf(asmCode, "	xori $%d $%d %d\n", k, k, 1);
		sym->reg = l;
	}
	else if (strcmp(op->asm_name, "astNeq") == 0)
	{
		if (left->value.ivalue != right->value.ivalue)
		{
			sym->value.ivalue = 1;
		}
		else
		{
			sym->value.ivalue = 0;
		}
		switch (left->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	lw $%d %d($fp)\n", l, left->asm_location);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'r':
			l = left->reg;
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'c':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	li $%d %d\n", l, left->value.ivalue);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		}
		fprintf(asmCode, "	sub $%d, $%d, $%d\n", l, l, r);
		sym->reg = l;
	}
	else if (strcmp(op->asm_name, "astLte") == 0)
	{
		if (left->value.ivalue <= right->value.ivalue)
		{
			sym->value.ivalue = 1;
		}
		else
		{
			sym->value.ivalue = 0;
		}
		switch (left->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	lw $%d %d($fp)\n", l, left->asm_location);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'r':
			l = left->reg;
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'c':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	li $%d %d\n", l, left->value.ivalue);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		}
		fprintf(asmCode, "	addu $%d $%d 1\n", r, r);
		fprintf(asmCode, "	slt $%d $%d $%d\n", l, l, r);
		sym->reg = l;
	}
	else if (strcmp(op->asm_name, "astGte") == 0)
	{
		if (left->value.ivalue >= right->value.ivalue)
		{
			sym->value.ivalue = 1;
		}
		else
		{
			sym->value.ivalue = 0;
		}
		switch (left->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	lw $%d %d($fp)\n", l, left->asm_location);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'r':
			l = left->reg;
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		case 'c':
			l = freeregister();
			registers[l - 2] = 1;
			fprintf(asmCode, "	li $%d %d\n", l, left->value.ivalue);
			switch (right->asmclass)
			{
			case 'm':
				r = freeregister();
				fprintf(asmCode, "	lw $%d %d($fp)\n", r, right->asm_location);
				break;
			case 'r':
				r = right->reg;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "	li $%d %d\n", r, right->value.ivalue);
				break;
			}
			break;
		}
		fprintf(asmCode, "	addu $%d $%d -1\n", r, r);
		fprintf(asmCode, "	slt $%d $%d $%d\n", l, r, l);
		sym->reg = l;
	}
	pushV(sym);
}

void processReturnStmt(struct Ast_node *p, int level)
{
	// Not invoked
}

void processArrayDecl(struct Ast_node *p, int level)
{
	struct Symbol *sym_node, *lhs, *rhs;
	generateCode(p->child_node[0], level + 1); // Array Type
	if (p->child_node[1] != NULL)
	{
		generateCode(p->child_node[1], level + 1); // Array Assignment
		lhs = p->symbol_node;
		int fr = freeregister();
		int l = lhs->asm_location;
		for (int i = 0; i < lhs->no_elements; i++)
		{
			fprintf(asmCode, "    li $%d, %d, \n", fr, dequeue()->value.ivalue);
			fprintf(asmCode, "    sw $%d, %d($fp), \n", fr, l);
			l = l + 4;
		}
	}
}

void processArrayType(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Array Type
	generateCode(p->child_node[1], level + 1); // Data
}

void processFuncCall(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Function Type - Show
	struct Symbol *sym = popV();
	generateCode(p->child_node[1], level + 1); // Arguments List
	int i;
	struct Symbol *argsList[SYM_TABLE_SIZE];
	// reverse popping
	for (i = sym->no_of_params - 1; i >= 0; i--)
	{
		argsList[i] = popV();
	}
	for (i = 0; i < sym->no_of_params; i++)
	{
		if (argsList[i]->asmclass == 'c')
		{ // constant value printing
			fprintf(asmCode, "    li $a0, %d\n", argsList[i]->value.ivalue);
			fprintf(asmCode, "    li $v0, 1\n");
			fprintf(asmCode, "    syscall\n");
		}
		else if (argsList[i]->asmclass == 'm')
		{
			if (argsList[i]->tag == 'v')
			{ // variable printing
				fprintf(asmCode, "    lw $a0, %d($fp)\n", argsList[i]->asm_location);
				fprintf(asmCode, "    li $v0, 1\n");
				fprintf(asmCode, "    syscall\n");
			}
			else if (argsList[i]->tag == 'a')
			{ // array access and printing
				fprintf(asmCode, "    lw $a0, %d($fp)\n", argsList[i]->asm_location);
				fprintf(asmCode, "    li $v0, 1\n");
				fprintf(asmCode, "    syscall\n");
			}
		}
		else if (argsList[i]->asmclass == 'r')
		{
			fprintf(asmCode, "    addi $a0, $%d, 0\n", argsList[i]->reg);
			fprintf(asmCode, "    li $v0, 1\n");
			fprintf(asmCode, "    syscall\n");
		}
		// for newline printing;
		fprintf(asmCode, "    li $v0, 4\n");
		fprintf(asmCode, "    la $a0, newline\n");
		fprintf(asmCode, "    syscall\n");
	}
}

void processCustomFunc(struct Ast_node *p)
{
	// Not Invoked
}

void processFuncShow(struct Ast_node *p)
{
	pushV(p->symbol_node);
}

void processFuncTake(struct Ast_node *p)
{
	// Not invoked
}

void processArgs(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Arguments
	generateCode(p->child_node[1], level + 1); // Expression
}

void processArrayAssign(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Identifiers List
}

void processIdList(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Identifiers List
	generateCode(p->child_node[1], level + 1); // Constant
}

void processParam(struct Ast_node *p, int level)
{
	pushV(p->symbol_node);
}

void processAssignment(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Expression
}

void processExpr(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Expression
	struct Symbol *lhs = popV();
	generateCode(p->child_node[1], level + 1); // Operator
	struct Symbol *op = popV();
	generateCode(p->child_node[2], level + 1); // Value
	struct Symbol *val = popV();
	struct Symbol * data;
	if(val->tag=='a'){
		data = popV();
	}
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	if (strcmp(op->name, "astAdd") == 0)
	{
		sym->value.ivalue = lhs->value.ivalue + val->value.ivalue;
		sym->asmclass = 'r';
		int l;
		int r;
		switch (lhs->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			lhs->reg = l;
			if (lhs->tag == 'a')
			{
				struct Symbol *data = popV();
				fprintf(asmCode, "	lw $%d %d($fp)\n", l, lhs->asm_location + 4 * (data->value.ivalue));
			}
			else
			{
				fprintf(asmCode, "    lw $%d, %d($fp)\n", l, lhs->asm_location);
			}
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					struct Symbol *data = popV();
					fprintf(asmCode, "	lw $%d %d($fp)\n", r, val->asm_location + 4 * (data->value.ivalue));
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				fprintf(asmCode, "   add $%d, $%d, $%d\n", l, r, l);
				sym->reg = l;
				break;
			case 'c':
				fprintf(asmCode, "	 addu $%d, $%d, %d\n", l, l, val->value.ivalue);
				sym->reg = l;
				break;
			case 'r':
				printf("IMPOSSIBLE ('m'-'r')\n");
				break;
			case 's':
				printf("IMPOSSIBLE ('m'-'s')\n");
				break;
			}
			break;
		case 'c':
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					struct Symbol *data = popV();
					fprintf(asmCode, "	lw $%d %d($fp)\n", r, val->asm_location + 4 * (data->value.ivalue));
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				registers[r - 2] = 1;
				fprintf(asmCode, "    addu $%d, $%d, %d\n", r, r, lhs->value.ivalue);
				sym->reg = r;
				break;
			case 'c':
				sym->value.ivalue = lhs->value.ivalue + val->value.ivalue;
				sym->asmclass = 'c';
				break;
			case 'r':
				printf("IMPOSSIBLE ('c'-'r')\n");
				break;
			case 's':
				printf("IMPOSSIBLE (CONSTANT-STACK)\n");
				break;
			}
			break;
		case 'r':
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					fprintf(asmCode, "    sll  $%d, $%d, 2\n", data->reg, data->reg);
					fprintf(asmCode, "    add  $%d, $%d, $fp\n", data->reg, data->reg);
					fprintf(asmCode, "    lw  $%d, %d($%d)\n", data->reg, val->asm_location, data->reg);
					fprintf(asmCode, "    add $%d, $%d, $%d\n", lhs->reg, lhs->reg, data->reg);
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				fprintf(asmCode, "    add $%d, $%d, $%d\n", lhs->reg, lhs->reg, r);
				sym->reg = lhs->reg;
				break;
			case 'c':
				fprintf(asmCode, "    addu $%d, $%d, %d\n", lhs->reg, lhs->reg, val->value.ivalue);
				sym->value.ivalue = lhs->value.ivalue + val->value.ivalue;
				sym->reg = lhs->reg;
				break;
			case 'r':
				printf("IMPOSSIBLE ('r'-'r')\n");
				break;
			case 's':
				printf("IMPOSSIBLE (CONSTANT-STACK)\n");
				break;
			}
			break;
		}
	}
	else if (strcmp(op->name, "astMul") == 0)
	{
		sym->value.ivalue = lhs->value.ivalue * val->value.ivalue;
		sym->asmclass = 'r';
		int l;
		int r;
		switch (lhs->asmclass)
		{
		case 'm':
			l = freeregister();
			lhs->reg = l;
			if (lhs->tag == 'a')
			{
				struct Symbol *data = popV();
				fprintf(asmCode, "	lw $%d %d($fp)\n", l, lhs->asm_location + 4 * (data->value.ivalue));
			}
			else
			{
				fprintf(asmCode, "    lw $%d, %d($fp)\n", l, lhs->asm_location);
			}
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					struct Symbol *data = popV();
					fprintf(asmCode, "	lw $%d %d($fp)\n", r, val->asm_location + 4 * (data->value.ivalue));
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				registers[r - 2] = 1;
				val->reg = r;
				fprintf(asmCode, "    mult $%d, $%d\n", l, r);
				fprintf(asmCode, "    mflo $%d\n", r);
				sym->reg = r;
				break;
			case 'c':
				r = freeregister();
				fprintf(asmCode, "    li $%d, %d\n", r, val->value.ivalue);
				registers[r - 2] = 1;
				fprintf(asmCode, "    mult $%d, $%d\n", l, r);
				fprintf(asmCode, "    mflo $%d\n", r);
				sym->reg = r;
				break;
			case 'r':
				fprintf(asmCode, "    add  eax, [REG_INT]\n");
				break;
			case 's':
				printf("IMPOSSIBLE ('m'-'s')\n");
				break;
			}
			break;
		case 'c':
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					struct Symbol *data = popV();
					fprintf(asmCode, "	lw $%d %d($fp)\n", r, val->asm_location + 4 * (data->value.ivalue));
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				registers[r - 2] = 1;
				val->reg = r;
				l = freeregister();
				fprintf(asmCode, "    li $%d, %d\n", l, lhs->value.ivalue);
				fprintf(asmCode, "    mult $%d, $%d\n", l, r);
				fprintf(asmCode, "    mflo $%d\n", r);
				sym->reg = r;
				break;
			case 'c':
				sym->value.ivalue = lhs->value.ivalue * val->value.ivalue;
				sym->asmclass = 'c';
				break;
			case 'r':
				fprintf(asmCode, "    mov  eax, %d\n", lhs->value.ivalue);
				fprintf(asmCode, "    add  eax, [REG_INT]\n");
				break;
			case 's':
				printf("IMPOSSIBLE (CONSTANT-STACK)\n");
				break;
			}
			break;
		case 'r':
			r = freeregister();
			switch (val->asmclass)
			{
			case 'm':
				if (val->tag == 'a')
				{
					fprintf(asmCode, "    sll  $%d, $%d, 2\n", data->reg, data->reg);
					fprintf(asmCode, "    add  $%d, $%d, $fp\n", data->reg, data->reg);
					fprintf(asmCode, "    lw  $%d, %d($%d)\n", data->reg, val->asm_location, data->reg);
					fprintf(asmCode, "    add $%d, $%d, $%d\n", lhs->reg, lhs->reg, data->reg);
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				val->reg = r;
				registers[r - 2] = 1;
				fprintf(asmCode, "    mult $%d, $%d\n", lhs->reg, val->reg);
				fprintf(asmCode, "    mflo $%d\n", val->reg);
				sym->reg = val->reg;
				break;
			case 'c':
				fprintf(asmCode, "    li $%d, %d\n", r, val->value.ivalue);
				registers[r - 2] = 1;
				fprintf(asmCode, "    mult $%d, $%d\n", lhs->reg, r);
				fprintf(asmCode, "    mflo $%d\n", r);
				sym->reg = r;
				break;
			case 'r':
				fprintf(asmCode, "    mov  eax, %d\n", lhs->value.ivalue);
				break;
			case 's':
				printf("IMPOSSIBLE (CONSTANT-STACK)\n");
				break;
			}
			break;
		}
	}
	else if (strcmp(op->name, "astSub") == 0)
	{
		sym->value.ivalue = lhs->value.ivalue - val->value.ivalue;
		sym->asmclass = 'r';
		int l;
		int r;
		switch (lhs->asmclass)
		{
		case 'm':
			l = freeregister();
			registers[l - 2] = 1;
			lhs->reg = l;
			if (lhs->tag == 'a')
			{
				struct Symbol *data = popV();
				fprintf(asmCode, "	lw $%d %d($fp)\n", l, lhs->asm_location + 4 * (data->value.ivalue));
			}
			else
			{
				fprintf(asmCode, "    lw $%d, %d($fp)\n", l, lhs->asm_location);
			}
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					struct Symbol *data = popV();
					fprintf(asmCode, "	lw $%d %d($fp)\n", r, val->asm_location + 4 * (data->value.ivalue));
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				fprintf(asmCode, "   sub $%d, $%d, $%d\n", l, r, l);
				sym->reg = l;
				break;
			case 'c':
				fprintf(asmCode, "	 subu $%d, $%d, %d\n", l, l, val->value.ivalue);
				sym->reg = l;
				break;
			case 'r':
				fprintf(asmCode, "    add  eax, [REG_INT]\n");
				break;
			case 's':
				printf("IMPOSSIBLE ('m'-'s')\n");
				break;
			}
			break;
		case 'c':
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					struct Symbol *data = popV();
					fprintf(asmCode, "	lw $%d %d($fp)\n", r, val->asm_location + 4 * (data->value.ivalue));
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				registers[r - 2] = 1;
				fprintf(asmCode, "    subu $%d, $%d, %d\n", r, r, lhs->value.ivalue);
				sym->reg = r;
				break;
			case 'c':
				sym->value.ivalue = lhs->value.ivalue + val->value.ivalue;
				sym->asmclass = 'c';
				break;
			case 'r':
				fprintf(asmCode, "    mov  eax, %d\n", lhs->value.ivalue);
				fprintf(asmCode, "    add  eax, [REG_INT]\n");
				break;
			case 's':
				printf("IMPOSSIBLE (CONSTANT-STACK)\n");
				break;
			}
			break;
		case 'r':
			switch (val->asmclass)
			{
			case 'm':
				r = freeregister();
				if (val->tag == 'a')
				{
					fprintf(asmCode, "    sll  $%d, $%d, 2\n", data->reg, data->reg);
					fprintf(asmCode, "    add  $%d, $%d, $fp\n", data->reg, data->reg);
					fprintf(asmCode, "    lw  $%d, %d($%d)\n", data->reg, val->asm_location, data->reg);
					fprintf(asmCode, "    add $%d, $%d, $%d\n", lhs->reg, lhs->reg, data->reg);
				}
				else
				{
					fprintf(asmCode, "    lw $%d, %d($fp)\n", r, val->asm_location);
				}
				fprintf(asmCode, "  sub $%d, $%d, $%d\n", lhs->reg, lhs->reg, r);
				sym->reg = lhs->reg;
				break;
			case 'c':
				fprintf(asmCode, "    subu $%d, $%d, %d\n", lhs->reg, lhs->reg, val->value.ivalue);
				sym->value.ivalue = lhs->value.ivalue - val->value.ivalue;
				sym->reg = lhs->reg;
				break;
			case 'r':
				fprintf(asmCode, "    mov  eax, %d\n", lhs->value.ivalue);
				break;
			case 's':
				printf("IMPOSSIBLE (CONSTANT-STACK)\n");
				break;
			}
			break;
		}
	}
	pushV(sym);
}

void processValue(struct Ast_node *p, int level)
{
	struct Symbol *sym, *data;
	generateCode(p->child_node[0], level + 1); // Value
	struct Symbol *s = (struct Symbol *)malloc(sizeof(struct Symbol));
	s->asmclass = 'r';
	int fr;
	switch (p->symbol_node->tag)
	{
	case 'a':
		sym = popV();
		data = popV();
		fprintf(asmCode, "    sll  $%d, $%d, 2\n", data->reg, data->reg);
		fprintf(asmCode, "    add  $%d, $%d, $fp\n", data->reg, data->reg);
		fprintf(asmCode, "    lw  $%d, %d($%d)\n", data->reg, sym->asm_location, data->reg);
		s->value.ivalue = data->value.ivalue;
		s->reg = data->reg;
		break;
	case 'v':
		sym = popV();
		fr = freeregister();
		registers[fr - 2] = 1;
		fprintf(asmCode, "    lw  $%d, %d($fp)\n", fr, sym->asm_location);
		s->value.ivalue = sym->value.ivalue;
		s->reg = fr;
		break;
	case 'c':
		sym = popV();
		fr = freeregister();
		registers[fr - 2] = 1;
		fprintf(asmCode, "    li  $%d, %d\n", fr, sym->value.ivalue);
		s->value.ivalue = sym->value.ivalue;
		s->reg = fr;
		break;
	}
	pushV(s);
}

void processArr(struct Ast_node *p, int level)
{
	generateCode(p->child_node[0], level + 1); // Expr
	pushV(p->symbol_node);
}

void processIntConst(struct Ast_node *p)
{
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
	p->symbol_node->asmclass = 'c';
	enqueue(p->symbol_node);
}

void processStrConst(struct Ast_node *p)
{
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
}

void processBoolConst(struct Ast_node *p)
{
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
}

void processFloatConst(struct Ast_node *p)
{
	p->symbol_node->asmclass = 'c';
	pushV(p->symbol_node);
}

void processId(struct Ast_node *p)
{
	p->symbol_node->asmclass = 'm';
	pushV(p->symbol_node);
}

void processLte(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astLte");
	pushV(sym);
}

void processGte(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astGte");
	pushV(sym);
}

void processEq(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astEq");
	pushV(sym);
}

void processNeq(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astNeq");
	pushV(sym);
}

void processGt(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astGt");
	pushV(sym);
}

void processLt(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astLt");
	pushV(sym);
}

void processAnd(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astAnd");
	pushV(sym);
}

void processOr(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astOr");
	pushV(sym);
}

void processXor(struct Ast_node *p)
{
	struct Symbol *sym = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(sym->asm_name, "astXor");
	pushV(sym);
}

/* For handling addition */
void processAdd(struct Ast_node *p)
{
	struct Symbol *new = (struct Symbol *)malloc(sizeof(struct Symbol));
	// set its lavalue and class
	strcpy(new->name, "astAdd");
	pushV(new);
}

void processMul(struct Ast_node *p)
{
	struct Symbol *new = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(new->name, "astMul");
	pushV(new);
}

void processSub(struct Ast_node *p)
{
	struct Symbol *new = (struct Symbol *)malloc(sizeof(struct Symbol));
	strcpy(new->name, "astSub");
	pushV(new);
}

void enqueue(struct Symbol *sym)
{
	if (end == 30)
	{
		end = 0;
	}
	iq[end++] = sym;
	}
struct Symbol *dequeue()
{
	if (start == 30)
	{
		start = 0;
	}
	return iq[start++];
}
void display()
{
	for (int i = 0; i < 30; i++)
	{
		if (iq[i] != NULL)
			printf("%d %d \n", i, iq[i]->value.ivalue);
	}
}

/************ Initializer of asm files ****************/
void enterInitCode()
{
	fprintf(asmCode, ".data\n");
	fprintf(asmCode, "newline:  .asciiz \"\\n\"\n");
	fprintf(asmCode, ".text\n");
}

/************ Code generation by traversing Tree ***************/
void generateCode(struct Ast_node *p, int level)
{
	if (p == NULL)
	{
		return;
	}
	switch (p->node_type)
	{
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
	case astAdd:
		processAdd(p);
		break;
	case astSub:
		processSub(p);
		break;
	case astMul:
		processMul(p);
		break;
	case astLte:
		processLte(p);
		break;
	case astGte:
		processGte(p);
		break;
	case astLt:
		processLt(p);
		break;
	case astGt:
		processGt(p);
		break;
	case astEq:
		processEq(p);
		break;
	case astNeq:
		processNeq(p);
		break;
	case astAnd:
		processAnd(p);
		break;
	case astOr:
		processOr(p);
		break;
	case astXor:
		processXor(p);
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
	case astValue:
		processValue(p, level);
		break;
	case astInt:
		break;
	default:
		printf("%d\n",p->node_type);
		printf("Error in semantics.c: No such Node Type found\n");
		break;
	}
}

void enterEmptyProgramCode()
{
	fprintf(asmCode, "\nNo code added in the program\n");
}

/************ Starter Functions *************/
void main(int argc, char *argv[])
{
	if (argc != 2)
	{
		printf("\nUsage: <exefile> <inputfile>\n\n");
		exit(0);
	}
	Initialize_Tables();
	Init_While_Stack();
	yyin = fopen(argv[1], "r");
	yyparse();
	traverse(astroot, -3);

	asmCode = fopen("./Compiler/AssemblyCode.asm", "w+");

	enterInitCode();
	if (astroot->node_type != astEmptyProgram)
	{
		generateCode(astroot, 0);
	}
	else
	{
		enterEmptyProgramCode();
	}
	fclose(asmCode);
}

void spacing(int n)
{
	int i;
	for (i = 0; i < n; i++)
		printf(" ");
}

/************ Tree traversal for output ************/
void traverse(struct Ast_node *p, int n)
{
	int i;

	n = n + 3;
	if (p)
	{
		switch (p->node_type)
		{
		case astProgram:
			spacing(n);
			printf("astProgram\n");
			break;
		case astFunctions:
			spacing(n);
			printf("astFunctions\n");
			break;
		case astFunction:
			spacing(n);
			printf("astFunction\n");
			break;
		case astFunctionName:
			spacing(n);
			printf("astFunctionName\n");
			break;
		case astParamList:
			spacing(n);
			printf("astParamList\n");
			break;
		case astStmtsList:
			spacing(n);
			printf("astStmtsList\n");
			break;
		case astBreak:
			spacing(n);
			printf("astBreak\n");
			break;
		case astContinue:
			spacing(n);
			printf("astContinue\n");
			break;
		case astAssignStmt:
			spacing(n);
			printf("astAssignStmt\n");
			break;
		case astLoop:
			spacing(n);
			printf("astLoop\n");
			break;
		case astConditional:
			spacing(n);
			printf("astConditional\n");
			break;
		case astRemaiCond:
			spacing(n);
			printf("astRemaiCond\n");
			break;
		case astElifStmts:
			spacing(n);
			printf("astElifStmts\n");
			break;
		case astElseStmt:
			spacing(n);
			printf("astElseStmt\n");
			break;
		case astConditions:
			spacing(n);
			printf("astConditions\n");
			break;
		case astBoolean:
			spacing(n);
			printf("astBoolean\n");
			break;
		case astReturnStmt:
			spacing(n);
			printf("astReturnStmt\n");
			break;
		case astArrayDecl:
			spacing(n);
			printf("astArrayDecl\n");
			break;
		case astFuncCall:
			spacing(n);
			printf("astFuncCall\n");
			break;
		case astCustomFunc:
			spacing(n);
			printf("astCustomFunc\n");
			break;
		case astFuncShow:
			spacing(n);
			printf("astFuncShow\n");
			break;
		case astFuncTake:
			spacing(n);
			printf("astFuncTake\n");
			break;
		case astArgs:
			spacing(n);
			printf("astArgs\n");
			break;
		case astArrayAssign:
			spacing(n);
			printf("astArrayAssign\n");
			break;
		case astIdList:
			spacing(n);
			printf("astIdList\n");
			break;
		case astParam:
			spacing(n);
			printf("astParam\n");
			break;
		case astAssignment:
			spacing(n);
			printf("astAssignment\n");
			break;
		case astExpr:
			spacing(n);
			printf("astExpr\n");
			break;
		case astArr:
			spacing(n);
			printf("astArr\n");
			break;
		case astData:
			spacing(n);
			printf("astData\n");
			break;
		case astInt:
			spacing(n);
			printf("astInt\n");
			break;
		case astBool:
			spacing(n);
			printf("astBool\n");
			break;
		case astStr:
			spacing(n);
			printf("astStr\n");
			break;
		case astDouble:
			spacing(n);
			printf("astDouble\n");
			break;
		case astVoid:
			spacing(n);
			printf("astVoid\n");
			break;
		case astAdd:
			spacing(n);
			printf("astAdd\n");
			break;
		case astSub:
			spacing(n);
			printf("astSub\n");
			break;
		case astMul:
			spacing(n);
			printf("astMul\n");
			break;
		case astDiv:
			spacing(n);
			printf("astDiv\n");
			break;
		case astLte:
			spacing(n);
			printf("astLte\n");
			break;
		case astGte:
			spacing(n);
			printf("astGte\n");
			break;
		case astLt:
			spacing(n);
			printf("astLt\n");
			break;
		case astGt:
			spacing(n);
			printf("astGt\n");
			break;
		case astEq:
			spacing(n);
			printf("astEq\n");
			break;
		case astNeq:
			spacing(n);
			printf("astNeq\n");
			break;
		case astAnd:
			spacing(n);
			printf("astAnd\n");
			break;
		case astOr:
			spacing(n);
			printf("astOr\n");
			break;
		case astXor:
			spacing(n);
			printf("astXor\n");
			break;
		case astIntConst:
			spacing(n);
			printf("astIntConst\n");
			break;
		case astStrConst:
			spacing(n);
			printf("astStrConst\n");
			break;
		case astBoolConst:
			spacing(n);
			printf("astBoolConst\n");
			break;
		case astFloatConst:
			spacing(n);
			printf("astFloatConst\n");
			break;
		case astId:
			spacing(n);
			printf("astId\n");
			break;
		case astValue:
			spacing(n);
			printf("astValue\n");
			break;
		case astArrayAssignStmt:
			spacing(n);
			printf("astArrayAssignStmt\n");
			break;
		default:
			printf("Not Found = %d\n", p->node_type);
		}
		for (i = 0; i < 4; i++)
			traverse(p->child_node[i], n);
	}
}