#ifndef SYMTAB_H
#define SYMTAB_H

#include <iostream>
#include <string>
#include <vector>
#include <map>

using namespace std;


class entry{
    public:
        string name;
        string type0; //var fun struct
        string gl;    // global local param
        int size;
        int offset;
        string type1; // int int** struct............
        entry(string name, string type0, string gl, int size, int offset, string type1){
            this->name=name;
            this->type0=type0;
            this->gl=gl;
            this->size=size;
            this->offset=offset;
            this->type1=type1;
        }
};

class global_st {
    public:
        entry* ent;
        global_st(entry* ent){
            this->ent= ent;
        }
        virtual void print(){
            if (ent->type0=="struct"){
            cout<<"[    \""<<ent->name<<"\",    \""<<ent->type0<<"\",    \""<<ent->gl<<"\",    "<<ent->size<<",    \"-\",    \""<<ent->type1<<"\"\n]";
            }
            else{
            cout<<"[    \""<<ent->name<<"\",    \""<<ent->type0<<"\",    \""<<ent->gl<<"\",    "<<ent->size<<",    "<<ent->offset<<",    \""<<ent->type1<<"\"\n]";
            }
        }
};

class local_st{
    public:
        entry* ent;
        local_st(entry* ent){
            this->ent= ent;
        }
        virtual void print(){
            cout<<"[    \""<<ent->name<<"\",    \""<<ent->type0<<"\",    \""<<ent->gl<<"\",    "<<ent->size<<",    "<<ent->offset<<",    \""<<ent->type1<<"\"\n]";
        }
};

entry * ssv(string id,vector<entry*> vect);
entry * mapfind(string id,map<string,entry*> map);
vector <entry*> sortedinsert(vector<entry*> vect, entry* ent);
vector <std::string> paramtypes(vector<entry*> vect);

#endif