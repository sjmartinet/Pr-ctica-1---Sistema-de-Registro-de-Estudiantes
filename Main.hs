module Main where

-- Importamos las librerías que necesitamos.
-- Control.Exception nos permite capturar errores (como archivo no encontrado).
-- Data.List nos da la función 'find' para buscar en listas.
-- Data.Maybe nos da 'fromMaybe' para extraer valores de un Maybe con un valor por defecto.
-- Data.Time nos permite obtener la hora actual del sistema operativo.
-- System.IO nos permite configurar la terminal.
import Control.Exception (catch, IOException)
import Data.List (find, intercalate)
import Data.Maybe (fromMaybe)
import Data.Time (getZonedTime, formatTime, defaultTimeLocale)
import System.IO

-- ================================================================
-- MODELO DE DATOS
-- ================================================================

-- Definimos cómo luce un estudiante en la memoria del programa.
-- En Haskell creamos un "tipo de dato" propio con la palabra 'data'.
-- Cada campo tiene un nombre y un tipo.
-- 'Maybe String' significa que el valor puede existir (Just "08:30")
-- o no existir todavía (Nothing). Así modelamos horas no registradas.
data Estudiante = Estudiante
  { idEstudiante    :: String        -- Código único del estudiante
  , nombre          :: String        -- Nombre completo
  , horaEntrada     :: Maybe String  -- Hora de entrada: Just "HH:MM" o Nothing
  , horaSalida      :: Maybe String  -- Hora de salida:  Just "HH:MM" o Nothing
  } deriving (Show, Eq)
-- 'deriving Show' le dice a Haskell que sepa imprimir este tipo automáticamente.
-- 'deriving Eq'   le dice que sepa comparar dos Estudiantes con ==.

-- ================================================================
-- CONVERSIÓN ENTRE ESTUDIANTE Y LÍNEA DE TEXTO (CSV)
-- ================================================================

-- Convierte un Estudiante a una línea de texto separada por comas.
-- Ejemplo: Estudiante "1001" "Ana" (Just "08:30") Nothing
--       →  "1001,Ana,08:30,"
-- 'intercalate' une una lista de strings poniendo "," entre cada uno.
-- 'fromMaybe ""' convierte Nothing en "" y Just "08:30" en "08:30".
aLinea :: Estudiante -> String
aLinea e = intercalate ","
  [ idEstudiante e
  , nombre e
  , fromMaybe "" (horaEntrada e)
  , fromMaybe "" (horaSalida  e)
  ]

-- Convierte una línea de texto CSV a un Estudiante.
-- Retorna 'Maybe Estudiante' porque la línea puede estar malformada.
-- Si tiene exactamente 4 campos → Just Estudiante.
-- Si tiene otro número de campos → Nothing (la ignoramos).
desdeLinea :: String -> Maybe Estudiante
desdeLinea linea = case dividir ',' linea of
  [i, n, entrada, salida] -> Just $ Estudiante i n
    (if null entrada then Nothing else Just entrada)
    (if null salida  then Nothing else Just salida)
  _ -> Nothing

-- Función auxiliar: divide un String en una lista usando un carácter separador.
-- Ejemplo: dividir ',' "a,b,c"  →  ["a", "b", "c"]
-- Haskell no incluye esta función por defecto, así que la definimos nosotros.
dividir :: Char -> String -> [String]
dividir _ "" = [""]
dividir sep (c:cs)
  | c == sep  = "" : dividir sep cs           -- Encontramos separador: empezamos nuevo segmento
  | otherwise = let (h:t) = dividir sep cs    -- No es separador: agregamos el caracter al segmento actual
                in  (c:h) : t

-- ================================================================
-- HORA DEL SISTEMA
-- ================================================================

-- Obtiene la hora local actual del sistema operativo en formato "HH:MM".
-- 'getZonedTime' pide la hora al SO. 'formatTime' la convierte a texto.
-- El símbolo '<$>' aplica la función formatTime al resultado de getZonedTime.
ahora :: IO String
ahora = formatTime defaultTimeLocale "%H:%M" <$> getZonedTime

-- ================================================================
-- MANEJO DEL ARCHIVO University.txt
-- ================================================================

