# METATRON 2.3.1 · build 10

Entrega para Apple Silicon, 25 de noviembre de 2026. Intelligent File Workflow for macOS.

## Cambios principales

- Integra la estabilización de cancelación, errores, ciclo de vida y carpetas vigiladas, y la transcripción local de Apple de 2.3. La transcripción entrega TXT o Markdown, conserva el audio y no genera resumen.
- Word a PDF mediante vista previa local de macOS cuando no se usa LibreOffice: conserva logo, colores y A4 del formulario reproducido y mantiene texto y dimensiones en un DOCX sintético multipágina. No instala LibreOffice ni cambia los originales.
- Ajustes → Guardado: junto al original, subcarpeta o carpeta fija. Las recetas con carpeta explícita conservan su prioridad. Simulación y ejecución comparten el destino.
- Comprobante JSON opcional, conservando verificación y reversión en Actividad. Los resultados JSON y el contenido propio de paquetes documentales no se eliminan.
- Cubo con dos triángulos y hexágono reforzados, trama secundaria tenue y superficies circulares independientes. Tipografía, contraste, espaciado y controles revisados en las ventanas y los seis accesos. Convertir muestra destino y estado del comprobante antes de ejecutar.
- Medición local de preparación/apertura contextual con número de archivos y duración, sin rutas ni contenido en los registros.

## Instalación y paquete

Descarga METATRON.zip de la release y coloca METATRON.app en Aplicaciones. SHA256SUMS.txt permite comprobar el ZIP descargado. La firma es local ad hoc, sin notarización Apple; conserva el procedimiento habitual de autorización de apertura que ofrece macOS.

No hace falta una cuenta para convertir ni transcribir con un idioma local ya instalado. Consulta PRIVACY.md y AUDIO-TRANSCRIPTION.md para preparar los recursos opcionales.

## Compatibilidad y límites

- Paquete arm64 para Apple Silicon. Comprobado en M1/8 GB con macOS 27.3 y en CI sobre macOS 26. El binario declara mínimo macOS 14; la ejecución en 14–25 se considera experimental hasta completar esa matriz.
- Apple Speech y Foundation Models requieren macOS 26+, disponibilidad del sistema e idioma/modelo preparados. No se incluyen modelos propios ni se descargan sin la acción correspondiente.
- Las tres acciones aparecen en Atajos, pero su ejecución no está validada con esta firma: falta Team ID Apple. Se mantiene la firma local elegida; CLI y recetas permiten automatización local.
- Office: fuentes ausentes, campos, saltos y repetición de encabezados/pies complejos pueden variar. Revisa el resultado antes de compartir. El recorrido depende del generador Office de Quick Look del sistema.
- La primera preparación de OCR de Vision puede tardar mucho más que las siguientes; se conservan las muestras lentas en los informes. No se ha reiniciado el Mac ni borrado cachés del sistema para simular un arranque frío.
- Las ráfagas de muchas aperturas simultáneas pueden demorar el renderizado. El objetivo de apertura se midió secuencialmente, sin incluir el compositor.
- VoiceOver completo, segunda pantalla, otros escalados y grabaciones reales ruidosas siguen en el plan de validación. La confirmación manual cubre conversión, cambio de categoría y Escape en los seis modos.
- LAN mantiene un enlace HTTP temporal sin cifrado. Docling, motores externos y organización condicional avanzada tienen alcances separados.

## Evidencia

La revisión de la candidata está en REVIEW-2.3.1.md. El cierre prolongado y la prueba de privacidad se registran en acceptance/FINAL-2026-11-25. La matriz vigente contiene 90 requisitos y distingue funciones implementadas, alcances parciales y ampliaciones posteriores; esta release no afirma que todos los requisitos futuros estén terminados.
