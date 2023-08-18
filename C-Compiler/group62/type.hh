#ifndef TYPE_H
#define TYPE_H

#include <string>
#include <vector>
#include <iostream>

using namespace std;

class mytype{
    public:
        string basetype;
        int size;
        int arrdepth;
        int ptrdepth;
        bool outerpointer;
        vector<int> arrvect;
        
        mytype(string s,int sz){
            size = sz;
            arrdepth = 0;
            ptrdepth = 0;
            int i=0;
            outerpointer=false;

            // storing basetype
            basetype = "";
            while(s[i]!='*' && s[i]!='[' && i<s.size()){
                basetype=basetype+s[i];
                i=i+1;
            }

            // storing pointerdepth
            while(s[i]=='*' && i<s.size()){
                ptrdepth=ptrdepth+1;
                i=i+1;
            }
            // storing arraydepth and arrayvector
            while(i<s.size() && s[i]=='['){
                int j=i+1;
                string k="";
                while(j<s.size() && s[j]!=']'){
                    k=k+s[j];
                    j=j+1;
                }
                int p = stoi(k);
                arrvect.insert(arrvect.end(),p);
                arrdepth+=1;
                i=j+1;
            }
        }
    
};

string typefinder(mytype* inp);
mytype* ptrarr(mytype* inp);
bool typeint(mytype* tp);
bool structtype(mytype * tp);
bool structptr(mytype * tp);
bool ptrint(mytype* tp);
bool intfloat(mytype* tp);
bool intcheck(mytype* tp);
bool floatcheck(mytype* tp);
bool perfectmatch(mytype* tp1, mytype* tp2);
bool arrcheck(mytype* tp);
bool ptrcheck(mytype* tp);

#endif