-- Lee University.txt y devuelve la lista de estudiantes.
-- Si el archivo no existe, devuelve lista vacía sin crashear.
-- 'catch' captura el error de tipo IOException si ocurre.
cargar :: IO [Estudiante]
cargar = catch leer manejarError
  where
    leer = do
      contenido <- readFile "University.txt"
      -- Procesamos el contenido línea por línea:
      -- 'lines'  → divide el texto en una lista de líneas
      -- 'filter' → elimina las líneas vacías
      -- 'map'    → intenta convertir cada línea a Estudiante
      -- la notación [e | Just e <- ...]  → se queda solo con los Just
      let lista = [e | Just e <- map desdeLinea $ filter (not . null) $ lines contenido]
      -- Forzamos evaluación completa antes de continuar.
      -- Haskell evalúa "de forma perezosa" (lazy), lo que significa
      -- que no procesa datos hasta que los necesita. Esto causaría
      -- que el archivo quede abierto cuando intentemos escribirlo.
      -- 'length lista `seq` return lista' fuerza que la lista se
      -- construya completamente antes de devolver el resultado.
      length lista `seq` return lista
    manejarError :: IOException -> IO [Estudiante]
    manejarError _ = putStrLn "[INFO] Archivo no encontrado, iniciando vacio." >> return []

-- Guarda la lista completa de estudiantes en University.txt.
-- Sobreescribe el archivo entero cada vez (estrategia de archivo plano).
guardar :: [Estudiante] -> IO ()
guardar lista = do
  writeFile "University.txt" (unlines $ map aLinea lista)
  putStrLn "[OK] Guardado en University.txt."

-- ================================================================
-- UTILIDADES
-- ================================================================

-- Indica si un estudiante está actualmente dentro de la universidad.
-- Condición: tiene hora de entrada registrada Y no tiene hora de salida.
estaAdentro :: Estudiante -> Bool
estaAdentro e = horaEntrada e /= Nothing && horaSalida e == Nothing

-- Reemplaza un estudiante en la lista por una versión actualizada.
-- Recorre toda la lista y sustituye el que tenga el mismo ID.
-- Esta es la forma funcional de "modificar": construir una lista NUEVA.
actualizar :: Estudiante -> [Estudiante] -> [Estudiante]
actualizar nuevo = map (\e -> if idEstudiante e == idEstudiante nuevo then nuevo else e)

-- Calcula los minutos totales de una hora "HH:MM".
-- Ejemplo: "09:45" → 585 minutos
aMinutos :: String -> Int
aMinutos t = case dividir ':' t of
  [h, m] -> read h * 60 + read m
  _      -> 0

-- Ajusta un texto a exactamente n caracteres (recorta o rellena con espacios).
-- Útil para alinear columnas en la tabla de listado.
columna :: Int -> String -> String
columna n texto = take n (texto ++ repeat ' ')

-- ================================================================
-- OPERACIONES DEL MENÚ
-- ================================================================
-- Patrón importante: las funciones que MODIFICAN la lista devuelven
-- IO [Estudiante] (la lista nueva). Las que solo CONSULTAN devuelven
-- IO () (solo hacen output, no cambian nada).

-- OPCIÓN 1: Registrar entrada de un estudiante
registrarEntrada :: [Estudiante] -> IO [Estudiante]
registrarEntrada lista = do
  putStr "ID del estudiante: " >> getLine >>= \i ->
    case find ((== i) . idEstudiante) lista of
      -- Caso: el estudiante ya está adentro, no hacemos nada
      Just e | estaAdentro e -> putStrLn "[!] Ya esta adentro." >> return lista
      -- Caso: el estudiante existe pero no está adentro (ya salió antes)
      Just e -> do
        t <- ahora
        -- Creamos una copia del estudiante con la nueva hora de entrada
        -- y sin hora de salida (la borramos con Nothing)
        let nueva = actualizar e { horaEntrada = Just t, horaSalida = Nothing } lista
        guardar nueva >> putStrLn ("[OK] Entrada de " ++ nombre e ++ " a las " ++ t) >> return nueva
      -- Caso: el estudiante no existe, lo creamos desde cero
      Nothing -> do
        putStr "Nombre: "; n <- getLine; t <- ahora
        let nueva = lista ++ [Estudiante i n (Just t) Nothing]
        guardar nueva >> putStrLn ("[OK] Entrada de " ++ n ++ " a las " ++ t) >> return nueva

