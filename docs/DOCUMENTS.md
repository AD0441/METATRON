# Documentos locales

METATRON ofrece tres rutas. **Nativo** es el valor inicial y no necesita Python: PDFKit extrae texto y Vision reconoce páginas escaneadas; el paquete incluye Markdown, vistas de página, imágenes raster incrustadas compatibles y procedencia. La extracción de imágenes conserva JPEG/JPEG 2000 y admite RGB, gris, CMYK y perfiles ICC de ocho bits; las máscaras, diagramas vectoriales y otros espacios de color requieren revisión del PDF original. El registro extraccion.json informa cuántos recursos se extrajeron u omitieron. Su estructura es básica y las tablas requieren revisión.

**MarkItDown** es opcional. Convierte documentos Office, PDF y tablas a Markdown en un proceso separado. Se instala expresamente desde la raíz del proyecto:

```sh
./script/install_document_engine.sh markitdown
```

Después se selecciona en el paso «Documento estructurado» de una receta. Ajustes → Documentos permite indicar el ejecutable; la detección automática incluye `.engines/markitdown/bin/markitdown` junto al proyecto. Una app trasladada a otra carpeta puede necesitar configurar esa ruta. El entorno no se incluye en el ZIP ni en GitHub.

**Docling** dispone de un adaptador opcional para Markdown, JSON e imágenes referenciadas. Requiere instalar y preparar sus modelos por separado. METATRON configura su ejecución sin descargas automáticas de Hugging Face y con dos hilos en CPU. La disponibilidad del adaptador no equivale a una validación del modelo: no se distribuyen pesos ni se promete reconstrucción perfecta de tablas, fórmulas o columnas.

## Límites

El paso documental admite archivos de hasta 50 MB y PDF desbloqueados de hasta 40 páginas. El proceso externo tiene un límite de 180 segundos, dos hilos y salida de diagnóstico acotada. La cola de la app procesa un trabajo cada vez. La cancelación de la cola se aplica al terminar el paso activo; un proceso externo puede permanecer activo hasta su límite.

Ningún LLM interviene en las conversiones normales. Los objetivos «Preparar para la web» y «Documento para análisis» son recetas explícitas y editables. El asistente de Apple es independiente, opcional, y responde a solicitudes escritas; sus sugerencias no ejecutan operaciones.

## PDF combinado

La receta «Combinar documentos en un PDF» admite imágenes, PDF y documentos que el motor pueda convertir a PDF. Conserva las páginas PDF existentes y convierte las demás entradas en orden. Algunos formatos Office necesitan LibreOffice. La edición, fuentes y diseño pueden cambiar; revisa el resultado. Los originales se conservan.

## CLI

```sh
metatron document informe.pdf --engine native -o salida
metatron document tabla.xlsx --engine markitdown --engine-path /ruta/markitdown -o salida
metatron run foto.heic --recipe entrega.metatron.json -o salida --json
metatron goal foto.heic --goal web -o salida
metatron goal informe.pdf --goal analysis -o salida
```

El resultado publica archivos con hashes y un recibo. La simulación muestra tamaño de entrada, resolución prevista y pérdidas conocidas; el peso comprimido real solo se conoce después de ejecutar.

Referencias: [MarkItDown](https://github.com/microsoft/markitdown), [Docling](https://github.com/docling-project/docling), [App Intents](https://developer.apple.com/documentation/appintents).
