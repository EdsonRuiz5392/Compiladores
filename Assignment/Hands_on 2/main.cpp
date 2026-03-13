#include <iostream>
#include "NumberFSA.h"

using namespace std;

int main() {

    NumberFSA fsa;
    string token;

    cout << "Ingresa un numero: ";
    cin >> token;

    if(fsa.validar(token))
        cout << "Token valido\n";
    else
        cout << "Token invalido\n";

    return 0;
}