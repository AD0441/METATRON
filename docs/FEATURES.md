# Alcance de METATRON 2.0

Las capacidades dependen del formato concreto, los codificadores disponibles y la versión de macOS. La rueda consulta el catálogo de acciones del equipo. Esta tabla distingue funcionamiento implementado de equivalencia completa con otras aplicaciones.

| Área | Implementado | Límites y dependencias |
|---|---|---|
| Imágenes | Conversión entre formatos ImageIO disponibles, WebP, reducción, compresión, recorte, fondo, giro, reflejo, blanco y negro, eliminación de metadatos, OCR y recorte de sujetos. | WebP necesita cwebp o FFmpeg; no todos los formatos conservan transparencia, animación o metadatos. Incluye anotación con lápiz, rectángulos, texto y ocultación de regiones, con copia PNG. |
| PDF | Imágenes por página, texto, documentos editables, unir, dividir, girar, proteger, comprimir y una imagen larga. | La conversión editable puede perder diseño. La compresión fuerte rasteriza páginas; Ghostscript mejora ciertas rutas cuando está instalado. |
| Markdown | Salida directa desde PDF, documentos, imágenes (OCR), tablas y subtítulos; receta dedicada, acciones y CLI. | Estructura básica; PDF por páginas, tablas de datos y énfasis/enlaces de documentos. No equivale a MarkItDown o Docling. |
| Organización | Carpetas favoritas con nombre y orden; cuarta página de destinos, barra de favoritos y movimientos reversibles. | Se deshace el último movimiento registrado. La ruleta muestra hasta 12 favoritos; los otros modos muestran todos. |
| Actividad | Buscar, filtrar, exportar JSON, limpiar registros y retención ilimitada/7/14/30 días. | Retirar un registro elimina su acceso a deshacer la conversión; conserva archivos y trabajos activos. |
| Documentos | Lectura/escritura de formatos de texto, Word, RTF, HTML, ODT y EPUB; PDF mediante AppKit o LibreOffice disponible. | No reproduce todos los elementos de Word/Pages/Keynote. No hay un escritor nativo de Pages. |
| Hojas y datos | CSV, TSV, XLSX, JSON y PLIST, con exportaciones tabulares. | El contenido tabular no equivale a preservar todas las fórmulas, gráficos y estilos de una planilla compleja. Office antiguo y algunos formatos necesitan LibreOffice. |
| Audio y vídeo | Conversiones nativas y FFmpeg, GIF, compresión, silencio, fotogramas; recorte y unión de vídeo; normalización y mono. | Los códecs dependen del equipo. Normalización/mono usan FFmpeg; unión comprueba orientación y puede requerir normalizar previamente los clips. No incluye una línea de tiempo de edición completa. |
| Subtítulos y archivos | SRT/VTT/TXT; ZIP/TAR.GZ y extracción con herramientas del sistema. | La compatibilidad de extracción depende de libarchive en macOS. |
| Recetas | Varios pasos, opciones, destino, sufijo, importar/exportar, simulación y cola por archivo. | Los pasos incompatibles fallan con explicación. Los parámetros de editores y contraseñas se vuelven a pedir al repetir esas operaciones. |
| Integridad | Área temporal, validación, hashes, comprobante, colisiones y deshacer condicionado a que la salida no haya cambiado. | El comprobante conserva rutas locales. El archivo de recuperación se guarda en Application Support/METATRON/Undo. |
| Automatización | Carpetas vigiladas por eventos, estabilidad del archivo y cola común. | Procesa nuevas entradas directas; no organiza recursivamente toda una biblioteca histórica. |
| Comparación | Diferencias visuales de PDF resaltadas por página, porcentaje de píxeles y exportación de imágenes. | No es un comparador semántico de contenido ni establece equivalencia de firmas digitales. |
| Investigación | Markdown por páginas, previews y JSON con método de extracción. | No usa Docling ni reconstruye con garantía tablas, fórmulas o jerarquías semánticas. |
| PDF a CSV | OCR y agrupación de cuadros de texto por filas. | La identificación de columnas y celdas requiere revisión; no es un reconocimiento garantizado de tablas. |
| Anonimización | Búsqueda de textos en PDF y OCR en páginas escaneadas; copia rasterizada sin texto recuperable. | Se deben revisar visualmente los resultados. No es detección exhaustiva de datos sensibles. Páginas rotadas deben normalizarse antes. |
| Biblioteca | Índice local de texto y etiquetas por reglas. | No sustituye a Paperless-ngx; no incorpora sus funciones de servidor, correo o multiusuario. |
| IA | Vision OCR y sujetos; asistente de Foundation Models disponible según el sistema. | No se entrenó un modelo propio y no se garantiza la colocación en Neural Engine. |
| Compartir | Panel nativo de macOS/AirDrop y enlace LAN temporal de un archivo. | LAN usa HTTP sin cifrado y no implementa el protocolo LocalSend. No se ha validado entre dos equipos. |
| Interfaz | Ventana SwiftUI en español, cuatro páginas de rueda; cubo de Metatrón y Burbujas flotantes sin marco, ruleta clásica, menú compacto, panel, y comandos elegibles; cinco paletas de color, atajos, ajustes y menú de barra. | La base conserva traducciones adicionales en sus ajustes; las pantallas nuevas se redactaron en español. |

## Límites frente a los proyectos de referencia

Anonimización avanzada por patrones, extracción semántica equivalente a Docling, intercambio compatible con LocalSend con cifrado y equivalencia completa de todas las conversiones de Tangerine. Estas capacidades no se anuncian como implementadas.
