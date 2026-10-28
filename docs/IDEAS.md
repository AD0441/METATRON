# Posibles próximas mejoras

Estas opciones son propuestas; no se anuncian como funciones integradas.

| Idea | Uso concreto | Próximo paso |
|---|---|---|
| Reglas de organización | «PDF con Informe en el nombre → Informes/2026»; revisar el plan antes de mover. | Condiciones por extensión, nombre y fecha, con simulación y registro reversible. |
| Renombrado por lotes | Prefijos, fecha, contador y sustitución de texto. | Vista previa de todos los nombres y colisiones antes de ejecutar. |
| Inspector y Quick Look | Revisar el archivo seleccionado y el resultado sin cambiar de aplicación. | Integrar el panel nativo de vista previa y metadatos mínimos. |
| Markdown con extracción estructural avanzada | Mejorar encabezados, tablas y orden de lectura de documentos complejos. | Motor opcional [MarkItDown](https://github.com/microsoft/markitdown) o [Docling](https://github.com/docling-project/docling), con instalación separada, procedencia del motor y medición en M1. |
| Compartir compatible con otros equipos | Descubrimiento y envío cifrado en LAN. | Evaluar compatibilidad real con [LocalSend](https://github.com/localsend/localsend), incluyendo recepción, TLS y pruebas con dos dispositivos. |
| Recetas favoritas con atajo propio | Un gesto para «Preparar PDF» o «Imagen para plataforma». | Asignación visible de atajos y resolución de conflictos. |

## Referencias consultadas

Se revisaron los README públicos de MarkItDown, Docling y LocalSend el 27-10-2026. MarkItDown declara conversión de múltiples formatos a Markdown; Docling añade comprensión de estructura y orden de lectura; LocalSend describe un protocolo local basado en HTTPS. Sus capacidades no implican equivalencia de la implementación nativa actual de METATRON.

## Prioridad sugerida

Primero reglas de organización y renombrado con simulación. Después vista previa, y luego motores estructurales opcionales. Así se amplía el flujo cotidiano sin cargar el arranque con modelos o procesos adicionales.
