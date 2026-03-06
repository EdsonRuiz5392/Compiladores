#include <iostream>
#include <vector>
using namespace std;

// Estructura que representa una instrucción del programa
struct Instruction {
    string opcode;   // nombre de la instrucción (MOV, ADD, STO, END)
    string op1;      // primer operando (generalmente un registro)
    int op2;         // segundo operando (dirección de memoria)

    // Constructor que permite crear instrucciones fácilmente
    Instruction(string code = "", string r = "", int addr = 0) {
        opcode = code;
        op1 = r;
        op2 = addr;
    }
};

// Clase que representa la memoria principal del sistema
class Memory {
public:
    vector<int> data;            // vector que simula las posiciones de memoria para datos
    vector<Instruction> program; // vector que contiene las instrucciones del programa

    // Constructor que inicializa la memoria con un tamaño determinado
    Memory(int size) {
        data.resize(size, 0); // se llena la memoria con ceros
    }
};

// Clase que simula la CPU
class CPU {
public:
    // Registros principales del procesador
    int PC = 0;     // Program Counter: indica la siguiente instrucción a ejecutar
    Instruction IR; // Instruction Register: guarda la instrucción actual
    int MAR = 0;    // Memory Address Register: almacena dirección de memoria
    int MBR = 0;    // Memory Buffer Register: almacena datos leídos de memoria
    int ACC = 0;    // Acumulador: guarda resultados de operaciones

    // Registros de propósito general
    int AL = 0, AH = 0, BL = 0, BH = 0;

    bool running = true; // controla si el programa sigue ejecutándose

    // Función que imprime el estado actual de los registros
    void printState(string stage) {
        cout << "\n==== " << stage << " ====\n";
        cout << "PC: " << PC << endl;
        cout << "IR: " << IR.opcode << " " << IR.op1 << " " << IR.op2 << endl;
        cout << "MAR: " << MAR << endl;
        cout << "MBR: " << MBR << endl;
        cout << "ACC: " << ACC << endl;
        cout << "AL: " << AL << " AH: " << AH
             << " BL: " << BL << " BH: " << BH << endl;
    }

    // Función que regresa la dirección de un registro según su nombre
    int* getRegister(string name) {
        if (name == "AL") return &AL;
        if (name == "BL") return &BL;
        if (name == "AH") return &AH;
        if (name == "BH") return &BH;
        return nullptr; // si no existe el registro
    }

    // Etapa FETCH del ciclo máquina
    // Se obtiene la siguiente instrucción desde la memoria
    void fetch(Memory &mem) {
        MAR = PC;                 // el MAR apunta a la dirección actual del PC
        IR = mem.program[MAR];    // se carga la instrucción en el IR
        PC++;                     // el PC avanza a la siguiente instrucción
        printState("FETCH");      // se muestra el estado del sistema
    }

    // Etapa DECODE del ciclo máquina
    // En este ejemplo solo se muestra el estado porque
    // la interpretación se hace directamente en execute
    void decode() {
        printState("DECODE");
    }

    // Etapa EXECUTE del ciclo máquina
    // Aquí se ejecuta la instrucción correspondiente
    void execute(Memory &mem) {

        // Instrucción MOV: mueve un valor de memoria a un registro
        if (IR.opcode == "MOV") {
            MAR = IR.op2;              // se coloca la dirección de memoria en MAR
            MBR = mem.data[MAR];       // se lee el valor de memoria hacia MBR
            *getRegister(IR.op1) = MBR;// el valor se copia al registro indicado
        }

        // Instrucción ADD: suma AL + BL
        else if (IR.opcode == "ADD") {
            ACC = AL + BL;             // el resultado se guarda en el acumulador
        }

        // Instrucción STO: guarda el acumulador en memoria
        else if (IR.opcode == "STO") {
            MAR = IR.op2;              // dirección de memoria destino
            MBR = ACC;                 // el valor del acumulador pasa al buffer
            mem.data[MAR] = MBR;       // se guarda en memoria
        }

        // Instrucción END: finaliza la ejecución del programa
        else if (IR.opcode == "END") {
            running = false;           // se detiene el ciclo de ejecución
        }

        printState("EXECUTE");         // se imprime el estado después de ejecutar
    }
};

int main() {

    // Se crea la memoria con 20 posiciones
    Memory memory(20);

    // Se crea la CPU
    CPU cpu;

    // Se guardan los valores que se van a sumar
    memory.data[6] = 10;
    memory.data[7] = 12;

    // Programa que ejecutará la máquina virtual
    memory.program = {
        Instruction("MOV", "AL", 6), // cargar valor de memoria[6] en AL
        Instruction("MOV", "BL", 7), // cargar valor de memoria[7] en BL
        Instruction("ADD"),          // sumar AL + BL
        Instruction("STO", "", 8),   // guardar resultado en memoria[8]
        Instruction("END")           // terminar programa
    };

    // Ciclo de ejecución de la máquina virtual
    // se repite mientras running sea verdadero
    while (cpu.running) {
        cpu.fetch(memory);   // obtener instrucción
        cpu.decode();        // interpretar instrucción
        cpu.execute(memory); // ejecutar instrucción
    }

    // Mostrar el resultado final almacenado en memoria
    cout << "\nResultado final en memoria[8]: "
         << memory.data[8] << endl;

    return 0;
}
