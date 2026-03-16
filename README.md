# Práctica 1 — Sistema de Registro de Estudiantes
**ST-0244 Programación de Lenguajes de Programación | EAFIT | Feb 2026**

---

## Estructura del proyecto

Los tres archivos deben estar siempre en la misma carpeta. Así es como debe verse tu carpeta antes de ejecutar cualquiera de los dos programas:

```
tu-carpeta/
├── Main.hs           → Versión Haskell (paradigma funcional)
├── main.pl           → Versión Prolog  (paradigma lógico)
└── University.txt    → Archivo de datos compartido por ambos
```

---

## El archivo University.txt

Ambos programas leen y escriben el mismo archivo `University.txt`. Cada línea representa un estudiante con 4 campos separados por coma: `ID,Nombre,HoraEntrada,HoraSalida`. Si una hora está vacía significa que todavía no ha sido registrada.

```
1001,Ana Garcia,08:30,
1002,Carlos Lopez,09:15,11:30
1003,Maria Torres,,
```

En el ejemplo de arriba, Ana está actualmente adentro (tiene entrada pero no salida), Carlos ya salió (tiene ambas horas), y Maria nunca ha hecho check-in (no tiene ninguna hora).

Ninguno de los dos programas mantiene el archivo abierto permanentemente. Al arrancar leen el archivo completo, y cada vez que hay un cambio (check-in o check-out) sobreescriben el archivo entero. Esto significa que si usas Haskell, cierras el programa y luego abres Prolog, Prolog verá exactamente los datos que Haskell dejó guardados. **No ejecutes los dos al mismo tiempo**, ya que podrían pisarse al escribir.

---

## Versión Haskell — Cómo ejecutar

Primero necesitas tener GHC instalado. Si no lo tienes, descárgalo desde https://www.haskell.org/ghcup/ e instala la versión recomendada.

Abre una terminal, navega hasta la carpeta del proyecto y ejecuta uno de estos dos comandos:

```bash
# Opción 1: compilar y luego ejecutar (más rápido para uso repetido)
ghc Main.hs -o registro
./registro

# Opción 2: ejecutar directamente sin compilar (más simple)
runghc Main.hs
```

El programa muestra un menú numerado en la terminal. Escribe el número de la opción que quieras y presiona Enter. La hora de entrada y salida se captura automáticamente del reloj de tu computador, no tienes que escribirla manualmente.

---

## Versión Prolog — Cómo ejecutar

Primero necesitas tener SWI-Prolog instalado. Si no lo tienes, descárgalo desde https://www.swi-prolog.org/download/stable

Abre una terminal, navega hasta la carpeta del proyecto y ejecuta:

```bash
swipl -g main -t halt main.pl
```

Al igual que Haskell, muestra un menú numerado en la terminal. Escribe el número y presiona Enter. La hora también se toma automáticamente del reloj del sistema.

---

## Funciones disponibles en ambos programas

Los dos programas tienen exactamente las mismas opciones, numeradas igual en el menú:

La **opción 1** registra la entrada de un estudiante. Si el ID ya existe en el sistema lo actualiza, si es nuevo te pide el nombre y lo crea.

La **opción 2** busca un estudiante por ID. Solo muestra estudiantes que estén actualmente adentro, es decir, que tengan hora de entrada pero no de salida.

La **opción 3** registra la salida de un estudiante activo y calcula automáticamente cuánto tiempo estuvo en la universidad.

La **opción 4** lista todos los estudiantes del archivo, tanto los activos como los que ya salieron o nunca entraron.

La **opción 5** cierra el programa.

---

## Conceptos clave para la defensa

**¿Por qué Haskell pasa la lista como argumento en el bucle?** En Haskell los datos son inmutables: una lista creada no puede modificarse directamente. Cada operación devuelve una lista nueva con los cambios aplicados, y el `bucle` siempre recibe la versión más reciente como argumento. Esa es la forma funcional de mantener estado: no hay variables globales, la "memoria" del programa viaja como argumento de función en función.

**¿Por qué Prolog usa `retract` y `assertz` para modificar un estudiante?** En Prolog los hechos son inmutables una vez creados. Para "modificar" un estudiante hay que hacer `retract` del hecho viejo (borrarlo de la base de datos) y `assertz` del hecho nuevo actualizado (agregarlo al final). Es la forma lógica de actualizar información.

**¿Cuál es la diferencia entre programación funcional y lógica?** En Haskell describes *transformaciones*: "dada esta lista, devuelve una lista nueva con este cambio aplicado". En Prolog describes *conocimiento*: "esto es verdad sobre el mundo", y el motor de inferencia decide cómo satisfacer cada consulta usando unificación y backtracking.
