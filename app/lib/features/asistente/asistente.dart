/// Asistente de UniPaz360: un chatbot que guía hasta cualquier lugar del campus **sin internet**.
///
/// Entiende la frase con reglas («¿cómo llego a la biblio?», «llévame al B2-201 sin escaleras»),
/// tolera errores de escritura, pregunta lo que falta (desde dónde sales, cuál de varios lugares)
/// y responde con la ruta paso a paso del motor de rutas. Todo sale del paquete de datos.
///
/// ```dart
/// final asistente = Asistente(FuenteGuia(grafo: grafo, espacios: espacios));
/// final r = asistente.responder('¿cómo llego a la biblioteca?', contexto: Contexto(nodoActual: 'V001'));
/// print(r.texto);                                // Ruta lista hasta la Biblioteca: 1 min (65 m).
/// for (final p in r.pasos) print(p.texto);
/// ```
library;

export 'analisis.dart' show Intencion;
export 'conocimiento.dart' show FuenteGuia, Lugar, aLugar, conArticulo, hastaLugar;
export 'motor.dart';
export 'respuesta.dart';
