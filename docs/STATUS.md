# METATRON · Estado de requisitos de 2.3.1

**Actualización:** 25 de noviembre de 2026. **Entrega:** 2.3.1 build 10, Apple Silicon. [Especificación](REQUIREMENTS.md) · [CSV](REQUIREMENTS_REVIEW.csv) · [Notas y límites](RELEASE-2.3.1.md).

La línea base anterior se conserva en [STATUS-2026-11-06.md](STATUS-2026-11-06.md) y REQUIREMENTS_REVIEW-2026-11-06.csv. Los informes M1/M2 y las notas de M3 conservan la fecha y alcance de su ejecución; sus referencias a PR abiertos o builds instaladas no describen el estado actual.

## Estado de la entrega

- #1 se integró antes de #2 el 9 de noviembre; main tuvo CI correcto. El cierre posterior se reúne en [PR #3](https://github.com/AD0441/METATRON/pull/3).
- Destino global, JSON opcional, Office a PDF y tratamiento visual del Cubo están implementados en 2.3.1. Los nuevos requisitos ORG-07 e INT-07 se incluyen aquí.
- La confirmación manual del usuario cubre conversión, cambio de categoría y Escape en los seis accesos. Los 49 renders propios cubren apariencia; no sustituyen VoiceOver ni otras pantallas.
- La firma sigue siendo local ad hoc. Firma Apple, notarización y ejecución de Atajos continúan aplazadas por decisión del usuario.
- La matriz distingue implementación, pruebas parciales y ampliaciones. «Implementado» acredita capacidad y evidencia acotada; no es certificación universal ni porcentaje de producto terminado.

## Resumen

90 requisitos: 72 P0, 16 P1, 2 P2.

| Estado | Cantidad |
| --- | ---: |
| Implementado | 54 |
| Parcial | 28 |
| Por validar | 1 |
| Pendiente | 6 |
| Condicionado | 1 |

## Matriz vigente

La fecha de revisión por requisito queda en el CSV. Las filas no modificadas conservan su evidencia anterior; no se presentan como ensayos nuevos.

### Objetivos y experiencia de uso

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| OBJ-01 | P0 | Parcial | Ventana, cola y herramientas propias además del acceso contextual. **Siguiente:** Completar la aceptación práctica de 2.3. | E01, E02, E15 |
| OBJ-02 | P0 | Implementado | El motor ejecuta procesos completos en vez de una sola conversión. **Siguiente:** Conservar las regresiones al incorporar nuevos pasos. | E02 |
| OBJ-03 | P0 | Parcial | Núcleo nativo, trabajo acotado y módulos de IA opcionales. **Siguiente:** Completar el ensayo offline y el perfil sostenido. | E10, E12, E13 |
| OBJ-04 | P0 | Implementado | La estabilización y la ampliación de audio están separadas en PR consecutivos. **Siguiente:** Cerrar la aceptación pendiente antes de integrar y publicar. | E09, E15, E16 |

### Acceso contextual y compatibilidad

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| CTX-01 | P0 | Implementado | Seis modos confirmados manualmente en 2.3.1; renders claro/oscuro revisados. **Siguiente:** Mantener regresiones y verificar nuevas presentaciones cuando cambien. | E01, E11, E15, E18, E20 |
| CTX-02 | P0 | Implementado | Cubo y Burbujas conservan superficies circulares independientes; estructura del Cubo reforzada en 2.3.1. **Siguiente:** Conservar transparencia y comprobar fondos/escalas adicionales en un lote posterior. | E01, E11, E18, E20 |
| CTX-03 | P0 | Implementado | Usuario confirmó ejecución, cambio de categoría y Escape en los seis modos de la copia instalada. **Siguiente:** Conservar pruebas de geometría; VoiceOver y pantallas adicionales siguen en su alcance propio. | E01, E11, E18, E20 |
| CTX-04 | P0 | Implementado | Catálogo compartido por presentaciones, espacio de trabajo y ejecución. **Siguiente:** Ampliar muestras cuando se añadan formatos o lectores. | E03, E04, E18 |
| CTX-05 | P0 | Implementado | Intersección por archivo, incluyendo subtipo Office y motores disponibles. **Siguiente:** Añadir casos por códec o contenedor al ampliar el catálogo. | E03, E18 |
| CTX-06 | P0 | Implementado | Ajustes usa la unión de capacidades; la selección real usa su intersección. **Siguiente:** Conservar pruebas del catálogo al cambiar los filtros. | E03 |
| CTX-07 | P0 | Parcial | Comprobación manual de los seis accesos y 49 renders propios; falta matriz física de pantallas y escalas. **Siguiente:** Completar segunda pantalla, otros Spaces y escalas; no presentar los renders como esa prueba. | E01, E11, E15, E20 |

