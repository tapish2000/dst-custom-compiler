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
            processProgram(p);
            break;
        case astFunctions: 
            processFunction(p);
            break;
        case astFunction: 
            processFunction(p);
            break;
        case astFunctionName: 
            processFunctionName(p);
            break;
        case astParamList:
            processParamList(p);
            break;
        case astStmtsList:
            processStmtsList(p);
            break;
        case astBreak:
            processBreak(p);
            break;
        case astContinue:
            processContinue(p);
            break;
        case astAssignStmt:
            processAssignStmt(p);
            break;
        case astLoop:
            processLoop(p);
            break;  
        case astConditional:
            processConditional(p); 
            break;   
        case astRemaiCond:
            processRemaiCond(p);
            break;
        case astElifStmts:
            processElifStmts(p);
            break;
        case astElseStmt:
            processElseStmt(p);
            break;
        case astConditions:
            processConditions(p);
            break;
        case astBoolean:
            processBoolean(p);
            break;
        case astReturnStmt: 
            processReturnStmt(p);
            break;
        case astArrayDecl: 
            processArrayDecl(p);
            break;
        case astFuncCall:
            processFuncCall(p);
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
            processArgs(p);
            break;
        case astArrayAssign:
            processArrayAssign(p);
            break;
        case astIdList: 
            processIdList(p);
            break;
        case astParam:
            processParam(p);
            break;
        case astAssignment:
            processAssignment(p);
            break;
        case astExpr:
            processExpr(p);
            break;
        case astArr:
            processArr(p);
            break;
        case astData:
            processData(p);
            break;
        case astInt:
            processInt(p);
            break;
        case astBool:
            processBool(p);
            break;
        case astStr:
            processStr(p);
            break;
        case astDouble:
            processDouble(p);
            break;
        case astVoid:
            processVoid(p);
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
        case astDiv: 
            processDiv(p);
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
    }
}