-- ============================================================
-- PRÁCTICA 1 - SISTEMA DE REGISTRO DE ESTUDIANTES
-- Versión A: Haskell (Programación Funcional)
-- ST 0244 - Programación de Lenguajes de Programación - EAFIT
-- ============================================================
--
-- CÓMO COMPILAR Y EJECUTAR:
--   ghc Main.hs -o registro
--   ./registro
--
-- O con runghc (sin compilar):
--   runghc Main.hs

module Main where

import Control.Exception (catch, IOException)
import Data.List         (find, intercalate)
import Data.Maybe        (fromMaybe)
import System.IO         (hSetBuffering, stdout, BufferMode(..))

-- ============================================================
-- 1. TIPO DE DATOS
-- ============================================================
-- Definimos cómo luce un "estudiante" en memoria.
-- Usamos 'Maybe String' para los tiempos:
--   Nothing  = todavía no tiene hora registrada
--   Just "08:30" = tiene hora registrada
--
-- Nota de Haskell: 'deriving Show' hace que Haskell pueda
-- imprimir el tipo automáticamente (útil para depurar).

data Student = Student
  { studentId   :: String        -- ID del estudiante, ej: "1001"
  , studentName :: String        -- Nombre completo
  , checkIn     :: Maybe String  -- Hora de entrada (HH:MM) o nada
  , checkOut    :: Maybe String  -- Hora de salida  (HH:MM) o nada
  } deriving (Show, Eq)

-- ============================================================
-- 2. NOMBRE DEL ARCHIVO DE PERSISTENCIA
-- ============================================================

fileName :: String
fileName = "University.txt"

-- ============================================================
-- 3. FUNCIONES DE CONVERSIÓN (Student <-> Línea de texto)
-- ============================================================
-- El archivo guarda cada estudiante en una línea así:
--   1001,Ana Garcia,08:30,10:45
--   1002,Carlos Lopez,09:15,
--
-- Si el campo de hora está vacío, significa 'Nothing'.

-- Convierte un estudiante a una línea de texto CSV
studentToLine :: Student -> String
studentToLine s = intercalate ","
  [ studentId   s
  , studentName s
  , fromMaybe "" (checkIn  s)  -- Nothing → cadena vacía
  , fromMaybe "" (checkOut s)
  ]

-- Convierte una línea de texto CSV a un estudiante
-- Retorna 'Nothing' si la línea no tiene el formato correcto
lineToStudent :: String -> Maybe Student
lineToStudent line = case splitOn ',' line of
  [i, n, ci, co] -> Just Student
    { studentId   = i
    , studentName = n
    , checkIn     = if null ci then Nothing else Just ci
    , checkOut    = if null co then Nothing else Just co
    }
  _              -> Nothing  -- Línea malformada, la ignoramos

-- Función auxiliar: divide un String usando un carácter separador
-- Ejemplo: splitOn ',' "a,b,c"  →  ["a","b","c"]
splitOn :: Char -> String -> [String]
splitOn _ ""     = [""]
splitOn sep (c:cs)
  | c == sep  = "" : splitOn sep cs
  | otherwise = let (primero:resto) = splitOn sep cs
                in (c:primero) : resto

-- ============================================================
-- 4. MANEJO DE ARCHIVOS
-- ============================================================

-- Carga la lista de estudiantes desde University.txt
-- Si el archivo no existe, retorna lista vacía
loadStudents :: IO [Student]
loadStudents = catch cargar manejarError
  where
    cargar = do
      contenido <- readFile fileName
      -- 'seq' fuerza la evaluación COMPLETA antes de continuar
      -- (necesario en Haskell por su evaluación perezosa "lazy")
      let estudiantes = [s | Just s <- map lineToStudent
                                      (filter (not . null) (lines contenido))]
      length estudiantes `seq` return estudiantes

    manejarError :: IOException -> IO [Student]
    manejarError _ = do
      putStrLn "Nota: University.txt no existe, iniciando con lista vacía."
      return []

