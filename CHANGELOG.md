# Historial de cambios

## 2.3.0 · en desarrollo

- Audio a TXT y Markdown mediante SpeechAnalyzer/SpeechTranscriber de Apple, con macOS 26+ y hardware compatible.
- Acción contextual «Audio a texto · Apple local», dos recetas y uso desde carpetas vigiladas y terminal.
- Idioma configurable y consulta del modelo instalado. La descarga solo se inicia desde el botón o comando explícito; sin reconocimiento remoto ni resumen.
- Progreso por tiempo reconocido, cancelación del análisis y conservación del audio incluso si está activado enviar originales a la Papelera tras convertir.
- Compatible con las opciones JSON de recetas previas. Idioma opcional por receta/CLI; el valor predeterminado de la app es español de Chile.


## 2.2.1 · en preparación

Mantenimiento de estabilidad, sin nuevas capacidades de conversión.

- Cancelación y tiempo límite de motores externos con grupo de procesos, cierre de ayudantes del mismo grupo y diagnósticos acotados. Audio del sistema usa el mismo ejecutor; la exportación nativa recibe cancelación.
- Cerrar la aplicación detiene la recepción de carpetas, cancela y espera los trabajos antes de salir. Cancelar el trabajo actual conserva el resto de la cola; cancelar desde Atajos afecta solo a su lote.
- Los errores del bloqueo de inicio se explican y se distinguen de una segunda instancia. La actividad dañada se respalda antes del siguiente guardado.
- Carpetas vigiladas: parada que invalida comprobaciones pendientes, tres muestras estables de tamaño y fecha, reinicio sin repetir archivos existentes y conservación de vigilancias que no cambiaron. Se rechazan destinos que forman ciclos entre entradas vigiladas.
- Los recibos de conversión no reemplazan otro recibo si se reutiliza un identificador. Fallos y cancelación antes de confirmar la publicación retiran las salidas parciales. LibreOffice usa un perfil aislado por trabajo.
- La CLI cancela con Ctrl+C/SIGTERM y falla explícitamente al vigilar una carpeta inexistente.
- Información de versión y enlace de actualizaciones corregidos para METATRON.
- Puente de acceso rápido con raíz concreta para evitar un fallo del optimizador de Swift 6.3 al compilar release.
- CI comprueba todas las suites y el paquete real: firma, arquitectura, recursos, tres App Intents, conversión, recibo, carpeta vigilada y Ctrl+C. Versión centralizada en Info.plist y checksum regenerado al empaquetar.

Validación local: 50 pruebas XCTest (una omitida por faltar Ghostscript) y 53 Swift Testing, cero fallos. Firma ad hoc; falta identidad Apple/Team ID y notarización. Las acciones nativas de Atajos siguen pendientes de ejecución con firma Apple. Ver [informe de estabilización](docs/STABILITY-2.2.1.md).

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
