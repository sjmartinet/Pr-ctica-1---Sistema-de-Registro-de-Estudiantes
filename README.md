# Práctica 1 - Sistema de Registro de Estudiantes
**ST 0244 - Programación de Lenguajes de Programación - EAFIT**

---

## Archivos del proyecto

```
├── Main.hs          ← Versión Haskell
├── main.pl          ← Versión Prolog
├── University.txt   ← Archivo de datos (compartido por ambas versiones)
└── README.md        ← Este archivo
```

---

## Formato de University.txt

Cada línea representa un estudiante con 4 campos separados por coma:

```
ID,Nombre,HoraEntrada,HoraSalida
```

- Si `HoraEntrada` está vacío → nunca ha hecho check-in
- Si `HoraSalida` está vacío → el estudiante está actualmente adentro

**Ejemplo:**
```
1001,Ana Garcia,08:30,
1002,Carlos Lopez,09:15,11:30
1003,Maria Torres,,
```

---

## Versión Haskell

### Requisitos
- GHC (Glasgow Haskell Compiler) instalado

### Compilar y ejecutar
```bash
# Opción 1: Compilar primero (más rápido)
ghc Main.hs -o registro
./registro

# Opción 2: Ejecutar directo sin compilar
runghc Main.hs
```

---

## Versión Prolog

### Requisitos
- SWI-Prolog instalado

### Ejecutar
```bash
# Opción 1: Desde la terminal directamente
swipl -g main -t halt main.pl

# Opción 2: Entrar al intérprete y llamar main
swipl main.pl
?- main.
```

---

## Conceptos clave para la defensa

### ¿Por qué Haskell pasa la lista como argumento en lugar de modificarla?
En Haskell, los datos son **inmutables**: una vez creada una lista, no se puede cambiar.
En lugar de modificar la lista, cada función devuelve una lista **nueva** con los cambios.
El `mainLoop` siempre recibe la versión más reciente de la lista.

### ¿Por qué Prolog usa `assertz` y `retract`?
En Prolog, la memoria son **hechos** de la base de datos.
- `assertz(student(...))` → agrega un hecho nuevo al final
- `retract(student(...))` → elimina un hecho existente
Esta es la manera de "modificar" datos en Prolog: eliminar el viejo y agregar el nuevo.

### ¿Cómo funciona la persistencia de archivos?
Ambas versiones leen `University.txt` al iniciar y lo reescriben completo
cada vez que hay un cambio (check-in o check-out). Esto garantiza que
los datos sobrevivan aunque se cierre el programa.

### ¿Por qué se usa `Maybe` en Haskell para las horas?
`Maybe String` puede ser `Nothing` (no hay hora) o `Just "08:30"` (hay hora).
Esto es más seguro que usar una cadena vacía `""`, porque obliga al programador
a manejar explícitamente el caso en que no hay hora.

### Diferencia funcional vs lógica
- **Haskell (funcional)**: Describes QUÉ transformaciones hace cada función sobre los datos.
- **Prolog (lógico)**: Describes QUÉ ES VERDAD sobre los datos y Prolog busca cómo satisfacerlo.
