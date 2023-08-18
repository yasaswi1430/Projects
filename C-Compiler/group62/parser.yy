%skeleton "lalr1.cc"
%require  "3.0.1"

%defines 
%define api.namespace {IPL}
%define api.parser.class {Parser}
%define api.location.type{IPL::location}

%define parse.trace


%code requires{

   #include "ast.hh"
   #include "symtab.hh"
   #include "location.hh"


   namespace IPL {
      class Scanner;
   }

  // # ifndef YY_NULLPTR
  // #  if defined __cplusplus && 201103L <= __cplusplus
  // #   define YY_NULLPTR nullptr
  // #  else
  // #   define YY_NULLPTR 0
  // #  endif
  // # endif

}

%printer { std::cerr << $$; } IDENTIFIER
%printer { std::cerr << $$; } OTHERS
%printer { std::cerr << $$; } EOFILE 
%printer { std::cerr << $$; } STRUCT 
%printer { std::cerr << $$; } VOID 
%printer { std::cerr << $$; } INT
%printer { std::cerr << $$; } FLOAT
%printer { std::cerr << $$; } INT_CONSTANT
%printer { std::cerr << $$; } FLOAT_CONSTANT
%printer { std::cerr << $$; } RETURN
%printer { std::cerr << $$; } OR_OP
%printer { std::cerr << $$; } AND_OP
%printer { std::cerr << $$; } EQ_OP
%printer { std::cerr << $$; } NE_OP
%printer { std::cerr << $$; } LE_OP
%printer { std::cerr << $$; } GE_OP
%printer { std::cerr << $$; } IF
%printer { std::cerr << $$; } ELSE
%printer { std::cerr << $$; } INC_OP
%printer { std::cerr << $$; } PTR_OP
%printer { std::cerr << $$; } STRING_LITERAL
%printer { std::cerr << $$; } WHILE
%printer { std::cerr << $$; } FOR


%parse-param { Scanner  &scanner  }
%locations
%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   #include <string>
   #include <cstring>
   #include <map>
   
   
   
   #include "scanner.hh"
     int k=1;
     std::string curfun;
     std::string cftype;
     std::string psid;
     vector<entry*> listtemp;
     global_st * gst;
     local_st* lst;
     std::map<std::string, entry*> gstmap;
     std::map<std::string, std::vector<entry*>> structlstmap;
     std::map<std::string, std::vector<entry*>> funmap;
     std::map<std::string, abstract_astnode*> funastmap;
     vector<std::string> lclist;
   

#undef yylex
#define yylex IPL::Parser::scanner.yylex

}




%define api.value.type variant
%define parse.assert

%start spirit



%token '\n' '\t'
%token <std::string> OTHERS
%token <std::string> EOFILE 
%token <std::string> STRUCT 
%token <std::string> VOID 
%token <std::string> INT
%token <std::string> FLOAT
%token <std::string> INT_CONSTANT
%token <std::string> FLOAT_CONSTANT
%token <std::string> RETURN
%token <std::string> OR_OP
%token <std::string> AND_OP
%token <std::string> EQ_OP
%token <std::string> NE_OP
%token <std::string> LE_OP
%token <std::string> GE_OP
%token <std::string> IF
%token <std::string> ELSE
%token <std::string> INC_OP
%token <std::string> PTR_OP
%token <std::string> STRING_LITERAL
%token <std::string> WHILE
%token <std::string> FOR
%token <std::string> IDENTIFIER
%token ',' ':' '(' ')' '+' '{' '}' '*' '[' ']' ';' '=' '<' '>' '-' '!' '&' '/' 

%nterm <abstract_astnode*> spirit translation_unit struct_specifier function_definition compound_statement statement statement_list assignment_statement procedure_call expression logical_and_expression equality_expression relational_expression additive_expression unary_expression multiplicative_expression postfix_expression primary_expression expression_list selection_statement iteration_statement
<assignE_astnode*> assignment_expression
<std::string> unary_operator fun_declarator type_specifier
<std::vector<entry*>> declaration_list declarator_list declaration parameter_list
<entry*> declarator declarator_arr parameter_declaration
%%

spirit:
     translation_unit{
          cout<<"\t"<<".section    .rodata\n";
          for (int i=0;i<lclist.size();i++){
               cout<<".LC"<<i<<":\n\t.string\t"<<lclist[i]<<"\n";
          }
          for (auto i=funmap.begin();i!=funmap.end();++i){
               map<string,entry*> lmap;
               int size=i->second.size();
               for(int j=0;j<size;j++){
                    lmap[i->second[j]->name]=i->second[j];
               }
               cout<<"\t.text\n\t.globl\t"<<i->first<<"\n\t.type\t"<<i->first<<", @function\n";
               cout<<i->first<<":\n";
               cout<<"\tpushl\t%ebp\n\tmovl\t%esp, %ebp\n";
               int localoffset=0;
               for (auto j=lmap.begin();j!=lmap.end();++j){
                    if(j->second->gl=="param"){
                         mytype* tp=new mytype(j->second->type1,0);
                         if(tp->ptrdepth==0 && tp->arrdepth==0 && tp->basetype.substr(0,6)=="struct"){
                              localoffset+=gstmap[tp->basetype]->size;
                         }
                         else{
                              localoffset+=4;
                         }
                    }
                    else{
                         localoffset+=j->second->size;
                    }
               }
               if(localoffset){
                    cout<<"\tsubl\t$"<<localoffset<<", %esp\n";
               }

               abstract_astnode* xyz=new seq_astnode(funastmap[i->first]->list);
               vector<std::string> reg{"%esi","%edi","%edx","%ecx","%ebx","%eax"};
               xyz->print(reg,lmap);
               if(i->first=="main"){
                    cout<<"\tmovl\t$0, %eax\n";
               }
               cout<<"\tleave\n\tret\n";
          }
     }

translation_unit:
     struct_specifier {}

     | function_definition {}

     | translation_unit struct_specifier {}

     | translation_unit function_definition {}

struct_specifier: 
     STRUCT IDENTIFIER {psid=$2;} '{' declaration_list '}' ';' {
          vector<entry*> vect=$5;
          int size=vect.size();
          vect[0]->offset=0;
          for (int i=0;i<size;i++){
               $5[i]->type0="var";
               $5[i]->gl="local";
          }
          listtemp.clear();
          for(int i=1;i<size;i++){
               vect[i]->offset=vect[i-1]->size+vect[i-1]->offset;
          }
          int s=vect[size-1]->size+vect[size-1]->offset;
          string name="struct "+$2;
          if(structlstmap.find(name)==structlstmap.end()){
               structlstmap[name]=$5;
          }
          else error(@1,"\""+name+"\" has a previous definition");
          entry* ent=new entry("struct "+$2,"struct","global",s,0,"-");
          gstmap["struct "+$2]=ent;
          psid="";
     }

function_definition: 
     type_specifier fun_declarator { 
          if ($1.substr(0,6)=="struct"){
               if (gstmap.find($1)==gstmap.end())error(@1,"\""+$1+"\" not declared");
          }
          cftype=$1; 
          curfun=$2;
          } compound_statement
          
          
          {
          funmap[$2]=listtemp;
          listtemp.clear();
          gstmap[$2]->type1=$1;
          vector<abstract_astnode*> slist;
          slist=$4->list;
          $$=new seq_astnode(slist);
          funastmap[$2]=$$;
     }

