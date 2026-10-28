# Revisión antes de la siguiente publicación

La versión pública 2.0 y el código previamente enviado permanecen en GitHub. Los cambios de esta revisión se preparan localmente y requieren completar la validación antes de publicar otra versión.

| Frente | Implementación | Límite práctico |
| --- | --- | --- |
| Recetas | Pasos ordenados, importación/exportación, cola serial, accesos contextuales y CLI | Una operación no compatible falla conservando originales |
| Documentos | OCR local, Markdown, procedencia, PDF combinado, adaptadores MarkItDown/Docling | Estructura y tablas requieren revisión; Docling requiere modelos locales |
| Carpetas inteligentes | Vigilancia por eventos y recetas guardadas | Pausar detiene nuevas entradas; no cancela el trabajo activo |
| Automatización | CLI, servicio Finder y acciones App Intents | Las tres acciones aparecen en Atajos; ejecución bloqueada por falta de Team ID en firma ad hoc |
| Calidad | Simulación, validación, hashes, recibos, historial, recuperación de salidas | No hay estimación exacta de compresión antes de ejecutar |
| Inteligencia local | Objetivos mediante recetas y asistente Apple opcional | No se incluye un modelo propio ni se ejecutan sugerencias automáticamente |
| Ciclo de vida | Bloqueo de instancia, ventana recuperable, menú superior y modo sin Dock | Cierre, reapertura, proceso único y política accessory sin Dock comprobados |

Los círculos de Cubo de Metatrón y Burbujas utilizan el panel transparente de la ruleta clásica. Los menús compacto, panel y comandos conservan una superficie rectangular porque son presentaciones de lista elegidas expresamente.

## Bloqueo confirmado en Atajos

La app empaqueta OpenMetatronIntent, PrepareFilesIntent y RunRecipeIntent. Las tres acciones aparecen en el buscador nativo de Atajos. La ejecución devuelve LinkDaemon.ProcessRegistry.Errors 0. El registro del sistema indica `Unable to get teamId from local.metatron.app`; este Mac no tiene identidades Apple de desarrollo disponibles. No se considera una función validada de esta compilación ad hoc.

El script admite `METATRON_SIGN_IDENTITY` para firmar con una identidad Apple válida. Con ella, se debe repetir la prueba de ejecución antes de publicar. La CLI y las recetas de la app están verificadas y permiten automatización local mientras tanto.