### Recetas encadenadas

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| REC-01 | P0 | Implementado | Secuencias reutilizables con calidad, sufijo, destino y metadatos. **Siguiente:** Revisar la edición práctica con recetas largas. | E02, E18 |
| REC-02 | P0 | Implementado | Campos opcionales de idioma y restricciones de entrada con compatibilidad anterior. **Siguiente:** Versionar el esquema si futuros cambios dejan de ser aditivos. | E02, E03, E04, E18 |
| REC-03 | P0 | Implementado | Comprobación previa centralizada para app, simulación, recetas y CLI. **Siguiente:** Conservar el rechazo previo a escritura con nuevos pasos. | E03, E18 |
| REC-04 | P0 | Implementado | El editor proyecta los tipos y admite restricciones exportables. **Siguiente:** Revisar claridad de mensajes al corregir una receta inválida. | E03, E04, E18 |
| REC-05 | P0 | Parcial | Datos previos y advertencias, con tamaños reales posteriores en Actividad. **Siguiente:** Completar estimaciones por cadena y documentar pasos de múltiples salidas. | E02, E03 |
| REC-06 | P1 | Pendiente | Ya hay acceso contextual a recetas; falta asignación individual completa. **Siguiente:** Diseñar después del cierre de 2.3. | E14 |

### Conversiones esenciales

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| FMT-01 | P0 | Parcial | OCR, anotaciones, filtros por ImageIO y reconocimiento del lector SVG propio. **Siguiente:** Completar matriz de pérdidas y muestras reales de cámaras. | E03, E05, E18 |
| FMT-02 | P0 | Parcial | Herramientas adicionales y límite de lienzo para imagen larga. **Siguiente:** Revisar PDF complejos, escaneados, bloqueados y con páginas rotadas. | E05, E06, E12, E18 |
| FMT-03 | P0 | Parcial | Office a PDF conserva logo, colores y A4 del formulario reproducido; DOCX multipágina verifica texto y tamaño. **Siguiente:** Ampliar corpus de fuentes, campos y encabezados complejos; no prometer fidelidad universal. | E05, E06, E09, E18, E20 |
| FMT-04 | P0 | Parcial | Markdown tabular e indexación de Excel mediante lector estructurado. **Siguiente:** Validar planillas reales complejas y explicar alcance tabular. | E03, E05, E06, E18 |
| FMT-05 | P0 | Parcial | Recorte/unión de vídeo y normalización/mono opcionales. **Siguiente:** Cerrar matriz de contenedores y codificadores con muestras diversas. | E05, E13 |
| FMT-06 | P0 | Parcial | Formatos adicionales mediante herramientas del sistema. **Siguiente:** Probar archivos dañados y variantes de libarchive; revisar límites de extracción. | E05 |