-- Guarda la lista completa de estudiantes en University.txt
saveStudents :: [Student] -> IO ()
saveStudents estudiantes = do
  writeFile fileName (unlines (map studentToLine estudiantes))
  putStrLn "✓ Datos guardados en University.txt"

-- ============================================================
-- 5. CÁLCULO DE TIEMPO
-- ============================================================

-- Convierte "HH:MM" a minutos totales (ej: "01:30" → 90)
timeToMinutes :: String -> Int
timeToMinutes t = case splitOn ':' t of
  [hh, mm] -> read hh * 60 + read mm
  _        -> 0

-- Calcula y muestra la diferencia entre hora de entrada y salida
showDuration :: String -> String -> String
showDuration inicio fin =
  let minInicio = timeToMinutes inicio
      minFin    = timeToMinutes fin
      diff      = minFin - minInicio
      horas     = diff `div` 60
      minutos   = diff `mod` 60
  in show horas ++ "h " ++ show minutos ++ "min"

-- ============================================================
-- 6. FUNCIONES DE CADA OPCIÓN DEL MENÚ
-- ============================================================
-- Nota importante de Haskell: como las listas son INMUTABLES,
-- cada función devuelve la lista NUEVA (modificada).
-- El menú principal siempre pasa la versión más reciente.

-- ── OPCIÓN 1: CHECK IN ──────────────────────────────────────
checkInStudent :: [Student] -> IO [Student]
checkInStudent estudiantes = do
  putStr "Ingrese el ID del estudiante: "
  sid <- getLine

  case find (\s -> studentId s == sid) estudiantes of

    -- Caso A: El estudiante ya está adentro (tiene entrada, sin salida)
    Just s | checkIn s /= Nothing && checkOut s == Nothing -> do
      putStrLn "⚠ El estudiante ya está registrado adentro."
      return estudiantes

    -- Caso B: El estudiante ya existe en el sistema (pero no está adentro)
    Just s -> do
      putStr "Ingrese la hora de entrada (HH:MM): "
      t <- getLine
      -- Actualizamos SU registro con la nueva hora de entrada
      let actualizado = map (\x -> if studentId x == sid
                                   then x { checkIn = Just t, checkOut = Nothing }
                                   else x) estudiantes
      saveStudents actualizado
      putStrLn $ "✓ Check-in registrado para " ++ studentName s ++ " a las " ++ t
      return actualizado

    -- Caso C: El estudiante es NUEVO, no está en el sistema
    Nothing -> do
      putStr "Estudiante nuevo. Ingrese el nombre: "
      nombre <- getLine
      putStr "Ingrese la hora de entrada (HH:MM): "
      t <- getLine
      let nuevo      = Student sid nombre (Just t) Nothing
      let actualizado = estudiantes ++ [nuevo]
      saveStudents actualizado
      putStrLn $ "✓ Check-in registrado para " ++ nombre ++ " a las " ++ t
      return actualizado

-- ── OPCIÓN 2: BUSCAR POR ID ─────────────────────────────────
searchStudent :: [Student] -> IO ()
searchStudent estudiantes = do
  putStr "Ingrese el ID del estudiante: "
  sid <- getLine
  -- Solo buscamos estudiantes que ESTÁN ADENTRO AHORA
  -- (tienen hora de entrada y NO tienen hora de salida)
  let adentro = find (\s -> studentId s == sid
                         && checkIn  s /= Nothing
                         && checkOut s == Nothing) estudiantes
  case adentro of
    Just s -> do
      putStrLn "\n=== Estudiante encontrado ==="
      putStrLn $ "ID:     " ++ studentId   s
      putStrLn $ "Nombre: " ++ studentName s
      putStrLn $ "Entró:  " ++ fromMaybe "—" (checkIn s)
    Nothing ->
      putStrLn "No se encontró ningún estudiante ACTIVO con ese ID."

