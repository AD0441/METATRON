# METATRON · Resultados M1 / S1

**Fecha:** 3 de noviembre de 2026 · **Aplicación:** `/Applications/METATRON.app`, 2.3.0 build 7, firma ad hoc.
**Equipo observado:** Apple M1, macOS 27.2 (26B123).
**Alcance:** aceptación instalada del [plan M1/S1](M1-S1.md), sin cambiar fuentes ni recompilar la candidata.

## Resultado del lote

**Diez casos comprobados en el alcance de M1, con los límites indicados en cada fila.** Se completaron las verificaciones manuales de arrastre y aparición del menú superior. El lote de diagnóstico queda cerrado; no equivale a aceptación integral de 2.3 ni autoriza publicarla.

Se ejecutaron **25 trabajos desde la interfaz**: 20 completados, tres cancelaciones intencionales y dos errores de lectura del PNG dañado. La fase asistida por la herramienta produjo 23 trabajos; después hubo un intento manual sobre danado.png y otro positivo sobre IMAGEN-VALIDA.png. Esos trabajos no son 25 pruebas unitarias ni sustituyen la batería anterior de 128 pruebas, que no se reejecutó en este lote.

La verificación independiente comprobó **12 entradas originales con sus hashes intactos y la copia adicional para arrastre, 20 recibos y 40 registros publicados** (20 resultados más sus recibos). No quedaron directorios de staging propios de los trabajos. La receta inválida se rechazó desde la CLI instalada con salida 1 y sin crear su carpeta de salida.

## Casos y evidencia

| Caso | Resultado | Comprobación realizada y límite |
| --- | --- | --- |
| M1-01 · Inicio | Aprobado | Ruta instalada y firma verificadas. Cierre de ventana y tres aperturas desde Finder; instancia única observada. PID inicial 2437; siguió vivo sin ventanas tras cerrar. Después de salir y reiniciar se observó una única instancia nueva, PID 3221. No se interpreta un cambio de PID tras Salir como duplicación. |
| M1-02 · Presentaciones | Aprobado en alcance | Cubo, Burbujas, menú compacto, panel, paleta y ruleta completaron cada uno PNG a JPG con salidas y recibos distintos. Paleta: búsqueda «jpg» + Enter. Cubo: Tab cambió de categoría, Escape cerró y clic en hueco no ejecutó. El arrastre nativo del autor produjo IMAGEN-VALIDA-metatron.jpg de 3200 × 2000 y recibo verificado. No se ensayó arrastrar en cada uno de los otros cinco modos ni se volvió a medir alfa; la observación visual fue acotada. |
| M1-03 · Compatibilidad | Aprobado | TXT/XLSX/CSV no ofrecieron transcripción ni recetas específicas de audio. Audio sí ofreció TXT/Markdown y transcripción local. CSV + PNG conservó el mismo conjunto al invertir el orden; la conversión común a Markdown completó los dos archivos. El orden visual PDF/Markdown cambió: no cambió el conjunto ni se ofrecieron operaciones ajenas. |
| M1-04 · Conversiones | Aprobado, muestras acotadas | Imagen a JPG; XLSX a Markdown con Reunión/42/Año/2026; TXT a PDF con Unicode; PDF de dos páginas a Markdown en orden; PDF escaneado y PNG a Markdown mediante OCR. Resultados abiertos/inspeccionados con lectores y comprobaciones independientes. No certifica todos los formatos ni fidelidad de documentos complejos. |
| M1-05 · Receta válida | Aprobado | Importó JSON anterior sin nuevos campos, se editó el nombre, se exportó/reimportó y se ejecutó desde la ventana. Redimensionar a 800 → JPG → retirar metadatos produjo 800 × 500 sin EXIF/GPS; la entrada sí tenía GPS ficticio. Tras reiniciar, las recetas persistían. También se creó una receta nueva desde su botón. |
| M1-06 · Receta inválida | Aprobado | XLSX → redimensionar mostró el motivo y bloqueó los siguientes pasos. Retirar el paso permitió añadir Markdown; el selector no ofrecía transcripción ni redimensionado de imagen. La CLI instalada rechazó la receta inválida original antes de crear destino. |
| M1-07 · Audio local | Aprobado con recursos existentes | AIFF sintético a TXT desde el contexto y a Markdown mediante la receta de audio. Contenido esperado, es_CL y sin resumen. Se usó el idioma y la voz ya instalados; no se instaló ni descargó nada. No se simuló retirar el modelo del usuario ni se realizó una auditoría de tráfico de red. |
| M1-08 · Cancelación | Aprobado | Con audio largo activo y audio corto pendiente, el botón Cancelar trabajo dejó el largo cancelado y el corto terminó. Se observó progreso antes del clic. Fuentes con el mismo hash y trabajo cancelado sin salidas registradas. Una ejecución posterior independiente del mismo audio largo sí terminó; su salida no se atribuye a la cancelación anterior. |
| M1-09 · Error y colisión | Aprobado funcional con observación | PNG dañado falló con cero salidas y el PNG válido del mismo lote terminó. Repetir JPG generó nombres únicos, sin reemplazos. Diagnóstico del archivo dañado en inglés: D-M1-01. |
| M1-10 · Ciclo de vida | Aprobado en alcance | Cerrar dejó el mismo proceso sin ventanas visibles, política accessory y reapertura desde Finder. Salir con audio activo canceló también el pendiente y terminó sin parciales. El usuario confirmó: «Sí, el menú aparece correctamente», ante Abrir/Pausar/Ajustes/Salir. Esta comprobación manual acredita su aparición, no que se accionaran todos esos comandos desde el icono. La salida, Ajustes y recuperación se ensayaron por sus otras entradas. |