type_specifier: 
     VOID {
          $$=$1;
     }
     | INT {
          $$=$1;
     }
     | FLOAT {
          $$=$1;
     }
     | STRUCT IDENTIFIER {
          $$=$1+" "+$2;
     }

fun_declarator: 
     IDENTIFIER '(' parameter_list ')' {
          if (funmap.find($1)==funmap.end()){
               vector<entry*> vect;
               funmap[$1]=vect;
               vector<std::string> check;
               for(int i=0;i<$3.size();i++){
                    for(int j=0;j<check.size();j++){
                         if (check[j]==$3[i]->name) error(@1,"\""+$3[i]->name+"\" has a previous declaration");
                    }
                    check.push_back($3[i]->name);
               }
               listtemp=$3;
          }
          else{
               error(@1,"The function \""+$1+"\" has a previous definition");
          }
          entry* ent=new entry($1,"fun","global",0,0,"-");
          gstmap[$1]=ent;
          $$=$1;
     }
     | IDENTIFIER '(' ')' {
          if (funmap.find($1)==funmap.end()){
               vector<entry*> vect;
               funmap[$1]=vect;
          }
          else{
               error(@1,"The function \""+$1+"\" has a previous definition");
          }

          entry* ent=new entry($1,"fun","global",0,0,"-");
          gstmap[$1]=ent;
          $$=$1;
     }

parameter_list: 
     parameter_declaration {
          vector<entry*> vect;
          vect.insert(vect.end(),$1);
          $$=vect;
     }
     | parameter_list ',' parameter_declaration {
          vector<entry*> vect=$1;
          entry* newent=$3;
          for (int i=0;i<vect.size();i++){
               vect[i]->offset=vect[i]->offset+newent->size;
          }
          vect.insert(vect.end(),newent);
          $$=vect;
     }

parameter_declaration: 
     type_specifier declarator {
          entry* ent= $2;
          if($1.substr(0,6)=="void"){
               if (ent->type1[0]=='*');
               else error(@1,"Cannot declare the type of a parameter as  \"void\"");
          }
          if ($1.substr(0,6)!="struct"){
               if (ent->type1[0]=='*');
               else if (ent->type1=="") ent->size=4;
               else if(ent->type1[0]=='[') ent->size=4*ent->size;
          }
          else{
               if (ent->type1[0]=='*');
               else if (ent->type1=="") ent->size=gstmap[$1]->size;
               else if(ent->type1[0]=='[') ent->size=gstmap[$1]->size*ent->size;
          }
          ent->type1=$1+ent->type1;
          ent->type0="var";
          ent->gl="param";
          ent->offset=12;
          $$=ent;
     }

declarator_arr: 
     IDENTIFIER {
          entry* ent=new entry($1,"","",0,0,"");
          $$=ent;
     }
     | declarator_arr '[' INT_CONSTANT ']' {
          entry*ent =$1;
          ent->type1=ent->type1+"["+$3+"]";
          if (ent->size==0){
               ent->size=stoi($3);
          }
          else{
               int l=stoi($3);
               ent->size=ent->size*l;
          }
          $$=ent;
     }

declarator: 
     declarator_arr {
          $$=$1;
     }
     | '*' declarator {
          entry* ent=$2;
          if (ent->type1==""){
               ent->size=4;
          }
          else if (ent->type1[0]=='*'){
             ;  
          }
          else if (ent->type1[0]=='['){
               ent->size=ent->size*4;
          }
          ent->type1="*"+ent->type1;
          $$=ent;
     }

compound_statement: 
     '{' '}' {
          vector<abstract_astnode*> slist(0);
          $$=new seq_astnode(slist);
     }
     | '{' statement_list '}' {
          vector<abstract_astnode*> slist;
          slist=$2->list;
          $$=new seq_astnode(slist);
     }
     | '{' declaration_list '}' {
          vector<entry*> vect=$2;
          int sum=0;
          for(int i=0;i<vect.size();i++){
               vect[i]->type0="var";
               vect[i]->gl="local";
               sum=sum-vect[i]->size;
               vect[i]->offset=sum;
          }
          vector<abstract_astnode*> slist(0);
          $$=new seq_astnode(slist);
     }
     | '{' declaration_list statement_list '}' {
          vector<entry*> vect=$2;
          int sum=0;
          for(int i=0;i<vect.size();i++){
               vect[i]->type0="var";
               vect[i]->gl="local";
               sum=sum-vect[i]->size;
               vect[i]->offset=sum;
          }
          vector<abstract_astnode*> slist;
          slist=$3->list;
          $$=new seq_astnode(slist);   
     }

statement_list: 
     statement {
          vector<abstract_astnode*> slist;
          slist.insert(slist.end(),$1);
          $$=new seq_astnode(slist);
     }
     | statement_list statement {
          vector<abstract_astnode*> slist;
          slist=$1->list;
          slist.push_back($2);
          $$=new seq_astnode(slist);
     }

statement: 
     ';' {
          $$=new empty_astnode();
     }

     | '{' statement_list '}' {
          vector<abstract_astnode*> explist;
          explist=$2->list;
          $$=new seq_astnode(explist);
     }

     | selection_statement {
          $$=$1;
     }

     | iteration_statement {
          $$=$1;
     }

     | assignment_statement {
          $$=$1;
     }

     | procedure_call {
          $$=$1;
     }

     | RETURN expression ';' {
          if (cftype=="int"){
               if (intcheck($2->type)){
                    $$=new return_astnode($2);
               }
               else if(floatcheck($2->type)){
                    abstract_astnode* temp=new op_unary_astnode("TO_INT",$2);
                    $$=new return_astnode(temp);
               }
               else{
                    error(@1,"Incompatible assignment when assigning return type to the function");
               }
          }
          else if (cftype=="float"){
               if (intcheck($2->type)){
                    abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$2);
                    $$=new return_astnode(temp);
               }
               else if(floatcheck($2->type)){
                    $$=new return_astnode($2);
               }
               else{
                    error(@1,"Incompatible assignment when assigning return type to the function");
               }
          }
          else if (cftype.substr(0,6)=="struct"){
               if (structtype($2->type)){
                    if (cftype==$2->type->basetype){
                         $$=new return_astnode($2);
                    }
                    else{
                         error(@1,"Incompatible assignment when assigning return type to the function");
                    }
               }
               else{
                    error(@1,"Incompatible assignment when assigning return type to the function");
               }
          }
          else{

               error(@1,"Incompatible assignment when assigning return type to the function");
          }
     }

assignment_expression: 
     unary_expression '=' expression {
          if (!$1->lvalue){
               error(@1,"Left operand of assignment should have an lvalue");
          }
          if(intcheck($1->type)+intcheck($3->type)==2){
               $$=new assignE_astnode($1,$3);
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$=new assignE_astnode($1,temp);
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_INT",$3);
               $$=new assignE_astnode(temp,$3);
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$=new assignE_astnode($1,$3);
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2  && $1->type->ptrdepth==$3->type->ptrdepth){
               $$=new assignE_astnode($1,$3);
          }
          else if(ptrcheck($1->type)+arrcheck($3->type)==2 && $3->type->arrdepth==1 && $1->type->ptrdepth-$3->type->ptrdepth==1){
               $$=new assignE_astnode($1,$3);
          }
          else if(ptrcheck($1->type) && $3->is_zero){
               $$=new assignE_astnode($1,$3);
          }
          else if($1->type->basetype.substr(0,6)=="struct" && $1->type->basetype==$3->type->basetype ){
               if (structtype($1->type) && structtype($3->type)){
                    $$=new assignE_astnode($1,$3);
               }
               else error(@1,"Invalid assignment");
          }
          else{
               error(@1,"Incompatible types for assignment expression");
               //error check incomplete
               //structs left
          }

     }

