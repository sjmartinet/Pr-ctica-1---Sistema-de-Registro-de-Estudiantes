% ================================================================
% PRÁCTICA 1 — SISTEMA DE REGISTRO DE ESTUDIANTES
% Versión B: Prolog  |  ST-0244 EAFIT  |  Feb 2026
% ================================================================
% EJECUTAR:
%   swipl -g main -t halt main.pl
%   o: swipl main.pl   luego escribir:  ?- main.
% ================================================================

% Declaramos 'estudiante' como dinámico para poder usar
% assertz (agregar hechos) y retract (borrar hechos) en ejecución.
% Estructura: estudiante(Id, Nombre, HoraEntrada, HoraSalida)
% Las horas usan el átomo 'ninguna' cuando no están registradas.
:- dynamic estudiante/4.

% ================================================================
% HORA DEL SISTEMA
% ================================================================

% Obtiene la hora actual del SO en formato "HH:MM".
% get_time devuelve segundos desde 1970, format_time lo formatea.
ahora(T) :- get_time(S), format_time(atom(T), '%H:%M', S).

% ================================================================
% MANEJO DEL ARCHIVO University.txt
% ================================================================

% Carga los estudiantes desde el archivo a la base de datos.
% Si el archivo no existe, simplemente inicia vacío sin crashear.
cargar :-
    ( exists_file('University.txt') ->
        open('University.txt', read, Flujo),
        leer_lineas(Flujo),
        close(Flujo),
        write('[OK] Datos cargados desde University.txt.'), nl
    ; write('[INFO] Archivo no encontrado, iniciando vacio.'), nl
    ).

% Lee línea por línea hasta llegar al fin del archivo (end_of_file).
% Es recursivo: procesa una línea y se llama a sí mismo.
leer_lineas(Flujo) :-
    read_line_to_string(Flujo, Linea),
    ( Linea == end_of_file -> true
    ; ( split_string(Linea, ",", "", [Is, Ns, Es, Ss]) ->
            atom_string(Id, Is), atom_string(Nom, Ns),
            % Campo vacío "" se convierte al átomo 'ninguna'
            ( Es == "" -> EA = ninguna ; atom_string(EA, Es) ),
            ( Ss == "" -> SA = ninguna ; atom_string(SA, Ss) ),
            assertz(estudiante(Id, Nom, EA, SA))
        ; true % Línea malformada: ignorar
        ),
        leer_lineas(Flujo)
    ).

% Guarda todos los hechos estudiante/4 sobreescribiendo el archivo.
% forall itera sobre cada estudiante y escribe su línea CSV.
guardar :-
    open('University.txt', write, Flujo),
    forall(estudiante(Id, N, E, S), (
        ( E == ninguna -> ES = "" ; atom_string(E, ES) ),
        ( S == ninguna -> SS = "" ; atom_string(S, SS) ),
        format(Flujo, "~w,~w,~w,~w~n", [Id, N, ES, SS])
    )),
    close(Flujo),
    write('[OK] Guardado en University.txt.'), nl.

% ================================================================
% UTILIDADES
% ================================================================

% Verdadero si el estudiante está actualmente adentro:
% tiene hora de entrada y NO tiene hora de salida.
esta_adentro(Id) :-
    estudiante(Id, _, E, ninguna), E \= ninguna, !.

