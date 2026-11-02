# METATRON — Especificación de requerimientos del producto

**Versión del documento:** 1.0 · **Corte:** 2 de noviembre de 2026.

**Producto:** METATRON · utilidad nativa de archivos y flujos reutilizables para macOS.

**Autor / identidad editorial:** Sebastián Pastén F.

**Base revisada:** candidato 2.3.0 build 7, commit `0f86ca829eb93a2b40796b01a5788d318d952c68`.

**Distribución pública al corte:** [2.2.0](https://github.com/AD0441/METATRON/releases/tag/v2.2.0). Las propuestas [#1 — estabilización](https://github.com/AD0441/METATRON/pull/1) y [#2 — versión 2.3](https://github.com/AD0441/METATRON/pull/2) siguen abiertas y sin integrar. La copia instalada revisada declara 2.3.0 build 7.

> **Propósito:** convertir, transformar, verificar y automatizar archivos locales con la misma sencillez para una operación aislada que para una receta completa.

## 0. Lectura, alcance y procedencia

Esta línea base consolida lo solicitado, lo mejorado y el trabajo pendiente. Adopta la estructura de la especificación y matriz de Naberius, consultadas localmente como referencia; no traslada sus requisitos de editor, restricciones de implementación ni decisiones tecnológicas a METATRON. La información funcional procede de nuestra conversación, del código y de los documentos del proyecto. No es una nueva auditoría exhaustiva ni una orden para implementar todas las propuestas.

- **P0:** comportamiento esencial o cierre crítico de 2.3; si ya está implementado, es una condición que se debe conservar.
- **P1:** siguiente ciclo o ampliación cuya aceptación sigue incompleta.
- **P2:** evolución posterior, evaluable después de estabilizar el producto.
- Los criterios de aceptación son verificaciones exigibles, no resultados ya obtenidos. Los estados actuales y las acciones están en [STATUS.md](STATUS.md) y en [REQUIREMENTS_REVIEW.csv](REQUIREMENTS_REVIEW.csv).
- **Implementado** acredita presencia funcional y evidencia acotada; no significa validación universal. **Parcial** identifica límites de alcance; **Por validar** exige completar aceptación; **Pendiente** indica trabajo no realizado; **Condicionado** depende de un recurso externo aplazado.
- Los requisitos nuevos de formalización, accesibilidad, medición y compatibilidad se identifican como propuestas; no se atribuyen retroactivamente al usuario. Las prioridades son una organización propuesta para revisión, salvo el orden de estabilización expresamente acordado.
- Los documentos históricos conservan su fecha. Sus conteos y omisiones no reemplazan el estado del candidato. Referencias de código y pruebas están en el registro de evidencia de STATUS.md.
- Esta tarea documental no fusiona ramas, publica una release, cambia la app instalada ni instala motores o modelos.

## 1. Decisiones consolidadas

| Código | Decisión vigente |
| --- | --- |
| D-01 | Nombre definitivo **METATRON**, símbolo original inspirado en el cubo geométrico, sin representación antropomórfica. |
| D-02 | Círculos del Cubo y Burbujas sobre el entorno y alrededor del archivo, sin ventana rectangular. Menú, panel y comandos conservan su presentación de lista. |
| D-03 | Seis presentaciones configurables y seis familias: Convertir, Herramientas, Acciones, Destinos, Recetas y Documentos. La petición inicial de una cuarta opción evolucionó a este alcance. |
| D-04 | Cinco paletas; dirección sobria de grafito y azul petróleo elegida por el usuario. |
| D-05 | Destinos predefinidos y ordenables, actividad con limpieza y retención de todo/7/14/30 días. |
| D-06 | Recetas encadenadas como principal diferenciación funcional, reutilizables desde contexto, app, carpetas y CLI. |
| D-07 | Procesamiento local, sin cuenta obligatoria. IA de Apple opcional según disponibilidad; no se afirma haber entrenado un modelo propio. |
| D-08 | Transcripción local de archivos a TXT/Markdown **sin resumen**, sin captura de micrófono y sin sustitución por reconocimiento remoto. |
| D-09 | Conservar originales y publicar resultados verificados; Mover y la preferencia explícita de Papelera son operaciones distintas. Audio a texto conserva siempre el audio. |
| D-10 | Mantener por ahora firma **ad hoc**. No insistir en Apple Developer; firma Apple/notarización y ejecución nativa de Atajos quedan condicionadas. |
| D-11 | Orden acordado: cancelación y errores → ciclo de vida → conversiones y carpetas → CI y empaquetado → firma y Atajos, estos últimos aplazados según D-10. |
| D-12 | Autoría «Creado por Sebastián Pastén F.» y Ko-fi discreto, solo abierto por interacción explícita. |
| D-13 | Autonomía técnica gradual, manteniendo la atribución MIT de Kumquat. Tangerine es referencia de comportamiento; no se distribuye su código propietario. |

## 2. Usuarios, escenarios y límites

- Uso cotidiano: convertir y ordenar uno o varios archivos desde Finder o el acceso contextual.
- Uso académico/profesional: obtener Markdown/OCR de documentos, revisar diferencias, preparar PDF y transcribir grabaciones autorizadas.
- Uso automatizado: reutilizar recetas desde carpetas vigiladas o scripts sin depender de Atajos.
- Equipo de referencia: Apple M1 con 8 GB. El núcleo anuncia macOS 14+; Apple Speech y Foundation Models requieren macOS 26+ y disponibilidad real. El mínimo anunciado debe verificarse en ejecución; compilar no demuestra esa compatibilidad.

Quedan fuera de la garantía actual la equivalencia universal con Tangerine, fidelidad perfecta de Office/PDF, detección exhaustiva de datos sensibles, separación de hablantes, detección automática de idioma, modelos propios entrenados, colaboración multiusuario, nube obligatoria, complementos arbitrarios y protocolo LocalSend completo. No se promete que macOS ejecute cada tarea en Neural Engine. El sistema de complementos sigue siendo una idea P2, sin arquitectura ni instalación aprobadas.

## 3. Requerimientos verificables por área

### OBJ · Objetivos y experiencia de uso

- **OBJ-01 [P0]** Convertir, transformar, verificar y organizar archivos desde un flujo contextual y una ventana de trabajo.
  - **Aceptación:** Completar una tarea representativa de cada familia desde la app instalada, sin recurrir a herramientas de desarrollo.
  - **Origen:** Visión acordada. **Introducción / alcance:** 2.0–2.3.
- **OBJ-02 [P0]** Resolver procesos de varios pasos con una sola receta reutilizable.
  - **Aceptación:** Guardar una secuencia, reabrirla y ejecutarla manteniendo orden y opciones.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **OBJ-03 [P0]** Priorizar funcionamiento local y uso sin cuenta, con recursos adecuados para M1 y 8 GB.
  - **Aceptación:** Completar las conversiones nativas sin conexión y registrar memoria, CPU y tiempos del lote de referencia.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.3.
- **OBJ-04 [P0]** Priorizar cancelación, ciclo de vida, conversiones y distribución antes de añadir capacidades.
  - **Aceptación:** Cada lote de cambios críticos conserva las pruebas y explicita límites de entrega.
  - **Origen:** Acuerdo de estabilización. **Introducción / alcance:** 2.2.1–2.3.

### CTX · Acceso contextual y compatibilidad

- **CTX-01 [P0]** Mantener seis presentaciones elegibles: ruleta clásica, Cubo de Metatrón, Burbujas, menú compacto, panel y comandos.
  - **Aceptación:** La elección persiste y cada presentación ejecuta la misma operación sobre una muestra compatible.
  - **Origen:** Solicitud expresa y elección posterior. **Introducción / alcance:** 2.0–2.2.
- **CTX-02 [P0]** Dibujar Cubo y Burbujas alrededor del archivo sin fondo ni marco rectangular.
  - **Aceptación:** Comprobar transparencia entre círculos y esquinas, con el icono del archivo en el centro.
  - **Origen:** Corrección expresa del usuario. **Introducción / alcance:** 2.1–2.2.
- **CTX-03 [P0]** Aceptar arrastres únicamente sobre objetivos visibles y permitir salir con Escape o clic fuera.
  - **Aceptación:** Los huecos entre círculos no ejecutan acciones; Escape y cambio de categoría responden correctamente.
  - **Origen:** Corrección expresa del usuario. **Introducción / alcance:** 2.1–2.2.
- **CTX-04 [P0]** Ocultar conversiones, herramientas y recetas incompatibles con los archivos seleccionados.
  - **Aceptación:** TXT, CSV y XLSX no muestran transcripción; los medios y documentos reciben acciones de su familia.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.3.
- **CTX-05 [P0]** Ofrecer en selecciones mixtas solo operaciones válidas para todos los archivos.
  - **Aceptación:** Invertir el orden de CSV/JSON u Office mixto conserva el conjunto permitido y excluye destinos incompatibles.
  - **Origen:** Solicitud expresa formalizada para lotes. **Introducción / alcance:** 2.3.
- **CTX-06 [P0]** Mantener el catálogo completo de cada familia en Ajustes, sin confundirlo con un lote real.
  - **Aceptación:** Ajustes conserva PNG, metadatos, unión PDF, XLSX, PPTX y PLIST cuando correspondan.
  - **Origen:** Corrección derivada del filtro. **Introducción / alcance:** 2.3.
- **CTX-07 [P0]** Conservar acceso, anclaje, foco y cierre de las presentaciones en distintas pantallas y escalas.
  - **Aceptación:** Probar bordes, dos pantallas, escala distinta, cambio de Space y ausencia de objetivos fuera del área visible.
  - **Origen:** Plan de aceptación propuesto. **Introducción / alcance:** 2.3.

### REC · Recetas encadenadas

- **REC-01 [P0]** Crear, editar, ordenar, guardar y eliminar pasos de una receta con opciones de salida.
  - **Aceptación:** Reabrir una receta de imagen con redimensionado, metadatos y conversión conservando su configuración.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **REC-02 [P0]** Importar y exportar recetas JSON sin perder orden ni opciones compatibles.
  - **Aceptación:** Una receta exportada e importada conserva opciones; JSON antiguo sin nuevos campos sigue cargando.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.3.
- **REC-03 [P0]** Validar cada paso contra el resultado previsto del paso anterior antes de crear salidas.
  - **Aceptación:** Imagen a PDF a extracción de texto es válida; PDF a TXT a extracción PDF se rechaza en el paso 2.
  - **Origen:** Solicitud expresa formalizada. **Introducción / alcance:** 2.3.
- **REC-04 [P0]** Filtrar los siguientes pasos del editor y respetar las restricciones de entrada de cada receta.
  - **Aceptación:** Después de crear PDF se ofrece extracción PDF y se oculta redimensionado; presets antiguos de audio excluyen Excel.
  - **Origen:** Solicitud expresa formalizada. **Introducción / alcance:** 2.3.
- **REC-05 [P0]** Simular propiedades, resolución, destinos y posibles pérdidas sin modificar archivos.
  - **Aceptación:** La simulación no escribe; identifica transparencia, metadatos y rutas orientativas sin prometer peso exacto.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2–2.3.
- **REC-06 [P1]** Asignar favoritos y atajos propios a recetas frecuentes con gestión de conflictos.
  - **Aceptación:** Ejecutar una receta elegida mediante su atajo y detectar combinaciones ya utilizadas.
  - **Origen:** Idea previamente propuesta. **Introducción / alcance:** Posterior.

### FMT · Conversiones esenciales

- **FMT-01 [P0]** Convertir y editar imágenes según lectores y escritores realmente disponibles.
  - **Aceptación:** Probar JPEG, PNG, HEIC, SVG y WebP; revisar dimensiones, alfa, orientación y metadatos.
  - **Origen:** Base heredada y mejoras acordadas. **Introducción / alcance:** 2.0–2.3.
- **FMT-02 [P0]** Unir, dividir, girar, proteger, comprimir y renderizar PDF con límites explícitos.
  - **Aceptación:** Verificar orden y cantidad de páginas, contraseña, texto y resolución antes y después.
  - **Origen:** Base heredada y ampliaciones acordadas. **Introducción / alcance:** 2.0–2.2.
- **FMT-03 [P0]** Convertir documentos de texto y formatos editables sin prometer fidelidad universal.
  - **Aceptación:** Comparar texto y estructura de DOCX, RTF, HTML, ODT y EPUB representativos; advertir pérdidas.
  - **Origen:** Solicitud de catálogo amplio. **Introducción / alcance:** 2.0–2.2.
- **FMT-04 [P0]** Leer y convertir CSV, TSV, XLSX, JSON y PLIST como datos estructurados.
  - **Aceptación:** Revisar Unicode, separadores, celdas y selección de hojas; no anunciar conservación completa de fórmulas y gráficos.
  - **Origen:** Solicitud de catálogo amplio. **Introducción / alcance:** 2.0–2.3.
- **FMT-05 [P0]** Convertir audio y vídeo, generar GIF y fotogramas y aplicar herramientas compatibles.
  - **Aceptación:** Comprobar duración, sonido y reproducción; probar rutas nativas y FFmpeg con códecs disponibles.
  - **Origen:** Base y ampliaciones acordadas. **Introducción / alcance:** 2.0–2.3.
- **FMT-06 [P0]** Convertir subtítulos y comprimir o extraer archivos con herramientas locales.
  - **Aceptación:** Verificar tiempos SRT/VTT y contenido de ZIP/TAR; errores de extracción no alteran el original.
  - **Origen:** Base y catálogo acordado. **Introducción / alcance:** 2.0–2.2.

### DOC · Procesamiento documental y Markdown

- **DOC-01 [P0]** Exportar Markdown desde fuentes compatibles, incluyendo tablas, PDF, OCR, documentos, subtítulos y audio.
  - **Aceptación:** Abrir el Markdown generado, comprobar UTF-8 y escapes y relacionarlo con el archivo de origen.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.3.
- **DOC-02 [P0]** Realizar OCR local de imágenes y PDF escaneados mediante APIs nativas.
  - **Aceptación:** Revisar texto español, números y páginas escaneadas; informar salida vacía o fallos de lectura.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **DOC-03 [P0]** Generar un paquete documental con Markdown, procedencia y recursos extraídos compatibles.
  - **Aceptación:** Revisar trazabilidad de páginas, vistas previas e imágenes raster; respetar 50 MB y 40 páginas del paso documental.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2.
- **DOC-04 [P0]** Combinar archivos convertibles de distintos tipos en un PDF final preservando los originales.
  - **Aceptación:** Combinar PDF, imagen y documento; comprobar orden y páginas; una entrada incompatible falla antes de publicar.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2.
- **DOC-05 [P1]** Reconocer mejor tablas, encabezados y orden de lectura con un motor documental opcional.
  - **Aceptación:** Medir exactitud estructural y recursos en M1; documentar instalación y procedencia del motor.
  - **Origen:** Solicitud expresa de procesamiento avanzado. **Introducción / alcance:** 2.2 y posterior.
- **DOC-06 [P1]** Comparar visualmente PDF y organizar páginas sin presentarlo como equivalencia semántica.
  - **Aceptación:** Detectar cambios en una página, exportar diferencias y rechazar órdenes de página inválidos.
  - **Origen:** Mejora ya incorporada. **Introducción / alcance:** 2.0–2.2.
- **DOC-07 [P1]** Producir copias PDF con términos retirados y exigir revisión de sus resultados.
  - **Aceptación:** El texto señalado no permanece recuperable en la copia rasterizada; el original se conserva.
  - **Origen:** Mejora ya incorporada. **Introducción / alcance:** 2.0–2.2.

### AUD · Audio a texto local, sin resumen

- **AUD-01 [P0]** Transcribir archivos de audio a TXT o Markdown mediante Apple Speech local.
  - **Aceptación:** Transcribir audio sintético es-CL y comprobar texto, recibo y original; nunca activar reconocimiento remoto alternativo.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.3.
- **AUD-02 [P0]** No generar resúmenes en el flujo de transcripción.
  - **Aceptación:** TXT contiene la transcripción; Markdown solo agrega título, idioma y aviso de revisión, sin un resumen del contenido.
  - **Origen:** Restricción expresa del usuario. **Introducción / alcance:** 2.3.
- **AUD-03 [P0]** Mostrar disponibilidad de hardware, sistema e idioma y descargar modelos solo por acción explícita.
  - **Aceptación:** En un equipo no compatible no se ofrece transcripción; un idioma ausente se explica sin descarga automática.
  - **Origen:** Solicitud y decisión de privacidad. **Introducción / alcance:** 2.3.
- **AUD-04 [P0]** Permitir progreso y cancelación, preservando siempre el audio original.
  - **Aceptación:** Cancelar una transcripción larga devuelve cancelación, mantiene el hash del audio y no publica resultados parciales.
  - **Origen:** Solicitud de estabilidad. **Introducción / alcance:** 2.3.
- **AUD-05 [P0]** Usar transcripción desde contexto, recetas, carpetas vigiladas y CLI con idioma configurable.
  - **Aceptación:** Ejecutar la misma receta por app y CLI; la carpeta ignora entradas no compatibles.
  - **Origen:** Alcance acordado. **Introducción / alcance:** 2.3.
- **AUD-06 [P1]** Medir calidad y recursos en grabaciones largas, ruidosas y con vocabulario específico.
  - **Aceptación:** Registrar duración, tiempo, memoria, errores y revisión humana; respetar 4 h y un millón de caracteres sin truncado silencioso.
  - **Origen:** Aceptación propuesta para una capacidad existente. **Introducción / alcance:** 2.3.

### ORG · Organización y destinos

- **ORG-01 [P0]** Definir, nombrar, ordenar y conservar destinos favoritos desde Ajustes.
  - **Aceptación:** Reabrir la app y encontrar los mismos destinos y orden, disponibles en acceso contextual y ventana.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **ORG-02 [P0]** Mover a un destino elegido resolviendo colisiones y permitiendo deshacer el último movimiento registrado.
  - **Aceptación:** Mover dos archivos de nombre repetido y deshacer sin reemplazar contenido ni tocar archivos ajenos.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **ORG-03 [P0]** Permitir elegir destino y sufijo de salida sin obligar a mover el original.
  - **Aceptación:** La salida queda en el destino elegido y se conserva el origen durante una receta.
  - **Origen:** Solicitud de orden y control. **Introducción / alcance:** 2.0–2.2.
- **ORG-04 [P1]** Renombrar por lotes con prefijos, fecha, contador y sustitución, con vista previa y reversión.
  - **Aceptación:** Previsualizar todos los nombres, resolver colisiones y revertir solo los cambios de la operación.
  - **Origen:** Idea previamente propuesta. **Introducción / alcance:** Posterior.
- **ORG-05 [P1]** Crear reglas de organización por extensión, nombre o fecha con simulación antes de mover.
  - **Aceptación:** Una regla propone movimientos revisables y registra su reversión sin actuar fuera de la carpeta autorizada.
  - **Origen:** Idea previamente propuesta. **Introducción / alcance:** Posterior.
- **ORG-06 [P1]** Integrar un inspector y Quick Look para revisar entradas y resultados sin cambiar de aplicación.
  - **Aceptación:** Previsualizar una fuente y su resultado, consultar propiedades básicas y cerrar sin alterar los archivos.
  - **Origen:** Idea previamente propuesta. **Introducción / alcance:** Posterior.

### HIS · Actividad e historial

- **HIS-01 [P0]** Buscar, filtrar y exportar la actividad con estados y tamaños de entrada y salida.
  - **Aceptación:** Un lote completado y uno fallido muestran estado correcto y se exportan a JSON.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **HIS-02 [P0]** Permitir borrar los registros de actividad sin borrar los archivos generados ni trabajos activos.
  - **Aceptación:** Limpiar registros y comprobar hashes de fuentes y salidas, conservando trabajos en cola o ejecutándose.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **HIS-03 [P0]** Aplicar retención de todo, 7, 14 o 30 días.
  - **Aceptación:** Probar registros antes, después y en el límite temporal; los trabajos activos permanecen.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **HIS-04 [P1]** Indexar localmente texto de documentos compatibles sin tratar binarios como texto crudo.
  - **Aceptación:** Indexar XLSX como tabla y rechazar audio, vídeo y comprimidos; buscar el contenido extraído.
  - **Origen:** Mejora ya incorporada. **Introducción / alcance:** 2.0–2.3.

### AUT · Automatización

- **AUT-01 [P0]** Vigilar nuevas entradas y ejecutar solo recetas compatibles tras comprobar estabilidad del archivo.
  - **Aceptación:** Copiar por etapas y añadir una ráfaga de 25 archivos sin duplicación; omitir entradas incompatibles.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2.1–2.3.
- **AUT-02 [P0]** Pausar o retirar reglas sin aceptar callbacks antiguos y prevenir ciclos entre entradas y salidas.
  - **Aceptación:** Parar, editar y reiniciar reglas; ningún callback retirado crea trabajos y no se aceptan destinos circulares.
  - **Origen:** Solicitud expresa de estabilidad. **Introducción / alcance:** 2.2.1.
- **AUT-03 [P0]** Distribuir una CLI para convertir, ejecutar recetas, vigilar, transcribir y cancelar con Ctrl+C.
  - **Aceptación:** Ejecutar la CLI extraída del ZIP, verificar recibo y finalizar vigilancia con salida 130.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2–2.3.
- **AUT-04 [P0]** Integrar selección de Finder, Abrir con y servicio contextual con diagnósticos de permisos.
  - **Aceptación:** Probar una instalación limpia con permisos concedidos y denegados y selecciones de varios tipos.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.3.
- **AUT-05 [P1]** Ejecutar las acciones App Intents desde Atajos cuando exista una identidad Apple válida.
  - **Aceptación:** Firmar con Team ID, ejecutar las tres acciones con archivos y comprobar resultado y cancelación.
  - **Origen:** Solicitud expresa; firma local elegida. **Introducción / alcance:** 2.2 y posterior.
- **AUT-06 [P2]** Evaluar un sistema de complementos con contratos versionados, capacidades declaradas y activación explícita.
  - **Aceptación:** Una extensión de prueba declara entradas, salidas, límites y errores; no elude la compatibilidad ni modifica originales fuera del plan.
  - **Origen:** Propuesta previa de evolución. **Introducción / alcance:** Posterior.

### INT · Integridad, errores y recuperación

- **INT-01 [P0]** Conservar originales durante recetas y exigir una preferencia explícita para cualquier envío posterior a Papelera.
  - **Aceptación:** Comparar hashes tras éxito, fallo y cancelación; en audio nunca se aplica la preferencia de Papelera.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.3.
- **INT-02 [P0]** Procesar en un área temporal y publicar solo resultados comprobados sin reemplazar archivos o recibos.
  - **Aceptación:** Forzar fallo antes de confirmar, colisión y recibo repetido; no quedan salidas parciales ni sobrescrituras.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.1.
- **INT-03 [P0]** Generar hashes y comprobantes que relacionen entradas y resultados.
  - **Aceptación:** Comprobar recibo contra archivos publicados y detectar cambios de contenido.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **INT-04 [P0]** Deshacer conversiones solo cuando sus resultados no hayan cambiado.
  - **Aceptación:** Modificar una salida y comprobar que la recuperación se niega sin afectar el resto ni borrar originales.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **INT-05 [P0]** Cancelar y limitar procesos con limpieza de ayudantes, salida acotada y errores comprensibles.
  - **Aceptación:** Cancelar padre y ayudante que ignoran TERM; comprobar tiempo límite, ejecutable ausente y grandes flujos simultáneos.
  - **Origen:** Prioridad expresa de estabilización. **Introducción / alcance:** 2.2.1–2.3.
- **INT-06 [P0]** Recuperar estado interrumpido y respaldar datos de actividad dañados antes de escribir de nuevo.
  - **Aceptación:** Abrir estado corrupto y conservar su copia; no sobrescribirlo si el respaldo falla.
  - **Origen:** Prioridad expresa de estabilización. **Introducción / alcance:** 2.2.1.

### LIF · Ciclo de vida y segundo plano

- **LIF-01 [P0]** Evitar instancias duplicadas y distinguirlas de errores de bloqueo o permisos.
  - **Aceptación:** Abrir varias veces conserva un único proceso funcional; un fallo de bloqueo muestra diagnóstico propio.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2–2.2.1.
- **LIF-02 [P0]** Cerrar la ventana sin terminar la aplicación ni perder la cola.
  - **Aceptación:** Cerrar, verificar trabajo/menú superior y reabrir con el mismo proceso.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2–2.2.1.
- **LIF-03 [P0]** Mantener un menú superior con abrir, pausar, Ajustes y salir completamente.
  - **Aceptación:** Accionar cada opción desde la barra de menús y observar su efecto real.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2.
- **LIF-04 [P0]** Permitir ocultar el Dock e iniciar en segundo plano conservando una vía de recuperación.
  - **Aceptación:** Iniciar sin Dock, abrir desde el menú superior y restaurar el icono sin duplicar procesos.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.2.
- **LIF-05 [P0]** Salir deteniendo vigilancias y esperando la limpieza de trabajos cancelados.
  - **Aceptación:** Salir con trabajos activos y pendientes; no quedan conversiones propias ejecutándose ni publicaciones parciales.
  - **Origen:** Prioridad expresa de estabilización. **Introducción / alcance:** 2.2.1.

### PRV · Privacidad y conexiones

- **PRV-01 [P0]** Mantener conversiones, OCR y transcripción en el equipo sin subir archivos a un servicio remoto.
  - **Aceptación:** Ejecutar rutas nativas con red deshabilitada y recursos locales preparados.
  - **Origen:** Decisión expresa. **Introducción / alcance:** 2.0–2.3.
- **PRV-02 [P0]** Activar descargas, actualizaciones consultadas, donaciones y compartición solo mediante acciones explícitas.
  - **Aceptación:** Al iniciar no se abre Ko-fi ni se descargan motores/modelos; los enlaces responden al gesto del usuario.
  - **Origen:** Decisión expresa. **Introducción / alcance:** 2.0–2.3.
- **PRV-03 [P0]** Verificar dinámicamente el funcionamiento offline y el alcance del almacenamiento local.
  - **Aceptación:** Registrar conexiones durante inicio y conversiones; revisar rutas, texto indexado y recibos con datos sintéticos.
  - **Origen:** Formalización propuesta de privacidad. **Introducción / alcance:** 2.3.
- **PRV-04 [P1]** Mantener compartición LAN explícita y temporal; añadir cifrado e interoperabilidad solo después de validarlos.
  - **Aceptación:** En el modo actual mostrar HTTP sin cifrar, detener/caducar el enlace y probar entre dos equipos antes de anunciarlo.
  - **Origen:** Idea previa y límite ya documentado. **Introducción / alcance:** 2.0 y posterior.

### IA · Inteligencia local opcional

- **IA-01 [P1]** Ofrecer sugerencias locales con Foundation Models solo cuando el sistema declare disponibilidad.
  - **Aceptación:** Sin modelo disponible la app conserva conversiones normales y muestra el motivo de indisponibilidad.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.2.
- **IA-02 [P0]** El asistente recibe solo lo escrito por el usuario y no ejecuta cambios de archivos por sí solo.
  - **Aceptación:** Pedir una sugerencia no inicia trabajos, no mueve archivos ni incorpora documentos implícitamente.
  - **Origen:** Control y privacidad acordados. **Introducción / alcance:** 2.0–2.2.
- **IA-03 [P2]** Recomendar recetas según el objetivo sin convertir las tareas normales en dependientes de un LLM.
  - **Aceptación:** Una sugerencia explica pasos y pérdidas; el usuario revisa el plan antes de ejecutar.
  - **Origen:** Propuesta previa de evolución. **Introducción / alcance:** Posterior.

### PER · Rendimiento en Apple Silicon

- **PER-01 [P0]** Acotar concurrencia y memoria y mantener conversiones fuera del actor de interfaz cuando corresponda.
  - **Aceptación:** Una sola tarea pesada de la cola y salidas de procesos acotadas; la ventana sigue aceptando cancelación.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0–2.3.
- **PER-02 [P0]** Elegir CPU, Core Image o Metal según mediciones reales, sin forzar GPU o prometer Neural Engine.
  - **Aceptación:** Comparar rutas equivalentes y justificar la elegida con equipo, parámetros y muestras.
  - **Origen:** Solicitud expresa de Metal/M1. **Introducción / alcance:** 2.0–2.2.
- **PER-03 [P0]** Medir la app instalada en M1 con 8 GB bajo reposo, lotes, PDF escaneados y audio largo.
  - **Aceptación:** Registrar p50/p95 de apertura contextual, tiempo, RSS, CPU y crecimiento tras 10 lotes y 30 min.
  - **Origen:** Plan acordado de estabilización. **Introducción / alcance:** 2.3.
- **PER-04 [P1]** Verificar la distribución por versión de macOS y arquitectura realmente soportadas.
  - **Aceptación:** Probar núcleo y UI en el mínimo anunciado y funciones Apple por disponibilidad; etiquetar las arquitecturas del ZIP real.
  - **Origen:** Formalización propuesta de compatibilidad. **Introducción / alcance:** 2.3.

### VIS · Identidad, apariencia y accesibilidad

- **VIS-01 [P0]** Usar METATRON y un símbolo geométrico original del cubo, sin figura antropomórfica.
  - **Aceptación:** Revisar icono en Finder, Dock, menú, ventana y recursos; no redistribuir la imagen de referencia.
  - **Origen:** Decisión expresa. **Introducción / alcance:** 2.0–2.2.
- **VIS-02 [P0]** Ofrecer cinco paletas elegibles, con grafito y azul petróleo como dirección predeterminada acordada.
  - **Aceptación:** Cambiar paleta, reabrir y comprobar claro/oscuro y legibilidad de los controles.
  - **Origen:** Decisión expresa. **Introducción / alcance:** 2.0–2.2.
- **VIS-03 [P0]** Permitir teclado, foco visible, nombres accesibles y adaptación a reducir movimiento.
  - **Aceptación:** Completar tareas críticas con teclado y VoiceOver, sin trampas de foco ni información solo por color.
  - **Origen:** Calidad propuesta para el cierre. **Introducción / alcance:** 2.3.
- **VIS-04 [P1]** Mantener español coherente y preparar localización de cadenas nuevas sin prometer traducción completa.
  - **Aceptación:** Revisar ventanas, errores, ayudas y menús; comprobar que no quedan claves o textos mezclados en el idioma elegido.
  - **Origen:** Interfaz existente y mejora propuesta. **Introducción / alcance:** 2.0 y posterior.
- **VIS-05 [P0]** Mostrar «Creado por Sebastián Pastén F.» y acceso discreto a Ko-fi en opciones y materiales.
  - **Aceptación:** Comprobar autoría y enlace https://ko-fi.com/C0C51WQ1T0; abrirlo solo por decisión explícita.
  - **Origen:** Solicitud expresa. **Introducción / alcance:** 2.0.

### DIST · Pruebas, instalación y publicación

- **DIST-01 [P0]** Generar y verificar app y CLI distribuidas con una fuente única de versión.
  - **Aceptación:** Extraer el ZIP y comprobar firma local, recursos, arquitectura, App Intents, hashes y conversión real.
  - **Origen:** Prioridad expresa de estabilización. **Introducción / alcance:** 2.2.1–2.3.
- **DIST-02 [P0]** Mantener CI del núcleo, flujos y aplicación, con paquete de candidato.
  - **Aceptación:** El commit candidato pasa todas las suites y el empaquetado remoto; registrar excepciones sin ocultarlas.
  - **Origen:** Prioridad expresa de estabilización. **Introducción / alcance:** 2.2.1–2.3.
- **DIST-03 [P0]** Verificar instalación, permisos y aceptación práctica de la copia en Aplicaciones.
  - **Aceptación:** Completar AC-01–AC-18 con datos sintéticos o autorizados y sin alterar preferencias o archivos ajenos.
  - **Origen:** Plan acordado antes de publicar. **Introducción / alcance:** 2.3.
- **DIST-04 [P0]** Integrar primero la estabilización y después 2.3, conservando la trazabilidad de ambas propuestas.
  - **Aceptación:** Revisar #1 y #2, integrar en orden y comprobar que main conserva pruebas y filtros.
  - **Origen:** Plan acordado de integración. **Introducción / alcance:** 2.3.
- **DIST-05 [P0]** Preparar release con ZIP, checksum, requisitos y límites reales, usando capturas de la versión entregada.
  - **Aceptación:** Versión, capturas y descripción coinciden con el binario; no se anuncia Atajos operativo con firma ad hoc.
  - **Origen:** Solicitud previa de una nueva entrega tras validación. **Introducción / alcance:** 2.3.
- **DIST-06 [P0]** Mantener requisitos, matriz, pruebas, privacidad y límites sincronizados sin reescribir evidencia histórica.
  - **Aceptación:** Cada requisito tiene prioridad, estado, criterio y próxima acción; documentos históricos conservan fecha y alcance.
  - **Origen:** Consolidación solicitada ahora. **Introducción / alcance:** 2.3.

### OWN · Autonomía técnica y procedencia

- **OWN-01 [P0]** Conservar atribución MIT de Kumquat y excluir código propietario o binarios de Tangerine.
  - **Aceptación:** Licencia y procedencia identifican la base; el repositorio distribuido no incluye materiales privados de investigación.
  - **Origen:** Consulta expresa sobre Kumquat y Tangerine. **Introducción / alcance:** 2.0.
- **OWN-02 [P1]** Separar gradualmente motor, catálogo, persistencia y UI mediante interfaces y pruebas de contrato propias.
  - **Aceptación:** Inventariar módulos heredados y sustituir uno por lote conservando fixtures, contratos y regresiones.
  - **Origen:** Consulta expresa sobre autonomía. **Introducción / alcance:** Posterior.
- **OWN-03 [P1]** Definir el producto por flujos verificables e identidad propia, sin atribuir exclusividad a funciones comunes.
  - **Aceptación:** La comparativa distingue heredado, propio y no confirmado, y cada afirmación corresponde a evidencia fechada.
  - **Origen:** Consulta expresa sobre diferenciación. **Introducción / alcance:** 2.0 y posterior.

## 4. Criterios medibles de calidad propuestos

Estos objetivos son **provisionales y pendientes de medición**, no garantías ni resultados alcanzados. AC-16 debe confirmarlos o proponer un ajuste documentado con evidencia.

| Escenario en M1/8 GB | Objetivo inicial | Método y límite |
| --- | --- | --- |
| Mostrar acciones de hasta 50 archivos conocidos | p95 ≤ 200 ms, motores ya detectados | Al menos 30 aperturas; separar detección fría de motores de la ruta caliente. |
| Reposo tras finalizar la cola | CPU media ≤ 1 % y RSS propio ≤ 200 MiB durante 60 s | Declarar procesos auxiliares y recursos del modelo por separado; no incluir una conversión activa como reposo. |
| 10 lotes repetidos y 30 min de uso | Sin crecimiento monotónico de memoria después del enfriamiento | Registrar muestras y revisar retenciones; no deducir fuga por una única medición. |
| Cancelación de proceso externo propio | Recolección del proceso y su grupo ≤ 2 s en el fixture controlado | No extenderlo a ayudantes que se independicen ni a una unidad nativa síncrona ya iniciada. |
| Fallo antes de confirmar publicación | Cero originales modificados y cero salidas parciales publicadas | Hashes antes/después y manifiesto del directorio; capturar recibos y estado final. |

Los microbenchmarks existentes no reemplazan estas medidas. El ensayo de imagen registra CPU ~1,11 ms frente a Metal ~29,93 ms para la operación indicada; el PDF largo pasó de ~524 MB a ~117 MB de RSS, pero cambió de resolución por el límite de lienzo. No son comparaciones equivalentes contra otras aplicaciones ni medidas globales de 2.3.

## 5. Arquitectura actual y reglas de evolución

- **MetatronCore:** catálogo, lectores/conversores nativos, motores externos, Vision y Apple Speech.
- **MetatronWorkflow:** recetas, compatibilidad, simulación, verificación, publicación, recuperación, documentos y perfiles de hardware.
- **App SwiftUI/AppKit:** espacio de trabajo, panel contextual, ajustes, menú superior y automatización por cola.
- **CLI y App Intents:** entradas al motor; la CLI está distribuida y probada. Metadatos App Intents no equivalen a ejecución validada de Atajos.
- Fuente única de versión en Resources/Info.plist; scripts compartidos de pruebas, generación Xcode, compilación y verificación del paquete.
- Los módulos heredados se revisan gradualmente; no se prescribe una reescritura completa. Retirar o reemplazar código no permite borrar la atribución requerida del código derivado.
- Motores documentales, códecs y modelos se preparan por separado. Evaluar licencia, tamaño, mantenimiento y consumo antes de añadir dependencias; Metal o un LLM no son requisitos para una conversión que funciona mejor de otra forma.

## 6. Orden de trabajo y puertas de salida

| Fase | Qué incluye | Condición para cerrar |
| --- | --- | --- |
| A — Cierre práctico de 2.3 | Seis presentaciones, filtros por archivo, permisos, conversiones, recetas, audio, carpetas, cancelación y ciclo de vida | AC-01–AC-14 con resultados registrados; fallos críticos P0 corregidos. Los casos no ejecutados siguen pendientes. |
| B — Calidad de la entrega | Offline, accesibilidad, perfil M1 y matriz de sistemas/arquitecturas | AC-15–AC-17 y PER-04 con alcances explícitos; objetivos incumplidos se corrigen o se reduce el alcance antes de prometerlos. |
| C — Integración y distribución | Revisar #1, integrar estabilización, revisar #2, integrar 2.3 y reconstruir | AC-18 y CI correctos sobre el commit integrado, no solo sobre las ramas. Nueva release requiere instrucción de publicación. |
| D — Productividad posterior | Reglas de organización, renombrado, Quick Look/inspector y atajos por receta | Lotes P1 separados, con vista previa, compatibilidad y reversión. Quick Look/inspector permanece propuesta de IDEAS.md. |
| E — Documentos y semántica | Evaluación de Docling, tablas complejas y sugerencias por objetivo | Corpus, licencias, instalación explícita y presupuesto de recursos; sin resumir transcripciones. |
| F — Ecosistema opcional | Firma Apple, Atajos ejecutables, LAN cifrada y eventual sistema de complementos | Recursos y alcance acordados por separado. No bloquear la distribución local por la firma aplazada. |

Las pruebas automáticas previas siguen siendo necesarias, pero no acreditan por sí solas que todas las paletas, pantallas, formatos reales y flujos de permisos hayan pasado aceptación. Los P0 de accesibilidad y compatibilidad no se declaran completados por tener capturas o compilar.

## 7. Pruebas de aceptación críticas

**Estado de este plan:** especificado, no ejecutado íntegramente durante esta consolidación. Hay evidencia anterior para partes de estos escenarios; debe citarse con su fecha. AC-19 es condicionado y AC-20 es una regla de secuenciación, no bloqueos de la distribución ad hoc.

| Caso | Escenario | Requisitos | Procedimiento y resultado esperado |
| --- | --- | --- | --- |
| AC-01 | Instalación y arranque | DIST-03,LIF-01 | Copiar el paquete final a Aplicaciones, verificar versión/firma y abrirlo tres veces. Debe existir un solo proceso y una vía clara para mostrar la ventana. |
| AC-02 | Seis presentaciones | CTX-01,CTX-02,CTX-03 | Ejecutar una conversión desde cada modo con datos sintéticos. Cubo/Burbujas son transparentes; huecos no activan; Escape, Tab y cambio de familia funcionan. |
| AC-03 | Pantallas y contraste | CTX-07,VIS-02 | Probar centro y bordes de pantalla, escalas y segunda pantalla si está disponible; repetir claro/oscuro. Registrar como no ejecutado cualquier entorno ausente. |
| AC-04 | Finder y permisos | AUT-04 | Probar selección, Abrir con y servicio con permisos concedidos y denegados; un rechazo debe explicar cómo continuar sin crear tareas vacías. |
| AC-05 | Matriz contextual | CTX-04,CTX-05,CTX-06 | Seleccionar TXT, XLSX, CSV, imagen, PDF, audio y lotes mixtos. No hay transcripción en documentos; Ajustes conserva las capacidades configurables de la familia. |
| AC-06 | Recetas y compatibilidad | REC-01,REC-02,REC-03,REC-04 | Guardar/importar una receta anterior; comprobar pasos filtrados. Cadena válida se ejecuta; una incompatible falla antes de crear staging o salida. |
| AC-07 | Conversiones esenciales | FMT-01,FMT-02,FMT-03,FMT-04,FMT-05,FMT-06 | Usar corpus con manifest de formatos, hashes, motores y propiedades esperadas. Revisar contenido, orden, dimensiones, duración y pérdidas; registrar cada combinación. |
| AC-08 | Documentos y Markdown | DOC-01,DOC-02,DOC-03,DOC-04 | Exportar imagen, PDF escaneado, tabla y documento; combinar entradas en PDF. Revisar encabezados, tablas, texto, recursos y procedencia, con límites explícitos. |
| AC-09 | Audio local sin resumen | AUD-01,AUD-02,AUD-03,AUD-05 | Con modelo ya instalado, transcribir muestra es-CL y muestra inglesa autorizada a TXT/Markdown. Comprobar ausencia de resumen y comportamiento sin idioma o hardware compatible, sin descargar nada implícitamente. |
| AC-10 | Cancelación y cola | INT-05,AUD-04 | Cancelar audio y un motor externo con ayudante. No se publican parciales; el original conserva hash y los trabajos independientes continúan. |
| AC-11 | Errores y recuperación | INT-02,INT-03,INT-06 | Probar fuente dañada, destino sin permiso, destino ocupado y estado corrupto en un perfil separado. Debe haber diagnóstico, respaldo y ninguna sobrescritura ajena. |
| AC-12 | Movimientos e historial | ORG-01,ORG-02,HIS-01,HIS-02,HIS-03,INT-04 | Mover y deshacer con colisión; limpiar actividad y aplicar cada retención con fechas sintéticas. Los archivos y trabajos activos permanecen; salida modificada impide deshacer. |
| AC-13 | Carpetas y CLI | AUT-01,AUT-02,AUT-03 | Copiar por etapas, añadir 25 entradas y una incompatible, pausar y editar reglas. Debe procesarse cada válida una vez; rechazar ciclos y terminar vigilancia con Ctrl+C. |
| AC-14 | Segundo plano y salida | LIF-01,LIF-02,LIF-03,LIF-04,LIF-05 | Cerrar ventana, ocultar Dock, reabrir y salir con trabajo activo. Cerrar conserva proceso; Salir cancela y limpia antes de terminar. |
| AC-15 | Privacidad offline | PRV-01,PRV-02,PRV-03,IA-02 | Con modelos locales preparados, ejecutar sin red; observar conexiones por separado al iniciar y convertir. El asistente no lee archivos implícitamente ni ejecuta acciones. No se abre Ko-fi automáticamente. |
| AC-16 | Perfil M1/8 GB | PER-01,PER-02,PER-03,AUD-06 | Usar corpus y build fijos, tres repeticiones, arranque frío/caliente, 10 lotes y 30 min. Medir UI, RSS propio y ayudantes, CPU, tiempos y cancelación; separar costes del modelo del sistema. |
| AC-17 | Accesibilidad y localización | VIS-03,VIS-04 | Completar selección, conversión, cancelación y reapertura por teclado/VoiceOver; revisar foco, etiquetas, contraste, reducir movimiento y cadenas visibles. |
| AC-18 | Paquete final y publicación | DIST-01,DIST-02,DIST-04,DIST-05 | Tras integrar las ramas, pasar CI y probar el ZIP extraído. Comparar versión, arquitectura, checksum, icono, CLI y capturas. Publicar solo con instrucción del usuario. |
| AC-19 | Atajos condicionado | AUT-05 | Solo si se dispone después de identidad Apple: firmar con Team ID y ejecutar las tres acciones. Hasta entonces conservar el límite en UI y documentación, sin marcarlo como aprobado. |
| AC-20 | Ampliaciones posteriores | ORG-04,ORG-05,ORG-06,REC-06,IA-03,AUT-06 | No comenzar renombrado, reglas avanzadas, inspector, planificación semántica o complementos por confundir esta hoja de ruta con una implementación. Definir y probar sus criterios en lotes separados. |

Para cada ejecución registrar: fecha, commit/build y ruta de la app, macOS/hardware, motores y modelo/idioma, fixture y hashes, resultado esperado/observado, pasos, evidencia y defecto asociado. No usar documentos ni audios personales sin autorización. No publicar rutas personales, audio o texto del usuario dentro de los comprobantes de prueba.

## 8. Documentos y mantenimiento

- [STATUS.md](STATUS.md): evaluación actual, mejoras, próxima acción y registro de evidencia por código.
- [REQUIREMENTS_REVIEW.csv](REQUIREMENTS_REVIEW.csv): la misma matriz en UTF-8 con BOM y delimitador punto y coma, importable en una planilla.
- [FEATURES.md](FEATURES.md), [AUDIO-TRANSCRIPTION.md](AUDIO-TRANSCRIPTION.md), [STABILITY-2.2.1.md](STABILITY-2.2.1.md), [COMPARISON.md](COMPARISON.md) y [CHANGELOG.md](../CHANGELOG.md): alcance detallado e historial; una fecha anterior no se convierte en validación nueva.
- Actualizar estado y evidencia al implementar o probar; no renumerar requisitos usados. Si se divide uno, conservar referencia y motivo.
- Este documento usa Naberius como patrón documental y no modifica ese proyecto. Las propuestas aquí identificadas no suponen adoptar sus dependencias ni copiar instrucciones de proceso ajenas.

**Creado por Sebastián Pastén F.**
