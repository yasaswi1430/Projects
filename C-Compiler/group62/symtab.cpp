#include "symtab.hh"

entry * ssv(string id,vector<entry*> vect){
    for (int i=0;i<vect.size();i++){
        if (vect[i]->name==id) return vect[i];
    }
    return NULL;
}

entry * mapfind(string id,map<string,entry*> map){
    if(map.find(id)==map.end())return NULL;
    return map[id];
}

vector <entry*> sortedinsert(vector<entry*> vect, entry* ent){
    if (vect.size()==0){
        vect.insert(vect.end(),ent);
        return vect;
    }
    else{
        for (int i=0;i<vect.size();i++){
            if (vect[i]->offset<ent->offset){
                vect.insert(vect.begin()+i,ent);
                return vect;
            }
        }
        vect.insert(vect.end(),ent); 
        return vect;
    }
}

vector <std::string> paramtypes(vector<entry*> vect){
    vector<entry*> paramvect;
    for (int i=0;i<vect.size();i++){
        if (vect[i]->gl=="param"){
            paramvect=sortedinsert(paramvect,vect[i]);
        }
    }
    vector <std::string> res;
    for(int i=0;i<paramvect.size();i++){
        res.insert(res.end(),paramvect[i]->type1);
    }
    return res;
}
