# Cierre de METATRON 2.3.1 · 25 de noviembre de 2026

Apple M1, 8 GiB, macOS 27.3. Build 10 release arm64. El usuario confirmó ejecución, cambio de categoría y Escape en Ruleta, Cubo, Burbujas, Menú, Panel y Comandos. No se instaló LibreOffice ni se descargaron modelos.

## Ensayo gráfico prolongado

Se copió el bundle release con un identificador distinto y se firmó localmente para aislar preferencias. La sección de instrucciones __text del ejecutable coincide por SHA-256 con la del bundle release, pese al identificador y firma distintos (binary-identity.json). La app usó `--data-dir` y cuatro carpetas vigiladas vacías fuera del perfil del usuario. El cierre normal de la app instalada liberó su bloqueo de instancia; al terminar se comprueba el perfil original y se restaura la copia instalada.

Se publicaron diez lotes separados 150 s durante una ventana de 1.800 s: cinco PNG 6400×4000, un DOCX sintético de varias páginas, un PDF escaneado y un WAV sintético en español por lote. El lienzo de 3200×2000 puntos se rasterizó a 2× en Retina: la dimensión real verificada fue 6400×4000 píxeles. Es una carga mayor que las imágenes de M2; los tiempos no son una comparación directa. La cola común de la app procesó las entradas; la muestra no sustituye una interacción manual de arrastre para cada archivo.

`sample.c` usa `proc_pid_rusage` para obtener RSS, huella física y CPU del proceso propio cada dos segundos. La huella física incluye memoria comprimida cargada al proceso y ayuda a interpretar la RSS en un M1 de 8 GiB. Los servicios compartidos de Vision/Speech/WebKit no se suman como si fueran memoria exclusiva de METATRON.

Los resultados numéricos y sus muestras quedan en `gui-results.json`. Cada salida y cada original se verifica por SHA-256; los recibos crudos y el perfil con rutas temporales permanecen fuera del repositorio.


## Resultados finales

- Ventana de ejecución: 1.800 s; intervalo entre primera y última muestra: 1.798,05 s (muestreo de 2 s).
- 10 lotes, 80 trabajos completados y 160 archivos publicados verificados. SHA-256 de todos los originales conservado. El perfil real del usuario conservó su hash; la app de prueba se cerró y desregistró, y sus preferencias se retiraron.
- Últimos 60 s: RSS mediana 14.91 MiB, huella física mediana 132.02 MiB, CPU media 0.0535 % de un núcleo.
- Pico muestreado: RSS 654.33 MiB y huella 737.08 MiB. Máximo de huella del proceso informado por el sistema: 810.64 MiB; incluye el estrés de aperturas superpuestas. No es consumo constante de una conversión normal.
- La huella mediana bajó de 148.83 MiB en el primer tramo de enfriamiento a 132.02 MiB en el tramo final. No se observó crecimiento sostenido en ese tramo de reposo; no es una certificación de ausencia de fugas en todas las cargas.
- Cero observaciones de sockets IP del proceso gráfico en el muestreo de lsof.
- Batería local final: 50 XCTest y 87 Swift Testing, sin fallos ni omisiones. El caso nuevo verifica que omitir el comprobante no elimina un resultado cuyo formato es JSON.

Los tiempos de CPU de proc_pid_rusage se normalizaron con mach_timebase_info (125/3 en este M1). La calibración se contrastó con el tiempo acumulado de ps; los contadores crudos no se interpretan como nanosegundos directamente. sample.c incorpora esta normalización para repetir el ensayo.

## Apertura contextual

La medición usa el registro `context-timing`: entrada en RingController hasta ordenar la ventana y revelar el modelo. No mide entrega de eventos de Launch Services, compositor ni píxeles en pantalla.

Con 50 PNG y motores detectados, 30 aperturas secuenciales, esperando el evento de finalización y dejando un segundo de asentamiento, dieron mediana **86,12 ms**, p95 **122,41 ms** y máximo **126,74 ms**. La primera solicitud de esa secuencia fue 98,10 ms. Se cumplió el objetivo provisional de p95 ≤ 200 ms para este extremo de medición.

Se conserva también el ensayo inicial de 31 solicitudes superpuestas: la primera tardó 210,68 ms y hubo callbacks demorados más de 30 s mientras AppKit procesaba renderizado acumulado. No se descartó como dato favorable ni se incluyó en la distribución secuencial. La respuesta a ráfagas intensivas sigue como límite conocido; la muestra no acredita un arranque frío completo del Mac.

## Prueba con red denegada

La CLI distribuida se ejecutó con `sandbox-exec`, política allow-default y deny-network. Un servidor HTTP de control en loopback respondió fuera de la restricción; la misma solicitud fue rechazada dentro. Las conversiones de PNG, CSV, PDF de texto y WAV a texto se completaron usando recursos locales.

Office no pudo ejecutarse dentro de ese sandbox: `qlmanage` devuelve «sandbox initialization failed: Operation not permitted». El mismo fallo aparece con una política exterior allow-default, por lo que no se considera una conversión fallida de la app ni una prueba offline aprobada para Office. Las conversiones Office sin sandbox anidado sí se ejecutaron en el ensayo gráfico. No se desactivó la red del usuario ni se cambió su configuración de seguridad.

Durante la carga se consultaron los sockets del proceso gráfico con lsof; nettop no mostró conexiones para ese proceso en la consulta realizada. Este alcance no es una auditoría de todos los servicios compartidos ni de motores externos.

## Reproducción

Los scripts reciben rutas y PID explícitos. Se necesitan los fixtures sintéticos `imagen.png`, `form.docx`, `escaneado.pdf`, `voz.wav`, `tabla.csv` y `texto.pdf` dentro de ROOT/input; el manifiesto identifica los usados. Los generadores M1 están en la carpeta de aceptación del 3 de noviembre. Los datos personales del formulario Word original no se publican.

1. Copiar la app release a ROOT/METATRON-Validation.app; usar un identificador único, firma local y preferencias separadas con cuatro reglas: images→JPG, office→PDF, ocr→Markdown y audio→transcripción. Destino fijo ROOT/output, originales conservados y comprobante activado.
2. Cerrar la instancia normal cuando esté inactiva y abrir el bundle de prueba con `--data-dir ROOT/profile`. Guardar su PID en ROOT/app-pid.
3. Compilar `sample.c` con clang en ROOT/sample; ejecutar `profile_gui.py ROOT PID 1800`. Publica las entradas, toma muestras y verifica 80 trabajos y sus hashes.
4. `context_sequential.py ROOT` requiere 50 imágenes en ROOT/context-files y registra 31 solicitudes separadas. Los logs originales quedan locales.
5. `offline.py ROOT /ruta/metatron-cli` comprueba la restricción y distingue el caso Office no ejecutable. Revisar estados, no solo el código final del script.
6. Cerrar normalmente la app de prueba, desregistrar/eliminar su bundle y preferencias temporales, comprobar el perfil real y abrir la app instalada.

VoiceOver integral, varias pantallas/escalas, ejecución macOS 14–25, audio real difícil y primera preparación de OCR tras un reinicio controlado conservan sus pendientes. El cierre de esta release no los presenta como pruebas aprobadas.
