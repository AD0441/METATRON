# Privacidad y funcionamiento local

METATRON convierte, verifica, organiza y transcribe archivos en el Mac. Las conversiones normales no necesitan cuenta ni un servicio de IA remoto. No se incorpora analítica ni envío automático de documentos.

## Almacenamiento

- Actividad, recetas e índice de texto: `~/Library/Application Support/METATRON`. El índice contiene texto de los archivos que eliges indexar.
- Preferencias: dominio local `local.metatron.app` de macOS.
- Resultados: destino de Ajustes → Guardado, salvo carpeta explícita de receta.
- Comprobantes opcionales: contienen rutas locales, tamaños y hashes. Revísalos antes de compartirlos. Omitir el JSON adicional no elimina Actividad ni los archivos propios de un paquete documental.
- Deshacer verifica el hash antes de mover salidas a `~/Library/Application Support/METATRON/Undo/<identificador>`. Retirar el historial elimina el acceso a esa acción; no elimina los archivos generados o de recuperación.
- Los temporales se retiran al terminar, fallar o cancelar, dentro de los límites de cancelación de cada motor.

La medición de apertura contextual usa el registro unificado del sistema: presentación, número de archivos y duración. No registra nombres, rutas ni contenido.

## Conexiones explícitas

Consultar versiones, donar o abrir enlaces abre el navegador por petición del usuario. No hay comprobación de actualizaciones en segundo plano. Descargar un idioma de Apple Speech requiere su botón o comando de instalación; la transcripción utiliza el idioma local ya preparado.

El asistente opcional Foundation Models depende de disponibilidad y recursos preparados por macOS. Recibe lo que escribes; no lee archivos ni ejecuta conversiones por su cuenta. Los motores externos no se instalan automáticamente y deben revisarse por separado.

Compartir por LAN crea un servidor HTTP temporal cuando lo solicitas. No ofrece todavía TLS ni compatibilidad LocalSend. Úsalo en una red de confianza y detén el enlace al terminar.

## Office a PDF

Quick Look genera la vista previa local. WebKit usa almacenamiento no persistente, JavaScript de página desactivado, política de contenido local y bloqueo HTTP/HTTPS en el renderizador. Fuentes, campos y encabezados complejos pueden variar. Esta protección no equivale a una auditoría de todos los servicios compartidos de macOS.

## Alcance de las pruebas

El informe de cierre registra los escenarios ejecutados con archivos sintéticos, restricción de red y observación del proceso gráfico. Las pruebas no certifican motores opcionales ajenos, todos los documentos posibles ni los servicios compartidos del sistema.