-- OPCIÓN 2: Buscar un estudiante activo por ID
buscarEstudiante :: [Estudiante] -> IO ()
buscarEstudiante lista = do
  putStr "ID del estudiante: " >> getLine >>= \i ->
    -- 'find' busca el primer elemento que cumpla la condición
    case find (\e -> idEstudiante e == i && estaAdentro e) lista of
      Just e  -> putStrLn $ "\nID: "      ++ idEstudiante e
                          ++ "\nNombre: " ++ nombre e
                          ++ "\nEntro a: " ++ fromMaybe "-" (horaEntrada e)
      Nothing -> putStrLn "[!] No se encontro ningun estudiante activo con ese ID."

-- OPCIÓN 3: Registrar salida de un estudiante
registrarSalida :: [Estudiante] -> IO [Estudiante]
registrarSalida lista = do
  putStr "ID del estudiante: " >> getLine >>= \i ->
    case find (\e -> idEstudiante e == i && estaAdentro e) lista of
      Nothing -> putStrLn "[!] No se encontro ese estudiante activo." >> return lista
      Just e  -> do
        t <- ahora
        -- Calculamos cuánto tiempo estuvo en la universidad
        let diff = aMinutos t - aMinutos (fromMaybe "00:00" (horaEntrada e))
        let nueva = actualizar e { horaSalida = Just t } lista
        guardar nueva
        putStrLn $ "[OK] Salida de " ++ nombre e ++ " a las " ++ t
        putStrLn $ "     Tiempo: " ++ show (diff `div` 60) ++ "h " ++ show (diff `mod` 60) ++ "min"
        return nueva

-- OPCIÓN 4: Mostrar todos los estudiantes
listarEstudiantes :: [Estudiante] -> IO ()
listarEstudiantes [] = putStrLn "[INFO] No hay estudiantes registrados."
listarEstudiantes lista = do
  putStrLn "\nID        | Nombre               | Entrada  | Salida"
  putStrLn $ replicate 55 '-'
  -- 'mapM_' es como un forEach: ejecuta la acción para cada elemento
  mapM_ (\e -> putStrLn $
    columna 10 (idEstudiante e) ++ "| " ++
    columna 22 (nombre e)       ++ "| " ++
    columna 9  (fromMaybe "-" (horaEntrada e)) ++ "| " ++
    fromMaybe "-" (horaSalida e)) lista

-- ================================================================
-- MENÚ Y BUCLE PRINCIPAL
-- ================================================================

-- Imprime las opciones del menú en pantalla.
mostrarMenu :: IO ()
mostrarMenu = mapM_ putStrLn
  [ "\n=============================="
  , "  SISTEMA DE REGISTRO EAFIT  "
  , "=============================="
  , "1. Registrar Entrada (Check In)"
  , "2. Buscar Estudiante por ID"
  , "3. Registrar Salida (Check Out)"
  , "4. Listar Todos los Estudiantes"
  , "5. Salir"
  , "==============================" ]

-- Bucle principal del programa. Recibe la lista actual de estudiantes,
-- muestra el menú, lee la opción del usuario y llama la función correcta.
-- Después se llama a sí mismo (recursión) con la lista actualizada.
-- Cuando el usuario elige "5", la recursión termina y el programa cierra.
bucle :: [Estudiante] -> IO ()
bucle lista = do
  mostrarMenu >> putStr "Opcion: " >> getLine >>= \op -> putStrLn "" >> case op of
    "1" -> registrarEntrada  lista >>= bucle   -- >>= pasa el resultado (lista nueva) al siguiente bucle
    "2" -> buscarEstudiante  lista >>  bucle lista
    "3" -> registrarSalida   lista >>= bucle
    "4" -> listarEstudiantes lista >>  bucle lista
    "5" -> putStrLn "Hasta luego!"
    _   -> putStrLn "[!] Opcion invalida." >> bucle lista

-- Punto de entrada del programa.
-- 'main' es la función que Haskell ejecuta al iniciar.
main :: IO ()
main = do
  hSetBuffering stdout NoBuffering  -- Salida inmediata sin buffer
  hSetEncoding  stdout utf8         -- Evita errores de caracteres en Windows
  lista <- cargar
  putStrLn $ "Cargados: " ++ show (length lista) ++ " estudiante(s)."
  bucle lista
