# Aportar a METATRON

Gracias por contribuir. Preferimos cambios concretos, pequeños y verificables.

1. Abre un issue para un error o una propuesta. Explica el archivo de entrada, resultado esperado, versión de macOS y motores disponibles.
2. Usa archivos sintéticos o anonimizados. No adjuntes documentos personales, contraseñas ni material con restricciones de redistribución.
3. Crea una rama, conserva las atribuciones y modifica las pruebas cuando el comportamiento lo requiera.
4. Ejecuta `./script/test.sh` y `./script/build_and_run.sh --verify`. Indica las pruebas omitidas y sus dependencias.
5. Envía un pull request con el problema, el cambio observable y la validación. Para interfaz, incluye capturas con datos de prueba; para rendimiento, mediciones release antes/después y sus límites.

## Entorno

macOS, Xcode y Swift 6.2+. La app y los módulos nuevos usan Swift 6; el conversor heredado conserva compatibilidad Swift 5. Swift Testing cubre el flujo nuevo; XCTest conserva el corpus de la base. Los motores externos son opcionales y deben detectarse sin descargarse a escondidas.

## Criterios

- Conserva originales en conversiones y evita sobrescrituras.
- Mantén foco, teclado, arrastre y accesibilidad en todos los accesos.
- No introduzcas temporizadores decorativos ni modelos cargados al iniciar.
- Mide memoria, latencia y resolución antes de afirmar mejoras.
- Declara límites de fidelidad y licencias de nuevas dependencias.

Las contribuciones se distribuyen bajo la licencia MIT del repositorio. No hace falta realizar una donación para contribuir o usar el código.
