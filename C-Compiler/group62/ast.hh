#include <iostream>
#include <string>
#include <vector>
#include "type.hh"
#include "symtab.hh"

using namespace std;
extern int k;
extern std::map<std::string, std::vector<entry*>> structlstmap;
extern std::map<std::string, entry*> gstmap;
extern std::map<std::string, std::vector<entry*>> funmap;

class abstract_astnode {
    public:
        string val="";
        bool intfloat=false;
        bool is_empty = false;
        bool is_zero = false;
        vector<abstract_astnode*> list;
        virtual void print(vector<std::string> reg,map<string,entry*> lmap) = 0;
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap)=0;
        mytype* type;
        bool lvalue;
};

class statement_astnode : public abstract_astnode{
};

class exp_astnode : public abstract_astnode{
};

class empty_astnode : public statement_astnode{
    public:
        empty_astnode(){
            is_empty = true;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class seq_astnode : public statement_astnode{
    public:
        //pointer to child

        seq_astnode(vector<abstract_astnode*> list){
            this->list=list;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            for(int i=0;i<list.size();i++){
                list[i]->print(reg,lmap);
            }
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}

};

class seq_exp_astnode : public exp_astnode{
    public:
        //pointer to child

        seq_exp_astnode(vector<abstract_astnode*> list){
            this->list=list;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}

};

class assignS_astnode : public statement_astnode{
    public:
        //pointers to children
        abstract_astnode * child1;
        abstract_astnode * child2;

        assignS_astnode(abstract_astnode * child1, abstract_astnode * child2){
            this->child1=child1;
            this->child2=child2;
        }

        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            if (!child2->intfloat){
                if (reg.size()<2){
                    child2->print(reg,lmap);
                    cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;
                    child1->addr(reg,lmap);
                    cout<<"\tmovl\t%esp, ("<<reg[reg.size()-1]<<")\n";
                    cout<<"\tsubl\t$4, %esp\n";
                }
                else{
                    child2->print(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    reg.pop_back();
                    child1->addr(reg,lmap);
                    cout<<"\tmovl\t"<<reg1<<", ("<<reg[reg.size()-1]<<")\n";
                    reg.push_back(reg1);
                }
            }
            else{
                child1->addr(reg,lmap);
                cout<<"\tmovl\t$"<<child2->val<<", ("<<reg[reg.size()-1]<<")\n";
            }
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class return_astnode : public statement_astnode{
    public:
        //pointer to child
        abstract_astnode * child;

        return_astnode(abstract_astnode* child){
            this->child=child;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            int sum=36;
            for (auto i=lmap.begin();i!=lmap.end();++i){
                if(i->second->gl=="param"){
                    sum+=4;
                }
                else;
            }
            child->print(reg,lmap);
            cout<<"\tmovl\t"<<reg[reg.size()-1]<<", "<<sum<<"(%ebp)\n";
            cout<<"\tleave\n\tret\n";
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class if_astnode : public statement_astnode{
    public:
        //pointers to children
        abstract_astnode * child1;
        abstract_astnode * child2;
        abstract_astnode * child3;

        if_astnode(abstract_astnode * child1, abstract_astnode * child2, abstract_astnode * child3){
            this->child1=child1;
            this->child2=child2;
            this->child3=child3;
        }

        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            child1->print(reg,lmap);
            cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
            int p1=k;
            int p2=k+1;
            k=k+2;
            cout<<"\tje\t.L"<<p1<<endl;
            child2->print(reg,lmap);
            cout<<"\tjmp\t.L"<<p2<<endl;
            cout<<".L"<<p1<<":\n";
            child3->print(reg,lmap);
            cout<<".L"<<p2<<":\n";
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class while_astnode : public statement_astnode{
    public:
        //pointers to children
        abstract_astnode * child1;
        abstract_astnode * child2;

        while_astnode(abstract_astnode * child1, abstract_astnode * child2){
            this->child1=child1;
            this->child2=child2;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            int p1=k;
            k=k+1;
            int p2=k;
            k=k+1;
            cout<<"\tjmp\t.L"<<p1<<endl;
            cout<<".L"<<p2<<":\n";
            child2->print(reg,lmap);
            cout<<".L"<<p1<<":\n";
            child1->print(reg,lmap);
            cout<<"\tcmpl\t$1, "<<reg[reg.size()-1]<<endl;
            cout<<"\tje\t.L"<<p2<<endl;
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class for_astnode : public statement_astnode{
    public:
        //pointers to variables
        abstract_astnode * child1;
        abstract_astnode * child2;
        abstract_astnode * child3;
        abstract_astnode * child4;

        for_astnode(abstract_astnode * child1, abstract_astnode * child2, abstract_astnode * child3, abstract_astnode * child4){
            this->child1=child1;
            this->child2=child2;
            this->child3=child3;
            this->child4=child4;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            child1->print(reg,lmap);
            int p1=k;
            k=k+1;
            int p2=k;
            k=k+1;
            cout<<"\tjmp\t.L"<<p1<<endl;
            cout<<".L"<<p2<<":\n";
            child4->print(reg,lmap);
            child3->print(reg,lmap);
            cout<<".L"<<p1<<":\n";
            child2->print(reg,lmap);
            cout<<"\tcmpl\t$1, "<<reg[reg.size()-1]<<endl;
            cout<<"\tje\t.L"<<p2<<endl;
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}

};

class proccall_astnode : public statement_astnode{
    public:
        //pointer to child
        string name;
        vector<abstract_astnode*> paramlist;

        proccall_astnode(string name, vector<abstract_astnode*> paramlist){
            this->name=name;
            this->paramlist=paramlist;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            if (name=="printf"){
                for (int i=1;i<paramlist.size()+1;i++){
                    if (paramlist[paramlist.size()-i]->intfloat){
                        cout<<"\tpushl\t$"<<paramlist[paramlist.size()-i]->val<<endl;
                    }
                    else{
                        paramlist[paramlist.size()-i]->print(reg,lmap);
                        cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;
                    }
                }
                cout<<"\tcall\tprintf\n";
                cout<<"\taddl\t$"<<4*paramlist.size()<<", %esp"<<endl;
            }
            else{
                cout<<"\tsubl\t$4, %esp\n";  //return addr
                // registers
                cout<<"\tpushl\t%eax\n";
                cout<<"\tpushl\t%ebx\n";
                cout<<"\tpushl\t%ecx\n";
                cout<<"\tpushl\t%edx\n";
                cout<<"\tpushl\t%edi\n";
                cout<<"\tpushl\t%esi\n";
                //parameters
                vector<entry*> referparams=funmap[name];
                for (int i=0;i<paramlist.size();i++){
                    string s=referparams[i]->type1;
                    mytype* tpref=new mytype(s,0);
                    // struct
                    if(tpref->arrdepth==0 && tpref->ptrdepth==0 && tpref->basetype.substr(0,6)=="struct"){
                        int size=gstmap[typefinder(paramlist[i]->type)]->size;
                        paramlist[i]->addr(reg,lmap);
                        cout<<"\taddl\t$"<<size-4<<", "<<reg[reg.size()-1]<<endl;
                        while(size>0){
                            cout<<"\tpushl\t("<<reg[reg.size()-1]<<")\n";
                            size=size-4;
                            cout<<"\tsubl\t$4, "<<reg[reg.size()-1]<<endl;
                        }
                    }
                    // int
                    else if(tpref->arrdepth==0 && tpref->ptrdepth==0 && tpref->basetype=="int"){
                        paramlist[i]->print(reg,lmap);
                        cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;
                    }
                    // ptr
                    else if(tpref->ptrdepth && !tpref->arrdepth){
                        if(paramlist[i]->is_zero){
                            cout<<"\tpushl\t$0\n";
                        }
                        else if(paramlist[i]->type->ptrdepth){
                            paramlist[i]->print(reg,lmap);
                            cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl; 
                        }
                        else {
                            paramlist[i]->addr(reg,lmap);
                            cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl; 
                        }
                    }
                    // arr
                    else{   
                        paramlist[i]->addr(reg,lmap);
                        cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;                    
                        // if(paramlist[i]->type->ptrdepth){
                        //     paramlist[i]->print(reg,lmap);
                        //     int size=4;
                        //     if (paramlist[i]->type->basetype.substr(0,6)=="struct"){
                        //         size=gstmap[paramlist[i]->type->basetype]->size;
                        //     } 
                        //     for(int j=0;j<tpref->arrvect.size();j++){
                        //         size=size*tpref->arrvect[j];
                        //     }
                        //     cout<<"\taddl\t$"<<size-4<<", "<<reg[reg.size()-1]<<endl;
                        //     while(size>0){
                        //         cout<<"\tpushl\t("<<reg[reg.size()-1]<<")\n";
                        //         size=size-4;
                        //         cout<<"\tsubl\t$4, "<<reg[reg.size()-1]<<endl;
                        //     }
                        // }
                        // else{
                        //     paramlist[i]->addr(reg,lmap);
                        //     int size=4;
                        //     for(int j=0;j<tpref->arrvect.size();j++){
                        //         size=size*tpref->arrvect[j];
                        //     }
                        //     if (paramlist[i]->type->basetype.substr(0,6)=="struct"){
                        //         size=gstmap[paramlist[i]->type->basetype]->size;
                        //     }
                        //     for(int j=0;j<tpref->arrvect.size();j++){
                        //         size=size*tpref->arrvect[j];
                        //     }
                        //     cout<<"\taddl\t$"<<size-4<<", "<<reg[reg.size()-1]<<endl;
                        //     while(size>0){
                        //         cout<<"\tpushl\t("<<reg[reg.size()-1]<<")\n";
                        //         size=size-4;
                        //         cout<<"\tsubl\t$4, "<<reg[reg.size()-1]<<endl;
                        //     }
                        // }
                    }
                }
                cout<<"\tsubl\t$4, %esp\n";
                cout<<"\tcall\t"<<name<<endl;
                cout<<"\taddl\t$"<<4*(paramlist.size()+1)<<", %esp\n";
                // restore registers
                cout<<"\tpopl\t%esi\n";
                cout<<"\tpopl\t%edi\n";
                cout<<"\tpopl\t%edx\n";
                cout<<"\tpopl\t%ecx\n";
                cout<<"\tpopl\t%ebx\n";
                cout<<"\tpopl\t%eax\n";
                cout<<"\taddl\t$4, %esp\n";
            }
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class op_binary_astnode : public exp_astnode{
    public:
        //pointers to children
        string  String ;
        abstract_astnode * child1;
        abstract_astnode * child2;

        op_binary_astnode(string String, abstract_astnode * child1, abstract_astnode * child2){
            this->String=String;
            this->child1=child1;
            this->child2=child2;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            if(child1->intfloat+child2->intfloat==2){
                if (String=="PLUS_INT"){
                    cout<<"\tmovl\t$"<<stoi(child1->val)+stoi(child2->val)<<", "<<reg[reg.size()-1]<<endl;
                }
                else if (String=="MINUS_INT"){
                    cout<<"\tmovl\t$"<<stoi(child1->val)-stoi(child2->val)<<", "<<reg[reg.size()-1]<<endl;
                }
                else if (String=="MULT_INT"){
                    cout<<"\tmovl\t$"<<stoi(child1->val)*stoi(child2->val)<<", "<<reg[reg.size()-1]<<endl;
                }
                else if(String=="DIV_INT"){
                    cout<<"\tmovl\t$"<<stoi(child1->val)/stoi(child2->val)<<", "<<reg[reg.size()-1]<<endl;
                }
                else if(String=="AND_OP"){
                    if (stoi(child1->val) && stoi(child2->val)){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="OR_OP"){
                    if (stoi(child1->val) || stoi(child2->val)){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="EQ_OP"){
                    if (child1->val == child2->val){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="NE_OP"){
                    if (child1->val != child2->val){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="GE_OP"){
                    if (stoi(child1->val) >= stoi(child2->val)){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="LE_OP"){
                    if (stoi(child1->val) <= stoi(child2->val)){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="GT_OP"){
                    if (stoi(child1->val) > stoi(child2->val)){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="LT_OP"){
                    if (stoi(child1->val) < stoi(child2->val)){
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
            }
            else if(child1->intfloat){
                if (String=="PLUS_INT"){
                    child2->print(reg,lmap);
                    if (child2->type->ptrdepth==1 && child2->type->arrdepth==0 && child2->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\taddl\t$"<<stoi(child1->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child2->type->ptrdepth==0 && child2->type->arrdepth>0 && child2->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\taddl\t$"<<stoi(child1->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child2->type->ptrdepth){
                        cout<<"\taddl\t$"<<stoi(child1->val)*4<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else cout<<"\taddl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                }
                else if (String=="MINUS_INT"){
                    child2->print(reg,lmap);
                    if (child2->type->ptrdepth==1 && child2->type->arrdepth==0 && child2->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\tsubl\t$"<<stoi(child1->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child2->type->ptrdepth==0 && child2->type->arrdepth>0 && child2->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\tsubl\t$"<<stoi(child1->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child2->type->ptrdepth){
                        cout<<"\tsubl\t$"<<stoi(child1->val)*4<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else cout<<"\tsubl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                    cout<<"\tnegl\t"<<reg[reg.size()-1]<<endl;
                }
                else if (String=="MULT_INT"){
                    child2->print(reg,lmap);
                    cout<<"\timull\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                }
                else if(String=="DIV_INT"){
                    child1->print(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if (reg1!="%eax"){
                        cout<<"\tpushl\t%eax\n";
                        cout<<"\tmovl\t"<<reg1<<", %eax\n";
                        if (reg[reg.size()-1]=="%edx"){
                            child2->print(reg,lmap);
                            cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                        }
                        else{
                            cout<<"\tpushl\t%edx\n";
                            child2->print(reg,lmap);
                            cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                            cout<<"\tpopl\t%edx\n";
                        }
                        cout<<"\tmovl\t%eax, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tpopl\t%eax\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                        reg.push_back("%eax");
                    }
                }
                else if(String=="AND_OP"){
                    if(stoi(child1->val)){
                        child2->print(reg,lmap);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tje\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tjmp\t.L"<<p2<<endl;
                        cout<<".L"<<p1<<":\n";
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<".L"<<p2<<":\n";
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="OR_OP"){
                    if(!stoi(child1->val)){
                        child2->print(reg,lmap);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tje\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tjmp\t.L"<<p2<<endl;
                        cout<<".L"<<p1<<":\n";
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<".L"<<p2<<":\n";
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="EQ_OP_INT"){
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+1;
                    cout<<"\tjne\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="NE_OP_INT"){
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+1;
                    cout<<"\tje\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="GE_OP_INT"){
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+1;
                    cout<<"\tjl\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="LE_OP_INT"){
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+1;
                    cout<<"\tjg\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="GT_OP_INT"){
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+1;
                    cout<<"\tjle\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="LT_OP_INT"){
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child1->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+1;
                    cout<<"\tjge\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
            }
            else if(child2->intfloat){
                if (String=="PLUS_INT"){
                    child1->print(reg,lmap);
                    if (child1->type->ptrdepth==1 && child1->type->arrdepth==0 && child1->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\taddl\t$"<<stoi(child2->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child1->type->ptrdepth==0 && child1->type->arrdepth>0 && child1->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\taddl\t$"<<stoi(child2->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child1->type->ptrdepth){
                        cout<<"\taddl\t$"<<stoi(child2->val)*4<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else cout<<"\taddl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                }
                else if (String=="MINUS_INT"){
                    child1->print(reg,lmap);
                    if (child1->type->ptrdepth==1 && child1->type->arrdepth==0 && child1->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\tsubl\t$"<<stoi(child2->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child1->type->ptrdepth==0 && child1->type->arrdepth>0 && child1->type->basetype.substr(0,6)=="struct"){
                        int size=gstmap[child1->type->basetype]->size;
                        cout<<"\tsubl\t$"<<stoi(child2->val)*size<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else if(child1->type->ptrdepth){
                        cout<<"\tsubl\t$"<<stoi(child2->val)*4<<", "<<reg[reg.size()-1]<<endl;
                    }
                    else cout<<"\tsubl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                }
                else if (String=="MULT_INT"){
                    child1->print(reg,lmap);
                    cout<<"\timull\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                }
                else if(String=="DIV_INT"){
                    child1->print(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if (reg1!="%eax"){
                        cout<<"\tpushl\t%eax\n";
                        cout<<"\tmovl\t"<<reg1<<", %eax\n";
                        if (reg[reg.size()-1]=="%edx"){
                            child2->print(reg,lmap);
                            cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                        }
                        else{
                            cout<<"\tpushl\t%edx\n";
                            child2->print(reg,lmap);
                            cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                            cout<<"\tpopl\t%edx\n";
                        }
                        cout<<"\tmovl\t%eax, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tpopl\t%eax\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                        reg.push_back("%eax");
                    }
                }
                else if(String=="AND_OP"){
                    if(stoi(child2->val)){
                        child1->print(reg,lmap);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tje\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tjmp\t.L"<<p2<<endl;
                        cout<<".L"<<p1<<":\n";
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<".L"<<p2<<":\n";
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="OR_OP"){
                    if(!stoi(child2->val)){
                        child1->print(reg,lmap);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tje\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tjmp\t.L"<<p2<<endl;
                        cout<<".L"<<p1<<":\n";
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                        cout<<".L"<<p2<<":\n";
                    }
                    else{
                        cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    }
                }
                else if(String=="EQ_OP_INT"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+2;
                    cout<<"\tjne\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="NE_OP_INT"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+2;
                    cout<<"\tje\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="GE_OP_INT"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+2;
                    cout<<"\tjl\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="LE_OP_INT"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+2;
                    cout<<"\tjg\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="GT_OP_INT"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+2;
                    cout<<"\tjle\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="LT_OP_INT"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$"<<child2->val<<", "<<reg[reg.size()-1]<<endl;
                    int p1=k;
                    int p2=k+1;
                    k=k+2;
                    cout<<"\tjge\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<p2<<endl;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
            }
            else{
                if (String=="PLUS_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\taddl\t%esp, %esi\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.insert(reg.end(),reg1);
                    }
                }
                else if (String=="MINUS_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\tsubl\t%esi, %esp\n";
                        cout<<"\tmovl\t%esp, %esi\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tsubl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.insert(reg.end(),reg1);
                    }
                }
                else if (String=="MULT_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\timul\t%esp, %esi";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timul\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.insert(reg.end(),reg1);
                    }
                }
                else if(String=="DIV_INT"){
                    child1->print(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if (reg1!="%eax"){
                        cout<<"\tpushl\t%eax\n";
                        cout<<"\tmovl\t"<<reg1<<", %eax\n";
                        if (reg[reg.size()-1]=="%edx"){
                            child2->print(reg,lmap);
                            cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                        }
                        else{
                            cout<<"\tpushl\t%edx\n";
                            child2->print(reg,lmap);
                            cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                            cout<<"\tpopl\t%edx\n";
                        }
                        cout<<"\tmovl\t%eax, "<<reg[reg.size()-1]<<endl;
                        cout<<"\tpopl\t%eax\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcltd\n\tidivl\t"<<reg[reg.size()-1]<<endl;
                        reg.push_back("%eax");
                    }
                }
                else if(String=="AND_OP"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tje\t.L"<<k<<endl;
                    int p1=k;
                    k=k+1;
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tje\t.L"<<p1<<endl;
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<k<<endl;
                    int p2=k;
                    k=k+1;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<p2<<":\n";
                }
                else if(String=="OR_OP"){
                    child1->print(reg,lmap);
                    cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjne\t.L"<<k<<endl;
                    int p1=k;
                    k=k+1;
                    child2->print(reg,lmap);
                    cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tje\t.L"<<k<<endl;
                    int p2=k;
                    k=k+1;
                    cout<<".L"<<p1<<":\n";
                    cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                    cout<<"\tjmp\t.L"<<k<<endl;
                    cout<<".L"<<p2<<":\n";
                    cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                    cout<<".L"<<k<<":\n";
                    k=k+1;
                }
                else if(String=="EQ_OP_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t%esp\t%esi\n";
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjne\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, %esi"<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, %esi"<<"\n.L"<<p2<<":\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjne\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg1<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, "<<reg1<<"\n.L"<<p2<<":\n";
                    }
                }
                else if(String=="NE_OP_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t%esp\t%esi\n";
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tje\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, %esi"<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, %esi"<<"\n.L"<<p2<<":\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tje\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg1<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, "<<reg1<<"\n.L"<<p2<<":\n";
                    }
                }
                else if(String=="LT_OP_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t%esp\t%esi\n";
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjge\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, %esi"<<endl;
                        cout<<"\tjmp\t.L"<<p2<<":\n.L"<<p1<<":\n\tmovl\t$0, %esi"<<"\n.L"<<p2<<":\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjge\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg1<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, "<<reg1<<"\n.L"<<p2<<":\n";
                    }
                }
                else if(String=="GT_OP_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t%esp\t%esi\n";
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjle\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, %esi"<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, %esi"<<"\n.L"<<p2<<":\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjle\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg1<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, "<<reg1<<"\n.L"<<p2<<":\n";
                    }
                }
                else if(String=="LE_OP_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t%esp\t%esi\n";
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjg\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, %esi"<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, %esi"<<"\n.L"<<p2<<":\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjg\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg1<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, "<<reg1<<"\n.L"<<p2<<":\n";
                    }
                }
                else if(String=="GE_OP_INT"){
                    if(reg.size()<2){
                        child1->print(reg,lmap);
                        cout<<"\tpushl\t%esi\n";
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t%esp\t%esi\n";
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjl\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, %esi"<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, %esi"<<"\n.L"<<p2<<":\n";
                        cout<<"\taddl\t$4, %esp\n";
                    }
                    else{
                        child1->print(reg,lmap);
                        string reg1=reg[reg.size()-1];
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\tcmpl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                        int p1=k;
                        int p2=k+1;
                        k=k+2;
                        cout<<"\tjl\t.L"<<p1<<endl;
                        cout<<"\tmovl\t$1, "<<reg1<<endl;
                        cout<<"\tjmp\t.L"<<p2<<"\n.L"<<p1<<":\n\tmovl\t$0, "<<reg1<<"\n.L"<<p2<<":\n";
                    }
                }
            }
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class op_unary_astnode : public exp_astnode{
    public:
        //pointers to children
        string String;
        abstract_astnode * child;

        op_unary_astnode(string String, abstract_astnode* child){
            this->String=String;
            this->child=child;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            if(String=="UMINUS"){
                child->print(reg,lmap);
                string reg1=reg[reg.size()-1];
                cout<<"\tnegl\t"<<reg1<<endl;
            }
            else if(String=="NOT"){
                child->print(reg,lmap);
                int p1=k;
                int p2=k+1;
                k=k+2;
                cout<<"\tcmpl\t$0, "<<reg[reg.size()-1]<<endl;
                cout<<"\tjne\t.L"<<p1<<endl;
                cout<<"\tmovl\t$1, "<<reg[reg.size()-1]<<endl;
                cout<<"\tjmp\t.L"<<p2<<endl;
                cout<<".L"<<p1<<":\n";
                cout<<"\tmovl\t$0, "<<reg[reg.size()-1]<<endl;
                cout<<".L"<<p2<<":\n";
            }
            else if(String=="PP"){
                if(reg.size()<1){
                    child->addr(reg,lmap);
                    cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;
                    cout<<"\tmovl\t(%esp), "<<reg[reg.size()-1]<<endl;
                    cout<<"\taddl\t$1, (%esp)\n";
                    cout<<"\tsubl\t$4, %esp\n";
                }
                else{
                    string reg1=reg[reg.size()-1];
                    reg.pop_back();
                    child->addr(reg,lmap);
                    cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg1<<endl;
                    cout<<"\taddl\t$1, ("<<reg[reg.size()-1]<<")\n";
                    reg.push_back(reg1);

                }
            }
            else if(String=="DEREF"){
                child->addr(reg,lmap);
                cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
                cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
            }
            else if(String=="ADDRESS"){
                child->addr(reg,lmap);
            }
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){
            if (String=="DEREF"){
                child->addr(reg,lmap);
                cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
            }
        }
};

class assignE_astnode : public exp_astnode{
    public:
        //pointers to children
        abstract_astnode * child1;
        abstract_astnode * child2;

        assignE_astnode(abstract_astnode * child1, abstract_astnode * child2){
            this->child1=child1;
            this->child2=child2;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            if(reg.size()<2){
                child1->addr(reg,lmap);
                cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;
                child2->print(reg,lmap);
                cout<<"\tmovl\t"<<reg[reg.size()-1]<<", (%esp)\n";
                cout<<"\tsubl\t$4, %esp";
            }
            else{
                string reg1=reg[reg.size()-1];
                child1->addr(reg,lmap);
                reg.pop_back();
                child2->print(reg,lmap);
                cout<<"\tmovl\t"<<reg[reg.size()-1]<<", ("<<reg1<<")\n";
                reg.push_back(reg1);
            }
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class funcall_astnode : public exp_astnode{
    public:
        //pointer to child
        string name;
        vector<abstract_astnode*> paramlist;

        funcall_astnode(string name, vector<abstract_astnode*> paramlist){
            this->name=name;
            this->paramlist=paramlist;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            cout<<"\tsubl\t$4, %esp\n";  //return addr
            // registers
            cout<<"\tpushl\t%eax\n";
            cout<<"\tpushl\t%ebx\n";
            cout<<"\tpushl\t%ecx\n";
            cout<<"\tpushl\t%edx\n";
            cout<<"\tpushl\t%edi\n";
            cout<<"\tpushl\t%esi\n";
            //parameters
            vector<entry*> referparams=funmap[name];
            for (int i=0;i<paramlist.size();i++){
                string s=referparams[i]->type1;
                mytype* tpref=new mytype(s,0);
                // struct
                if(tpref->arrdepth==0 && tpref->ptrdepth==0 && tpref->basetype.substr(0,6)=="struct"){
                    int size=gstmap[typefinder(paramlist[i]->type)]->size;
                    paramlist[i]->addr(reg,lmap);
                    cout<<"\taddl\t$"<<size-4<<", "<<reg[reg.size()-1]<<endl;
                    while(size>0){
                        cout<<"\tpushl\t("<<reg[reg.size()-1]<<")\n";
                        size=size-4;
                        cout<<"\tsubl\t$4, "<<reg[reg.size()-1]<<endl;
                    }
                }
                // int
                else if(tpref->arrdepth==0 && tpref->ptrdepth==0 && tpref->basetype=="int"){
                    paramlist[i]->print(reg,lmap);
                    cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;
                }
                // ptr
                else if(tpref->ptrdepth && !tpref->arrdepth){
                    if(paramlist[i]->is_zero){
                        cout<<"\tpushl\t$0\n";
                    }
                    else if(paramlist[i]->type->ptrdepth){
                        paramlist[i]->print(reg,lmap);
                        cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl; 
                    }
                    else {
                        paramlist[i]->addr(reg,lmap);
                        cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl; 
                    }
                }
                // arr
                else{
                    paramlist[i]->addr(reg,lmap);
                    cout<<"\tpushl\t"<<reg[reg.size()-1]<<endl;
                    // if(paramlist[i]->type->ptrdepth){
                    //     paramlist[i]->print(reg,lmap);
                    //     int size=4;
                    //     if (paramlist[i]->type->basetype.substr(0,6)=="struct"){
                    //         size=gstmap[paramlist[i]->type->basetype]->size;
                    //     } 
                    //     for(int j=0;j<tpref->arrvect.size();j++){
                    //         size=size*tpref->arrvect[j];
                    //     }
                    //     cout<<"\taddl\t$"<<size-4<<", "<<reg[reg.size()-1]<<endl;
                    //     while(size>0){
                    //         cout<<"\tpushl\t("<<reg[reg.size()-1]<<")\n";
                    //         size=size-4;
                    //         cout<<"\tsubl\t$4, "<<reg[reg.size()-1]<<endl;
                    //     }
                    // }
                    // else{
                    //     paramlist[i]->addr(reg,lmap);
                    //     int size=4;
                    //     for(int j=0;j<tpref->arrvect.size();j++){
                    //         size=size*tpref->arrvect[j];
                    //     }
                    //     if (paramlist[i]->type->basetype.substr(0,6)=="struct"){
                    //         size=gstmap[paramlist[i]->type->basetype]->size;
                    //     }
                    //     for(int j=0;j<tpref->arrvect.size();j++){
                    //         size=size*tpref->arrvect[j];
                    //     }
                    //     cout<<"\taddl\t$"<<size-4<<", "<<reg[reg.size()-1]<<endl;
                    //     while(size>0){
                    //         cout<<"\tpushl\t("<<reg[reg.size()-1]<<")\n";
                    //         size=size-4;
                    //         cout<<"\tsubl\t$4, "<<reg[reg.size()-1]<<endl;
                    //     }
                    // }
                }
            }
            cout<<"\tsubl\t$4, %esp\n";
            cout<<"\tcall\t"<<name<<endl;
            cout<<"\taddl\t$"<<4*(paramlist.size()+1)<<", %esp\n";
            // restore registers
            cout<<"\tpopl\t%esi\n";
            cout<<"\tpopl\t%edi\n";
            cout<<"\tpopl\t%edx\n";
            cout<<"\tpopl\t%ecx\n";
            cout<<"\tpopl\t%ebx\n";
            cout<<"\tpopl\t%eax\n";
            cout<<"\tpopl\t"<<reg[reg.size()-1]<<endl;
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class intconst_astnode : public exp_astnode{
    public:
        //variables
        int value;

        intconst_astnode(int value){
            this->value=value;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            cout<<"\tmovl\t$"<<value<<", "<<reg[reg.size()-1]<<endl;
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class floatconst_astnode : public exp_astnode{
     public:
        //variables
        float value;

        floatconst_astnode(float value){
            this->value=value;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            cout<<"\tmovl\t$"<<value<<", "<<reg[reg.size()-1]<<endl;
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class stringconst_astnode : public exp_astnode{
     public:
        //variables
        string value;

        stringconst_astnode(string value){
            this->value=value;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            cout<<"\tmovl\t$"<<value<<", "<<reg[reg.size()-1]<<endl;
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){}
};

class ref_astnode : public exp_astnode{
};

class identifier_astnode : public ref_astnode{
    public:
        //variables
        string String;

        identifier_astnode(string String){
            this->String=String;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            cout<<"\tmovl\t"<<lmap[String]->offset<<"(%ebp), "<<reg[reg.size()-1]<<endl;;    
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){
            if(lmap[String]->offset>0 && lmap[String]->type1[lmap[String]->type1.length()-1]==']'){
                cout<<"\tmovl\t"<<lmap[String]->offset<<"(%ebp), "<<reg[reg.size()-1]<<endl;
            }
            else{
                cout<<"\tleal\t"<<lmap[String]->offset<<"(%ebp), "<<reg[reg.size()-1]<<endl;
            }
        }
};

class arrayref_astnode : public ref_astnode{
    public:
        //pointers to variables
        abstract_astnode * child1;
        abstract_astnode * child2;
        
        arrayref_astnode(abstract_astnode * child1, abstract_astnode * child2){
            this->child1=child1;
            this->child2=child2;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            if(child1->type->basetype.substr(0,6)=="struct"){
                int size=gstmap[child1->type->basetype]->size;
                for(int i=1;i<child1->type->arrdepth;i++){
                    size=size*child1->type->arrvect[i];
                }
                if(!child1->type->arrdepth){
                    child1->print(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                    cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
                }
                else{
                    child1->addr(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                    cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
                }
            }
            else{
                int size=4;
                if(child1->type->outerpointer){
                    for(int i=0;i<child1->type->arrdepth;i++){
                        size=size*child1->type->arrvect[i];
                    }
                }
                else{
                    for(int i=1;i<child1->type->arrdepth;i++){
                        size=size*child1->type->arrvect[i];
                    }
                }
                if(!child1->type->arrdepth){
                    if(child1->type->outerpointer){
                        child1->addr(reg,lmap);
                    }
                    else{
                        child1->print(reg,lmap);
                    }
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                    cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
                }
                else{
                    child1->addr(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                    if(!child1->type->outerpointer){
                        cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
                    }
                }
            }
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){
            if(child1->type->basetype.substr(0,6)=="struct"){
                int size=gstmap[child1->type->basetype]->size;
                for(int i=1;i<child1->type->arrdepth;i++){
                    size=size*child1->type->arrvect[i];
                }
                if(!child1->type->arrdepth){
                    child1->print(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                }
                else{
                    child1->addr(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                }
            }
            else{
                int size=4;
                for(int i=1;i<child1->type->arrdepth;i++){
                    size=size*child1->type->arrvect[i];
                }
                if(!child1->type->arrdepth){
                    child1->print(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                }
                else{
                    child1->addr(reg,lmap);
                    string reg1=reg[reg.size()-1];
                    if(reg.size()<2){
                        cout<<"\tpushl\t"<<reg1<<endl;
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg1<<endl;
                        cout<<"\taddl\t%esp, "<<reg1<<endl;
                        cout<<"\tsubl\t$4, %esp\n";
                    }
                    else{
                        reg.pop_back();
                        child2->print(reg,lmap);
                        cout<<"\timull\t$"<<size<<", "<<reg[reg.size()-1]<<endl;
                        cout<<"\taddl\t"<<reg[reg.size()-1]<<", "<<reg1<<endl;
                        reg.push_back(reg1);
                    }
                }
            }
        }
};

class member_astnode : public ref_astnode{
    public:
        //pointers to variables
        abstract_astnode * child1;
        abstract_astnode * child2;
        
        member_astnode(abstract_astnode * child1, abstract_astnode * child2){
            this->child1=child1;
            this->child2=child2;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            vector<entry*> members=structlstmap[typefinder(child1->type)];
            int offset=0;
            for (int i=0;i<members.size();i++){
                if (child2->val==members[i]->name){
                    offset=members[i]->offset;
                    break;
                }
                else continue;
            }
            child1->addr(reg,lmap);
            cout<<"\taddl\t$"<<offset<<", "<<reg[reg.size()-1]<<endl;
            cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){
            vector<entry*> members=structlstmap[typefinder(child1->type)];
            int offset=0;
            for (int i=0;i<members.size();i++){
                if (child2->val==members[i]->name){
                    offset=members[i]->offset;
                    break;
                }
                else continue;
            }
            child1->addr(reg,lmap);
            cout<<"\taddl\t$"<<offset<<", "<<reg[reg.size()-1]<<endl;
        }
};

class arrow_astnode : public ref_astnode{
    public:
        //pointers to variables
        abstract_astnode * child1;
        abstract_astnode * child2;
        
        arrow_astnode(abstract_astnode * child1, abstract_astnode * child2){
            this->child1=child1;
            this->child2=child2;
        }
        virtual void print(vector<std::string> reg,map<string,entry*> lmap){
            string xyz=typefinder(child1->type);
            mytype* tp=new mytype(xyz,0);
            vector<entry*> members=structlstmap[tp->basetype];
            int offset=0;
            for (int i=0;i<members.size();i++){
                if (child2->val==members[i]->name){
                    offset=members[i]->offset;
                    break;
                }
                else continue;
            }
            child1->addr(reg,lmap);
            cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
            cout<<"\taddl\t$"<<offset<<", "<<reg[reg.size()-1]<<endl;
            cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
            
        }
        virtual void addr(vector<std::string> reg,map<string,entry*> lmap){
            string xyz=typefinder(child1->type);
            mytype* tp=new mytype(xyz,0);
            vector<entry*> members=structlstmap[tp->basetype];
            int offset=0;
            for (int i=0;i<members.size();i++){
                if (child2->val==members[i]->name){
                    offset=members[i]->offset;
                    break;
                }
                else continue;
            }
            child1->addr(reg,lmap);
            cout<<"\tmovl\t("<<reg[reg.size()-1]<<"), "<<reg[reg.size()-1]<<endl;
            cout<<"\taddl\t$"<<offset<<", "<<reg[reg.size()-1]<<endl;
        }
};