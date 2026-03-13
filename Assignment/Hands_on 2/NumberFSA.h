#ifndef NUMBERFSA_H
#define NUMBERFSA_H

#include <string>

class NumberFSA {
public:
    NumberFSA();
    bool validar(const std::string& lexema);

private:
    enum Estado {
        q0, // inicio
        q1, // entero
        q2, // punto decimal
        q3, // parte decimal
        q4, // E
        q5, // signo en exponente
        q6  // parte del exponente
    };

    bool esEstadoDeAceptacion(Estado e);
};

#endif