### Procesamiento documental y Markdown

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| DOC-01 | P0 | Implementado | Markdown integrado en catálogo, recetas y CLI; audio se añade en 2.3. **Siguiente:** Revisar muestras complejas sin prometer reconstrucción perfecta. | E04, E05, E06, E18 |
| DOC-02 | P0 | Parcial | Vision se integra en extracción y paquetes documentales. **Siguiente:** Medir exactitud y latencia en un corpus acordado. | E05, E06 |
| DOC-03 | P0 | Parcial | Paquetes estructurados nativos con procedencia y adaptadores opcionales. **Siguiente:** Revisar extracción de recursos y límites en documentos reales. | E06 |
| DOC-04 | P0 | Implementado | Paso bundlePDF y validación de compatibilidad por entrada. **Siguiente:** Ampliar fixtures con documentos editables de más de una página. | E03, E06 |
| DOC-05 | P1 | Parcial | OCR por filas y adaptadores MarkItDown/Docling; Docling no está validado con modelos aquí. **Siguiente:** Validar Docling solo en un lote posterior con instalación explícita. | E06, E14 |
| DOC-06 | P1 | Parcial | Comparador raster y operaciones de organización de páginas. **Siguiente:** Comprobar tolerancias y documentos con rotaciones o tamaños mixtos. | E06 |
| DOC-07 | P1 | Parcial | Retirada por texto y OCR, sin afirmar detección exhaustiva de datos sensibles. **Siguiente:** Normalizar páginas rotadas y validar visualmente cada caso de aceptación. | E06 |

### Audio a texto local, sin resumen

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| AUD-01 | P0 | Implementado | SpeechAnalyzer/SpeechTranscriber, formatos, herramienta y dos recetas. **Siguiente:** Repetir con audio real autorizado en español e inglés. | E04, E18 |
| AUD-02 | P0 | Implementado | Se eliminó la propuesta de resumir; esta ruta no utiliza un LLM. **Siguiente:** Mantener esta restricción al ampliar exportaciones. | E04, E18 |
| AUD-03 | P0 | Implementado | Ajustes de idioma, consulta de activos y comando speech-install explícito. **Siguiente:** Probar el mensaje de idioma ausente sin iniciar descarga. | E03, E04, E18 |
| AUD-04 | P0 | Implementado | Cancelación del analizador y protección del audio aun con preferencia de Papelera. **Siguiente:** Ampliar pruebas con contenedores y duraciones diferentes. | E04, E09, E18 |
| AUD-05 | P0 | Implementado | Idioma global o por receta/CLI, compatible con JSON anterior. **Siguiente:** Completar ensayo práctico de receta vigilada con audio autorizado. | E03, E04, E08, E18 |
| AUD-06 | P1 | Por validar | Hay límites explícitos y una prueba sintética; no una evaluación de exactitud general. **Siguiente:** Preparar corpus autorizado y resultados reproducibles; no prometer diarización ni idioma automático. | E04, E12 |

### Organización y destinos

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| ORG-01 | P0 | Implementado | Página de destinos y barra de favoritos. **Siguiente:** Probar destino retirado, movido o sin permisos. | E07, E15 |
| ORG-02 | P0 | Implementado | Transacción de movimiento y recuperación por hash. **Siguiente:** Ampliar ensayo a otro volumen y destinos no disponibles. | E07 |
| ORG-03 | P0 | Implementado | Guardado común conectado al motor de recetas; carpeta explícita de receta tiene prioridad. **Siguiente:** Conservar los casos de colisiones, destinos inválidos y originales intactos. | E02, E09, E20 |
| ORG-04 | P1 | Pendiente | No confundir el sufijo de una conversión con un renombrador general. **Siguiente:** Diseñar y probar después de estabilizar 2.3. | E14 |
| ORG-05 | P1 | Pendiente | Las carpetas vigiladas procesan recetas; no son todavía un organizador condicional completo. **Siguiente:** Definir precedencia, exclusiones y prevención de ciclos. | E08, E14 |
| ORG-06 | P1 | Pendiente | Hay simulación y propiedades parciales; no un inspector completo de comparación con Quick Look. **Siguiente:** Diseñar acceso y compatibilidad después del cierre de 2.3. | E14 |
| ORG-07 | P0 | Implementado | Conectado al flujo común y probado en OutputPreferenceTests. **Siguiente:** Mantener regresiones al cambiar destinos o publicación. | E20 |

