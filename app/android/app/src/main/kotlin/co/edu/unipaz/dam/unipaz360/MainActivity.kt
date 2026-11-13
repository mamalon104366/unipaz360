package co.edu.unipaz.dam.unipaz360

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Una placa QR del campus abre la app con unipaz360://nodo/<id>. Al volver desde
    // «Recientes», Android repite el enlace de la última placa: no es una placa nueva, así que
    // la app no lo toma como si se acabara de leer.
    override fun shouldHandleDeeplinking(): Boolean {
        val desdeRecientes = (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        return !desdeRecientes && super.shouldHandleDeeplinking()
    }

    // Una placa nueva con la app abierta: su enlace reemplaza al de la tarea (si no, la
    // revisión de arriba seguiría mirando el enlace viejo).
    override fun onNewIntent(intent: Intent) {
        setIntent(intent)
        super.onNewIntent(intent)
    }
}
