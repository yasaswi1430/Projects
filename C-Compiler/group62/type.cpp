#include "type.hh"

string typefinder(mytype* inp){
    string str="";
    str+=inp->basetype;
    for (int i=0;i<inp->ptrdepth;i++){
        str+="*";
    }
    for(int i=0;i<inp->arrdepth;i++){
        str=str+"["+to_string(inp->arrvect[i])+"]";
    }
    return str;
}

mytype* ptrarr(mytype * inp){
    string str=typefinder(inp);
    int sz=inp->size;
    mytype* tp= new mytype(str,sz);
    if((tp->arrdepth+tp->ptrdepth)<1){
        return NULL ;
    }
    else if(tp->arrdepth>0){
        tp->arrdepth=tp->arrdepth-1;
        for (int i=0;i<tp->arrdepth;i++){
            tp->arrvect[i]=tp->arrvect[i+1];
        }
        tp->arrvect.pop_back();
        tp->outerpointer=inp->outerpointer;
        return tp;
    }
    else{
        tp->ptrdepth=tp->ptrdepth-1;
        return tp;
    }
}

bool typeint(mytype * tp){
    if (tp->arrdepth==0 && tp->ptrdepth==0 && tp->basetype=="int"){
        return true;
    }
    return false;
}

bool structtype(mytype* tp){
    if (tp->arrdepth==0 && tp->ptrdepth==0 && tp->basetype.substr(0,6)=="struct"){
        return true;
    }
    return false;
}

bool structptr(mytype* tp){
    if (tp->arrdepth+tp->ptrdepth==1 && tp->basetype.substr(0,6)=="struct"){
        return true;
    }
    return false;
}

bool ptrint(mytype* tp){
    if(tp->arrdepth==0 && tp->ptrdepth>0 or tp->basetype=="int"){
        return true;
    }
    return false;
}

bool intfloat(mytype* tp){
    if(tp->ptrdepth==0 && tp->arrdepth==0 && (tp->basetype=="float" or tp->basetype=="int")){
        return true;
    }
    return false;
}

bool intcheck(mytype* tp){
    if(tp->ptrdepth==0 && tp->arrdepth==0 && tp->basetype=="int"){
        return true;
    }
    return false;
}

bool floatcheck(mytype* tp){
    if(tp->ptrdepth==0 && tp->arrdepth==0 && tp->basetype=="float"){
        return true;
    }
    return false;
}

bool perfectmatch(mytype* tp1, mytype* tp2){
    if (tp1->basetype==tp2->basetype && tp1->ptrdepth==tp2->ptrdepth && tp1->arrdepth==tp2->arrdepth && tp1->arrvect==tp2->arrvect){
        return true;
    }
    return false;
}

bool arrcheck(mytype* tp){
    if (tp->arrdepth >0){
        return true;
    }
    return false;
}

bool ptrcheck(mytype* tp){
    if (tp->arrdepth==0 && tp->ptrdepth>0){
        return true;
    }
    return false;
}