### Actividad e historial

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| HIS-01 | P0 | Implementado | Historial consultable con metadatos de cada ejecución. **Siguiente:** Revisar mensajes y filtros con lotes grandes. | E02, E07 |
| HIS-02 | P0 | Implementado | Limpieza de actividad separada de eliminación de archivos. **Siguiente:** Confirmar en interfaz que retirar el registro elimina su acceso a deshacer. | E07 |
| HIS-03 | P0 | Implementado | Política explícita de retención, persistida en Ajustes. **Siguiente:** Mantener regresiones de fechas y estados. | E07 |
| HIS-04 | P1 | Parcial | Índice local y corrección del lector Excel en 2.3. **Siguiente:** Completar corpus y advertencias sobre contenido y rutas guardados localmente. | E03, E06, E13 |

### Automatización

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| AUT-01 | P0 | Implementado | Tres muestras de tamaño/fecha y filtro de tipos antes de encolar. **Siguiente:** Documentar que una pausa larga de copia puede aparentar estabilidad. | E03, E08 |
| AUT-02 | P0 | Implementado | Tokens de generación y preservación de vigilantes que no cambiaron. **Siguiente:** Mantener pruebas de eventos tardíos y alias simbólicos. | E08, E09 |
| AUT-03 | P0 | Implementado | Automatización desde scripts sin necesitar Atajos. **Siguiente:** Verificar ayuda y ejemplos con cada cambio de comandos. | E04, E08, E16 |
| AUT-04 | P0 | Parcial | Arrastre confirmado en M1; los seis accesos se confirmaron en 2.3.1. La ruta Abrir con se usa en la medición contextual. **Siguiente:** Completar servicio Finder con permisos denegados y recuperación de permisos. | E01, E10, E15, E20 |
| AUT-05 | P1 | Condicionado | Metadatos y acciones visibles; ejecución bloqueada en la distribución ad hoc. **Siguiente:** Aplazar firma Apple y prueba nativa según la decisión del usuario; no bloquear la entrega local por ello. | E08, E10, E16 |
| AUT-06 | P2 | Pendiente | Motores configurables y CLI ya permiten extensión acotada; no existe un sistema general de complementos. **Siguiente:** Evaluar mantenimiento, aislamiento y licencias antes de elegir arquitectura o distribuir complementos. | E08, E14, E17 |

### Integridad, errores y recuperación

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| INT-01 | P0 | Parcial | Recetas no modifican originales y transcripción añade una protección específica. **Siguiente:** Revisar coherencia entre rutas heredadas directas y motor de recetas. | E02, E04, E09, E18 |
| INT-02 | P0 | Implementado | Publicación verificada, nombres únicos y reversión de resultados propios. **Siguiente:** Conservar pruebas de fallos parciales con nuevas salidas múltiples. | E02, E09, E18 |
| INT-03 | P0 | Implementado | Hashes y Actividad se conservan; el comprobante JSON adicional ahora es opcional. **Siguiente:** Explicar rutas locales antes de compartir comprobantes o índices. | E02, E09, E18, E20 |
| INT-04 | P0 | Implementado | Recuperación condicionada a integridad, distinta de una reversión universal. **Siguiente:** Documentar ubicación y limpieza de archivos de recuperación. | E02, E07 |
| INT-05 | P0 | Implementado | Ejecutor POSIX por grupo; TERM y KILL posterior, drenaje de tuberías y cancelación nativa. **Siguiente:** Explicar que una unidad síncrona nativa termina antes de devolver control. | E09, E04, E18 |
| INT-06 | P0 | Implementado | Recuperación de recetas y trabajos sin ocultar errores de almacenamiento. **Siguiente:** Probar también poco espacio y permisos revocados en la aceptación práctica. | E09 |
| INT-07 | P0 | Implementado | Conectado al flujo común y probado en OutputPreferenceTests. **Siguiente:** Mantener regresiones al cambiar destinos o publicación. | E20 |

### Ciclo de vida y segundo plano

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| LIF-01 | P0 | Implementado | Bloqueo de instancia con recuperación de ventana existente. **Siguiente:** Repetir apertura desde Finder y Aplicaciones con la versión final. | E10, E18 |
| LIF-02 | P0 | Implementado | Ciclo de vida desacoplado de la ventana principal. **Siguiente:** Repetir durante una conversión y tras despertar el Mac. | E10, E18 |
| LIF-03 | P0 | Implementado | Control permanente de la app en segundo plano. **Siguiente:** Completar prueba visual de la copia instalada 2.3. | E10, E15, E18 |
| LIF-04 | P0 | Implementado | Preferencias de inicio y política accessory. **Siguiente:** Revisar que no se acumulan proveedores de pruebas en Launch Services. | E10, E16, E18 |
| LIF-05 | P0 | Implementado | Terminación diferida hasta cancelar y drenar la cola. **Siguiente:** Repetir con audio y un motor externo en la app instalada. | E09, E10, E18 |

