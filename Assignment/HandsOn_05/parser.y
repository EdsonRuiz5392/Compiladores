%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int    lineno;
extern FILE  *yyin;

int  yylex(void);
void yyerror(const char *s);

#define MAX_SYM 512

typedef struct {
    char nombre[64];
    char clase[16];
    char tipo[16];
    int  aridad;
    int  ambito;
    int  activo;
    int  usado;
} Simbolo;

static Simbolo tabla[MAX_SYM];
static int     n_sim        = 0;
static int     ambito_actual = 0;
static int     errores      = 0;
static char    func_actual[64];

static int buscar_en_todo(const char *nom, const char *clase)
{
    for (int i = 0; i < n_sim; i++) {
        if (strcmp(tabla[i].nombre, nom) == 0 &&
            (!clase || strcmp(tabla[i].clase, clase) == 0))
            return i;
    }
    return -1;
}

static void insertar_macro(const char *nom)
{
    if (buscar_en_todo(nom, "macro") >= 0) {
        fprintf(stderr,
            "Error semantico en linea %d: macro '%s' ya definida\n",
            lineno, nom);
        errores++;
        return;
    }
    strcpy(tabla[n_sim].nombre, nom);
    strcpy(tabla[n_sim].clase,  "macro");
    strcpy(tabla[n_sim].tipo,   "int");
    tabla[n_sim].aridad  = -1;
    tabla[n_sim].ambito  =  0;
    tabla[n_sim].activo  =  1;
    tabla[n_sim].usado   =  1;
    n_sim++;
}

static void insertar_variable(const char *nom)
{
    for (int i = 0; i < n_sim; i++) {
        if (tabla[i].activo &&
            tabla[i].ambito == ambito_actual &&
            strcmp(tabla[i].clase,  "variable") == 0 &&
            strcmp(tabla[i].nombre, nom)        == 0) {
            fprintf(stderr,
                "Error semantico en linea %d: redeclaracion de variable '%s'\n",
                lineno, nom);
            errores++;
            return;
        }
    }
    strcpy(tabla[n_sim].nombre, nom);
    strcpy(tabla[n_sim].clase,  "variable");
    strcpy(tabla[n_sim].tipo,   "int");
    tabla[n_sim].aridad  = -1;
    tabla[n_sim].ambito  =  ambito_actual;
    tabla[n_sim].activo  =  1;
    tabla[n_sim].usado   =  0;
    n_sim++;
}

static void insertar_parametro(const char *nom)
{
    strcpy(tabla[n_sim].nombre, nom);
    strcpy(tabla[n_sim].clase,  "variable");
    strcpy(tabla[n_sim].tipo,   "int");
    tabla[n_sim].aridad  = -1;
    tabla[n_sim].ambito  =  ambito_actual;
    tabla[n_sim].activo  =  1;
    tabla[n_sim].usado   =  1;
    n_sim++;
}

static void insertar_funcion(const char *nom, int aridad)
{
    if (buscar_en_todo(nom, "funcion") >= 0) {
        fprintf(stderr,
            "Error semantico en linea %d: funcion '%s' ya declarada\n",
            lineno, nom);
        errores++;
        return;
    }
    strcpy(tabla[n_sim].nombre, nom);
    strcpy(tabla[n_sim].clase,  "funcion");
    strcpy(tabla[n_sim].tipo,   "int");
    tabla[n_sim].aridad  =  aridad;
    tabla[n_sim].ambito  =  0;
    tabla[n_sim].activo  =  1;
    tabla[n_sim].usado   =  1;
    n_sim++;
}

static void verificar_variable(const char *nom)
{
    for (int i = n_sim - 1; i >= 0; i--) {
        if (tabla[i].activo &&
            strcmp(tabla[i].clase,  "variable") == 0 &&
            strcmp(tabla[i].nombre, nom)        == 0)
            return;
    }
    fprintf(stderr,
        "Error semantico en linea %d: variable '%s' no declarada\n",
        lineno, nom);
    errores++;
}

static void marcar_usado(const char *nom)
{
    for (int i = n_sim - 1; i >= 0; i--) {
        if (tabla[i].activo &&
            strcmp(tabla[i].clase,  "variable") == 0 &&
            strcmp(tabla[i].nombre, nom)        == 0) {
            tabla[i].usado = 1;
            return;
        }
    }
    fprintf(stderr,
        "Error semantico en linea %d: variable '%s' no declarada\n",
        lineno, nom);
    errores++;
}

static void verificar_funcion(const char *nom, int argc_llamada)
{
    int idx = buscar_en_todo(nom, "funcion");
    if (idx < 0) {
        fprintf(stderr,
            "Error semantico en linea %d: funcion '%s' no declarada\n",
            lineno, nom);
        errores++;
        return;
    }
    if (tabla[idx].aridad != argc_llamada) {
        fprintf(stderr,
            "Error semantico en linea %d: funcion '%s' espera %d argumento(s), pero recibio %d\n",
            lineno, nom, tabla[idx].aridad, argc_llamada);
        errores++;
    }
}