assignment_statement: 
     assignment_expression ';' {
          abstract_astnode* child1=$1->child1;
          abstract_astnode* child2=$1->child2;
          $$=new assignS_astnode(child1,child2);
     }

procedure_call: 
     IDENTIFIER '(' ')' ';' {
          if (curfun==$1){
               if (listtemp.size()==0){
                    vector<abstract_astnode*> nullvect(0);
                    $$=new proccall_astnode($1,nullvect);
               }
               else{
                    error(@1,"Procedure \""+$1+"\"  called with too few arguments");
               }
          }
          else if(funmap.find($1)==funmap.end()){
               error(@1,"Procedure \""+$1+"\" not defined");
          }
          else{
               vector <std::string> vect;
               vect=paramtypes(funmap[$1]);
               if(vect.size()==0){
                    vector<abstract_astnode*> nullvect(0);
                    $$=new proccall_astnode($1,nullvect);
               }
               else{
                   error(@1,"Procedure \""+$1+"\"  called with too few arguments"); 
               }
          }
     }
     | IDENTIFIER '(' expression_list ')' ';' {
          if($1=="printf" || $1=="scanf"){
               vector<abstract_astnode*>vect= $3->list;
               $$=new proccall_astnode($1,vect);
               mytype* tp=new mytype("void",0);
               $$->type=tp;
          }
          else {
               if (curfun==$1){
                    vector<std::string> paramtype = paramtypes(listtemp);
                    if (paramtype.size()>$3->list.size()){
                         error(@1,"Procedure \""+$1+"\"  called with too few arguments");
                    }
                    else if(paramtype.size()<$3->list.size()){
                         error(@1,"Procedure \""+$1+"\"  called with too many arguments");
                    }
                    else{
                         for( int i=0;i<$3->list.size();i++){
                              mytype* tp=new mytype(paramtype[i],0);
                              if (tp->basetype=="void" && tp->ptrdepth==1 && tp->arrdepth==0){
                                   if ($3->list[i]->type->arrdepth+$3->list[i]->type->ptrdepth>1);
                                   else error(@1,"Incompatible argument types given for \"void *\"");
                              }
                              else if (structtype(tp)){
                                   if(perfectmatch(tp,$3->list[i]->type));
                                   else error(@1,"Incompatible argument types given");
                              }
                              else if (paramtype[i]=="int"){
                                   if (intcheck($3->list[i]->type));
                                   else if(floatcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_NT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"int\" but argument is not int");
                                   //check at end
                              }
                              else if (paramtype[i]=="float"){
                                   if (floatcheck($3->list[i]->type));
                                   else if (intcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"float\" but argument is not int");
                                   //check at end
                              }
                              else{
                                   if (ptrcheck(tp)+$3->list[i]->is_zero==2){
                                        ;
                                   }
                                   else if (ptrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        else if (tp->ptrdepth==$3->list[i]->type->ptrdepth);
                                        else error(@1,"Incompatible type of argument");
                                        //check at end
                                   }
                                   else if (ptrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==1 && !$3->list[i]->type->outerpointer);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if (arrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        else if (tp->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==-1);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if(arrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        mytype* tp1=ptrarr(tp);
                                        mytype* tp2=ptrarr($3->list[i]->type);
                                        if (tp->arrdepth==$3->list[i]->type->arrdepth && perfectmatch(tp1,tp2) && !$3->list[i]->type->outerpointer);
                                        else if(tp->arrdepth-$3->list[i]->type->arrdepth==1 && $3->list[i]->type->outerpointer){
                                             $3->list[i]->type->ptrdepth-=1;
                                             if(perfectmatch(tp,$3->list[i]->type));
                                             else error(@1,"Incompatible argument type given");
                                        }
                                        else error(@1,"Incompatible argument type given");
                                        //check at end;
                                   }
                                   else error(@1,"Incompatible argument type given");
                                   //check at end
                              }
                         }    
                    }
               }
               else if(funmap.find($1)==funmap.end()){
                    error(@1,"Procedure \""+$1+"\" not defined");
               }
               else{
                    vector<std::string> paramtype = paramtypes(funmap[$1]);
                    if (paramtype.size()>$3->list.size()){
                         error(@1,"Procedure \""+$1+"\"  called with too few arguments");
                    }
                    else if(paramtype.size()<$3->list.size()){
                         error(@1,"Procedure \""+$1+"\"  called with too many arguments");
                    }
                    else{
                         for( int i=0;i<$3->list.size();i++){
                              mytype* tp=new mytype(paramtype[i],0);
                              if (tp->basetype=="void" && tp->ptrdepth==1 && tp->arrdepth==0){
                                   if ($3->list[i]->type->arrdepth+$3->list[i]->type->ptrdepth>1);
                                   else error(@1,"Incompatible argument types given for \"void *\"");
                              }
                              else if (structtype(tp)){
                                   if(perfectmatch(tp,$3->list[i]->type));
                                   else error(@1,"Incompatible argument types given");
                              }
                              else if (paramtype[i]=="int"){
                                   if (intcheck($3->list[i]->type));
                                   else if(floatcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_NT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"int\" but argument is not int");
                                   //check at end
                              }
                              else if (paramtype[i]=="float"){
                                   if (floatcheck($3->list[i]->type));
                                   else if (intcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"float\" but argument is not int");
                                   //check at end
                              }
                              else{
                                   if (ptrcheck(tp)+$3->list[i]->is_zero==2){
                                        ;
                                   }
                                   else if (ptrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        if (tp->ptrdepth==$3->list[i]->type->ptrdepth);
                                        else error(@1,"Incompatible type of argument");
                                        //check at end
                                   }
                                   else if (ptrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==1 && !$3->list[i]->type->outerpointer);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if (arrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        else if (tp->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==-1);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if(arrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        mytype* tp1=ptrarr(tp);
                                        mytype* tp2=ptrarr($3->list[i]->type);
                                        if (tp->arrdepth==$3->list[i]->type->arrdepth && perfectmatch(tp1,tp2) && !$3->list[i]->type->outerpointer);
                                        else if(tp->arrdepth-$3->list[i]->type->arrdepth==1 && $3->list[i]->type->outerpointer){
                                             $3->list[i]->type->ptrdepth-=1;
                                             if(perfectmatch(tp,$3->list[i]->type));
                                             else error(@1,"Incompatible argument type given");
                                        }
                                        else error(@1,"Incompatible argument type given");
                                        //check at end;
                                   }
                                   else error(@1,"Incompatible argument type given");
                                   //check at end
                              }
                         }
                    }
               }
               vector<abstract_astnode*>vect= $3->list;
               $$=new proccall_astnode($1,vect);
          }
     }

expression: 
     logical_and_expression {
          $$=$1;
     }
     | expression OR_OP logical_and_expression {
          if(structtype($1->type) || structtype($3->type)){
               error(@3,"Invalid operand of ||, not scalar or pointer");
          }
          $$= new op_binary_astnode("OR_OP",$1,$3);
          $$->type=new mytype("int",4);
     }

logical_and_expression: 
     equality_expression {
          $$=$1;
     }
     | logical_and_expression AND_OP equality_expression {
          if(structtype($1->type) || structtype($3->type)){
               error(@$,"Invalid operand of &&,  not scalar or pointer");
          }
          $$= new op_binary_astnode("AND_OP",$1,$3);
          $$->type=new mytype("int",4);
     }
   
equality_expression: 
     relational_expression {
          $$=$1;
     }
     | equality_expression EQ_OP relational_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("EQ_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("EQ_OP_FLOAT",$1,temp);
               $$->type=new mytype("int",4);
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("EQ_OP_FLOAT",temp,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("EQ_OP_FLOAT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((ptrcheck($1->type)+$3->is_zero==2)||($1->is_zero+ptrcheck($3->type)==2)){
               $$= new op_binary_astnode("EQ_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((arrcheck($1->type)+$3->is_zero==2)||($1->is_zero+arrcheck($3->type)==2)){
               $$= new op_binary_astnode("EQ_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2){
               if (perfectmatch($1->type,$3->type)){
                    $$= new op_binary_astnode("EQ_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary ==, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if (arrcheck($1->type)+ptrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (perfectmatch(tp1,tp2) && !tp1->outerpointer){
                    $$= new op_binary_astnode("EQ_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary ==");
               }
          }
          else if (ptrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (perfectmatch(tp1,tp2) && !tp2->outerpointer){
                    $$= new op_binary_astnode("EQ_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary ==, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (tp1->arrdepth==tp2->arrdepth){
                    if($1->type->outerpointer+$3->type->outerpointer==2 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("EQ_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else if($1->type->outerpointer+$3->type->outerpointer==0 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("EQ_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }    
                    else error(@1,"Invalid operands types for binary \"==\"");
               } 
               else if(tp1->arrdepth-tp2->arrdepth==1){
                    $3->type->ptrdepth-=1;
                    if(perfectmatch(tp1,$3->type) && !tp1->outerpointer && tp2->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("EQ_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"==\"");
               }
               else if(tp2->arrdepth-tp1->arrdepth==1){
                    $1->type->ptrdepth-=1;
                    if(perfectmatch(tp2,$1->type) && !tp2->outerpointer && tp1->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("EQ_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"==\"");
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary ==, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operands types for binary ==, \""+s1+"\" and \""+s2+"\"");
          }
     }
     | equality_expression NE_OP relational_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("NE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("NE_OP_FLOAT",$1,temp);
               $$->type=new mytype("int",4);
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("NE_OP_FLOAT",temp,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("NE_OP_FLOAT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((ptrcheck($1->type)+$3->is_zero==2)||($1->is_zero+ptrcheck($3->type)==2)){
               $$= new op_binary_astnode("NE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((arrcheck($1->type)+$3->is_zero==2)||($1->is_zero+arrcheck($3->type)==2)){
               $$= new op_binary_astnode("NE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2){
               if (perfectmatch($1->type,$3->type)){
                    $$= new op_binary_astnode("NE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary !=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if (arrcheck($1->type)+ptrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (perfectmatch(tp1,tp2) && !tp1->outerpointer){
                    $$= new op_binary_astnode("NE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary \"!=\"");
               }
          }
          else if (ptrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (perfectmatch(tp1,tp2) && !tp2->outerpointer){
                    $$= new op_binary_astnode("NE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary !=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (tp1->arrdepth==tp2->arrdepth){
                    if($1->type->outerpointer+$3->type->outerpointer==2 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("NE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else if($1->type->outerpointer+$3->type->outerpointer==0 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("NE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }    
                    else error(@1,"Invalid operands types for binary \"!=\"");
               } 
               else if(tp1->arrdepth-tp2->arrdepth==1){
                    $3->type->ptrdepth-=1;
                    if(perfectmatch(tp1,$3->type) && !tp1->outerpointer && tp2->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("NE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"!=\"");
               }
               else if(tp2->arrdepth-tp1->arrdepth==1){
                    $1->type->ptrdepth-=1;
                    if(perfectmatch(tp2,$1->type) && !tp2->outerpointer && tp1->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("NE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"!=\"");
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary !=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operands types for binary !=, \""+s1+"\" and \""+s2+"\"");
          }
     }

relational_expression: 
     additive_expression {
          $$=$1;
     }
     | relational_expression '<' additive_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("LT_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("LT_OP_FLOAT",$1,temp);
               $$->type=new mytype("int",4);
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("LT_OP_FLOAT",temp,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("LT_OP_FLOAT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((ptrcheck($1->type)+$3->is_zero==2)||($1->is_zero+ptrcheck($3->type)==2)){
               $$= new op_binary_astnode("LT_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((arrcheck($1->type)+$3->is_zero==2)||($1->is_zero+arrcheck($3->type)==2)){
               $$= new op_binary_astnode("LT_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2){
               if (perfectmatch($1->type,$3->type)){
                    $$= new op_binary_astnode("LT_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary <, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(ptrcheck($1->type)+arrcheck($3->type)==2){
               mytype * tp=ptrarr($3->type);
               tp->ptrdepth+=1;
               if (perfectmatch($1->type,tp) && !tp->outerpointer){
                    $$= new op_binary_astnode("LT_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary <, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+ptrcheck($3->type)==2){
               mytype * tp=ptrarr($1->type);
               tp->ptrdepth+=1;
               if (perfectmatch(tp,$3->type) && !tp->outerpointer){
                    $$= new op_binary_astnode("LT_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary <, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (tp1->arrdepth==tp2->arrdepth ){
                    if($1->type->outerpointer+$3->type->outerpointer==2 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("LT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else if($1->type->outerpointer+$3->type->outerpointer==0 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("LT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }    
                    else error(@1,"Invalid operands types for binary \"<\"");
               } 
               else if(tp1->arrdepth-tp2->arrdepth==1){
                    $3->type->ptrdepth-=1;
                    if(perfectmatch(tp1,$3->type) && !tp1->outerpointer && tp2->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("LT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"<\"");
               }
               else if(tp2->arrdepth-tp1->arrdepth==1){
                    $1->type->ptrdepth-=1;
                    if(perfectmatch(tp2,$1->type) && !tp2->outerpointer && tp1->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("LT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"<\"");
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary < , \""+s1+"\" and \""+s2+"\"");
               }
          }
          else{
               string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary <, \""+s1+"\" and \""+s2+"\"");
          }
     }
     | relational_expression '>' additive_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("GT_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("GT_OP_FLOAT",$1,temp);
               $$->type=new mytype("int",4);
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("GT_OP_FLOAT",temp,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("GT_OP_FLOAT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((ptrcheck($1->type)+$3->is_zero==2)||($1->is_zero+ptrcheck($3->type)==2)){
               $$= new op_binary_astnode("GT_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((arrcheck($1->type)+$3->is_zero==2)||($1->is_zero+arrcheck($3->type)==2)){
               $$= new op_binary_astnode("GT_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2){
               if (perfectmatch($1->type,$3->type)){
                    $$= new op_binary_astnode("GT_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary > , \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(ptrcheck($1->type)+arrcheck($3->type)==2){
               mytype * tp=ptrarr($3->type);
               tp->ptrdepth+=1;
               if (perfectmatch($1->type,tp) && !tp->outerpointer){
                    $$= new op_binary_astnode("GT_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary >, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+ptrcheck($3->type)==2){
               mytype * tp=ptrarr($1->type);
               tp->ptrdepth+=1;
               if (perfectmatch(tp,$3->type) && !tp->outerpointer){
                    $$= new op_binary_astnode("GT_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary >, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (tp1->arrdepth==tp2->arrdepth ){
                    if($1->type->outerpointer+$3->type->outerpointer==2 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("GT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else if($1->type->outerpointer+$3->type->outerpointer==0 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("GT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }    
                    else error(@1,"Invalid operands types for binary \">\"");
               } 
               else if(tp1->arrdepth-tp2->arrdepth==1){
                    $3->type->ptrdepth-=1;
                    if(perfectmatch(tp1,$3->type) && !tp1->outerpointer && tp2->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("GT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \">\"");
               }
               else if(tp2->arrdepth-tp1->arrdepth==1){
                    $1->type->ptrdepth-=1;
                    if(perfectmatch(tp2,$1->type) && !tp2->outerpointer && tp1->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("GT_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \">\"");
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary >, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operand types for binary >, \""+s1+"\" and \""+s2+"\"");
          }
     }
     |relational_expression LE_OP additive_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("LE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("LE_OP_FLOAT",$1,temp);
               $$->type=new mytype("int",4);
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("LE_OP_FLOAT",temp,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("LE_OP_FLOAT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((ptrcheck($1->type)+$3->is_zero==2)||($1->is_zero+ptrcheck($3->type)==2)){
               $$= new op_binary_astnode("LE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((arrcheck($1->type)+$3->is_zero==2)||($1->is_zero+arrcheck($3->type)==2)){
               $$= new op_binary_astnode("LE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2){
               if (perfectmatch($1->type,$3->type)){
                    $$= new op_binary_astnode("LE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary <=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(ptrcheck($1->type)+arrcheck($3->type)==2){
               mytype * tp=ptrarr($3->type);
               tp->ptrdepth+=1;
               if (perfectmatch($1->type,tp) && !tp->outerpointer){
                    $$= new op_binary_astnode("LE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary <=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+ptrcheck($3->type)==2){
               mytype * tp=ptrarr($1->type);
               tp->ptrdepth+=1;
               if (perfectmatch(tp,$3->type) && !tp->outerpointer){
                    $$= new op_binary_astnode("LE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary <=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (tp1->arrdepth==tp2->arrdepth ){
                    if($1->type->outerpointer+$3->type->outerpointer==2 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("LE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else if($1->type->outerpointer+$3->type->outerpointer==0 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("LE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }    
                    else error(@1,"Invalid operands types for binary \"<=\"");
               } 
               else if(tp1->arrdepth-tp2->arrdepth==1){
                    $3->type->ptrdepth-=1;
                    if(perfectmatch(tp1,$3->type) && !tp1->outerpointer && tp2->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("LE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"<=\"");
               }
               else if(tp2->arrdepth-tp1->arrdepth==1){
                    $1->type->ptrdepth-=1;
                    if(perfectmatch(tp2,$1->type) && !tp2->outerpointer && tp1->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("LE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"<=\"");
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary <=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operand types for binary <=, \""+s1+"\" and \""+s2+"\"");
          }
     }
     | relational_expression GE_OP additive_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("GE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("GE_OP_FLOAT",$1,temp);
               $$->type=new mytype("int",4);
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("GE_OP_FLOAT",temp,$3);
               $$->type=new mytype("int",4);
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("GE_OP_FLOAT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((ptrcheck($1->type)+$3->is_zero==2)||($1->is_zero+ptrcheck($3->type)==2)){
               $$= new op_binary_astnode("GE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if((arrcheck($1->type)+$3->is_zero==2)||($1->is_zero+arrcheck($3->type)==2)){
               $$= new op_binary_astnode("GE_OP_INT",$1,$3);
               $$->type=new mytype("int",4);
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2){
               if (perfectmatch($1->type,$3->type)){
                    $$= new op_binary_astnode("GE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary >=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(ptrcheck($1->type)+arrcheck($3->type)==2){
               mytype * tp=ptrarr($3->type);
               tp->ptrdepth+=1;
               if (perfectmatch($1->type,tp) && !tp->outerpointer){
                    $$= new op_binary_astnode("GE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary >=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+ptrcheck($3->type)==2){
               mytype * tp=ptrarr($1->type);
               tp->ptrdepth+=1;
               if (perfectmatch(tp,$3->type) && !tp->outerpointer){
                    $$= new op_binary_astnode("GE_OP_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary >=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if (tp1->arrdepth==tp2->arrdepth ){
                    if($1->type->outerpointer+$3->type->outerpointer==2 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("GE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else if($1->type->outerpointer+$3->type->outerpointer==0 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("GE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }    
                    else error(@1,"Invalid operands types for binary \">=\"");
               } 
               else if(tp1->arrdepth-tp2->arrdepth==1){
                    $3->type->ptrdepth-=1;
                    if(perfectmatch(tp1,$3->type) && !tp1->outerpointer && tp2->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("GE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \">=\"");
               }
               else if(tp2->arrdepth-tp1->arrdepth==1){
                    $1->type->ptrdepth-=1;
                    if(perfectmatch(tp2,$1->type) && !tp2->outerpointer && tp1->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("GE_OP_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \">=\"");
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operands types for binary >=, \""+s1+"\" and \""+s2+"\"");
               }
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operand types for binary >=, \""+s1+"\" and \""+s2+"\"");
          }
     }

additive_expression: 
     multiplicative_expression {
          $$=$1;
     }
     | additive_expression '+' multiplicative_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("PLUS_INT",$1,$3);
               $$->type=$1->type;
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("PLUS_FLOAT",$1,temp);
               $$->type=$1->type;
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("PLUS_FLOAT",temp,$3);
               $$->type=$3->type;
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("PLUS_FLOAT",$1,$3);
               $$->type=$1->type;
          }
          else if(intcheck($1->type)+ptrcheck($3->type)==2){
               $$= new op_binary_astnode("PLUS_INT",$1,$3);
               $$->type=$3->type;
          }
          else if(ptrcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("PLUS_INT",$1,$3);
               $$->type=$1->type;
          }
          else if(intcheck($1->type)+arrcheck($3->type)==2){
               $$= new op_binary_astnode("PLUS_INT",$1,$3);
               mytype* tp=ptrarr($3->type);
               tp->ptrdepth+=1;
               if ($3->type->outerpointer){
                    $$->type=$3->type;
               }
               else $$->type=tp;
          }
          else if(arrcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("PLUS_INT",$1,$3);
               mytype* tp=ptrarr($1->type);
               tp->ptrdepth+=1;
               if ($1->type->outerpointer){
                    $$->type=$1->type;
               }
               else $$->type=tp;
          }
          else {
               error(@1,"Invalid operand types for binary +");
          }
     }
     | additive_expression '-' multiplicative_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("MINUS_INT",$1,$3);
               $$->type=$1->type;
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("MINUS_FLOAT",$1,temp);
               $$->type=$1->type;
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("MINUS_FLOAT",temp,$3);
               $$->type=$3->type;
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("MINUS_FLOAT",$1,$3);
               $$->type=$1->type;
          }
          else if(ptrcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("MINUS_INT",$1,$3);
               $$->type=$1->type;
          }
          else if(arrcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("MINUS_INT",$1,$3);
               mytype* tp=ptrarr($1->type);
               tp->ptrdepth+=1;
               if ($1->type->outerpointer){
                    $$->type=$1->type;
               }
               else {
                    $$->type=tp;
                    $$->type->outerpointer;
               }
          }
          else if(ptrcheck($1->type)+ptrcheck($3->type)==2){
               if (perfectmatch($1->type,$3->type)){
                    $$= new op_binary_astnode("MINUS_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary - , \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(arrcheck($1->type)+arrcheck($3->type)==2){
               mytype* tp1= ptrarr($1->type);
               mytype* tp2= ptrarr($3->type);
               if($1->type->arrdepth==$3->type->arrdepth){
                    if(tp1->outerpointer + tp2->outerpointer==2 && perfectmatch($1->type,$3->type)){
                         $$=new op_binary_astnode("MINUS_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else if(tp1->outerpointer + tp2->outerpointer==0 && perfectmatch(tp1,tp2)) {
                         $$=new op_binary_astnode("MINUS_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }   
                    else error(@1,"Invalid operands types for binary \"-\"");
               } 
               else if(tp1->arrdepth-tp2->arrdepth==1 ){
                    $3->type->ptrdepth-=1;
                    if(perfectmatch(tp1,$3->type) && !tp1->outerpointer && tp2->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("MINUS_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"-\"");
               }
               else if(tp2->arrdepth-tp1->arrdepth==1){
                    $1->type->ptrdepth-=1;
                    if(perfectmatch(tp2,$1->type) && !tp2->outerpointer && tp1->outerpointer){
                         $3->type->ptrdepth+=1;
                         $$=new op_binary_astnode("MINUS_INT",$1,$3);
                         $$->type=new mytype("int",4);
                    }
                    else error(@1,"Invalid operands types for binary \"-\"");
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary - , \""+s1+"\" and \""+s2+"\"");
               }  
          }
          else if(arrcheck($1->type)+ptrcheck($3->type)==2){
               mytype * tp=ptrarr($1->type);
               tp->ptrdepth+=1;
               if (perfectmatch(tp,$3->type) && !tp->outerpointer){
                    $$= new op_binary_astnode("MINUS_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary - , \""+s1+"\" and \""+s2+"\"");
               }
          }
          else if(ptrcheck($1->type)+arrcheck($3->type)==2){
               mytype * tp=ptrarr($3->type);
               tp->ptrdepth+=1;
               if (perfectmatch($1->type,tp) && !tp->outerpointer){
                    $$= new op_binary_astnode("MINUS_INT",$1,$3);
                    $$->type=new mytype("int",4);
               }
               else{
                    string s1=typefinder($1->type);
                    string s2=typefinder($3->type);
                    error(@1,"Invalid operand types for binary - , \""+s1+"\" and \""+s2+"\"");
               }
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operand types for binary - , \""+s1+"\" and \""+s2+"\"");
          }
     }

unary_expression: 
     postfix_expression {
          $$ = $1;
     }
     | unary_operator unary_expression {
          if ($1=="UMINUS"){
               if(intfloat($2->type)){
                    $$=new op_unary_astnode("UMINUS",$2);
                    $$->type=$2->type;
                    $$->lvalue=false;
               }
               else{
                    error(@1,"syntax error");
               }
          }

          if ($1=="NOT"){
               if(structtype($2->type)){
                    error(@1,"Operand of NOT should be an int or float or pointer");
               }
               $$=new op_unary_astnode("NOT",$2);
               $$->type=new mytype("int",4);
               $$->lvalue=false;
          }

          if ($1=="ADDRESS"){
               if(!$2->lvalue){
                    error(@1,"Operand of & should  have lvalue");
               }
               if(arrcheck($2->type)){
                    $2->type->outerpointer=true;
               }
               $$=new op_unary_astnode("ADDRESS",$2);
               $$->lvalue=false;
               $2->type->ptrdepth+=1;
               $$->type=$2->type;     
          }

          if($1=="DEREF"){
               if(ptrarr($2->type)==NULL){
                    error(@1,"Invalid operand type \""+$2->type->basetype+"\" of unary *");
               }
               else if($2->type->basetype=="void" && $2->type->arrdepth==0 && $2->type->ptrdepth==1){
                    error(@1,"Invalid operand type \"void *\" of unary *");
               }
               $$=new op_unary_astnode("DEREF",$2);
               $$->lvalue=true;
               $$->type=ptrarr($2->type);
          }
     }

multiplicative_expression: 
     unary_expression {
          $$=$1;
     }
     | multiplicative_expression '*' unary_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("MULT_INT",$1,$3);
               $$->type=$1->type;
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("MULT_FLOAT",$1,temp);
               $$->type=$1->type;
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("MULT_FLOAT",temp,$3);
               $$->type=$3->type;
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("MULT_FLOAT",$1,$3);
               $$->type=$1->type;
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operand types for binary * , \""+s1+"\" and \""+s2+"\"");
          }
     }
     | multiplicative_expression '/' unary_expression {
          if (intcheck($1->type)+intcheck($3->type)==2){
               $$= new op_binary_astnode("DIV_INT",$1,$3);
               $$->type=$1->type;
          }
          else if(floatcheck($1->type)+intcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3);
               $$= new op_binary_astnode("DIV_FLOAT",$1,temp);
               $$->type=$1->type;
          }
          else if(intcheck($1->type)+floatcheck($3->type)==2){
               abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$1);
               $$= new op_binary_astnode("DIV_FLOAT",temp,$3);
               $$->type=$3->type;
          }
          else if(floatcheck($1->type)+floatcheck($3->type)==2){
               $$= new op_binary_astnode("DIV_FLOAT",$1,$3);
               $$->type=$1->type;
          }
          else{
               string s1=typefinder($1->type);
               string s2=typefinder($3->type);
               error(@1,"Invalid operand types for binary / , \""+s1+"\" and \""+s2+"\"");
          }
     }

postfix_expression: 
     primary_expression {
          $$=$1;
     }

     | postfix_expression '[' expression ']' {
          if (!typeint($3->type)){
               error(@1,"Array subscript is not an integer");
          }
          mytype *tp=ptrarr($1->type);
          if(tp==NULL){
               error(@1,"Subscripted value is neither array nor pointer");
          }
          $$=new arrayref_astnode($1,$3);
          $$->type=tp;
          $$->lvalue=true;
     }

     | IDENTIFIER '(' ')' {
          if (curfun==$1){
               if (listtemp.size()==0){
                    vector<abstract_astnode*> nullvect(0);
                    $$=new funcall_astnode($1,nullvect);
                    $$->lvalue=false;
                    $$->type=new mytype(cftype,0);
               }
               else{
                    error(@1,"Function \""+$1+"\"  called with too few arguments");
               }
          }
          else if(funmap.find($1)==funmap.end()){
               error(@1,"Function \""+$1+"\" not defined");
          }
          else{
               vector <std::string> vect;
               vect=paramtypes(funmap[$1]);
               if(vect.size()==0){
                    vector<abstract_astnode*> nullvect(0);
                    $$=new funcall_astnode($1,nullvect);
                    $$->lvalue=false;
                    $$->type=new mytype(mapfind($1,gstmap)->type1,0);
               }
               else{
                   error(@1,"Function \""+$1+"\"  called with too few arguments"); 
               }
          }
     }

     | IDENTIFIER '(' expression_list ')' {
          if($1=="printf" || $1=="scanf"){
               vector<abstract_astnode*>vect= $3->list;
               $$=new funcall_astnode($1,vect);
               mytype* tp=new mytype("void",0);
               $$->type=tp;
          }
          else if($1=="mod"){
               vector<abstract_astnode*>vect= $3->list;
               $$=new funcall_astnode($1,vect);
               mytype* tp=new mytype("int",0);
               $$->type=tp;
          }
          else {
               if (curfun==$1){
                    vector<std::string> paramtype = paramtypes(listtemp);
                    if (paramtype.size()>$3->list.size()){
                         error(@1,"Function \""+$1+"\"  called with too few arguments");
                    }
                    else if(paramtype.size()<$3->list.size()){
                         error(@1,"Function \""+$1+"\"  called with too many arguments");
                    }
                    else{
                         for( int i=0;i<$3->list.size();i++){
                              mytype* tp=new mytype(paramtype[i],0);
                              if (tp->basetype=="void" && tp->ptrdepth==1 && tp->arrdepth==0){
                                   if ($3->list[i]->type->arrdepth+$3->list[i]->type->ptrdepth>1);
                                   else error(@1,"Incompatible argument types given for \"void *\"");
                              }
                              else if (structtype(tp)){
                                   if(perfectmatch(tp,$3->list[i]->type));
                                   else error(@1,"Incompatible argument types given");
                              }
                              else if (paramtype[i]=="int"){
                                   if (intcheck($3->list[i]->type));
                                   else if(floatcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_NT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"int\" but argument is not int");
                                   //check at end
                              }
                              else if (paramtype[i]=="float"){
                                   if (floatcheck($3->list[i]->type));
                                   else if (intcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"float\" but argument is not int");
                                   //check at end
                              }
                              else{
                                   if (ptrcheck(tp)+$3->list[i]->is_zero==2){
                                        ;
                                   }
                                   else if (ptrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        else if (tp->ptrdepth==$3->list[i]->type->ptrdepth);
                                        else error(@1,"Incompatible type of argument");
                                        //check at end
                                   }
                                   else if (ptrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==1 && !$3->list[i]->type->outerpointer);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if (arrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        else if (tp->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==-1);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if(arrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        mytype* tp1=ptrarr(tp);
                                        mytype* tp2=ptrarr($3->list[i]->type);
                                        if (tp->arrdepth==$3->list[i]->type->arrdepth && perfectmatch(tp1,tp2) && !$3->list[i]->type->outerpointer);
                                        else if(tp->arrdepth-$3->list[i]->type->arrdepth==1 && $3->list[i]->type->outerpointer){
                                             $3->list[i]->type->ptrdepth-=1;
                                             if(perfectmatch(tp,$3->list[i]->type));
                                             else error(@1,"Incompatible argument type given");
                                        }
                                        else error(@1,"Incompatible argument type given");
                                        //check at end;
                                   }
                                   else error(@1,"Incompatible argument type given");
                                   //check at end
                              }
                         }
                    }
                    vector<abstract_astnode*>vect= $3->list;
                    $$=new funcall_astnode($1,vect);
                    $$->lvalue=false;
                    $$->type=new mytype(cftype,0);
               }
               else if(funmap.find($1)==funmap.end()){
                    error(@1,"Function \""+$1+"\" not defined");
               }
               else{
                    vector<std::string> paramtype = paramtypes(funmap[$1]);
                    if (paramtype.size()>$3->list.size()){
                         error(@1,"Function \""+$1+"\"  called with too few arguments");
                    }
                    else if(paramtype.size()<$3->list.size()){
                         error(@1,"Function \""+$1+"\"  called with too many arguments");
                    }
                    else{
                         for( int i=0;i<$3->list.size();i++){
                              mytype* tp=new mytype(paramtype[i],0);
                              if (tp->basetype=="void" && tp->ptrdepth==1 && tp->arrdepth==0){
                                   if ($3->list[i]->type->arrdepth+$3->list[i]->type->ptrdepth);
                                   else error(@1,"Incompatible argument types given for \"void *\"");
                              }
                              else if (structtype(tp)){
                                   if(perfectmatch(tp,$3->list[i]->type));
                                   else error(@1,"Incompatible argument types given");
                              }
                              else if (paramtype[i]=="int"){
                                   if (intcheck($3->list[i]->type));
                                   else if(floatcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_NT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"int\" but argument is not int");
                                   //check at end
                              }
                              else if (paramtype[i]=="float"){
                                   if (floatcheck($3->list[i]->type));
                                   else if (intcheck($3->list[i]->type)){
                                        abstract_astnode* temp=new op_unary_astnode("TO_FLOAT",$3->list[i]);
                                        $3->list[i]=temp;
                                   }
                                   else error(@1,"Expected \"float\" but argument is not int");
                                   //check at end
                              }
                              else{
                                   if (ptrcheck(tp)+$3->list[i]->is_zero==2){
                                        ;
                                   }
                                   else if (ptrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        else if (tp->ptrdepth==$3->list[i]->type->ptrdepth);
                                        else error(@1,"Incompatible type of argument");
                                        //check at end
                                   }
                                   else if (ptrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==1 && !$3->list[i]->type->outerpointer);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if (arrcheck(tp)+ptrcheck($3->list[i]->type)==2){
                                        if ($3->list[i]->type->basetype=="void" && $3->list[i]->type->ptrdepth==1 && $3->list[i]->type->arrdepth==0);
                                        else if (tp->arrdepth==1 && tp->ptrdepth-$3->list[i]->type->ptrdepth==-1);
                                        else error(@1,"Incompatible argument type given");
                                        //check at end
                                   }
                                   else if(arrcheck(tp)+arrcheck($3->list[i]->type)==2){
                                        mytype* tp1=ptrarr(tp);
                                        mytype* tp2=ptrarr($3->list[i]->type);
                                        if (tp->arrdepth==$3->list[i]->type->arrdepth && perfectmatch(tp1,tp2) && !$3->list[i]->type->outerpointer);
                                        else if(tp->arrdepth-$3->list[i]->type->arrdepth==1 && $3->list[i]->type->outerpointer){
                                             $3->list[i]->type->ptrdepth-=1;
                                             if(perfectmatch(tp,$3->list[i]->type));
                                             else error(@1,"Incompatible argument type given");
                                        }
                                        else error(@1,"Incompatible argument type given");
                                        //check at end;
                                   }
                                   else error(@1,"Incompatible argument type given");
                                   //check at end
                              }
                         }
                    }
                    vector<abstract_astnode*>vect= $3->list;
                    $$=new funcall_astnode($1,vect);
                    $$->lvalue=false;
                    $$->type=new mytype(mapfind($1,gstmap)->type1,0);
               }

          }
     }

     | postfix_expression '.' IDENTIFIER {

          if(!structtype($1->type)){
               error(@1,"Left operand of \".\"  is not a  structure");
          }
          if (ssv($3,structlstmap[$1->type->basetype])==NULL){
               error(@1,"Struct \""+$1->type->basetype+"\" has no member named \""+$3+"\"");
          }

          abstract_astnode* id=new identifier_astnode($3);
          id->val=$3;
          entry* ent=ssv($3,structlstmap[$1->type->basetype]);
          $$= new member_astnode($1,id);
          $$->type=new mytype(ent->type1,ent->size);
          $$->lvalue=true;
     }

     | postfix_expression PTR_OP IDENTIFIER {

          if(!structptr($1->type)){
               error(@1,"Left operand of \"->\" is not a pointer to structure");
          }
          if (ssv($3,structlstmap[$1->type->basetype])==NULL){
               error(@1,"Struct \""+$1->type->basetype+"\" has no member named "+$3);
          }

          abstract_astnode* id=new identifier_astnode($3);
          id->val=$3;
          entry* ent=ssv($3,structlstmap[$1->type->basetype]);
          $$= new arrow_astnode($1,id);
          $$->type=new mytype(ent->type1,ent->size);
          $$->lvalue=true;
     }

     | postfix_expression INC_OP {
          if (intcheck($1->type)+floatcheck($1->type)+ptrcheck($1->type)<1){
               error(@1,"Operand of \"++\" should be a int, float or pointer");
          }
          if (!$1->lvalue){
               error(@1,"Operand of \"++\" should have lvalue");
          }
          
          $$=new op_unary_astnode("PP",$1);
          $$->lvalue=false;
          $$->type=$1->type;
     }

primary_expression: 
     IDENTIFIER {
          abstract_astnode * id=new identifier_astnode($1);
          $$=id;
          entry* ent =ssv($1,listtemp);
          if (ent==NULL){
               error(@$," Variable \""+$1+"\" not declared");
          }
          mytype* tp=new mytype(ent->type1,ent->size);
          if(ent->gl=="param"){
               if(tp->arrdepth){
                    tp->arrdepth-=1;
                    tp->ptrdepth+=1;
                    tp->outerpointer=true;
                    tp->arrvect.erase(tp->arrvect.begin());
               }
          }
          $$->type=tp;
          $$->lvalue = true;
          $$->val=$1;
     }
     | INT_CONSTANT {
          int value=stoi($1);
          abstract_astnode* intnode = new intconst_astnode(value);
          $$ =intnode;
          if (value==0){
               $$->is_zero=true;
          }
          $$->type = new mytype("int",4);
          $$->lvalue = false;
          $$->val=$1;
          $$->intfloat=true;
     }

     | FLOAT_CONSTANT {
          float value=stof($1);
          abstract_astnode* flnode = new floatconst_astnode(value);
          $$ = flnode;
          $$->type = new mytype("float",4);
          $$->lvalue = false;
          $$->val=$1;
          $$->intfloat=true;
     }

     | STRING_LITERAL {
          lclist.insert(lclist.end(),$1);
          abstract_astnode * String = new stringconst_astnode($1);
          $$ = String;
          $$->lvalue = false;
          mytype * tp=new mytype("string",0);
          $$->type=tp;
          $$->val=".LC"+to_string(lclist.size()-1);
          $$->intfloat=true;
     }

     | '(' expression ')' {
          $$=$2;
     }

expression_list: 
     expression {
          vector<abstract_astnode*> explist;
          explist.insert(explist.end(),$1);
          $$=new seq_exp_astnode(explist);
     }
     | expression_list ',' expression {
          vector<abstract_astnode*> explist;
          explist=$1->list;
          explist.insert(explist.end(),$3);
          $$=new seq_exp_astnode(explist);
     }

unary_operator: 
     '-' {
          $$="UMINUS";
     }
     | '!' {
          $$="NOT";
     }
     | '&' {
          $$="ADDRESS";
     }
     | '*' {
          $$="DEREF";
     }

selection_statement: 
     IF '(' expression ')' statement ELSE statement {
          abstract_astnode* child1= $3;
          abstract_astnode* child2= $5;
          abstract_astnode* child3= $7;
          $$=new if_astnode(child1,child2,child3);
     }

iteration_statement: 
     WHILE '(' expression ')' statement {
          abstract_astnode* child1= $3;
          abstract_astnode* child2= $5;
          $$=new while_astnode(child1,child2);
     }
     | FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement {
          abstract_astnode* child1= $3;
          abstract_astnode* child2= $5;
          abstract_astnode* child3= $7;
          abstract_astnode* child4= $9;
          $$=new for_astnode(child1,child2,child3,child4);
     }

declaration_list: 
     declaration {
          $$=$1;
     }
     | declaration_list declaration {
          vector<entry*> vect=$1;
          vector<entry*> add=$2;
          int k=vect.size();
          int size = add.size();
          for (int i=0;i<add.size();i++){
               listtemp.insert(listtemp.end(),add[i]);
          }
          for (int i=0;i<size;i++){
               vect.insert(vect.end(),add[i]);
          }
          $$=vect;
     }

declaration: 
     type_specifier declarator_list ';' {
          vector<entry*> vect=$2;
          int size;
          size = vect.size();
          if($1=="void"){
               for (int i=0;i<size;i++){
                    if(vect[i]->type1[0]=='*'){
                         vect[i]->type1=$1+vect[i]->type1;
                    }
                    else error(@1,"Cannot declare variable of type \"void\"");
               }
          }
          else if ($1.substr(0,6)!="struct"){
               for (int i=0;i<size;i++){
                    if (vect[i]->type1==""){
                    vect[i]->size=4;
                    }
                    else if(vect[i]->type1[0]=='*'){
                         ;
                    }
                    else if(vect[i]->type1[0]=='['){
                         vect[i]->size=4*vect[i]->size;
                    }
                    vect[i]->type1=$1+vect[i]->type1;
               }
          }
          else{
               for (int i=0;i<size;i++){
                    if ($1=="struct "+psid){
                         if(vect[i]->type1[0]=='*'){
                              ;
                         }
                         else error(@1," \"struct "+ psid + "\" not defined");
                         vect[i]->type1=$1+vect[i]->type1;
                    }
                    else{
                         if(gstmap.find($1)==gstmap.end()){
                              error(@1,$1+" not defined");
                         }
                         if (vect[i]->type1==""){
                         vect[i]->size=gstmap[$1]->size;
                         }
                         else if(vect[i]->type1[0]=='*'){
                              ;
                         }
                         else if(vect[i]->type1[0]=='['){
                              vect[i]->size=gstmap[$1]->size*vect[i]->size;
                         }
                         vect[i]->type1=$1+vect[i]->type1;
                    }
               }
          }
          for (int i=0;i<vect.size();i++){
               for (int j=0;j<listtemp.size();j++){
                    if (listtemp[j]->name==vect[i]->name) error(@1,"\""+vect[i]->name+ "\" has a previous declaration");
               }
               listtemp.insert(listtemp.end(),vect[i]);
          }
          $$=vect;
     }

declarator_list: 
     declarator {
          vector<entry*> vect;
          vect.insert(vect.end(),$1);
          $$=vect;
     }
     | declarator_list ',' declarator {
          vector<entry*> vect=$1;
          for (int i=0;i<vect.size();i++){
               if (vect[i]->name==$3->name) error(@1,"\"" +$3->name+"\" has a previous declaration");
          }
          vect.insert(vect.end(),$3);
          $$=vect;
     }



%%
void IPL::Parser::error( const location_type &l, const std::string &err_message )
{
   std::cout << "Error at line " <<  l.begin.line << ": "<< err_message<< "\n";
   exit(1);
}
