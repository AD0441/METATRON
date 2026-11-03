# Evidencia de M1/S1 · 3 de noviembre de 2026

[Informe de resultados](../../M1-S1-RESULTS.md) · [plan](../../M1-S1.md).

Estos artefactos corresponden a la app instalada 2.3.0 build 7, en Apple M1/macOS 27.2. La fuente del producto no se modificó. No se incluye una copia del perfil, recientes del usuario, audio ni archivos personales.

| Archivo | Qué demuestra / límite |
| --- | --- |
| totals.json | Resumen final: diez casos acotados y 25 trabajos, con la separación de los 23 iniciales y los dos manuales. |
| manual-drag-and-menu.json | Positivo por arrastre verificado, negativo recibido y confirmación del usuario sobre la aparición del menú. No certifica accionar todos sus comandos. |
| manual-negative-drag.json | Traza del intento manual que recibió danado.png; separa la muestra dañada del posterior positivo. |
| fixtures.json | Manifiesto SHA-256 y tamaños de las 12 entradas sintéticas del ensayo. Las salidas conservadas en la carpeta temporal permiten repetir la comparación mientras esa carpeta exista. |
| verification.json | Verificación de fuentes, 19 recibos y 38 registros publicados; Unicode/OCR, audio, receta de imagen, rechazo previo y limpieza. No es una auditoría de red. |
| presentations.json | Seis conversiones JPG por clic, una por presentación. La paleta se ejecutó mediante búsqueda y Enter; la ruleta por coordenadas de su sector visible. No acredita todos los arrastres. |
| ui-jobs.json | 23 trabajos reales de la app, con entradas reducidas a nombres, estado y mensaje. Hay 19 éxitos, tres cancelaciones y un fallo provocado. |
| output-inspection.json | Lectura independiente por ImageIO/PDFKit; dimensiones, metadatos y texto del PDF generado. Las entradas de imagen eran 3200 × 2000 píxeles debido al backing Retina del generador; la receta genera 800 × 500. |
| closed-window.json | Proceso 2437 persistía sin ventanas visibles tras cerrar la ventana. |
| quit-active.json | Cero instancias/ventanas tras Salir mientras se transcribía y había un trabajo pendiente. |
| final-instance.json | Una instancia nueva de la copia instalada tras reiniciar; no confundir con el PID anterior a Salir. |
| host.json | Equipo y ruta de la instancia inicial. |
| fixture-generator.swift / .py | Generadores sintéticos sin código de automatización gráfica. No instalan motores, modelos ni voces. |

## Preparar otro corpus

Usar un directorio nuevo. Los hashes de PDF, ZIP/XLSX o síntesis pueden variar entre ejecuciones y sistemas; se verifica cada ejecución contra su propio manifiesto, no se promete reproducción binaria exacta.

```sh
M1_RUN=$(mktemp -d /private/tmp/metatron-m1-replay.XXXXXX)
mkdir -p "$M1_RUN/private-backup" "$M1_RUN/logs"
xcrun swift fixture-generator.swift "$M1_RUN"
python3 fixture-generator.py "$M1_RUN"
```

Ejecutar desde esta carpeta con las herramientas nativas disponibles. Para audio, el generador usa Paulina solo si ya está instalada; si falta no crea audio. Para convertir a texto hace falta además un idioma Apple Speech local disponible. No ejecutar speech-install como parte automática de la preparación.

Después, usar la copia instalada mediante la interfaz y seguir los diez casos del plan. Para la comprobación de preflight por CLI, ejecutar una receta de redimensionado sobre XLSX y comprobar salida 1 y destino inexistente. Para cancelación, observar tarea activa antes del clic; una tarea que ya terminó no sirve como evidencia.

Las capturas de interfaz se observaron en el chat mediante la herramienta de uso del ordenador. No se adjunta un PNG que no se haya exportado. Los respaldos privados del perfil y las salidas grandes permanecen fuera del repositorio.