### Privacidad y conexiones

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| PRV-01 | P0 | Implementado | Núcleo local; ninguna sustitución remota de Apple Speech. **Siguiente:** La auditoría dinámica de tráfico se registra aparte en PRV-03. | E04, E05, E13 |
| PRV-02 | P0 | Implementado | Motores separados y botón/comando explícito para idiomas. **Siguiente:** Revisar redirecciones y mensajes de instalación al publicar. | E04, E13 |
| PRV-03 | P0 | Parcial | CLI con red denegada y control negativo para imagen, tabla, PDF de texto y voz; observación del proceso gráfico. **Siguiente:** Office no admite el sandbox anidado de esta prueba; ampliar auditoría de servicios compartidos sin afirmar certificación total. | E13, E20 |
| PRV-04 | P1 | Parcial | Hay enlace temporal local; no implementa todavía LocalSend ni TLS. **Siguiente:** Validar modo existente y evaluar envío/recepción cifrados en un lote posterior. | E13, E14 |

### Inteligencia local opcional

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| IA-01 | P1 | Parcial | Asistente opcional; no se entrenó un modelo propio. **Siguiente:** Validar estados de disponibilidad y explicar requisitos en pantalla. | E13 |
| IA-02 | P0 | Implementado | Separación entre sugerencia semántica y motor determinista. **Siguiente:** Mantener esa separación al ampliar recomendaciones. | E13 |
| IA-03 | P2 | Pendiente | Los objetivos actuales son recetas explícitas, no planificación autónoma por IA. **Siguiente:** Definir evaluación de calidad y consumo antes de integrar automatismos semánticos. | E13, E14 |

### Rendimiento en Apple Silicon

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| PER-01 | P0 | Implementado | Cola serial, trabajo concurrente separado y límites de imágenes/documentos/audio. **Siguiente:** Medir el comportamiento sostenido; este diseño no demuestra por sí solo fluidez integral. | E09, E12 |
| PER-02 | P0 | Implementado | El redimensionado simple mantuvo CPU tras superar a Metal en el ensayo local. **Siguiente:** Repetir si cambian algoritmo, resolución o hardware. | E12 |
| PER-03 | P0 | Parcial | Build 10: 30 minutos, 10 lotes/80 trabajos, memoria/CPU en reposo y 30 aperturas con 50 archivos; p95 de preparación 122,41 ms. **Siguiente:** Optimizar ráfagas de aperturas y repetir OCR tras reinicio controlado. El renderizado en pantalla no forma parte del extremo medido. | E12, E19, E21 |
| PER-04 | P1 | Parcial | Paquete arm64 verificado; macOS 26 en CI y 27.3 en M1. Binario declara mínimo 14. **Siguiente:** macOS 14–25 se documenta como compatibilidad experimental, sin aceptación de ejecución todavía. | E04, E16, E20 |

### Identidad, apariencia y accesibilidad

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| VIS-01 | P0 | Implementado | Identidad METATRON y Cubo con propuesta 2: estructura primaria más legible, trama secundaria tenue. **Siguiente:** Mantener activos y revisar versiones pequeñas al modificar el símbolo. | E11, E20 |
| VIS-02 | P0 | Implementado | Paletas existentes conservadas; 49 renders en claro/oscuro y tamaños de control revisados. **Siguiente:** Completar mediciones de contraste en todas las combinaciones de paleta y fondos reales. | E11, E15, E20 |
| VIS-03 | P0 | Parcial | Teclado y Escape confirmados por el usuario en seis modos; nombres accesibles presentes. **Siguiente:** Completar auditoría VoiceOver, foco y ajustes de accesibilidad en todos los flujos. | E01, E11, E15, E20 |
| VIS-04 | P1 | Parcial | El error del PNG se guarda traducido en Actividad desde la build 8. **Siguiente:** Completar la localización de las demás pantallas y diagnósticos. | E11, E18, E19 |
| VIS-05 | P0 | Implementado | Identidad editorial y donación integradas sin bloquear funciones. **Siguiente:** Mantener coherencia en README, app y release. | E11, E13 |

