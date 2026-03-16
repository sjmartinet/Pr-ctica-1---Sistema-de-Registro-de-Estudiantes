% ============================================================
% PRÁCTICA 1 - SISTEMA DE REGISTRO DE ESTUDIANTES
% Versión B: Prolog (Programación Lógica)
% ST 0244 - Programación de Lenguajes de Programación - EAFIT
% ============================================================
%
% CÓMO EJECUTAR (SWI-Prolog):
%   swipl main.pl
%   ?- main.
%
% O directamente desde la terminal:
%   swipl -g main -t halt main.pl
% ============================================================

% ============================================================
% 1. DECLARACIÓN DE PREDICADOS DINÁMICOS
% ============================================================
% En Prolog, usamos "hechos dinámicos" como nuestra lista en memoria.
% :- dynamic  le dice a Prolog que este predicado puede cambiar
%             durante la ejecución (con assertz/retract).
%
% Cada estudiante se guarda como:
%   student(Id, Nombre, HoraEntrada, HoraSalida)
%
% Para las horas usamos el átomo 'none' cuando está vacío.
% Ejemplo:
%   student('1001', 'Ana Garcia', '08:30', none)  ← está adentro
%   student('1002', 'Carlos',     '09:00', '11:30') ← ya salió
%   student('1003', 'Maria',      none,    none)  ← nunca entró

:- dynamic student/4.

% ============================================================
% 2. NOMBRE DEL ARCHIVO DE PERSISTENCIA
% ============================================================

file_name('University.txt').

% ============================================================
% 3. MANEJO DE ARCHIVOS
% ============================================================

% Carga todos los estudiantes del archivo a la base de datos
% (convierte cada línea del CSV en un hecho student/4)
load_students :-
    file_name(File),
    (exists_file(File) ->
        open(File, read, Stream),
        read_all_lines(Stream),
        close(Stream),
        write('Datos cargados desde University.txt.'), nl
    ;
        write('University.txt no existe, iniciando vacío.'), nl
    ).

% Lee todas las líneas del stream hasta llegar al final del archivo
read_all_lines(Stream) :-
    read_line_to_string(Stream, Line),
    (Line == end_of_file ->
        true                      % Llegamos al final, terminamos
    ;
        parse_and_assert(Line),   % Procesar línea y guardarla
        read_all_lines(Stream)    % Continuar con la siguiente
    ).

% Convierte una línea CSV a un hecho student/4 y lo guarda en memoria
parse_and_assert(Line) :-
    split_string(Line, ",", "", [IdS, NameS, CiS, CoS]),
    % Convertir strings a átomos (Prolog trabaja mejor con átomos)
    atom_string(Id,   IdS),
    atom_string(Name, NameS),
    % Si el campo está vacío → guardamos el átomo 'none'
    (CiS == "" -> Ci = none ; atom_string(Ci, CiS)),
    (CoS == "" -> Co = none ; atom_string(Co, CoS)),
    assertz(student(Id, Name, Ci, Co)).  % Guardar en base de datos

% Guarda todos los estudiantes de la base de datos al archivo
save_students :-
    file_name(File),
    open(File, write, Stream),
    % forall: para cada student que exista, escribir su línea
    forall(student(Id, Name, Ci, Co),
           write_line(Stream, Id, Name, Ci, Co)),
    close(Stream),
    write('✓ Datos guardados en University.txt.'), nl.

% Escribe una línea CSV en el archivo para un estudiante
write_line(Stream, Id, Name, Ci, Co) :-
    % Convertir 'none' de vuelta a cadena vacía para el archivo
    (Ci == none -> CiS = "" ; atom_string(Ci, CiS)),
    (Co == none -> CoS = "" ; atom_string(Co, CoS)),
    format(Stream, "~w,~w,~w,~w~n", [Id, Name, CiS, CoS]).

% ============================================================
% 4. CÁLCULO DE TIEMPO
% ============================================================

% Convierte un átomo "HH:MM" a minutos totales desde medianoche
% Ejemplo: '08:30' → 510
time_to_minutes(Time, Minutes) :-
    atom_string(Time, TimeStr),
    split_string(TimeStr, ":", "", [HH, MM]),
    number_string(H, HH),
    number_string(M, MM),
    Minutes is H * 60 + M.

% Muestra el tiempo que estuvo un estudiante en la universidad
show_duration(Start, End) :-
    time_to_minutes(Start, SM),
    time_to_minutes(End,   EM),
    Diff is EM - SM,
    H    is Diff // 60,   % División entera para horas
    M    is Diff mod 60,  % Resto para minutos
    format("  Tiempo en la universidad: ~wh ~wmin~n", [H, M]).

% ============================================================
% 5. PREDICADOS DE CADA OPCIÓN DEL MENÚ
% ============================================================

