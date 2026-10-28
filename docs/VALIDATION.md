# Registro de validación de METATRON

Fecha: 27 de octubre de 2026. Equipo: Apple M1 con 8 GB, macOS 27.2, Swift 6.4, compilación release.

| Área | Resultado |
| --- | --- |
| XCTest heredado | 50 pruebas, 1 omitida por Ghostscript, 0 fallos |
| Swift Testing | 25 pruebas en 10 suites, 0 fallos |
| Geometría | 13 centros, 78 conexiones, 12 posiciones de acciones separadas y dentro del lienzo |
| Integridad | Simulación sin escrituras, originales conservados, colisiones, publicación verificada y deshacer condicionado a hashes |
| Markdown | Exportación de PDF y tabla CSV, escapes de celdas, UTF-8, comprobante de salida |
| Historial | Retención de trabajos activos, plazos de 7/14/30 días; limpieza probada con datos sintéticos separados |
| PDF | Comparación, retirada rasterizada de texto y límite/orden de páginas en imagen larga |
| Firma | Paquete generado firmado ad hoc y verificado antes de copiarlo al Escritorio; ZIP de distribución sin metadatos extendidos |

## Rendimiento

La medición sintética del PDF de 24 páginas está en [performance-pdf-m1.json](performance-pdf-m1.json); la reducción de imágenes en [performance-m1.json](performance-m1.json). Se comparan las rutas concretas descritas y no el rendimiento global de la aplicación. La nueva imagen larga reduce resolución para respetar un lienzo máximo de 24 megapíxeles.

## Límites

No se verificó envío LAN entre dos equipos ni autonomía de batería. LibreOffice y Ghostscript no estaban instalados durante la validación original. Las conversiones de documentos complejos, tablas OCR y copias con texto retirado requieren revisión de salida.

Los registros completos de compilación y pruebas se conservan localmente; no se publican logs con rutas personales. Las capturas del repositorio usan datos sintéticos. La revisión independiente adicional quedó incompleta por el límite de uso del servicio; la comprobación de entrega se continúa localmente.

## Verificación de interfaz

Con una instancia separada y una tabla CSV sintética, se completaron conversiones desde el cubo, la paleta (buscando `md` y usando Enter), Burbujas, el panel y el menú compacto. Se guardó una carpeta favorita desde Ajustes, se movió la muestra y Deshacer movimiento la restauró. El favorito temporal se retiró después de capturar la demostración.

Se corrigieron el primer clic de paneles, Escape, el cierre diferido de presentaciones antiguas, el tamaño de Burbujas y la navegación Tab. Las capturas exportadas corresponden a la ventana propia, sin capturar otras aplicaciones o el escritorio.

## Corrección 2.1: integración con el entorno

Cubo y Burbujas se trasladaron al panel transparente y sin bordes de la ruleta clásica, anclado al punto de activación. El material nativo se recorta en cada círculo. El icono del archivo permanece en el centro. La capa acepta acciones solamente dentro de los círculos; los huecos no son destinos de arrastre. Las pruebas de geometría incluyen 1 a 12 burbujas, separación entre objetivos y detección de huecos.

Se simplificó una expresión de la prueba de anonimización que agotaba el comprobador de tipos de Swift en GitHub, conservando la misma comprobación de píxeles.

## Revisión local 2.2 · 28 de octubre de 2026

- Paquete release arm64 compilado con Xcode; CLI y núcleo conservan SwiftPM.
- 50 pruebas XCTest, una omitida por faltar Ghostscript, cero fallos; 33 pruebas Swift Testing en 13 suites, cero fallos.
- Casos nuevos: bloqueo de instancia, Markdown con procedencia, extracción de imagen raster incrustada con perfil ICC, PDF combinado conservando originales, adaptador documental explícito y simulación de resolución sin crear salidas.
- MarkItDown 0.1.9 ejecutado realmente desde la CLI sobre un CSV sintético; produjo Markdown y recibo verificado. Su entorno aislado está excluido del repositorio y del paquete.
- Segundo plano probado desde Ajustes: mismo proceso, política de activación accessory (sin Dock), proceso no terminado y reapertura sin duplicación.
- Capturas Cubo y Burbujas: alfa cero en las esquinas; Burbujas también conserva alfa cero en el hueco entre botones.
- Las tres acciones aparecen en el buscador de Atajos. Ejecución bloqueada por Team ID ausente en firma ad hoc, confirmada por el registro linkd. No hay identidad Apple de desarrollo disponible en el Mac.
- Docling dispone de adaptador; no se instalaron ni validaron sus modelos. Tablas y orden de lectura requieren revisión.
- La revisión independiente anterior quedó incompleta por el límite de uso de los revisores; las comprobaciones de esta sección son locales.
- Esta revisión es la base de la release 2.2.0. El ZIP distribuido se comprueba por SHA-256 y firma ad hoc antes de adjuntarlo; no se presenta como notarizado por Apple.
