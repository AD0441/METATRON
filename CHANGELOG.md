# Historial de cambios

## 2.2.0 · 28 de octubre de 2026

METATRON amplía el flujo contextual con recetas reutilizables, procesamiento documental y controles para mantener la app en segundo plano.

### Cambios desde 2.0

- Cubo de Metatrón y Burbujas flotan alrededor del archivo, con fondo transparente y objetivos circulares separados.
- Seis familias contextuales: Convertir, Herramientas, Acciones, Destinos, Recetas y Documentos. Las listas y la búsqueda conservan el catálogo completo.
- Recetas guardadas accesibles desde el contexto y la CLI; objetivos editables «Preparar para la web» y «Documento para análisis».
- Simulación con peso de entrada, dimensiones, resolución prevista y advertencias de pérdidas; Actividad muestra tamaños reales de entrada y salida.
- Markdown con procedencia, OCR nativo, extracción de imágenes raster incrustadas compatibles y combinación de PDF, imágenes y documentos convertibles en un PDF final.
- Configuración de motores documentales opcionales: MarkItDown y adaptador Docling. No se incluyen sus entornos ni modelos en la descarga.
- Instancia única con bloqueo del sistema, ventana recuperable, modo sin Dock y controles superiores para abrir, pausar, entrar en Ajustes y salir.
- Pausar detiene también nuevas entradas de carpetas vigiladas. Las recetas utilizan la cola común y conservan los originales.
- Proyecto Xcode para generar metadatos de App Intents; SwiftPM conserva núcleo, CLI y pruebas. Empaquetado preparado para una identidad Apple configurable.
- Comparativa documentada con Kumquat y Tangerine; capturas actualizadas y atribución MIT conservada.

### Verificación

83 pruebas locales en total, sin fallos; una omitida por faltar Ghostscript. Se comprobó el paquete arm64, su firma ad hoc, la transparencia de los círculos, el proceso único, el modo sin Dock y la ejecución real de MarkItDown sobre datos sintéticos.

### Límites de esta distribución

- macOS 14+ en Apple Silicon. Las acciones de archivos de Atajos requieren macOS 15+; el asistente Apple requiere macOS 26+ y disponibilidad del sistema.
- Firma local **ad hoc**, sin notarización Apple. Las tres acciones aparecen en Atajos, pero **no se pueden ejecutar en esta copia por falta de Team ID Apple**. La CLI y las recetas de la app siguen disponibles.
- Docling dispone de adaptador; sus modelos no se instalaron ni validaron en este equipo. La estructura, tablas y fidelidad de documentos necesitan revisión.
- Los motores externos y sus dependencias se instalan por separado. La conversión normal no utiliza un LLM.

## 2.0.0 · 27 de octubre de 2026

Primera publicación de METATRON: identidad geométrica, espacio de trabajo, recetas, historial, destinos favoritos, herramientas documentales, cinco paletas y seis presentaciones. Conserva la base MIT de Kumquat y documenta Tangerine como referencia de comportamiento.