% ── OPCIÓN 1: CHECK IN ──────────────────────────────────────
check_in :-
    write('Ingrese el ID del estudiante: '),
    read_line_to_string(user_input, IdStr),
    atom_string(Id, IdStr),

    % CASO A: El estudiante ya está adentro (tiene entrada, sin salida)
    (student(Id, _, Ci, none), Ci \= none ->
        write('⚠ El estudiante ya está registrado adentro.'), nl

    % CASO B: El estudiante existe pero ya salió (o nunca entró)
    ; student(Id, Name, _, _) ->
        write('Ingrese la hora de entrada (HH:MM): '),
        read_line_to_string(user_input, TimeStr),
        atom_string(Time, TimeStr),
        % Retract elimina el hecho viejo, assertz agrega el nuevo
        retract(student(Id, Name, _, _)),
        assertz(student(Id, Name, Time, none)),
        save_students,
        format("✓ Check-in registrado para ~w a las ~w~n", [Name, Time])

    % CASO C: Es un estudiante completamente nuevo
    ;
        write('Estudiante nuevo. Ingrese el nombre: '),
        read_line_to_string(user_input, NameStr),
        atom_string(Name, NameStr),
        write('Ingrese la hora de entrada (HH:MM): '),
        read_line_to_string(user_input, TimeStr),
        atom_string(Time, TimeStr),
        assertz(student(Id, Name, Time, none)),
        save_students,
        format("✓ Check-in registrado para ~w a las ~w~n", [Name, Time])
    ).

% ── OPCIÓN 2: BUSCAR POR ID ─────────────────────────────────
search_student :-
    write('Ingrese el ID del estudiante: '),
    read_line_to_string(user_input, IdStr),
    atom_string(Id, IdStr),
    % Buscamos alguien que esté ADENTRO AHORA
    (student(Id, Name, Ci, none), Ci \= none ->
        nl,
        write('=== Estudiante encontrado ==='), nl,
        format("ID:     ~w~n", [Id]),
        format("Nombre: ~w~n", [Name]),
        format("Entró:  ~w~n", [Ci])
    ;
        write('No se encontró ningún estudiante ACTIVO con ese ID.'), nl
    ).

% ── OPCIÓN 3: CHECK OUT ─────────────────────────────────────
check_out :-
    write('Ingrese el ID del estudiante: '),
    read_line_to_string(user_input, IdStr),
    atom_string(Id, IdStr),
    (student(Id, Name, Ci, none), Ci \= none ->
        write('Ingrese la hora de salida (HH:MM): '),
        read_line_to_string(user_input, TimeStr),
        atom_string(Time, TimeStr),
        % Reemplazamos el hecho: quitamos el viejo, ponemos el nuevo
        retract(student(Id, Name, Ci, none)),
        assertz(student(Id, Name, Ci, Time)),
        save_students,
        format("✓ Check-out registrado para ~w~n", [Name]),
        show_duration(Ci, Time)
    ;
        write('No se encontró ese estudiante activo.'), nl
    ).

% ── OPCIÓN 4: LISTAR ESTUDIANTES ────────────────────────────
% Predicado auxiliar: convierte 'none' a '-' para mostrar
display_val(none, '-') :- !.
display_val(Val,  Val).

list_students :-
    % Verificamos si existe AL MENOS UN estudiante
    (student(_, _, _, _) ->
        nl,
        write('=== Lista de Estudiantes ==='), nl,
        write('ID       | Nombre            | Entrada | Salida'), nl,
        write('--------------------------------------------------'), nl,
        % forall: recorre TODOS los estudiantes e imprime cada uno
        forall(
            student(Id, Name, Ci, Co),
            (display_val(Ci, CiD), display_val(Co, CoD),
             format("~w | ~w | ~w | ~w~n", [Id, Name, CiD, CoD]))
        )
    ;
        write('No hay estudiantes registrados.'), nl
    ).

% ============================================================
% 6. MENÚ PRINCIPAL
% ============================================================

print_menu :-
    nl,
    write('=============================='), nl,
    write('  SISTEMA DE REGISTRO EAFIT  '), nl,
    write('=============================='), nl,
    write('1. Check In  (Registrar Entrada)'), nl,
    write('2. Buscar Estudiante por ID'), nl,
    write('3. Check Out (Registrar Salida)'), nl,
    write('4. Listar Todos los Estudiantes'), nl,
    write('5. Salir'), nl,
    write('=============================='), nl,
    write('Seleccione una opción: ').

% Despacha la opción elegida al predicado correspondiente
handle_option("1") :- check_in.
handle_option("2") :- search_student.
handle_option("3") :- check_out.
handle_option("4") :- list_students.
handle_option(_)   :- write('Opción inválida.'), nl.

% Loop principal: muestra menú, lee opción, ejecuta, repite
main_loop :-
    print_menu,
    read_line_to_string(user_input, Option),
    (Option == "5" ->
        write('¡Hasta luego!'), nl
    ;
        handle_option(Option),
        main_loop          % Llamada recursiva = "volver al menú"
    ).

% ============================================================
% 7. PUNTO DE ENTRADA
% ============================================================

:- initialization(main, main).

main :-
    write('Cargando datos desde University.txt...'), nl,
    load_students,
    main_loop.
