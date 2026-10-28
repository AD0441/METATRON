# Estabilización de METATRON 2.2.1

Candidato local de mantenimiento, build 5, revisado el 28 de octubre de 2026. La release pública 2.2.0 no se reemplaza con este trabajo. No se incorporan nuevos formatos ni modelos.

## Cancelación y errores

El ejecutor externo inicia un grupo POSIX por invocación. La cancelación y el tiempo límite envían TERM al grupo; tras 0,5 s se usa KILL si sigue pendiente. Se espera y recoge el estado del proceso propio; las tuberías y los temporizadores se cierran al terminar. stdout y stderr se consumen simultáneamente, con un máximo conservado de 1 MiB por flujo. Un ayudante que se independiza deliberadamente del grupo no queda bajo esa garantía.

Las pruebas ejecutan realmente un padre y un ayudante que ignoran TERM, cancelación antes del arranque, ejecutable inexistente, stderr de fallo, salida abundante y tiempo límite. La CLI gestiona Ctrl+C/SIGTERM mediante un callback Sendable: la prueba del ZIP detectó y permitió corregir un fallo de aislamiento de Swift en el primer intento.

El audio con afconvert usa el mismo ejecutor. AVFoundation recibe cancelExport y hay puntos de cancelación entre páginas y fotogramas. Algunas operaciones síncronas nativas, como decodificar una imagen o reconocer una página, terminan su unidad actual antes de devolver el control.

## Ciclo de vida y conservación

Salir completamente detiene las vigilancias y los accesos contextuales, cancela los trabajos activos y pendientes, espera su limpieza y persiste sus estados antes de responder a macOS. Cerrar la ventana mantiene el proceso en segundo plano. Cancelar el trabajo actual deja continuar la cola independiente. Cancelar una llamada de Atajos cancela solamente sus trabajos y espera las respuestas antes de borrar las entradas temporales.

Los errores de permisos o del archivo de bloqueo ya no se tratan como otra instancia. Si workspace.json es ilegible, se conserva y se copia a workspace-recovery-UUID.json antes del primer guardado. Si esa copia falla, no se sobrescribe el original. Se verifica también la recuperación de recetas y trabajos interrumpidos.

En el M1 se verificó una sola instancia, inicio sin Dock y sin ventanas normales, cierre de ventana conservando el PID y reapertura desde Finder con el mismo PID. Acerca de muestra 2.2.1 y el enlace de versiones propio. Una observación en segundo plano dio unos 53 MiB de RSS y 0,0 % CPU; es una muestra puntual, no un presupuesto ni una medición de todas las cargas.

## Conversiones y carpetas

La publicación conserva originales, evita colisiones tanto en archivos como en recibos y revierte las salidas creadas si falla antes de confirmar. Nuevas regresiones: imagen corrupta, destino que es un archivo, recibo con identificador repetido y cancelación al publicar. Las pruebas previas de imágenes, PDF, Markdown, tablas, OCR, integridad y deshacer continúan en la batería completa. LibreOffice usa un perfil exclusivo por trabajo para evitar conflictos entre app y CLI.

Una vigilancia mantiene todos sus estados en su cola serial. Parar invalida las comprobaciones pendientes; iniciar de nuevo toma los archivos actuales como base y no los repite. El tamaño y fecha deben permanecer iguales durante tres muestras, separadas un segundo. Esto detecta actividad reciente, pero no prueba que otro programa haya terminado para siempre de escribir: una copia que se pause más tiempo puede aparentar estabilidad. Temporales conocidos, directorios y enlaces simbólicos no se envían a conversión.

Se prueban copias por etapas, parada/reinicio y ráfagas de 25 archivos sin duplicados. Editar otra regla conserva los vigilantes que no cambiaron. Los tokens impiden aceptar callbacks de reglas retiradas. Se rechaza una salida que coincida con otra entrada vigilada, resolviendo alias simbólicos. La CLI rechaza entrada inexistente y salida igual a entrada.

## CI y paquete

- Batería local: 50 XCTest, una omitida por Ghostscript; 53 Swift Testing en 17 suites; cero fallos. Veinte pruebas nuevas respecto a 2.2.0.
- CI ejecuta todas las suites Core, Workflow y App, y compila con el mismo script de distribución.
- script/verify_package.sh extrae el ZIP fuera del Escritorio, verifica firma de app y CLI, arquitectura del host, versión/build, icono, licencia y los tres App Intents extraídos por Xcode.
- La CLI extraída convierte un CSV sintético a Markdown; se comparan contenido, original y hashes del recibo. Después se vigila una carpeta real, se convierte una llegada y se comprueba salida 130 tras Ctrl+C.
- Resources/Info.plist es la fuente de versión para Xcode y empaquetado. SHA256SUMS.txt se regenera. La copia intermedia de Xcode se retira de Launch Services para reducir proveedores duplicados; la copia dist se registra.

Comandos reproducibles:

```sh
./script/test.sh
./script/build_and_run.sh --build-only
./script/verify_package.sh dist/METATRON.zip
```

## Firma y Atajos: bloqueo externo pendiente

security find-identity no encuentra identidades válidas de firma en este Mac. El paquete se firma ad hoc; no tiene Team ID ni notarización. La verificación de metadatos no demuestra ejecución de Atajos. No se cambian las protecciones del sistema para eludir esa falta.

Con un certificado Apple instalado, el script admite METATRON_SIGN_IDENTITY y firma con hardened runtime y timestamp. Para exigir Team ID en la comprobación:

```sh
METATRON_SIGN_IDENTITY='Developer ID Application: NOMBRE (TEAMID)' METATRON_REQUIRE_TEAM_ID=1 ./script/build_and_run.sh --build-only
```

Después se debe validar Preparar archivos, Ejecutar receta y Abrir METATRON en Atajos, incluida la cancelación. La distribución notarizada exige además credenciales válidas de notarytool y verificar/staplear el resultado. Ese paso no se ha realizado.

## Comprobaciones aún pendientes

No se declara completada una prueba prolongada de suspensión/reanudación, volúmenes externos que se desconectan, batería o un corpus amplio de documentos reales. La fidelidad de tablas/OCR y modelos Docling conserva los límites de 2.2.0. El envío LAN no se ha modificado ni se presenta como cifrado. Estas pruebas y la firma Apple deben quedar documentadas antes de afirmar que la versión cubre esos escenarios.
