#include <stdio.h>
#include "Definitions.h"

/************ Tree traversal for output ************/
/************ Required subroutines for code generation *******/
void processProgram(struct Ast_node *p){}
void processFunctions(struct Ast_node *p){}
void processFunction(struct Ast_node *p){}
void processFunctionName(struct Ast_node *p){}
void processParamList(struct Ast_node *p){} 
void processStmtsList(struct Ast_node *p){} 
void processBreak(struct Ast_node *p){} 
void processContinue(struct Ast_node *p){} 
void processAssignStmt(struct Ast_node *p){}
void processLoop(struct Ast_node *p){} 
void processConditional(struct Ast_node *p){}
void processRemaiCond(struct Ast_node *p){} 
void processElifStmts(struct Ast_node *p){} 
void processElseStmt(struct Ast_node *p){} 
void processConditions(struct Ast_node *p){}
void processBoolean(struct Ast_node *p){}
void processReturnStmt(struct Ast_node *p){}
void processArrayDecl(struct Ast_node *p){} 
void processFuncCall(struct Ast_node *p){}
void processCustomFunc(struct Ast_node *p){}
void processFuncShow(struct Ast_node *p){} 
void processFuncTake(struct Ast_node *p){} 
void processArgs(struct Ast_node *p){}
void processArrayAssign(struct Ast_node *p){}
void processIdList(struct Ast_node *p){} 
void processParam(struct Ast_node *p){} 
void processAssignment(struct Ast_node *p){}
void processExpr(struct Ast_node *p){}
void processArr(struct Ast_node *p){}
void processData(struct Ast_node *p){}
void processInt(struct Ast_node *p){}
void processBool(struct Ast_node *p){}
void processStr(struct Ast_node *p){}
void processDouble(struct Ast_node *p){}
void processVoid(struct Ast_node *p){}
void processAdd(struct Ast_node *p){}
void processSub(struct Ast_node *p){}
void processMul(struct Ast_node *p){}
void processDiv(struct Ast_node *p){}
void processLte(struct Ast_node *p){}
void processGte(struct Ast_node *p){}
void processLt(struct Ast_node *p){}
void processGt(struct Ast_node *p){}
void processEq(struct Ast_node *p){}
void processNeq(struct Ast_node *p){}
void processAnd(struct Ast_node *p){}
void processOr(struct Ast_node *p){}
void processXor(struct Ast_node *p){}
void processIntConst(struct Ast_node *p){}
void processStrConst(struct Ast_node *p){}
void processBoolConst(struct Ast_node *p){}
void processFloatConst(struct Ast_node *p){}
void processId(struct Ast_node *p){}


/************ Code generation by traversing Tree ***************/
void generate(struct Ast_node *p){
    switch (p->node_type){
        case astProgram:
            break;
        case astFunctions: 
            break;
        case astFunction: 
            break;
        case astFunctionName: 
            break;
        case astParamList: 
            break;
        case astStmtsList: 
            break;
        case astBreak: 
            break;
        case astContinue: 
            break;
        case astAssignStmt: 
            break;
        case astLoop: 
            break;  
        case astConditional: 
            break;   
        case astRemaiCond: 
            break;
        case astElifStmts: 
            break;
        case astElseStmt: 
            break;
        case astConditions:
            break;
        case astBoolean:
            break;
        case astReturnStmt: 
            break;
        case astArrayDecl: 
            break;
        case astFuncCall:
            break;
        case astCustomFunc:
            break;
        case astFuncShow: 
            break;
        case astFuncTake: 
            break;
        case astArgs:
            break;
        case astArrayAssign:
            break;
        case astIdList: 
            break;
        case astParam: 
            break;
        case astAssignment:
            break;
        case astExpr: 
            break;
        case astArr: 
            break;
        case astData:
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
            break;
        case astStrConst: 
            break;
        case astBoolConst:
            break;
        case astFloatConst:
            break;
        case astId:
            break;
    }
}