Las diez comprobaciones se cierran en el alcance registrado, combinando observación de la herramienta, verificación de archivos y la confirmación manual indicada. Los límites no ejecutados permanecen explícitos. Esto no promueve automáticamente los 29 requisitos completos ni acredita todas las combinaciones de controles, formatos o permisos.

## Hallazgos para M2

### D-M1-01 · Diagnóstico en inglés en interfaz española

- **Severidad:** media, claridad/localización; no se observó pérdida de datos.
- **Requisitos:** VIS-04 e INT-05; caso M1-09.
- **Reproducción:** seleccionar el PNG sintético dañado y otro válido; ejecutar JPG y revisar Actividad.
- **Observado:** `Couldn't read danado.png.` El válido termina y el fallido conserva cero salidas.
- **Esperado:** diagnóstico equivalente en español, con el nombre del archivo y sin ocultar la causa.
- **Siguiente acción:** corregir la localización de esa ruta y comprobar de forma dirigida el error y la continuidad de la cola. No se cambió código durante M1.

### O-M1-02 · Foco y Cerrar después del panel contextual

Durante una secuencia automatizada, ⌘W no cerró y Archivo → Cerrar aparecía deshabilitado. Tras abrir desde Finder reapareció el cierre nativo; su botón cerró correctamente y el proceso permaneció vivo. Algunas observaciones de accesibilidad y activación pueden alterar el foco o volver a mostrar una ventana; se contrastó el cierre con metadatos de proceso/ventanas sin reactivar la app.

**No se atribuye todavía un fallo de producto.** Repetir manualmente abrir Cubo → Escape → ⌘W, con foco real en la ventana, antes de decidir si necesita corrección. No es evidencia de que Salir falle: la salida durante trabajo activo se verificó por separado.

### O-M1-03 · Orden de acciones en selección mixta

CSV + PNG y PNG + CSV mostraron PDF/Markdown en orden distinto, pero conservaron el mismo conjunto. Cumple el criterio de compatibilidad de M1; puede evaluarse un orden estable como mejora posterior, sin tratarlo como conversión incompatible.

## Comprobación manual final

El primer aviso «No se puede procesar» correspondía a **danado.png**, no a la imagen válida: el registro de la app confirmó ese nombre y cero salidas. Es el diagnóstico esperado para la muestra negativa y no se registra como fallo del motor de arrastre.

Para separar ambos ensayos se abrió una carpeta con un único archivo, **IMAGEN-VALIDA.png**. El nuevo trabajo recibió ese archivo, terminó correctamente y sus dos registros publicados (JPG y recibo) se verificaron por tamaño y hash; ImageIO/sips identificó JPEG de 3200 × 2000. El usuario confirmó después la aparición del menú superior. [Eventos manuales y alcance](acceptance/M1-S1-2026-11-03/manual-drag-and-menu.json).

## Recursos y entorno

La consulta desde el entorno de comandos restringido devolvió inicialmente Metal/Speech no disponibles. La misma consulta con acceso nativo al Mac detectó Apple M1, Metal y es_CL instalado; la app ejecutó realmente OCR y transcripción. Esos falsos negativos del aislamiento no se registran como defectos de METATRON.

LibreOffice no estaba instalado; FFmpeg, Ghostscript y cwebp sí se detectaron. Las rutas elegidas de este lote fueron nativas. No se instalaron motores para obtener un resultado positivo. No se probaron firma Apple, Atajos, todas las paletas, todos los macOS ni recepción/transferencia entre equipos.

## Conservación y limpieza

- Corpus sintético aislado en `/private/tmp/metatron-m1-s1-20261103`; metadatos GPS son ficticios.
- Se respaldó el perfil antes y después, de forma privada, y se verificó que las recetas originales no cambiaron.
- Con la app cerrada se retiraron únicamente sus 23 trabajos sintéticos y cuatro recetas de ensayo, conservando sus evidencias. Se restauraron los recientes y las preferencias temporales del selector de archivos; se dejó Cubo, inicio en segundo plano y Dock oculto como estaban.
- Las copias completas del perfil y los recientes anteriores **no se incorporan al repositorio**. Los artefactos publicados contienen datos sintéticos y resultados acotados.
- Las dos ejecuciones manuales se preservaron por separado y también se retiraron del perfil al concluir. Se restauraron los recientes originales de nuevo. Los 25 trabajos quedan en las evidencias; los respaldos privados no se publican.

## Artefactos y siguiente paso

[Evidencias, manifiesto y generadores de muestras](acceptance/M1-S1-2026-11-03/README.md). Incluyen verificaciones de hashes/recibos, trabajos de interfaz sanitizados, metadatos de cierre/salida y generadores que no instalan recursos. Las observaciones de interfaz y capturas vistas durante la prueba están en el chat; no se anuncia un archivo PNG exportado si no se guardó.

M1 entrega un diagnóstico cerrado y acotado, sin fallos de integridad observados. Para M2: reproducir O-M1-02, corregir D-M1-01 y acordar una carga pequeña para medir tiempo/memoria. Los controles del menú no accionados y los otros límites indicados siguen sin acreditación específica. No se fusionaron PR, recompiló la app ni publicó una release en este lote.

**Creado por Sebastián Pastén F.**
