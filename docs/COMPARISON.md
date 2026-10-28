# Qué aporta METATRON frente a Kumquat y Tangerine

Revisión: **28 de octubre de 2026**. Esta comparación distingue la base de código, la referencia de interacción y las mejoras propias. No afirma equivalencia universal de formatos ni superioridad de conversión sin pruebas comparables.

## Procedencia y versiones

| Proyecto o versión | Relación con METATRON | Alcance de la comparación |
| --- | --- | --- |
| **Kumquat** | Base de código abierto, bajo licencia MIT; se conserva su atribución. | Código fijado en [f748f057](https://github.com/iandifilippo/Kumquat/tree/f748f057a763909244e6fd6118f65dc0eac2342c), sin asumir que refleja cambios posteriores. |
| **Tangerine** | Referencia del gesto contextual; no es la base de código de este repositorio. | Aplicación instalada 2.0.2, build 9, observada el 27 de octubre; información pública del desarrollador consultada el 28 de octubre. |
| **METATRON 2.0** | Primera versión publicada de este proyecto. | Ventana de trabajo, recetas, organización, historial, identidad y herramientas propias. |
| **Corrección posterior a 2.0** | Disponible en el código público. | Cubo y Burbujas pasan a ser superficies flotantes transparentes, sin marco rectangular. |
| **METATRON 2.2 en preparación** | Implementación y comprobaciones locales; todavía sin nueva release. | Acceso contextual a recetas, previsualización de propiedades, documentos y ciclo de vida ampliados. Las limitaciones pendientes se enumeran abajo. |

## Qué se conserva de Kumquat

La ruleta contextual, el procesamiento local, los conversores nativos, OCR con Vision, motores opcionales, atajo de Finder, carpetas vigiladas y CLI ya forman parte de la base estudiada. METATRON los adapta y extiende; **no los presenta como invenciones propias**. La base también ofrecía notificaciones y deshacer.

## Mejoras propias sobre la base

| Área | Aporte de METATRON | Utilidad concreta |
| --- | --- | --- |
| **Espacio de trabajo** | Ventana con navegación, cola, recetas, actividad, biblioteca y herramientas documentales. | Revisar un lote y sus resultados sin depender exclusivamente del arrastre. |
| **Recetas encadenadas** | Secuencias editables con orden, calidad, metadatos, sufijo y destino; importar y exportar JSON. | Preparar una imagen con varias transformaciones mediante una sola receta. |
| **Publicación verificable** | Área temporal, validación de salida, hashes, recibos y resolución de nombres repetidos. | Vincular cada resultado a su ejecución y evitar reemplazos accidentales. |
| **Actividad y recuperación** | Búsqueda, filtros, exportación y retención de 7, 14, 30 días o sin límite; recuperación condicionada a hashes. | Limpiar registros conservando archivos y retirar salidas que no hayan sido modificadas. |
| **Organización** | Destinos con nombre y orden, acceso contextual y registro reversible del último movimiento. | Ordenar archivos en carpetas habituales desde el mismo flujo. |
| **Interfaz** | Seis presentaciones y cinco paletas sobrias; símbolo geométrico propio. | Elegir entre ruleta, Cubo de Metatrón, Burbujas, menú, panel y búsqueda por comandos. |
| **Documentos** | Markdown, paquetes con procedencia, comparación visual de PDF, organización de páginas y herramientas de revisión. | Preparar y contrastar documentos conservando relación con su origen. |
| **Herramientas adicionales** | Anotación de imágenes, biblioteca local y acciones de portapapeles bajo demanda. | Encadenar preparación, revisión y organización. |

La interfaz de círculos mantiene el archivo en el centro y deja transparentes las zonas entre controles. La identidad de Metatrón se construye con geometría original; no se redistribuye la imagen usada como referencia.

## Comparación con Tangerine

Tangerine documenta conversión y herramientas locales mediante ruedas contextuales, acciones sobre archivos y guardado de copias. Su catálogo público incluye Markdown. Por eso **la rueda, el procesamiento local, conservar originales o Markdown no se anuncian como novedades exclusivas de METATRON**. Véanse el [sitio oficial](https://www.tangerineformac.com/) y su [presentación del producto](https://www.tangerineformac.com/press).

| Criterio | Tangerine: alcance confirmado | METATRON: propuesta y mejoras propias |
| --- | --- | --- |
| **Interacción** | Ruedas para formatos, herramientas y acciones durante el arrastre. | Conserva ese acceso y añade ventana de trabajo, seis presentaciones y recetas reutilizables. |
| **Organización** | Documenta acciones como mover y copiar. | Añade destinos predefinidos con nombre y orden, más recuperación del último movimiento. |
| **Documentación y control** | No se auditó exhaustivamente su historial ni sus comprobaciones internas. | Expone cola, actividad exportable, políticas de retención, hashes y recibos. |
| **Flujos completos** | Esta revisión no confirma todo su alcance de recetas o automatización. | Ofrece un motor explícito de pasos guardables, extensible a carpetas vigiladas y CLI. |
| **Documentos** | Publica rutas PDF y Markdown, entre otros formatos. | Añade comparación visual y paquetes de análisis; mantiene advertencias sobre estructura y fidelidad. |
| **Código** | Referencia de comportamiento; su código propietario no se incorpora. | Fuentes MIT, atribución de Kumquat, pruebas y documentación de límites. |

**No confirmado no significa ausente.** No se afirma que Tangerine carezca de lotes, OCR, historial, recetas o verificación. Tampoco se promete igualar su catálogo: por ejemplo, METATRON no incluye un escritor nativo de Pages y algunas rutas Office requieren LibreOffice.

## Mejoras de la revisión local 2.2

Estas capacidades están preparadas localmente y **no deben confundirse con la release 2.0 descargable**:

- **Recetas desde el contexto:** seis familias —convertir, herramientas, acciones, destinos, recetas y documentos—; búsqueda y listas conservan el catálogo completo y los círculos muestran hasta doce acciones por familia.
- **Objetivos editables:** «Preparar para la web» y «Documento para análisis» se resuelven con recetas; las conversiones normales no necesitan un modelo de lenguaje.
- **Comprobación previa:** peso de entrada, dimensiones, resolución prevista y advertencias de pérdida de transparencia, metadatos o estructura. El peso comprimido real se muestra después de convertir.
- **Procesamiento documental:** OCR nativo, Markdown con procedencia, extracción de imágenes raster incrustadas compatibles y combinación de PDF, imágenes y documentos convertibles en un PDF final.
- **Motores opcionales:** MarkItDown probado con un CSV sintético; adaptador Docling disponible para una instalación y modelos preparados por el usuario. Docling no se ha validado con modelos en este equipo.
- **Automatización:** ejecutar una receta JSON u objetivos desde la CLI; carpetas vigiladas utilizan la cola común. Pausar bloquea nuevas entradas sin borrar los originales.
- **Segundo plano:** bloqueo de instancia, ventana recuperable, ocultación del Dock y controles superiores para abrir, pausar, entrar en Ajustes y salir completamente.
- **Atajos:** tres acciones App Intents empaquetadas y visibles en Atajos. Su ejecución está bloqueada en esta copia ad hoc por falta de Team ID Apple; necesita firma válida y repetir la prueba. No se anuncia como integración operativa todavía.

## Rendimiento en Apple Silicon

METATRON reutiliza el contexto Core Image/Metal y limita el trabajo pesado de su cola. La reducción simple de imágenes usa Core Graphics porque la medición local fue más favorable que el viaje de ida y vuelta a la GPU. Vision y macOS deciden dónde se ejecutan sus tareas; no se promete un modelo propio ni colocación garantizada en Neural Engine.

La generación de imagen larga de un PDF sintético de 24 páginas pasó de unos **524 MB a 117 MB** de memoria residente máxima. La salida también tiene menos píxeles y límites de lienzo: **no es una comparación a igual resolución ni un benchmark contra Tangerine o Kumquat**. Los [datos de la medición](performance-pdf-m1.json) permiten revisar esa diferencia.

La revisión local registra **50 pruebas del núcleo, una omitida por faltar Ghostscript, y 33 pruebas de flujos de trabajo, sin fallos**. Estas pruebas no demuestran fidelidad universal de documentos ni equivalencia con otros productos.

## Fuentes y límites

- [Kumquat: base fijada](https://github.com/iandifilippo/Kumquat/tree/f748f057a763909244e6fd6118f65dc0eac2342c) y [procedencia de METATRON](../UPSTREAM.md).
- [Tangerine: sitio oficial](https://www.tangerineformac.com/) y [press kit del desarrollador](https://www.tangerineformac.com/press). La web puede describir una versión distinta de la aplicación instalada.
- [METATRON 2.0](https://github.com/AD0441/METATRON/releases/tag/v2.0.0) y [corrección de círculos transparentes](https://github.com/AD0441/METATRON/commit/b74689ce5b7ea49ae977b669f12aced2c309987e).
- [Matriz pública de funciones y dependencias](FEATURES.md). La revisión local 2.2 sigue pendiente de publicación y no se infiere de la release descargable.

Los materiales privados de investigación y los binarios de Tangerine quedan fuera de este repositorio. METATRON no está afiliado con Tangerine, Apple ni los proyectos citados.

**Creado por Sebastián Pastén F.**
