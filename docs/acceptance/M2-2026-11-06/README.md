# Evidencia de M2

- [Informe](../../M2-RESULTS.md)
- [Cargas y muestras de CLI](cli.json)
- [OCR repetido](ocr-recheck.json)
- [Reposo gráfico](gui-idle.json)
- [Regresión gráfica](gui-regression.json)
- [Procesos compartidos del sistema](speech-processes.json)

Para repetir la carga de CLI en un Mac con las muestras de [M1](../M1-S1-2026-11-03/README.md), usa Python 3.9 o posterior, la CLI del ZIP verificado y un directorio de salida nuevo. La prueba de audio requiere el recurso es-CL de Apple Speech ya instalado. El script solo usa copias de las muestras y no instala modelos.

```sh
python3 docs/acceptance/M2-2026-11-06/profile.py \
  /ruta/a/METATRON.app/Contents/MacOS/metatron-cli \
  /ruta/a/las/muestras/M1/input \
  /private/tmp/metatron-m2-repeticion
```

El script conserva cada salida en su carpeta y comprueba la cantidad de archivos, sus hashes y el recibo. `gui-idle.json` registra RSS en KiB y CPU acumulada en segundos, a intervalos de un segundo. Para repetir el reposo de la app, usa [sample-idle.py](sample-idle.py) con el PID de METATRON, `60` y un nombre de archivo para el JSON. `speech-processes.json` resume muestras por nombre de proceso desde el tramo de OCR hasta el final de la prueba de voz, separadas de la RSS de la CLI.