-- ── OPCIÓN 3: CHECK OUT ─────────────────────────────────────
checkOutStudent :: [Student] -> IO [Student]
checkOutStudent estudiantes = do
  putStr "Ingrese el ID del estudiante: "
  sid <- getLine
  -- Solo podemos hacer check-out de alguien que esté adentro
  let adentro = find (\s -> studentId s == sid
                         && checkIn  s /= Nothing
                         && checkOut s == Nothing) estudiantes
  case adentro of
    Nothing -> do
      putStrLn "No se encontró ese estudiante activo."
      return estudiantes
    Just s -> do
      putStr "Ingrese la hora de salida (HH:MM): "
      t <- getLine
      let entrada     = fromMaybe "00:00" (checkIn s)
      let duracion    = showDuration entrada t
      let actualizado = map (\x -> if studentId x == sid
                                   then x { checkOut = Just t }
                                   else x) estudiantes
      saveStudents actualizado
      putStrLn $ "✓ Check-out registrado para " ++ studentName s
      putStrLn $ "  Tiempo en la universidad: " ++ duracion
      return actualizado

-- ── OPCIÓN 4: LISTAR ESTUDIANTES ────────────────────────────
listStudents :: [Student] -> IO ()
listStudents [] = putStrLn "No hay estudiantes registrados."
listStudents estudiantes = do
  putStrLn "\n=== Lista de Estudiantes ==="
  putStrLn $ columna 8 "ID" ++ " | " ++ columna 18 "Nombre" ++ " | " ++
             columna 7 "Entrada" ++ " | " ++ "Salida"
  putStrLn (replicate 52 '-')
  mapM_ imprimirFila estudiantes
  where
    imprimirFila s = putStrLn $
      columna 8  (studentId   s) ++ " | " ++
      columna 18 (studentName s) ++ " | " ++
      columna 7  (fromMaybe "—" (checkIn  s)) ++ " | " ++
      fromMaybe "—" (checkOut s)

    -- Ajusta una cadena a un ancho fijo (rellena con espacios)
    columna n str = take n (str ++ repeat ' ')

-- ============================================================
-- 7. MENÚ PRINCIPAL
-- ============================================================

mostrarMenu :: IO ()
mostrarMenu = do
  putStrLn "\n=============================="
  putStrLn "  SISTEMA DE REGISTRO EAFIT  "
  putStrLn "=============================="
  putStrLn "1. Check In  (Registrar Entrada)"
  putStrLn "2. Buscar Estudiante por ID"
  putStrLn "3. Check Out (Registrar Salida)"
  putStrLn "4. Listar Todos los Estudiantes"
  putStrLn "5. Salir"
  putStrLn "=============================="
  putStr "Seleccione una opción: "

-- El loop recibe SIEMPRE la lista actualizada
-- Esta es la idea funcional clave: no hay variables globales,
-- la "memoria" se pasa como argumento en cada llamada recursiva.
mainLoop :: [Student] -> IO ()
mainLoop estudiantes = do
  mostrarMenu
  opcion <- getLine
  case opcion of
    "1" -> checkInStudent  estudiantes >>= mainLoop
    "2" -> searchStudent   estudiantes >>  mainLoop estudiantes
    "3" -> checkOutStudent estudiantes >>= mainLoop
    "4" -> listStudents    estudiantes >>  mainLoop estudiantes
    "5" -> putStrLn "¡Hasta luego!"
    _   -> putStrLn "Opción inválida." >> mainLoop estudiantes

-- ============================================================
-- 8. PUNTO DE ENTRADA
-- ============================================================

main :: IO ()
main = do
  -- Desactivar el buffer para que la salida aparezca inmediatamente
  hSetBuffering stdout NoBuffering
  putStrLn "Cargando datos desde University.txt..."
  estudiantes <- loadStudents
  putStrLn $ "Se cargaron " ++ show (length estudiantes) ++ " estudiante(s)."
  mainLoop estudiantes