% Calcula e imprime el tiempo de permanencia entre dos horas HH:MM.
mostrar_duracion(Inicio, Fin) :-
    hora_a_minutos(Inicio, MI), hora_a_minutos(Fin, MF),
    Diff is MF - MI,
    format("     Tiempo: ~wh ~wmin~n", [Diff // 60, Diff mod 60]).

hora_a_minutos(Hora, Min) :-
    atom_string(Hora, S), split_string(S, ":", "", [Hs, Ms]),
    number_string(H, Hs), number_string(M, Ms),
    Min is H * 60 + M.

% Convierte 'ninguna' a '-' solo para mostrar en pantalla.
mostrar(ninguna, '-') :- !.
mostrar(V, V).

% ================================================================
% OPERACIONES DEL MENÚ
% ================================================================

% OPCIÓN 1: Registrar entrada (Check In)
registrar_entrada :-
    write('ID del estudiante: '),
    read_line_to_string(user_input, Is), atom_string(Id, Is),
    ( esta_adentro(Id) ->
        write('[!] Ya esta adentro.'), nl
    ; estudiante(Id, N, _, _) ->
        % Existe pero no está adentro: actualizamos su registro
        ahora(T), retract(estudiante(Id, N, _, _)),
        assertz(estudiante(Id, N, T, ninguna)),
        guardar, format("[OK] Entrada de ~w a las ~w~n", [N, T])
    ;   % Estudiante nuevo: pedimos nombre y lo creamos
        write('Nombre: '), read_line_to_string(user_input, Ns),
        atom_string(N, Ns), ahora(T),
        assertz(estudiante(Id, N, T, ninguna)),
        guardar, format("[OK] Entrada de ~w a las ~w~n", [N, T])
    ).

% OPCIÓN 2: Buscar estudiante activo por ID
buscar_estudiante :-
    write('ID del estudiante: '),
    read_line_to_string(user_input, Is), atom_string(Id, Is),
    ( esta_adentro(Id), estudiante(Id, N, E, _) ->
        format("~n  ID:      ~w~n  Nombre:  ~w~n  Entro a: ~w~n", [Id, N, E])
    ; write('[!] No se encontro ningun estudiante activo con ese ID.'), nl
    ).

% OPCIÓN 3: Registrar salida (Check Out)
registrar_salida :-
    write('ID del estudiante: '),
    read_line_to_string(user_input, Is), atom_string(Id, Is),
    ( esta_adentro(Id), estudiante(Id, N, E, ninguna) ->
        ahora(T),
        retract(estudiante(Id, N, E, ninguna)),
        assertz(estudiante(Id, N, E, T)),
        guardar,
        format("[OK] Salida de ~w a las ~w~n", [N, T]),
        mostrar_duracion(E, T)
    ; write('[!] No se encontro ese estudiante activo.'), nl
    ).

% OPCIÓN 4: Listar todos los estudiantes
listar_estudiantes :-
    ( estudiante(_, _, _, _) ->
        write("\nID       | Nombre             | Entrada | Salida"), nl,
        write("--------------------------------------------------"), nl,
        forall(estudiante(Id, N, E, S), (
            mostrar(E, ED), mostrar(S, SD),
            format("~w | ~w | ~w | ~w~n", [Id, N, ED, SD])
        ))
    ; write('[INFO] No hay estudiantes registrados.'), nl
    ).

% ================================================================
% MENÚ Y BUCLE PRINCIPAL
% ================================================================

mostrar_menu :-
    nl, write('=============================='), nl,
    write('  SISTEMA DE REGISTRO EAFIT  '), nl,
    write('=============================='), nl,
    write('1. Registrar Entrada (Check In)'), nl,
    write('2. Buscar Estudiante por ID'), nl,
    write('3. Registrar Salida (Check Out)'), nl,
    write('4. Listar Todos los Estudiantes'), nl,
    write('5. Salir'), nl,
    write('=============================='), nl,
    write('Opcion: ').

% Relaciona cada opción con su predicado. Si no es ninguna, avisa.
despachar("1") :- registrar_entrada.
despachar("2") :- buscar_estudiante.
despachar("3") :- registrar_salida.
despachar("4") :- listar_estudiantes.
despachar(Op)  :- Op \= "5", write('[!] Opcion invalida.'), nl.

% Bucle recursivo: muestra menú → lee opción → ejecuta → repite.
% Se detiene cuando el usuario elige "5".
bucle :-
    mostrar_menu,
    read_line_to_string(user_input, Op), nl,
    ( Op == "5" -> write('Hasta luego!'), nl
    ; despachar(Op), bucle
    ).

% ================================================================
% PUNTO DE ENTRADA
% ================================================================
% :- initialization ejecuta 'main' automáticamente al iniciar.
:- initialization(main, main).

main :- cargar, bucle.