static void abrir_ambito(void)
{
    ambito_actual++;
}

static void cerrar_ambito(void)
{
    for (int i = 0; i < n_sim; i++) {
        if (tabla[i].ambito == ambito_actual &&
            tabla[i].activo) {
            if (strcmp(tabla[i].clase, "variable") == 0 &&
                !tabla[i].usado) {
                fprintf(stderr,
                    "Advertencia: variable '%s' declarada pero no usada\n",
                    tabla[i].nombre);
            }
            tabla[i].activo = 0;
        }
    }
    ambito_actual--;
}

static void imprimir_tabla(void)
{
    printf("\n+----------------+----------+--------+--------+--------+\n");
    printf("| %-14s | %-8s | %-6s | %-6s | %-6s |\n",
           "Nombre", "Clase", "Tipo", "Ambito", "Aridad");
    printf("+----------------+----------+--------+--------+--------+\n");
    for (int i = 0; i < n_sim; i++) {
        char ar[8];
        if (tabla[i].aridad < 0)
            strcpy(ar, "-");
        else
            snprintf(ar, sizeof(ar), "%d", tabla[i].aridad);
        printf("| %-14s | %-8s | %-6s | %-6d | %-6s |\n",
               tabla[i].nombre, tabla[i].clase, tabla[i].tipo,
               tabla[i].ambito, ar);
    }
    printf("+----------------+----------+--------+--------+--------+\n");
    printf("\nTotal de errores semanticos: %d\n", errores);
}
%}

%union {
    int  num;
    char *str;
}

%token <str> ID STRING
%token <num> NUM
%token INCLUDE DEFINE INT FUNC RETURN IF
%token PLUS MINUS TIMES DIVIDE
%token ASSIGN LPAREN RPAREN LBRACE RBRACE SEMI COMMA LT GT DOT

%type <num> param_list_opt param_list arg_list_opt arg_list expr

%left  PLUS MINUS
%left  TIMES DIVIDE

%%

program
    : preprocessor global_decls func_list
        { imprimir_tabla(); }
    ;

preprocessor
    : /* vacio */
    | preprocessor include_dir
    | preprocessor define_dir
    ;

include_dir
    : INCLUDE LT ID DOT ID GT   { free($3); free($5); }
    | INCLUDE STRING             { free($2); }
    ;

define_dir
    : DEFINE ID NUM              { insertar_macro($2); free($2); }
    | DEFINE ID STRING           { insertar_macro($2); free($2); free($3); }
    ;

global_decls
    : /* vacio */
    | global_decls global_decl
    ;

global_decl
    : INT ID SEMI                { insertar_variable($2); free($2); }
    ;

func_list
    : /* vacio */
    | func_list func_def
    ;

func_def
    : FUNC ID
      {
          strcpy(func_actual, $2);
          free($2);
          abrir_ambito();
      }
      LPAREN param_list_opt RPAREN
      {
          insertar_funcion(func_actual, $5);
      }
      LBRACE stmt_list RBRACE
      {
          cerrar_ambito();
      }
    ;

param_list_opt
    : /* vacio */    { $$ = 0; }
    | param_list     { $$ = $1; }
    ;

param_list
    : ID
        { insertar_parametro($1); free($1); $$ = 1; }
    | param_list COMMA ID
        { insertar_parametro($3); free($3); $$ = $1 + 1; }
    ;

stmt_list
    : /* vacio */
    | stmt_list stmt
    ;

stmt
    : INT ID SEMI
        { insertar_variable($2); free($2); }
    | ID ASSIGN expr SEMI
        { marcar_usado($1); free($1); }
    | ID LPAREN arg_list_opt RPAREN SEMI
        { verificar_funcion($1, $3); free($1); }
    | RETURN expr SEMI
    | if_stmt
    | block
    ;

if_stmt
    : IF LPAREN ID RPAREN
        { marcar_usado($3); free($3); }
      LBRACE
        { abrir_ambito(); }
      stmt_list RBRACE
        { cerrar_ambito(); }
    ;

block
    : LBRACE
        { abrir_ambito(); }
      stmt_list RBRACE
        { cerrar_ambito(); }
    ;

arg_list_opt
    : /* vacio */          { $$ = 0; }
    | arg_list             { $$ = $1; }
    ;

arg_list
    : expr                 { $$ = 1; }
    | arg_list COMMA expr  { $$ = $1 + 1; }
    ;

expr
    : ID                   { marcar_usado($1); free($1); $$ = 0; }
    | NUM                  { $$ = $1; }
    | expr PLUS  expr      { $$ = 0; }
    | expr MINUS expr      { $$ = 0; }
    | expr TIMES expr      { $$ = 0; }
    | expr DIVIDE expr     { $$ = 0; }
    ;

%%

void yyerror(const char *s)
{
    fprintf(stderr, "Error sintactico en linea %d: %s\n", lineno, s);
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <archivo.c>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "No se pudo abrir el archivo: %s\n", argv[1]);
        return 1;
    }
    yyparse();
    fclose(yyin);
    return 0;
}
