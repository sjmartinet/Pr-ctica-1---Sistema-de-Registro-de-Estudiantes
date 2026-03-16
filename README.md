# Práctica 1 — Sistema de Registro de Estudiantes
**ST-0244 Programación de Lenguajes de Programación | EAFIT | Feb 2026**

---

## Archivos del proyecto

El proyecto contiene tres archivos principales. `Main.hs` es la versión funcional escrita completamente en Haskell. `main_swish.pl` es la versión lógica escrita en Prolog, adaptada para ejecutarse en el navegador usando SWISH. `University.txt` es el archivo de datos que usa Haskell para guardar y cargar estudiantes entre sesiones.

---

## Formato de University.txt

Cada línea representa un estudiante con 4 campos separados por coma: `ID,Nombre,HoraEntrada,HoraSalida`. Si una hora está vacía significa que no ha sido registrada todavía.

```
1001,Ana Garcia,08:30,
1002,Carlos Lopez,09:15,11:30
1003,Maria Torres,,
```

---

## Versión Haskell — Cómo ejecutar

Necesitas tener GHC instalado. Puedes descargarlo desde https://www.haskell.org/ghcup/

Coloca `Main.hs` y `University.txt` en la misma carpeta. Luego abre una terminal en esa carpeta y ejecuta:

```bash
# Opción 1: compilar primero y luego ejecutar (más rápido)
ghc Main.hs -o registro
./registro

# Opción 2: ejecutar directamente sin compilar
runghc Main.hs
```

El programa muestra un menú numerado en la terminal. Escribe el número de la opción y presiona Enter. La hora de entrada y salida se toma automáticamente del reloj de tu computador, no tienes que escribirla.

---

## Versión Prolog — Cómo ejecutar en SWISH

SWISH es un entorno Prolog que corre directamente en el navegador, sin instalar nada. El archivo `main_swish.pl` está diseñado específicamente para funcionar allí.

**Paso 1:** Entra a https://swish.swi-prolog.org desde cualquier navegador.

**Paso 2:** Verás un editor de código a la izquierda. Borra el contenido que traiga por defecto, luego abre el archivo `main_swish.pl`, copia todo su contenido y pégalo en ese editor.

**Paso 3:** Haz clic en el botón azul **"Run!"** en la parte superior derecha del editor. Esto carga el programa y automáticamente mostrará los estudiantes de ejemplo y las consultas disponibles.

**Paso 4:** En el panel inferior (donde dice "?-") escribe la consulta que quieras ejecutar y presiona Enter o el botón de play.

### Consultas disponibles

Para registrar la entrada de un estudiante que ya existe en el sistema escribe en el panel de consultas:
```prolog
?- registrar_entrada('1001', 'Ana Garcia').
```

Para registrar la entrada de un estudiante completamente nuevo (el segundo argumento es el nombre):
```prolog
?- registrar_entrada('9999', 'Nuevo Estudiante').
```

Para buscar un estudiante que esté actualmente adentro:
```prolog
?- buscar_estudiante('1003').
```

Para registrar la salida de un estudiante activo:
```prolog
?- registrar_salida('1003').
```

Para ver la lista completa de todos los estudiantes:
```prolog
?- listar_estudiantes.
```

### Datos de ejemplo precargados

El programa incluye 5 estudiantes de ejemplo que cubren todos los casos posibles. Ana y Carlos no tienen ninguna hora registrada, así que sirven para probar el check-in. Maria y Sofia están actualmente adentro (tienen entrada pero no salida), así que sirven para probar la búsqueda y el check-out. Pedro ya completó su visita y tiene ambas horas registradas, así que sirve para ver un registro completo en el listado.

### Nota importante sobre SWISH

SWISH no guarda datos entre sesiones. Cada vez que recargas la página o haces clic en "Run!" de nuevo, la base de datos vuelve a los 5 estudiantes de ejemplo originales. Esto es normal y esperado: es la forma en que funciona el entorno web.

---

## Conceptos clave para la defensa

**¿Por qué Haskell pasa la lista como argumento en el bucle?**
En Haskell los datos son inmutables: una lista creada no puede modificarse. Cada operación devuelve una lista nueva con los cambios aplicados. El `bucle` siempre recibe la versión más reciente como argumento, que es la forma funcional de mantener estado.

**¿Por qué Prolog usa `retract` y `assertz` para modificar un estudiante?**
En Prolog los hechos son inmutables una vez creados. Para "modificar" un estudiante hay que hacer `retract` del hecho viejo (borrarlo) y `assertz` del hecho nuevo actualizado (agregarlo al final). Es la forma lógica de actualizar información.

**¿Por qué la versión Prolog no tiene menú como la versión Haskell?**
SWISH es un entorno web sin terminal interactiva, así que no es posible leer texto del usuario con `read_line_to_string`. En cambio, cada operación es un predicado independiente que recibe los datos como argumentos directamente en la consulta. Esto es más natural en Prolog de todas formas, porque Prolog fue diseñado para responder consultas, no para ejecutar programas secuenciales.

**¿Cuál es la diferencia entre programación funcional y lógica?**
En Haskell describes transformaciones: "dada esta lista, devuelve una lista nueva con este cambio". En Prolog describes conocimiento: "esto es verdad sobre el mundo" y el motor de Prolog decide cómo satisfacer cada consulta usando unificación y backtracking.
