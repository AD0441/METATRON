# METATRON · M2, fallos y recursos

6 de noviembre de 2026, America/Santiago. Candidata release arm64 **2.3.0 build 8**, Apple M1 con 8 GiB, macOS 27.2 (26B123). Carga de referencia con archivos sintéticos de [M1](M1-S1-RESULTS.md).

## Fallos y pruebas dirigidas

| Hallazgo | Resultado |
| --- | --- |
| D-M1-01 · Error del PNG dañado | Corregido. Actividad usa el mismo mensaje traducido que el aviso de conversión. En la candidata, `00-danado.png` mostró «No se pudo leer 00-danado.png.» y publicó cero archivos. El siguiente trabajo convirtió `01-valido.png` a JPEG de 3200 × 2000. Se verificaron la salida, su recibo y los hashes de ambos originales. |
| O-M1-02 · ⌘W después del Cubo | Escape ocultó el Cubo. El intento automatizado de ⌘W dejó la ventana principal visible, con el proceso inactivo antes y después del atajo. Finder logró activar el proceso brevemente, pero la observación registró pérdida de foco antes de ⌘W. En la prueba manual, Sebastián confirmó que ⌘K → Escape → ⌘W sí cerró la ventana. No se reprodujo el fallo con la interacción manual. |
| O-M1-03 · Orden en selecciones mixtas | El conjunto de acciones ya había coincidido en M1. El orden queda como mejora posterior. |

`script/test.sh --filter WorkspaceStabilityTests` pasó **6 pruebas**, incluida la regresión que convierte el PNG válido tras el fallo, recarga el historial y comprueba el diagnóstico persistido. Los otros cinco casos del mismo grupo cubren cancelación, apagado y persistencia. Las 128 pruebas del candidato anterior quedan en su registro histórico.

El ZIP pasó la verificación de paquete, firma ad hoc estricta, tres metadatos de App Intents y las pruebas de conversión y vigilancia con la CLI incluida. La prueba visual usó una extracción verificada del ZIP y un espacio de trabajo temporal. El historial real conservó su hash. Finder añadió metadatos extendidos a la copia expandida bajo `dist`, que se rechazó al verificar su firma. El ZIP y la extracción independiente pasaron.

## Carga de referencia y mediciones

Tres ejecuciones secuenciales por operación con la CLI release del ZIP, cada una con su propio directorio de salida. El tiempo de pared incluye iniciar el proceso, convertir, verificar y publicar. La RSS máxima por ejecución se obtuvo con `/usr/bin/time -l`; la columna muestra el mayor valor de las tres. Las cachés del sistema no se reiniciaron.

| Operación | Tiempos, en segundos | Mediana | RSS pico propia |
| --- | ---: | ---: | ---: |
| Cinco PNG de 3200 × 2000 → JPG, calidad 0,85 | 1,64 · 2,64 · 1,36 | 1,64 s | 167,0 MiB |
| PDF de dos páginas con capa de texto → Markdown | 0,274 · 0,146 · 0,145 | 0,146 s | 26,9 MiB |
| PDF escaneado de una página → Markdown con OCR | 63,37 · 0,582 · 0,327 | 0,582 s | 106,2 MiB |
| WAV de 28 min 25 s → TXT con Apple Speech es-CL | 27,38 · 27,72 · 23,73 | 27,38 s | 23,6 MiB |

El primer OCR tardó 63,37 s y produjo el mismo Markdown que los siguientes. Tras el reposo, otras tres ejecuciones con la misma entrada tardaron 1,071 · 0,352 · 0,351 s. Se conserva la primera muestra. El registro local consultado no identificó la causa. Para confirmar si es una demora de inicio, repetir tras un arranque frío controlado.

Se verificaron **24 salidas y 12 recibos** en la carga principal, más tres salidas y tres recibos en la repetición de OCR. Los hashes de las entradas de la carga principal permanecieron idénticos. El Markdown conservó las páginas de texto y el OCR leyó el texto sintético de la muestra. La transcripción produjo texto local sin resumen. En el muestreo separado durante Speech, `localspeechrecognition` alcanzó **181,0 MiB de RSS**. Es un proceso compartido de macOS y su RSS no se suma a la de la CLI para inferir memoria exclusiva.

Con la candidata gráfica abierta e inactiva, al terminar la cola, **61 muestras durante 60 s** registraron **0,58 % de CPU media** y **55,8 MiB de RSS máxima** (mediana 22,7 MiB). La CPU se calculó por diferencia de tiempo acumulado del proceso. Esta muestra cumple los objetivos provisionales de reposo para el escenario observado.

## Alcance pendiente

PER-03 y AC-16 quedan parciales. Esta pasada separó la CLI bajo carga de la app gráfica en reposo. Faltan la latencia p50/p95 de apertura contextual con 50 archivos y la memoria de la app gráfica tras diez lotes y 30 minutos de uso. Queda por contrastar la primera ejecución del OCR en frío. El candidato se preparó con firma local para M3.

[Datos y reproducción](acceptance/M2-2026-11-06/README.md).
