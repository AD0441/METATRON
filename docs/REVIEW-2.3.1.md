# Revisión de METATRON 2.3.1, build 9

Candidata local del 25 de noviembre de 2026. Conserva el perfil y los originales. No instala motores ni modelos adicionales.

## Comportamiento de documentos

DOC/DOCX/ODT → PDF, cuando no se usa el motor opcional LibreOffice, genera una vista previa Office con el servicio local de macOS. WebKit renderiza el HTML local con carga de red bloqueada y Core Graphics compone páginas vectoriales con las dimensiones declaradas por el documento. Los temporales se eliminan al terminar o fallar.

La reproducción privada de un formulario de una página conserva ahora logo, colores de tablas, pie y A4. No se incorpora el documento ni sus imágenes al repositorio. Un DOCX sintético multipágina independiente verifica encabezado, pie, tabla, todos los marcadores de texto, dimensiones A5 y conservación del original.

Este motor depende del generador Office de Quick Look del sistema. Si no produce HTML, presenta un error explícito. No equivale al motor de Word: fuentes ausentes, repetición de encabezados/pies, saltos manuales, campos y documentos complejos pueden cambiar. La actividad pide revisar fuentes y saltos antes de compartir. macOS 14 es el mínimo del proyecto; este nuevo recorrido se ha ejecutado localmente en macOS 27, y su cobertura en sistemas anteriores sigue pendiente.

## Destino y comprobante

Ajustes → Guardado se aplica a los trabajos nuevos del espacio de trabajo, acceso contextual, Atajos y automatización:

- Junto al original.
- Subcarpeta con nombre, validado para impedir rutas relativas fuera de la carpeta.
- Carpeta fija elegida por el usuario.

La carpeta explícita de una receta tiene prioridad. La CLI sin estos campos conserva el comportamiento anterior: subcarpeta Metatron. Simular y ejecutar comparten el mismo plan de destino.

«Guardar comprobante JSON junto al resultado» controla únicamente el recibo adicional. La integridad y los datos para deshacer siguen registrados en Actividad. Los resultados de formato JSON y los archivos propios de paquetes documentales no se eliminan. Las carpetas vigiladas rechazan destinos que coinciden con otra entrada vigilada, incluida su propia carpeta, para evitar ciclos de procesamiento.

## Revisión visual

Se implementó la propuesta 2 aprobada, «Estructura del cubo»: dos triángulos y un hexágono más marcados, conexiones secundarias tenues, bordes circulares claros, selección con texto blanco y objetivos independientes. No cambian las posiciones ni las áreas de interacción.

Se ajustaron fuentes, tamaños, contraste, espaciado y alineación en Convertir, Actividad y Ajustes. Convertir muestra el destino y el estado del comprobante antes de ejecutar. Los accesos Panel, Comandos, Compacto, Ruleta, Burbujas y Cubo mantienen el mismo catálogo contextual. El Panel dispone de más ancho para sus seis categorías.

Se generaron 49 vistas nativas de comprobación: ocho secciones y diez paneles de Ajustes en claro/oscuro, seis accesos en claro/oscuro y la ventana principal vacía en su tamaño mínimo. Se inspeccionó el primer lote, se aplicó una corrección acotada y se comprobó el lote final. Son renders de las vistas propias fuera de pantalla, con superficies sólidas; no acreditan vibrancia sobre fondos reales, foco del sistema ni nuevas pruebas interactivas de arrastre y teclado. La herramienta de control visual no pudo arrancar por un error de sandbox en una raíz de trabajo antigua; no se modificó esa configuración para eludirlo.

## Validación

La batería completa pasó: 50 XCTest y 86 pruebas Swift Testing, sin fallos ni omisiones. Incluye destinos con/sin recibo, coincidencia entre simulación y ejecución, reversión, cancelación sin salidas parciales, compatibilidad de recetas anteriores y el documento multipágina. Una primera ejecución en la copia temporal falló por no haber copiado el icono usado como fixture por una prueba existente; se añadió el recurso y se repitió correctamente la batería completa. El paquete release pasó `script/verify_package.sh`: firma ad hoc estricta de app y CLI, metadatos 2.3.1/build 9, recursos, tres App Intents y arquitectura arm64. La CLI distribuida convirtió CSV a Markdown, preservó el original y verificó hashes del recibo; la carpeta vigilada convirtió un nuevo CSV y terminó con Ctrl+C. La misma CLI convirtió la reproducción privada del Word a PDF y verificó sus hashes. La distribución conserva firma local ad hoc. No se dispone de Team ID ni notarización; la limitación conocida de ejecución de App Intents en Atajos continúa vigente.

## Seguimiento del cierre, build 10

El usuario confirmó el 25 de noviembre que las seis presentaciones ejecutan una conversión, cambian de categoría y cierran con Escape. El CI en macOS 26 pasó las pruebas y el paquete de la candidata; se omitieron tres pruebas de motores externos ausentes. La build 10 añade únicamente medición de apertura contextual sin contenido ni rutas. La aceptación prolongada y los límites de privacidad/compatibilidad se registran en acceptance/FINAL-2026-11-25.

La batería final de build 10 pasó 50 XCTest + 87 Swift Testing (137), sin fallos ni omisiones. Se comprobó además que omitir recibos conserva una salida de formato JSON. El cierre de 30 minutos verificó 80 trabajos y 160 archivos publicados, con originales y perfil del usuario intactos. Las métricas y el caso Office no ejecutable bajo sandbox anidado se conservan en el informe de cierre.
