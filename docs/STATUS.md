# METATRON — Estado de requisitos y próximos trabajos

**Corte:** 2 de noviembre de 2026. **Especificación:** [REQUIREMENTS.md](REQUIREMENTS.md). **Base:** 2.3.0 build 7, commit `0f86ca829eb93a2b40796b01a5788d318d952c68`.

Se revisaron conversación, código, pruebas y documentación; no se ejecutó una nueva batería de conversiones, interfaz o rendimiento al redactar esta matriz. «Implementado» no equivale a aceptación exhaustiva. Los criterios de la especificación describen lo que debe comprobarse; la columna de próxima acción describe lo que falta. «Introducción» no significa publicado en esa versión: 2.2.1 y 2.3 siguen en propuestas abiertas.

## Línea base comprobada al corte

- La [release pública sigue en 2.2.0](https://github.com/AD0441/METATRON/releases/tag/v2.2.0). No se ha publicado otra entrega desde esta tarea.
- [#1 — estabilización](https://github.com/AD0441/METATRON/pull/1) apunta a main; [#2 — 2.3](https://github.com/AD0441/METATRON/pull/2) apunta a la rama de #1. Ambas están abiertas, sin fusionar, y ya no están marcadas como borrador.
- La copia en Aplicaciones declara 2.3.0 build 7; su copia y firma/integridad se verificaron el 28 de octubre. La consulta de versión se repitió en esta revisión; no acredita un ensayo nuevo de interfaz.
- Validación local previa: **50 XCTest + 78 Swift Testing = 128 pruebas, sin fallos ni omisiones**, más repeticiones dirigidas tras las últimas revisiones. El [CI del commit](https://github.com/AD0441/METATRON/actions/runs/40792241911) figura correcto, incluidas pruebas, compilación, paquete y artefacto. No es una ejecución nueva del 2 de noviembre.
- Ensayo local previo de Apple Speech: audio sintético es-CL a TXT y Markdown, recibo y cancelación con original intacto y sin resultados parciales. No se descargaron modelos ni se usaron grabaciones del usuario.
- Firma elegida: **ad hoc**. La firma Apple y notarización se aplazan; la ejecución nativa de Atajos sigue condicionada. Esa decisión no impide revisar o distribuir honestamente el paquete local.

## Lectura de estados

| Estado | Significado |
| --- | --- |
| Implementado | Capacidad presente, con código y/o evidencia previa acotada. Mantener sus regresiones; no presume todas las variantes verificadas. |
| Parcial | Hay comportamiento útil, pero falta parte del alcance, fidelidad o verificación representativa. |
| Por validar | Hay implementación o una condición de calidad que requiere completar una prueba concreta. |
| Pendiente | No está implementado o no se ha ejecutado el trabajo indicado. |
| Condicionado | Depende de un recurso externo aplazado, como una identidad Apple para Atajos. |

## Resumen de la matriz

**88 requisitos**, 70 P0, 16 P1, 2 P2. Las 13 decisiones y los 20 casos de aceptación son referencias adicionales; no se suman al conteo.

| Estado | Cantidad |
| --- | ---: |
| Implementado | 49 |
| Parcial | 23 |
| Por validar | 7 |
| Pendiente | 8 |
| Condicionado | 1 |

Estos conteos no representan porcentaje de producto terminado; cada requisito tiene alcance y esfuerzo distintos.

## Matriz de revisión

### OBJ · Objetivos y experiencia de uso

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| OBJ-01 | P0 | Parcial | Ventana, cola y herramientas propias además del acceso contextual. | Completar la aceptación práctica de 2.3. | [E01](#e01), [E02](#e02), [E15](#e15) |
| OBJ-02 | P0 | Implementado | El motor ejecuta procesos completos en vez de una sola conversión. | Conservar las regresiones al incorporar nuevos pasos. | [E02](#e02) |
| OBJ-03 | P0 | Parcial | Núcleo nativo, trabajo acotado y módulos de IA opcionales. | Completar el ensayo offline y el perfil sostenido. | [E10](#e10), [E12](#e12), [E13](#e13) |
| OBJ-04 | P0 | Implementado | La estabilización y la ampliación de audio están separadas en PR consecutivos. | Cerrar la aceptación pendiente antes de integrar y publicar. | [E09](#e09), [E15](#e15), [E16](#e16) |

### CTX · Acceso contextual y compatibilidad

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| CTX-01 | P0 | Implementado | Se amplió la propuesta inicial de tres accesos más uno configurable. | Repetir la comprobación visual de los seis modos en la app instalada. | [E01](#e01), [E11](#e11), [E15](#e15) |
| CTX-02 | P0 | Implementado | Ambos usan el panel transparente de la ruleta; las listas conservan su superficie propia. | Revisar contraste claro/oscuro y bordes de pantalla. | [E01](#e01), [E11](#e11) |
| CTX-03 | P0 | Implementado | Geometría y detección de objetivos separadas de la malla decorativa. | Repetir arrastre y navegación por teclado en los seis modos. | [E01](#e01), [E11](#e11) |
| CTX-04 | P0 | Implementado | Catálogo compartido por presentaciones, espacio de trabajo y ejecución. | Ampliar muestras cuando se añadan formatos o lectores. | [E03](#e03), [E04](#e04) |
| CTX-05 | P0 | Implementado | Intersección por archivo, incluyendo subtipo Office y motores disponibles. | Añadir casos por códec o contenedor al ampliar el catálogo. | [E03](#e03) |
| CTX-06 | P0 | Implementado | Ajustes usa la unión de capacidades; la selección real usa su intersección. | Conservar pruebas del catálogo al cambiar los filtros. | [E03](#e03) |
| CTX-07 | P0 | Por validar | El anclaje contextual ya existe; esta matriz de entornos no está cerrada. | Ejecutar AC-03 y documentar capturas acotadas a METATRON. | [E01](#e01), [E11](#e11), [E15](#e15) |

### REC · Recetas encadenadas

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| REC-01 | P0 | Implementado | Secuencias reutilizables con calidad, sufijo, destino y metadatos. | Revisar la edición práctica con recetas largas. | [E02](#e02) |
| REC-02 | P0 | Implementado | Campos opcionales de idioma y restricciones de entrada con compatibilidad anterior. | Versionar el esquema si futuros cambios dejan de ser aditivos. | [E02](#e02), [E03](#e03), [E04](#e04) |
| REC-03 | P0 | Implementado | Comprobación previa centralizada para app, simulación, recetas y CLI. | Conservar el rechazo previo a escritura con nuevos pasos. | [E03](#e03) |
| REC-04 | P0 | Implementado | El editor proyecta los tipos y admite restricciones exportables. | Revisar claridad de mensajes al corregir una receta inválida. | [E03](#e03), [E04](#e04) |
| REC-05 | P0 | Parcial | Datos previos y advertencias, con tamaños reales posteriores en Actividad. | Completar estimaciones por cadena y documentar pasos de múltiples salidas. | [E02](#e02), [E03](#e03) |
| REC-06 | P1 | Pendiente | Ya hay acceso contextual a recetas; falta asignación individual completa. | Diseñar después del cierre de 2.3. | [E14](#e14) |

### FMT · Conversiones esenciales

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| FMT-01 | P0 | Parcial | OCR, anotaciones, filtros por ImageIO y reconocimiento del lector SVG propio. | Completar matriz de pérdidas y muestras reales de cámaras. | [E03](#e03), [E05](#e05) |
| FMT-02 | P0 | Parcial | Herramientas adicionales y límite de lienzo para imagen larga. | Revisar PDF complejos, escaneados, bloqueados y con páginas rotadas. | [E05](#e05), [E06](#e06), [E12](#e12) |
| FMT-03 | P0 | Parcial | Rutas nativas y LibreOffice opcional, con perfil de proceso aislado. | Completar corpus y tabla de compatibilidad por elementos. | [E05](#e05), [E06](#e06), [E09](#e09) |
| FMT-04 | P0 | Parcial | Markdown tabular e indexación de Excel mediante lector estructurado. | Validar planillas reales complejas y explicar alcance tabular. | [E03](#e03), [E05](#e05), [E06](#e06) |
| FMT-05 | P0 | Parcial | Recorte/unión de vídeo y normalización/mono opcionales. | Cerrar matriz de contenedores y codificadores con muestras diversas. | [E05](#e05), [E13](#e13) |
| FMT-06 | P0 | Parcial | Formatos adicionales mediante herramientas del sistema. | Probar archivos dañados y variantes de libarchive; revisar límites de extracción. | [E05](#e05) |

### DOC · Procesamiento documental y Markdown

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| DOC-01 | P0 | Implementado | Markdown integrado en catálogo, recetas y CLI; audio se añade en 2.3. | Revisar muestras complejas sin prometer reconstrucción perfecta. | [E04](#e04), [E05](#e05), [E06](#e06) |
| DOC-02 | P0 | Parcial | Vision se integra en extracción y paquetes documentales. | Medir exactitud y latencia en un corpus acordado. | [E05](#e05), [E06](#e06) |
| DOC-03 | P0 | Parcial | Paquetes estructurados nativos con procedencia y adaptadores opcionales. | Revisar extracción de recursos y límites en documentos reales. | [E06](#e06) |
| DOC-04 | P0 | Implementado | Paso bundlePDF y validación de compatibilidad por entrada. | Ampliar fixtures con documentos editables de más de una página. | [E03](#e03), [E06](#e06) |
| DOC-05 | P1 | Parcial | OCR por filas y adaptadores MarkItDown/Docling; Docling no está validado con modelos aquí. | Validar Docling solo en un lote posterior con instalación explícita. | [E06](#e06), [E14](#e14) |
| DOC-06 | P1 | Parcial | Comparador raster y operaciones de organización de páginas. | Comprobar tolerancias y documentos con rotaciones o tamaños mixtos. | [E06](#e06) |
| DOC-07 | P1 | Parcial | Retirada por texto y OCR, sin afirmar detección exhaustiva de datos sensibles. | Normalizar páginas rotadas y validar visualmente cada caso de aceptación. | [E06](#e06) |

### AUD · Audio a texto local, sin resumen

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| AUD-01 | P0 | Implementado | SpeechAnalyzer/SpeechTranscriber, formatos, herramienta y dos recetas. | Repetir con audio real autorizado en español e inglés. | [E04](#e04) |
| AUD-02 | P0 | Implementado | Se eliminó la propuesta de resumir; esta ruta no utiliza un LLM. | Mantener esta restricción al ampliar exportaciones. | [E04](#e04) |
| AUD-03 | P0 | Implementado | Ajustes de idioma, consulta de activos y comando speech-install explícito. | Probar el mensaje de idioma ausente sin iniciar descarga. | [E03](#e03), [E04](#e04) |
| AUD-04 | P0 | Implementado | Cancelación del analizador y protección del audio aun con preferencia de Papelera. | Ampliar pruebas con contenedores y duraciones diferentes. | [E04](#e04), [E09](#e09) |
| AUD-05 | P0 | Implementado | Idioma global o por receta/CLI, compatible con JSON anterior. | Completar ensayo práctico de receta vigilada con audio autorizado. | [E03](#e03), [E04](#e04), [E08](#e08) |
| AUD-06 | P1 | Por validar | Hay límites explícitos y una prueba sintética; no una evaluación de exactitud general. | Preparar corpus autorizado y resultados reproducibles; no prometer diarización ni idioma automático. | [E04](#e04), [E12](#e12) |

### ORG · Organización y destinos

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| ORG-01 | P0 | Implementado | Página de destinos y barra de favoritos. | Probar destino retirado, movido o sin permisos. | [E07](#e07), [E15](#e15) |
| ORG-02 | P0 | Implementado | Transacción de movimiento y recuperación por hash. | Ampliar ensayo a otro volumen y destinos no disponibles. | [E07](#e07) |
| ORG-03 | P0 | Implementado | Opciones por receta y planificación de nombres únicos. | Revisar errores de permisos y disco sin espacio en aceptación. | [E02](#e02), [E09](#e09) |
| ORG-04 | P1 | Pendiente | No confundir el sufijo de una conversión con un renombrador general. | Diseñar y probar después de estabilizar 2.3. | [E14](#e14) |
| ORG-05 | P1 | Pendiente | Las carpetas vigiladas procesan recetas; no son todavía un organizador condicional completo. | Definir precedencia, exclusiones y prevención de ciclos. | [E08](#e08), [E14](#e14) |
| ORG-06 | P1 | Pendiente | Hay simulación y propiedades parciales; no un inspector completo de comparación con Quick Look. | Diseñar acceso y compatibilidad después del cierre de 2.3. | [E14](#e14) |

### HIS · Actividad e historial

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| HIS-01 | P0 | Implementado | Historial consultable con metadatos de cada ejecución. | Revisar mensajes y filtros con lotes grandes. | [E02](#e02), [E07](#e07) |
| HIS-02 | P0 | Implementado | Limpieza de actividad separada de eliminación de archivos. | Confirmar en interfaz que retirar el registro elimina su acceso a deshacer. | [E07](#e07) |
| HIS-03 | P0 | Implementado | Política explícita de retención, persistida en Ajustes. | Mantener regresiones de fechas y estados. | [E07](#e07) |
| HIS-04 | P1 | Parcial | Índice local y corrección del lector Excel en 2.3. | Completar corpus y advertencias sobre contenido y rutas guardados localmente. | [E03](#e03), [E06](#e06), [E13](#e13) |

### AUT · Automatización

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| AUT-01 | P0 | Implementado | Tres muestras de tamaño/fecha y filtro de tipos antes de encolar. | Documentar que una pausa larga de copia puede aparentar estabilidad. | [E03](#e03), [E08](#e08) |
| AUT-02 | P0 | Implementado | Tokens de generación y preservación de vigilantes que no cambiaron. | Mantener pruebas de eventos tardíos y alias simbólicos. | [E08](#e08), [E09](#e09) |
| AUT-03 | P0 | Implementado | Automatización desde scripts sin necesitar Atajos. | Verificar ayuda y ejemplos con cada cambio de comandos. | [E04](#e04), [E08](#e08), [E16](#e16) |
| AUT-04 | P0 | Por validar | Entradas nativas y accesos ya presentes, sin nueva aceptación completa en 2.3. | Ejecutar AC-04 sobre la copia de Aplicaciones. | [E01](#e01), [E10](#e10), [E15](#e15) |
| AUT-05 | P1 | Condicionado | Metadatos y acciones visibles; ejecución bloqueada en la distribución ad hoc. | Aplazar firma Apple y prueba nativa según la decisión del usuario; no bloquear la entrega local por ello. | [E08](#e08), [E10](#e10), [E16](#e16) |
| AUT-06 | P2 | Pendiente | Motores configurables y CLI ya permiten extensión acotada; no existe un sistema general de complementos. | Evaluar mantenimiento, aislamiento y licencias antes de elegir arquitectura o distribuir complementos. | [E08](#e08), [E14](#e14), [E17](#e17) |

### INT · Integridad, errores y recuperación

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| INT-01 | P0 | Parcial | Recetas no modifican originales y transcripción añade una protección específica. | Revisar coherencia entre rutas heredadas directas y motor de recetas. | [E02](#e02), [E04](#e04), [E09](#e09) |
| INT-02 | P0 | Implementado | Publicación verificada, nombres únicos y reversión de resultados propios. | Conservar pruebas de fallos parciales con nuevas salidas múltiples. | [E02](#e02), [E09](#e09) |
| INT-03 | P0 | Implementado | Trazabilidad local con tamaños y procedencia. | Explicar que el recibo contiene rutas locales al exportarlo. | [E02](#e02), [E09](#e09) |
| INT-04 | P0 | Implementado | Recuperación condicionada a integridad, distinta de una reversión universal. | Documentar ubicación y limpieza de archivos de recuperación. | [E02](#e02), [E07](#e07) |
| INT-05 | P0 | Implementado | Ejecutor POSIX por grupo; TERM y KILL posterior, drenaje de tuberías y cancelación nativa. | Explicar que una unidad síncrona nativa termina antes de devolver control. | [E09](#e09), [E04](#e04) |
| INT-06 | P0 | Implementado | Recuperación de recetas y trabajos sin ocultar errores de almacenamiento. | Probar también poco espacio y permisos revocados en la aceptación práctica. | [E09](#e09) |

### LIF · Ciclo de vida y segundo plano

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| LIF-01 | P0 | Implementado | Bloqueo de instancia con recuperación de ventana existente. | Repetir apertura desde Finder y Aplicaciones con la versión final. | [E10](#e10) |
| LIF-02 | P0 | Implementado | Ciclo de vida desacoplado de la ventana principal. | Repetir durante una conversión y tras despertar el Mac. | [E10](#e10) |
| LIF-03 | P0 | Implementado | Control permanente de la app en segundo plano. | Completar prueba visual de la copia instalada 2.3. | [E10](#e10), [E15](#e15) |
| LIF-04 | P0 | Implementado | Preferencias de inicio y política accessory. | Revisar que no se acumulan proveedores de pruebas en Launch Services. | [E10](#e10), [E16](#e16) |
| LIF-05 | P0 | Implementado | Terminación diferida hasta cancelar y drenar la cola. | Repetir con audio y un motor externo en la app instalada. | [E09](#e09), [E10](#e10) |

### PRV · Privacidad y conexiones

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| PRV-01 | P0 | Implementado | Núcleo local; ninguna sustitución remota de Apple Speech. | La auditoría dinámica de tráfico se registra aparte en PRV-03. | [E04](#e04), [E05](#e05), [E13](#e13) |
| PRV-02 | P0 | Implementado | Motores separados y botón/comando explícito para idiomas. | Revisar redirecciones y mensajes de instalación al publicar. | [E04](#e04), [E13](#e13) |
| PRV-03 | P0 | Por validar | El diseño local existe; no hay aquí una nueva auditoría de tráfico completa. | Ejecutar AC-15 y describir excepciones de red explícitas. | [E13](#e13) |
| PRV-04 | P1 | Parcial | Hay enlace temporal local; no implementa todavía LocalSend ni TLS. | Validar modo existente y evaluar envío/recepción cifrados en un lote posterior. | [E13](#e13), [E14](#e14) |

### IA · Inteligencia local opcional

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| IA-01 | P1 | Parcial | Asistente opcional; no se entrenó un modelo propio. | Validar estados de disponibilidad y explicar requisitos en pantalla. | [E13](#e13) |
| IA-02 | P0 | Implementado | Separación entre sugerencia semántica y motor determinista. | Mantener esa separación al ampliar recomendaciones. | [E13](#e13) |
| IA-03 | P2 | Pendiente | Los objetivos actuales son recetas explícitas, no planificación autónoma por IA. | Definir evaluación de calidad y consumo antes de integrar automatismos semánticos. | [E13](#e13), [E14](#e14) |

### PER · Rendimiento en Apple Silicon

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| PER-01 | P0 | Implementado | Cola serial, trabajo concurrente separado y límites de imágenes/documentos/audio. | Medir el comportamiento sostenido; este diseño no demuestra por sí solo fluidez integral. | [E09](#e09), [E12](#e12) |
| PER-02 | P0 | Implementado | El redimensionado simple mantuvo CPU tras superar a Metal en el ensayo local. | Repetir si cambian algoritmo, resolución o hardware. | [E12](#e12) |
| PER-03 | P0 | Por validar | Hay microbenchmarks y una muestra de reposo históricos, no un perfil completo de 2.3. | Ejecutar AC-16 con objetivos provisionales documentados. | [E12](#e12) |
| PER-04 | P1 | Por validar | El paquete verifica arquitectura y metadatos; falta matriz de ejecución entre sistemas. | No equiparar compilación con soporte validado de todas las versiones. | [E04](#e04), [E16](#e16) |

### VIS · Identidad, apariencia y accesibilidad

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| VIS-01 | P0 | Implementado | Marca, icono y activos generables originales. | Revisar tamaños pequeños y coherencia de las nuevas capturas. | [E11](#e11) |
| VIS-02 | P0 | Implementado | Temas configurables en vez de una única apariencia. | Medir contraste de estados y selección en todas las paletas. | [E11](#e11), [E15](#e15) |
| VIS-03 | P0 | Parcial | Existen atajos y navegación; no se ha cerrado una auditoría integral de accesibilidad. | Ejecutar AC-17 y registrar los hallazgos por presentación. | [E01](#e01), [E11](#e11), [E15](#e15) |
| VIS-04 | P1 | Parcial | Base con traducciones heredadas y pantallas nuevas en español. | Inventariar cadenas y validar inglés por un lote separado. | [E11](#e11) |
| VIS-05 | P0 | Implementado | Identidad editorial y donación integradas sin bloquear funciones. | Mantener coherencia en README, app y release. | [E11](#e11), [E13](#e13) |

### DIST · Pruebas, instalación y publicación

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| DIST-01 | P0 | Implementado | Script común de compilación/verificación; corregido fallo release del optimizador Swift 6.3. | Repetir sobre el commit integrado final. | [E16](#e16) |
| DIST-02 | P0 | Implementado | 128 pruebas locales previas y CI del candidato correcto; Speech respeta disponibilidad del equipo. | Reejecutar CI tras integrar las ramas. | [E16](#e16), [E03](#e03), [E04](#e04) |
| DIST-03 | P0 | Por validar | 2.3.0 build 7 fue copiada y verificada; falta aceptación práctica completa en esa copia. | Cerrar bloqueos P0 y guardar evidencias antes de publicar. | [E10](#e10), [E15](#e15), [E16](#e16) |
| DIST-04 | P0 | Pendiente | Cambios preparados; ambas propuestas continúan abiertas al corte de esta especificación. | La redacción de este documento no autoriza fusionar ni publicar. | [E16](#e16) |
| DIST-05 | P0 | Pendiente | Release pública 2.2.0 y candidato 2.3 claramente separados. | Publicar únicamente tras cerrar aceptación e instrucción de publicación. | [E11](#e11), [E15](#e15), [E16](#e16) |
| DIST-06 | P0 | Parcial | Esta especificación y matriz consolidan las decisiones; algunos documentos previos requieren actualización para 2.3. | Completar manual, privacidad y capturas de la entrega final. | [E14](#e14), [E15](#e15), [E16](#e16) |

### OWN · Autonomía técnica y procedencia

| Código | Prioridad | Estado | Mejora / situación actual | Trabajo siguiente | Evidencia |
| --- | --- | --- | --- | --- | --- |
| OWN-01 | P0 | Implementado | Identidad y funciones propias sin ocultar el origen del código. | Revisar licencias de cualquier dependencia nueva antes de integrarla. | [E17](#e17) |
| OWN-02 | P1 | Parcial | Ya hay módulos Core/Workflow, recetas y pruebas propias; sigue existiendo código derivado. | Preparar inventario y decisiones por módulo; no prometer independencia total actual. | [E02](#e02), [E03](#e03), [E17](#e17) |
| OWN-03 | P1 | Parcial | Recetas, historial, controles e interfaz propios documentados. | Actualizar comparativa para 2.3 sin inferir carencias de otros productos. | [E14](#e14), [E17](#e17) |

## Qué debemos hacer primero

1. **Validación práctica del candidato:** CTX-07, AUT-04 y DIST-03, con AC-01–AC-14 sobre la copia instalada. Conservar la evidencia histórica sin volver a presentar como pendientes las funciones ya probadas.
2. **Cerrar calidad P0:** PER-03, PRV-03 y VIS-03. Medir la versión actual en M1/8 GB, comprobar offline y completar teclado/VoiceOver. La comparación entre sistemas de PER-04 se valida o acota antes de anunciar soporte.
3. **Integrar y reconstruir:** DIST-04, en orden #1 → #2, con revisión y CI sobre el commit integrado. Este documento no ejecuta esas fusiones.
4. **Preparar entrega:** DIST-05/06, actualizar documentación de 2.3, capturas y requisitos del paquete, y comprobar ZIP/checksum. Mantener firma local y límite de Atajos; publicar con instrucción del usuario.
5. **Después de estabilizar:** ORG-04/05 y REC-06; luego DOC-05 e IA-03. Quick Look, LAN cifrada, firma Apple y complementos requieren su propio lote, alcance y recursos.

## Registro de evidencia

Las rutas siguientes muestran dónde revisar la implementación y sus pruebas. Un archivo de pruebas no prueba por sí solo que cada requisito se haya ejecutado ni que cubra toda su aceptación. E14 registra propuestas, E12 mediciones limitadas y E13 revisión de código: no deben confundirse con validaciones completas.

### E01

**Acceso contextual.**

- [Sources/Metatron/Ring/RingController.swift](../Sources/Metatron/Ring/RingController.swift)
- [Sources/Metatron/Ring/RingModel.swift](../Sources/Metatron/Ring/RingModel.swift)
- [Sources/Metatron/Workbench/Views/QuickAccessView.swift](../Sources/Metatron/Workbench/Views/QuickAccessView.swift)
- [Tests/MetatronWorkflowTests/MetatronGeometryTests.swift](../Tests/MetatronWorkflowTests/MetatronGeometryTests.swift)
- [Tests/MetatronWorkflowTests/OrbitGeometryTests.swift](../Tests/MetatronWorkflowTests/OrbitGeometryTests.swift)

### E02

**Recetas y publicación.**

- [Sources/MetatronWorkflow/Models/Recipe.swift](../Sources/MetatronWorkflow/Models/Recipe.swift)
- [Sources/MetatronWorkflow/Execution/RecipeExecutor.swift](../Sources/MetatronWorkflow/Execution/RecipeExecutor.swift)
- [Sources/MetatronWorkflow/Execution/Simulation.swift](../Sources/MetatronWorkflow/Execution/Simulation.swift)
- [Sources/Metatron/Workbench/Stores/WorkspaceStore.swift](../Sources/Metatron/Workbench/Stores/WorkspaceStore.swift)
- [Tests/MetatronWorkflowTests/WorkflowTests.swift](../Tests/MetatronWorkflowTests/WorkflowTests.swift)

### E03

**Compatibilidad 2.3.**

- [Sources/MetatronCore/Action.swift](../Sources/MetatronCore/Action.swift)
- [Sources/MetatronCore/Engine.swift](../Sources/MetatronCore/Engine.swift)
- [Sources/MetatronWorkflow/Execution/RecipeCompatibility.swift](../Sources/MetatronWorkflow/Execution/RecipeCompatibility.swift)
- [Tests/MetatronWorkflowTests/RecipeCompatibilityTests.swift](../Tests/MetatronWorkflowTests/RecipeCompatibilityTests.swift)
- [Tests/MetatronAppTests/ContextCompatibilityTests.swift](../Tests/MetatronAppTests/ContextCompatibilityTests.swift)

### E04

**Apple Speech local.**

- [Sources/MetatronCore/AppleSpeech.swift](../Sources/MetatronCore/AppleSpeech.swift)
- [Tests/MetatronCoreTests/AppleSpeechTests.swift](../Tests/MetatronCoreTests/AppleSpeechTests.swift)
- [Tests/MetatronWorkflowTests/TranscriptWorkflowTests.swift](../Tests/MetatronWorkflowTests/TranscriptWorkflowTests.swift)
- [script/verify_speech.sh](../script/verify_speech.sh)
- [docs/AUDIO-TRANSCRIPTION.md](AUDIO-TRANSCRIPTION.md)

### E05

**Conversiones y lectores.**

- [Sources/MetatronCore/Images.swift](../Sources/MetatronCore/Images.swift)
- [Sources/MetatronCore/PDFs.swift](../Sources/MetatronCore/PDFs.swift)
- [Sources/MetatronCore/Documents.swift](../Sources/MetatronCore/Documents.swift)
- [Sources/MetatronCore/DataFiles.swift](../Sources/MetatronCore/DataFiles.swift)
- [Sources/MetatronCore/Media.swift](../Sources/MetatronCore/Media.swift)
- [Sources/MetatronCore/ExtendedMedia.swift](../Sources/MetatronCore/ExtendedMedia.swift)
- [Tests/MetatronCoreTests/EngineTests.swift](../Tests/MetatronCoreTests/EngineTests.swift)
- [Tests/MetatronCoreTests/FormatTests.swift](../Tests/MetatronCoreTests/FormatTests.swift)
- [Tests/MetatronCoreTests/EngineIntegrationTests.swift](../Tests/MetatronCoreTests/EngineIntegrationTests.swift)
- [docs/FEATURES.md](FEATURES.md)

### E06

**Documentos.**

- [Sources/MetatronCore/MarkdownExport.swift](../Sources/MetatronCore/MarkdownExport.swift)
- [Sources/MetatronWorkflow/Documents/DocumentProcessing.swift](../Sources/MetatronWorkflow/Documents/DocumentProcessing.swift)
- [Sources/MetatronWorkflow/Documents/PDFWorkbench.swift](../Sources/MetatronWorkflow/Documents/PDFWorkbench.swift)
- [Sources/MetatronWorkflow/Documents/DocumentIndex.swift](../Sources/MetatronWorkflow/Documents/DocumentIndex.swift)
- [Tests/MetatronWorkflowTests/DocumentProcessingTests.swift](../Tests/MetatronWorkflowTests/DocumentProcessingTests.swift)
- [Tests/MetatronWorkflowTests/OrganizationTests.swift](../Tests/MetatronWorkflowTests/OrganizationTests.swift)
- [docs/DOCUMENTS.md](DOCUMENTS.md)

### E07

**Organización y actividad.**

- [Sources/MetatronWorkflow/Execution/FileMoveTransaction.swift](../Sources/MetatronWorkflow/Execution/FileMoveTransaction.swift)
- [Sources/MetatronWorkflow/Models/ActivityRetention.swift](../Sources/MetatronWorkflow/Models/ActivityRetention.swift)
- [Tests/MetatronWorkflowTests/OrganizationTests.swift](../Tests/MetatronWorkflowTests/OrganizationTests.swift)
- [Tests/MetatronWorkflowTests/WorkflowTests.swift](../Tests/MetatronWorkflowTests/WorkflowTests.swift)

### E08

**Automatización.**

- [Sources/MetatronCore/FolderWatcher.swift](../Sources/MetatronCore/FolderWatcher.swift)
- [Sources/Metatron/Automation/WatchService.swift](../Sources/Metatron/Automation/WatchService.swift)
- [Sources/Metatron/Automation/FileIntents.swift](../Sources/Metatron/Automation/FileIntents.swift)
- [Sources/MetatronCLI/main.swift](../Sources/MetatronCLI/main.swift)
- [Tests/MetatronCoreTests/FolderWatcherTests.swift](../Tests/MetatronCoreTests/FolderWatcherTests.swift)

### E09

**Estabilidad.**

- [Sources/MetatronCore/ToolInvocation.swift](../Sources/MetatronCore/ToolInvocation.swift)
- [Sources/MetatronWorkflow/Execution/FileIntegrity.swift](../Sources/MetatronWorkflow/Execution/FileIntegrity.swift)
- [Sources/Metatron/Workbench/Stores/WorkspaceStore.swift](../Sources/Metatron/Workbench/Stores/WorkspaceStore.swift)
- [Tests/MetatronCoreTests/ToolInvocationTests.swift](../Tests/MetatronCoreTests/ToolInvocationTests.swift)
- [Tests/MetatronWorkflowTests/ConversionStabilityTests.swift](../Tests/MetatronWorkflowTests/ConversionStabilityTests.swift)
- [Tests/MetatronAppTests/WorkspaceStabilityTests.swift](../Tests/MetatronAppTests/WorkspaceStabilityTests.swift)
- [docs/STABILITY-2.2.1.md](STABILITY-2.2.1.md)

### E10

**Ciclo de vida.**

- [Sources/Metatron/App/AppDelegate.swift](../Sources/Metatron/App/AppDelegate.swift)
- [Sources/Metatron/App/MetatronApp.swift](../Sources/Metatron/App/MetatronApp.swift)
- [Sources/MetatronWorkflow/Execution/InstanceLease.swift](../Sources/MetatronWorkflow/Execution/InstanceLease.swift)
- [Tests/MetatronWorkflowTests/InstanceLeaseTests.swift](../Tests/MetatronWorkflowTests/InstanceLeaseTests.swift)
- [docs/STABILITY-2.2.1.md](STABILITY-2.2.1.md)

### E11

**Marca y apariencia.**

- [Sources/Metatron/Settings/Theme.swift](../Sources/Metatron/Settings/Theme.swift)
- [Sources/Metatron/Settings/SettingsView.swift](../Sources/Metatron/Settings/SettingsView.swift)
- [docs/BRAND.md](BRAND.md)
- [docs/screenshots/access-metatron.png](screenshots/access-metatron.png)
- [docs/screenshots/access-bubbles.png](screenshots/access-bubbles.png)
- [script/make_brand.swift](../script/make_brand.swift)

### E12

**Rendimiento: evidencia acotada.**

- [Sources/MetatronWorkflow/Performance/HardwareProfile.swift](../Sources/MetatronWorkflow/Performance/HardwareProfile.swift)
- [Sources/MetatronWorkflow/Performance/ImageBenchmark.swift](../Sources/MetatronWorkflow/Performance/ImageBenchmark.swift)
- [docs/performance-m1.json](performance-m1.json)
- [docs/performance-pdf-m1.json](performance-pdf-m1.json)

### E13

**Privacidad, asistente y LAN: revisión de código.**

- [Sources/Metatron/Workbench/Views/LocalAssistantView.swift](../Sources/Metatron/Workbench/Views/LocalAssistantView.swift)
- [Sources/Metatron/Sharing/LocalTransfer.swift](../Sources/Metatron/Sharing/LocalTransfer.swift)
- [Sources/Metatron/Sharing/LocalTransferView.swift](../Sources/Metatron/Sharing/LocalTransferView.swift)
- [Sources/Metatron/Automation/UpdateChecker.swift](../Sources/Metatron/Automation/UpdateChecker.swift)
- [Sources/Metatron/Runner/ActionRunner.swift](../Sources/Metatron/Runner/ActionRunner.swift)
- [docs/AUDIO-TRANSCRIPTION.md](AUDIO-TRANSCRIPTION.md)

### E14

**Propuestas y alcance previo.**

- [docs/IDEAS.md](IDEAS.md)
- [docs/FEATURES.md](FEATURES.md)
- [docs/COMPARISON.md](COMPARISON.md)

### E15

**Validación histórica: no equivale a auditoría nueva.**

- [docs/VALIDATION.md](VALIDATION.md)
- [docs/PREPUBLICATION.md](PREPUBLICATION.md)
- [docs/STABILITY-2.2.1.md](STABILITY-2.2.1.md)
- [CHANGELOG.md](../CHANGELOG.md)

### E16

**Distribución y pruebas del candidato.**

- [Resources/Info.plist](../Resources/Info.plist)
- [script/build_and_run.sh](../script/build_and_run.sh)
- [script/verify_package.sh](../script/verify_package.sh)
- [script/test.sh](../script/test.sh)
- [.github/workflows/swift.yml](../.github/workflows/swift.yml)
- [CHANGELOG.md](../CHANGELOG.md)

### E17

**Procedencia y autonomía.**

- [UPSTREAM.md](../UPSTREAM.md)
- [LICENSE](../LICENSE)
- [Package.swift](../Package.swift)
- [docs/COMPARISON.md](COMPARISON.md)

## Reglas para actualizar esta matriz

- Usar el mismo código en requisito, CSV, prueba de aceptación y defecto. Adjuntar commit/build y resultado de la verificación.
- No cambiar «Parcial» o «Por validar» a «Implementado» por añadir un botón, adaptar un catálogo o tomar una captura aislada.
- Una aprobación local no reemplaza el CI del commit integrado; un CI correcto no acredita permisos, VoiceOver o fidelidad de documentos reales.
- No borrar licencias para expresar autonomía, instalar modelos sin acción explícita ni convertir sugerencias de IA en ejecución automática.
- No arrastrar como actuales las omisiones antiguas de Ghostscript: pertenecen a sus validaciones fechadas. Las 128 pruebas locales del candidato no tuvieron omisiones.
- No incluir los materiales de marketing locales no versionados en un cambio documental por accidente.

**Creado por Sebastián Pastén F.**
