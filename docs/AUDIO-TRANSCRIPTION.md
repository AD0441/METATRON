# Audio a texto · Apple local

Función de la rama 2.3, separada de la candidata de mantenimiento 2.2.1. La release pública sigue siendo 2.2.0. Solo transcripción a TXT o Markdown; no genera resúmenes ni utiliza Foundation Models en esta ruta.

## Requisitos y privacidad

macOS 26 o posterior, hardware compatible con SpeechTranscriber y un idioma admitido por Apple. La disponibilidad se consulta en el equipo. Se utilizan SpeechAnalyzer y SpeechTranscriber, que procesan el audio en el dispositivo; no se usa SFSpeechRecognizer ni un reemplazo en la nube.

Los modelos pertenecen al sistema y se comparten entre aplicaciones. Si falta un idioma, la conversión termina con una explicación. Solo **Descargar idioma desde Apple…** en Ajustes o el comando **speech-install** inicia una instalación y requiere Internet. Consultar disponibilidad o convertir no llama a downloadAndInstall. El inventario puede mostrar un modelo como compatible hasta que se reserve; la conversión reserva el idioma antes de comprobar que está preparado, y libera su reserva temporal al finalizar.

Los archivos se leen mediante AVAudioFile y el analizador nativo, sin cargar la grabación completa en un Data. Los formatos no decodificables por AVFoundation requieren FFmpeg instalado; se prepara una copia WAV temporal local, limitada a cuatro horas más un segundo para detectar/rechazar grabaciones excesivas. No se instala FFmpeg automáticamente.

## Uso

1. En **Ajustes → Documentos → Audio a texto**, elige el idioma de la grabación. La app usa es-CL por defecto.
2. Abre un audio en las acciones contextuales. **TXT** y **Markdown** aparecen como conversiones; **Audio a texto · Apple local** produce TXT desde Herramientas.
3. También puedes elegir las recetas **Audio a texto · Apple local** y **Audio a Markdown · Apple local**. Son accesibles desde la cola y desde las reglas de carpetas vigiladas.
4. Actividad informa el progreso y permite cancelar. La publicación usa las verificaciones, hashes, recibos y resolución de colisiones del motor de recetas.

La transcripción siempre conserva el audio; no se aplica la preferencia de enviar originales a la Papelera en estas conversiones. Una transcripción no sustituye la grabación. TXT contiene el texto reconocido; Markdown añade título, idioma y aviso de revisión. No se promete reconocimiento literal perfecto, identificación de hablantes ni separación automática de idiomas. Revisa nombres, cifras y puntuación.

```sh
metatron-cli speech-status --locale es-CL
# Acción explícita, solo si el modelo falta:
metatron-cli speech-install --locale es-CL
metatron-cli transcribe reunion.m4a --to txt --locale es-CL -o salida
metatron-cli transcribe reunion.mp3 --to md --locale es-ES -o salida
metatron-cli convert reunion.wav --to md --locale es-CL
```

El paso tool.transcribeAudio permite fijar el idioma en su campo de receta; vacío utiliza el idioma guardado en Ajustes. conversionOptions.speechLocale es opcional para conservar compatibilidad con recetas previas. Desde la CLI puede usarse --locale también con run y watch.

## Límites y validación

- Una tarea pesada por vez en la app. Máximo cuatro horas por archivo y un millón de caracteres reconocidos; límites explícitos, sin truncado silencioso.
- Cancelación propagada al analizador nativo. Una operación cancelada antes de confirmar no publica resultados parciales.
- No captura micrófono ni sonido del sistema. Solo lee los archivos elegidos.
- En un M1 de 8 GB con macOS 27 se transcribió realmente una grabación sintética en español, con el modelo es_CL existente, sin instalar otros modelos. El resultado conservó el contenido y generó Markdown y recibo. También se verificó cancelación de una copia sintética larga: salida CLI 130, original intacto y sin salidas parciales.
- Las pruebas automáticas normales cubren catálogo, compatibilidad JSON, TXT/Markdown, cancelación previa y simulación. No descargan modelos ni presuponen idiomas instalados en CI.
- Para repetir la prueba nativa, usa script/verify_speech.sh. Si el idioma o la voz de prueba no están instalados, termina con código 77; no los descarga.

La firma sigue siendo local ad hoc. La transcripción real desde la CLI se ha probado con esa firma; el bloqueo de Team ID de las acciones nativas de Atajos permanece separado.

Fuentes: [SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer), [modelos e instalación](https://developer.apple.com/documentation/speech/assetinventory), [privacidad del reconocimiento](https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition).