### Pruebas, instalación y publicación

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| DIST-01 | P0 | Implementado | Script común de compilación/verificación; corregido fallo release del optimizador Swift 6.3. **Siguiente:** Repetir sobre el commit integrado final. | E16 |
| DIST-02 | P0 | Implementado | 128 pruebas locales previas y CI del candidato correcto; Speech respeta disponibilidad del equipo. **Siguiente:** Reejecutar CI tras integrar las ramas. | E16, E03, E04 |
| DIST-03 | P0 | Parcial | M1 cerró diez casos acotados, con verificación de arrastre y confirmación manual de aparición del menú; ver límites del informe. **Siguiente:** Continuar con M2 y sus defectos/mediciones; completar después la aceptación general de permisos y compatibilidad. | E10, E15, E16, E18 |
| DIST-04 | P0 | Implementado | PR #1 integrado antes de #2 el 9 de noviembre; main tuvo CI correcto. **Siguiente:** Integrar PR #3 de cierre con cabeza verificada y repetir CI del commit integrado. | E16, E20 |
| DIST-05 | P0 | Implementado | Paquete 2.3.1 build 10 verificado, con notas, requisitos, renders identificados y preparación de ZIP/checksum para la entrega. **Siguiente:** Conservar y comprobar los assets publicados de 2.3.1; mantener límites de firma y Atajos. | E20, E21, E22 |
| DIST-06 | P0 | Implementado | 90 requisitos sincronizados con CSV, corte histórico, privacidad, manual, renders identificados y límites de 2.3.1. **Siguiente:** Mantener documentación y paquete alineados en la siguiente entrega. | E20, E21 |

### Autonomía técnica y procedencia

| Código | Prioridad | Estado | Situación y siguiente acción | Evidencia |
| --- | --- | --- | --- | --- |
| OWN-01 | P0 | Implementado | Identidad y funciones propias sin ocultar el origen del código. **Siguiente:** Revisar licencias de cualquier dependencia nueva antes de integrarla. | E17 |
| OWN-02 | P1 | Parcial | Ya hay módulos Core/Workflow, recetas y pruebas propias; sigue existiendo código derivado. **Siguiente:** Preparar inventario y decisiones por módulo; no prometer independencia total actual. | E02, E03, E17 |
| OWN-03 | P1 | Parcial | Recetas, historial, controles e interfaz propios documentados. **Siguiente:** Actualizar comparativa para 2.3 sin inferir carencias de otros productos. | E14, E17 |

## Evidencias

- **E01–E19:** el [registro histórico](STATUS-2026-11-06.md#registro-de-evidencia) enlaza código, pruebas, M1 y M2. La ejecución de M3 quedó en las notas del paquete 2.3.0 y el CI de main `1fc48d6`.
- **E20:** [revisión 2.3.1](REVIEW-2.3.1.md), pruebas DocumentLayoutTests/OutputPreferenceTests y confirmación manual de los seis accesos del 25 de noviembre.
- **E21:** [cierre final](acceptance/FINAL-2026-11-25/README.md): perfil M1, apertura contextual, privacidad, verificación y limitaciones.
- **E22:** CI del [PR #3](https://github.com/AD0441/METATRON/pull/3), commit integrado y paquete de la release 2.3.1.

## Trabajo posterior

La validación de otras pantallas/VoiceOver, macOS 14–25, audios reales difíciles, corpus documental amplio y auditoría de servicios del sistema conserva su alcance pendiente o parcial. Renombrado por lotes, organización condicional, inspector, atajos por receta, recomendaciones semánticas y complementos son ampliaciones posteriores. No se anuncian como funciones terminadas de 2.3.1.
