# Criterios de aceptación: borrador para el Sprint 1

Este es un **borrador para discutir y validar con usuarios reales**: dos estudiantes nuevos y un visitante. Después de cada sesión de validación, el PO anota qué dijo el usuario y ajusta los criterios. Cuando una historia queda lista, sus criterios se copian al issue correspondiente.

Todas las historias suponen que el paquete de datos ya está instalado y que el teléfono está **sin conexión**.

## HU-01 · Buscar un aula u oficina por su nombre o código
- [ ] **Dado** que estoy en la pantalla de búsqueda, **cuando** escribo al menos 2 letras de un nombre (por ejemplo, «lab»), **entonces** veo en menos de 1 s los espacios que coinciden, sin importar mayúsculas ni tildes.
- [ ] **Dado** que escribo un código oficial completo (por ejemplo, «B1-101»), **cuando** se muestran los resultados, **entonces** ese espacio aparece primero.
- [ ] **Dado** que no hay coincidencias, **cuando** termino de escribir, **entonces** veo el mensaje «No encontramos “…”» y la lista de categorías para explorar.

*Preguntas para el usuario:* ¿Buscarías por nombre, por código o por categoría? ¿Qué escribirías para encontrar la sala de sistemas?

## HU-02 · Ver la ficha de un espacio
- [ ] **Dado** un resultado de búsqueda, **cuando** lo toco, **entonces** veo nombre, código, bloque, piso, horario, servicios y foto, y un botón «Cómo llegar».
- [ ] **Dado** que el espacio no tiene foto, **cuando** abro su ficha, **entonces** veo una imagen genérica de su categoría en lugar de un espacio vacío.

*Pregunta para el usuario:* ¿Qué dato necesitas para estar seguro de que es el lugar correcto?

## HU-03 · Elegir el origen de una lista
- [ ] **Dado** que pulsé «Cómo llegar» y no tengo origen, **cuando** se abre el selector, **entonces** veo una lista de puntos de referencia (porterías, entradas de bloque, cafetería) con buscador.
- [ ] **Dado** que elijo un punto, **cuando** confirmo, **entonces** la app lo usa como origen y lo muestra en la parte superior de la ruta, donde puedo cambiarlo.

*Pregunta para el usuario:* Cuando llegas al campus, ¿cómo describirías dónde estás?

## HU-04 · Calcular el camino más corto a pie
- [ ] **Dado** un origen y un destino conectados, **cuando** pido la ruta, **entonces** la app calcula en menos de 1 s el camino de menor distancia, el mismo que da Dijkstra en las pruebas.
- [ ] **Dado** que el destino no tiene camino desde el origen, **cuando** pido la ruta, **entonces** veo «No hay un camino registrado hasta este lugar» y la opción de reportarlo.
- [ ] **Dado** que el origen y el destino son el mismo punto, **cuando** pido la ruta, **entonces** veo «Ya estás aquí».

## HU-05 · Ver la ruta sobre el plano
- [ ] **Dado** una ruta calculada, **cuando** se abre, **entonces** veo el plano con la ruta resaltada, el origen y el destino marcados, y puedo acercar, alejar y desplazarme.
- [ ] **Dado** que la ruta pasa por puntos de referencia (por ejemplo, una portería o la entrada de un bloque), **cuando** la veo, **entonces** esos puntos aparecen con su nombre para guiarme.
- [ ] **Dado** que giro el teléfono, **cuando** cambia la orientación, **entonces** la ruta sigue visible y centrada.

*Pregunta para el usuario:* Con este plano, ¿sabrías hacia dónde caminar primero?
