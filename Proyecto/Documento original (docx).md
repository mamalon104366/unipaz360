**UNIPAZ360: DESARROLLO DE UNA APLICACIÓN MULTIPLATAFORMA PARA LA ORIENTACIÓN, NAVEGACIÓN Y RECORRIDO VIRTUAL DEL CAMPUS DEL CENTRO DE INVESTIGACIONES SANTA LUCÍA DEL INSTITUTO UNIVERSITARIO DE LA PAZ – UNIPAZ**

ESTEBAN DAVID MERLANO QUINTANA

JUAN ANDRES RANGEL FRENANDEZ

INSTITUTO UNIVERSITARIO DE LA PAZ – UNIPAZ

ESCUELA DE CIENCIAS

INGENIERÍA INFORMÁTICA

BARRANCABERMEJA

2026

**UNIPAZ360: DESARROLLO DE UNA APLICACIÓN MULTIPLATAFORMA PARA LA ORIENTACIÓN, NAVEGACIÓN Y RECORRIDO VIRTUAL DEL CAMPUS DEL CENTRO DE INVESTIGACIONES SANTA LUCÍA DEL INSTITUTO UNIVERSITARIO DE LA PAZ – UNIPAZ**

ESTEBAN DAVID MERLANO QUINTANA

JUAN ANDRES RANGEL FRENANDEZ

Proyecto de grado presentado como requisito para optar al título de ingeniero informático

Director

[NOMBRE Y TÍTULO ACADÉMICO DEL DIRECTOR]

Codirector

[NOMBRE Y TÍTULO ACADÉMICO DEL CODIRECTOR]

INSTITUTO UNIVERSITARIO DE LA PAZ – UNIPAZ

ESCUELA DE CIENCIAS

INGENIERÍA INFORMÁTICA

BARRANCABERMEJA

2026

**CONTENIDO**

pág.

[1. PLANTEAMIENTO DEL PROBLEMA 4](#_Toc241778649)

[2. JUSTIFICACIÓN 6](#_Toc241778650)

[3. OBJETIVOS 8](#_Toc241778651)

[3.1 OBJETIVO GENERAL 8](#_Toc241778652)

[3.2 OBJETIVOS ESPECÍFICOS 8](#_Toc241778653)

[4. ESTADO DEL ARTE 9](#_Toc241778654)

[4.1 CRITERIOS DE LA REVISIÓN 9](#_Toc241778655)

[4.2 ÁMBITO MUNICIPAL 9](#_Toc241778656)

[4.2.1 Mapa Interactivo de Barrancabermeja 9](#_Toc241778657)

[4.2.2 Ausencia de un segundo antecedente municipal 10](#_Toc241778658)

[4.3 ÁMBITO DEPARTAMENTAL 10](#_Toc241778659)

[4.3.1 UIS-ARMobile: realidad aumentada para la ubicación geolocalizada de lugares de interés 11](#_Toc241778660)

[4.3.2 UISMaps: sistema de información geográfico móvil para la navegación en el campus 12](#_Toc241778661)

[4.4 ÁMBITO NACIONAL 13](#_Toc241778662)

[4.4.1 UVManos: hacia un campus universitario inteligente en la Universidad del Valle 13](#_Toc241778663)

[4.4.2 Smart Map Javeriana: rutas inteligentes sobre un modelo tridimensional del campus 14](#_Toc241778664)

[4.5 ÁMBITO INTERNACIONAL 15](#_Toc241778665)

[4.5.1 Sistema sin conexión para navegación interior en dos dimensiones 15](#_Toc241778666)

[4.5.2 Efecto de la ayuda de navegación y de las habilidades espaciales en el recorrido de un campus 16](#_Toc241778667)

[4.6 SÍNTESIS DE LA REVISIÓN Y VACÍO IDENTIFICADO 17](#_Toc241778668)

[BIBLIOGRAFÍA 20](#_Toc241778669)

# PLANTEAMIENTO DEL PROBLEMA

El Instituto Universitario de la Paz – UNIPAZ<sup>1</sup> es un establecimiento público de educación superior del orden departamental, creado mediante el Decreto Ordenanzal 0331 del 19 de noviembre de 1987, con sede en el Distrito de Barrancabermeja, Santander. Su campus principal, el Centro de Investigaciones Santa Lucía, se ubica en zona rural, en el kilómetro 14 de la vía Barrancabermeja – Bucaramanga, y agrupa bloques de aulas, laboratorios, áreas experimentales, oficinas administrativas, biblioteca y escenarios deportivos. Por él circula una población que se renueva cada semestre, conformada por estudiantes, docentes, personal administrativo, asistentes a eventos y aspirantes. Además, la cobertura de datos móviles es irregular en varias zonas del campus, mientras que el uso de teléfonos inteligentes en la comunidad universitaria es generalizado.

Pese a estas condiciones, UNIPAZ no dispone de una herramienta digital de orientación: no existe un mapa interactivo del campus, un buscador de aulas, oficinas, laboratorios o servicios, ni un sistema que calcule la ruta hacia un destino, por lo que la ubicación depende de la señalización física y de la consulta a terceros. Estas carencias coinciden con las dos preguntas que, según Rincón-Romero, Muñoz Herrera y Leal Guancha<sup>2</sup>, debe resolver una herramienta de movilidad en un campus universitario: “¿en dónde queda?” y “¿cómo llego a…?”. A su vez, los aspirantes no cuentan con un recorrido virtual que les permita conocer las instalaciones sin desplazarse. En consecuencia, la comunidad universitaria y los visitantes no pueden ubicarse ni desplazarse de forma autónoma dentro del campus, y quienes están fuera de él no pueden conocerlo de manera remota.

Esta situación genera pérdida de tiempo y retrasos en la llegada a clases, en especial entre estudiantes de primeros semestres, y obliga a recurrir a mapas de uso general que exigen conexión activa, no representan interiores ni pisos y desconocen la nomenclatura institucional. El conocimiento sobre la ubicación de los espacios se transmite de manera informal y se pierde cuando los estudiantes egresan, y porterías y secretarías atienden consultas ajenas a sus funciones. Para las personas con movilidad reducida, desconocer si una ruta es transitable equivale a no poder recorrerla, condición que la institución, como entidad pública, debe atender en el marco de la Ley 1618 de 2013<sup>3</sup> y de la Resolución 1519 de 2020 del Ministerio de Tecnologías de la Información y las Comunicaciones<sup>4</sup>. Asimismo, los aspirantes deciden sin conocer el campus y la institución carece de información digital de sus propios espacios.

Desde el punto de vista técnico, el problema obedece a cuatro limitaciones. Primera, los planos existentes son documentos estáticos: calcular una ruta exige representar el campus como un grafo de puertas, pasillos, escaleras, rampas y accesos, con tramos ponderados por distancia, desnivel y accesibilidad. Segunda, la conectividad intermitente impide consultar un servidor en cada búsqueda, por lo que el mapa y el cálculo de rutas deben operar con datos almacenados en el dispositivo, enfoque cuya utilidad en entornos de conectividad limitada demostraron Veloz et al.<sup>5</sup> Tercera, el GPS pierde precisión bajo cubierta y no distingue pisos, por lo que el origen debe definirse manualmente o mediante códigos QR. Cuarta, los mapas de terceros no modelan interiores ni admiten la nomenclatura institucional, y la diversidad de dispositivos Android, iOS y de escritorio exige una única base de código multiplataforma.

A partir de lo expuesto, se plantea la siguiente pregunta de investigación: ¿cómo puede una aplicación multiplataforma desarrollada en Flutter facilitar la localización de espacios, el cálculo de rutas peatonales sin conexión a internet y el reconocimiento virtual de las instalaciones del Centro de Investigaciones Santa Lucía del Instituto Universitario de la Paz – UNIPAZ, para estudiantes, docentes, personal administrativo, aspirantes y visitantes?

# 2. JUSTIFICACIÓN

La orientación dentro del Centro de Investigaciones Santa Lucía es una necesidad permanente y no un contratiempo ocasional: cada semestre ingresan estudiantes nuevos y la población del campus rota de manera continua, de modo que la demanda se renueva sin cesar y hoy se resuelve por medios informales que la institución no controla ni puede mantener. Atenderla de forma estable exige una herramienta propia, y las condiciones para desarrollarla ya están dadas: la penetración de teléfonos inteligentes en la comunidad universitaria es alta, un solo desarrollo cubre los distintos dispositivos y la solución no demanda obra física ni equipos adicionales. UniPaz360 se desarrolla, entonces, porque lo que falta no son más avisos en los pasillos, sino una herramienta que responda, cada semestre y para cada persona que llega, lo que hoy solo puede responder alguien que ya conozca el campus.

Como se evidencia en el proyecto de la Universidad del Valle en el que se implementó UVManos<sup>6</sup> para el campus Meléndez, de 100 hectáreas y 18 kilómetros de caminos, el usuario busca el sitio al que necesita llegar y el sistema le indica dónde queda, la ruta, la distancia y el tiempo estimado de recorrido, y lo hace sin conexión a internet. Ese antecedente muestra qué resultado puede esperarse en un campus colombiano de escala comparable. UniPaz360 aportará a Santa Lucía una aplicación que ubica cualquier aula, laboratorio, oficina o servicio, entrega la ruta para llegar hasta él, contempla rutas accesibles y permite recorrer virtualmente las instalaciones a quien no puede visitarlas.

El beneficio directo corresponde al estudiante de primeros semestres, que llega sin conocer el campus, y al estudiante avanzado cuando una asignatura lo envía a un espacio que no conoce. Beneficia también a docentes y personal administrativo que deben ubicar espacios fuera de su rutina habitual; a los aspirantes y estudiantes de bachillerato de municipios vecinos, que podrán conocer las instalaciones sin asumir el costo del desplazamiento; y a los visitantes ocasionales y asistentes a eventos. Un beneficio de especial peso corresponde a las personas con movilidad reducida, para quienes desconocer si una ruta es transitable equivale a no poder recorrerla, y que dispondrán de un modo de ruta accesible. De manera indirecta se benefician porterías y secretarías, que dejarán de absorber consultas de ubicación, y la propia institución, que tendrá en formato consultable la información de sus espacios, hoy transmitida de boca en boca y perdida cuando los estudiantes se gradúan.

UniPaz360 convierte en información digital, verificable y actualizable lo que hoy solo existe como conocimiento oral: quien sabe dónde queda cada aula, laboratorio u oficina lo sabe porque alguien se lo dijo, y ese saber se pierde cuando esa persona se gradúa o se traslada. La institución no posee ese dato en ningún formato consultable, de modo que cada semestre debe reconstruirse de cero por vías informales que nadie administra. Con la aplicación, la información de los espacios del Centro de Investigaciones Santa Lucía queda registrada, bajo control de UNIPAZ y disponible para cualquiera que la necesite, sin depender de que exista un intermediario dispuesto a explicarla. El proyecto no se limita entonces a resolver la orientación de quien hoy se pierde: deja a la institución en posesión de un activo de información que antes no tenía y que ninguna otra iniciativa está produciendo.

# 3. OBJETIVOS

## 3.1 OBJETIVO GENERAL

Desarrollar una aplicación multiplataforma que permita localizar espacios, calcular rutas sin conexión a internet y realizar recorridos virtuales, con el fin de facilitar la orientación y el reconocimiento de las instalaciones de la UNIPAZ.

## 3.2 OBJETIVOS ESPECÍFICOS

* Analizar las necesidades de orientación y las características de los espacios institucionales, para establecer los requerimientos funcionales de la aplicación.
* Diseñar la estructura de navegación y la interfaz de la aplicación, para organizar de forma clara la consulta de espacios, rutas y recorridos virtuales.
* Codificar la aplicación multiplataforma con las funcionalidades de localización, cálculo de rutas sin conexión a internet y recorrido virtual, para facilitar la orientación y el reconocimiento de las instalaciones de la UNIPAZ.
* Evaluar el funcionamiento de la aplicación mediante pruebas funcionales y de usabilidad con estudiantes y visitantes, para verificar que la localización, el cálculo de rutas sin conexión y el recorrido virtual cumplan con los requerimientos establecidos.

# 4. ESTADO DEL ARTE

## 4.1 CRITERIOS DE LA REVISIÓN

La revisión se orientó a identificar desarrollos que abordaran, total o parcialmente, el problema que origina este proyecto: la orientación peatonal dentro de un campus universitario resuelta por medios digitales. Los descriptores empleados fueron aplicación móvil, navegación en campus universitario, mapa interactivo, sistema de información geográfica, cálculo de rutas peatonales, navegación sin conexión, recorrido virtual y accesibilidad, combinados entre sí y consultados en español e inglés.

Se examinaron los repositorios institucionales Noesis de la Universidad Industrial de Santander, el de la Pontificia Universidad Javeriana, el de la Universidad Autónoma de Bucaramanga y el de la Universidad Distrital Francisco José de Caldas; la Red Colombiana de Información Científica; las bases Dialnet, Crossref y MDPI; y los portales de las entidades públicas del Distrito de Barrancabermeja. La ventana temporal comprende de 2013 a 2025.

Los trabajos se exponen por alcance geográfico ascendente municipal, departamental, nacional e internacional y de cada uno se consignan título, objetivo general, pregunta problema, metodología y resultados. Varios de los documentos revisados, por tratarse de trabajos de grado de corte tecnológico, no enuncian una pregunta de investigación formal; en esos casos la pregunta se deriva del problema que sus autores declaran, sin alterar su alcance.

## 4.2 ÁMBITO MUNICIPAL

La búsqueda en el Distrito de Barrancabermeja arrojó un solo desarrollo con vocación cartográfica y ninguno con capacidad de navegación. El resultado es en sí mismo un hallazgo y se documenta como tal.

### 4.2.1 Mapa Interactivo de Barrancabermeja

El Mapa Interactivo de Barrancabermeja fue desarrollado por Jaime Camilo Tolosa Herazo<sup>7</sup>, estudiante de Ingeniería Industrial de la Universidad Cooperativa de Colombia, sede Barrancabermeja, y se encuentra publicado de manera abierta en un portal de divulgación local.

Tiene como objetivo poner a disposición del público un mapa digital consultable que reúna los aspectos históricos, culturales y geográficos del municipio, con propósito educativo. La pregunta que lo articula es cómo representar digitalmente esa información para que resulte consultable por cualquier ciudadano desde un navegador web.

El desarrollo se resuelve sobre Leaflet, biblioteca de código abierto para cartografía web, sobre la cual se disponen capas vectoriales de puntos de interés servidas desde teselas de un proveedor externo. No se reporta levantamiento de requerimientos con usuarios, ciclo formal de ingeniería de software ni fase de evaluación funcional o de usabilidad: se trata de una iniciativa individual de divulgación, no de un proyecto de investigación aplicada.

El resultado es un mapa web publicado y en ampliación permanente. Su alcance, sin embargo, difiere del que persigue UniPaz360 en cuatro aspectos determinantes: opera a escala urbana y no institucional; no modela interiores ni niveles de edificación; no dispone de un grafo de tramos transitables y, por tanto, no calcula rutas entre origen y destino; y no contempla operación sin conexión. Constituye un antecedente de contexto, no un antecedente funcional.

No se identificó en el ámbito municipal ningún otro proyecto académico o institucional que resuelva la orientación peatonal dentro de un campus, calcule rutas sin conexión a internet o permita el reconocimiento remoto de unas instalaciones.

La revisión del portafolio digital del Distrito confirma la ausencia desde el lado institucional: la Sede Electrónica y la aplicación móvil de la Alcaldía<sup>8</sup>, en servicio desde diciembre de 2020, concentran sus funciones en trámites tributarios, expedición de certificados y radicación de reportes ciudadanos, sin módulo cartográfico ni de localización. La búsqueda en repositorios de las instituciones de educación superior con presencia en el municipio no arrojó trabajos de grado sobre la materia.

Esta ausencia delimita el aporte del presente proyecto: UniPaz360 sería el primer desarrollo de su tipo en el Distrito de Barrancabermeja.

## 4.3 ÁMBITO DEPARTAMENTAL

En Santander la producción se concentra en la Universidad Industrial de Santander, donde el problema fue abordado en dos trabajos de grado sucesivos separados por dos años, con un cambio deliberado de enfoque técnico: del reconocimiento visual del entorno al cálculo de trayectorias.

### 4.3.1 UIS-ARMobile: realidad aumentada para la ubicación geolocalizada de lugares de interés

Carlos Enrique Díaz Aranda y Gabriel Fernando Pérez Arenas<sup>9</sup> presentaron en 2013, bajo la dirección de Hernán Porras Díaz y Óscar Alberto Rodríguez Cuadros, el trabajo «Desarrollo de una aplicación móvil basada en la realidad aumentada para la ubicación geolocalizada de lugares de interés al interior de la Universidad Industrial de Santander».

Su objetivo fue desarrollar una aplicación móvil que facilitara la ubicación de los sitios de mayor importancia del claustro universitario a quienes visitan sus instalaciones, entregando además información de cada edificio mediante material gráfico. La pregunta que lo orienta es cómo permitir que un visitante sin conocimiento previo identifique y ubique los lugares de interés del campus valiéndose únicamente de su dispositivo.

La solución se implementó como aplicación nativa en Java para tabletas Android. La realidad aumentada opera como capa de presentación: los datos de cada edificación se superponen sobre la imagen capturada por la cámara. La posición del usuario y la orientación del equipo se derivan de la fusión de tres sensores embarcados acelerómetro, receptor GPS y magnetómetro, mientras que las coordenadas geográficas de los puntos de interés se obtienen a través de la interfaz de programación de mapas de Google. Los autores incorporaron al diseño una tolerancia explícita al error, atribuible tanto a la deriva del receptor satelital como al movimiento continuo del dispositivo en manos del usuario.

El resultado, UIS-ARMobile, demuestra la viabilidad de la geolocalización aplicada al reconocimiento de espacios universitarios. Tres limitaciones, sin embargo, resultan críticas para el problema aquí planteado: la aplicación depende del posicionamiento satelital, cuya precisión se degrada bajo cubierta y entre edificaciones; se apoya en una plataforma de mapas de terceros sobre la cual la institución no ejerce control ni puede introducir su nomenclatura propia; y carece de grafo de rutas, de modo que informa dónde queda un lugar, pero no cómo llegar hasta él.

### 4.3.2 UISMaps: sistema de información geográfico móvil para la navegación en el campus

Precisamente ese vacío es el que aborda el trabajo siguiente. En 2015 Marcelo Reyes Correa y Jefry Alejandro Sanabria Palencia<sup>10</sup> presentaron «Desarrollo de un sistema de información geográfico móvil para la navegación dentro del campus universitario», dirigido por Fernando Antonio Rojas Morales y acompañado por Christophe Claramunt, director del Instituto de Investigación de la Academia Naval de Francia<sup>11</sup>.

El objetivo fue desarrollar una aplicación móvil que incorporara las funciones propias de un sistema de información geográfico para la ubicación y la navegación dentro del campus de la Universidad Industrial de Santander, cubriendo oficinas, laboratorios, decanaturas y escuelas. A diferencia del trabajo precedente, los autores sí explicitan el problema: la desorientación y la pérdida constante de personas dentro del campus. De allí se desprende la pregunta: cómo lograr que cualquier persona incluidas aquellas con discapacidad visual se ubique y navegue de forma autónoma dentro del campus.

La aplicación se desarrolló como cliente nativo Android en Java, sobre Android Studio, empleando la biblioteca cartográfica CartoType para la representación del mapa y la resolución de trayectorias. El posicionamiento y la orientación se derivan nuevamente de GPS y magnetómetro, con tolerancia declarada al error del receptor. El aporte metodológico distintivo del trabajo es la incorporación de un modo de operación alterno para usuarios con discapacidad visual, que sustituye la guía gráfica por síntesis de voz y reconocimiento automático del habla: el usuario conoce su posición respecto de las edificaciones circundantes y recibe por audio las indicaciones para alcanzar su destino.

El resultado fue UISMaps, aplicación que permite buscar un espacio por nombre o explorarlo por categorías, consultar la información del edificio y las dependencias que alberga, y recibir guía visual o sonora hasta él. El trabajo demuestra que la navegación asistida y accesible es realizable en un campus colombiano con los recursos de un trabajo de grado. Sus limitaciones frente al presente proyecto son precisas: no reporta operación completa sin conexión, no modela interiores ni distingue niveles de edificación, no incorpora un modo de ruta accesible para movilidad reducida y no contempla el reconocimiento remoto de las instalaciones.

Debe consignarse, para cerrar este ámbito, que en el departamento existen recorridos virtuales institucionales como el que la Universidad de Santander mantiene publicado para su planta física en Bucaramanga, Cúcuta, Valledupar y Bogotá<sup>12</sup>, pero se trata de piezas de comunicación institucional, ajenas a todo proceso de investigación documentado y desacopladas de cualquier función de localización o enrutamiento.

## 4.4 ÁMBITO NACIONAL

Los dos trabajos colombianos identificados elevan el rigor metodológico de la revisión, y uno de ellos incorpora explícitamente la restricción que gobierna el diseño de UniPaz360: la operación sin conexión a internet.

### 4.4.1 UVManos: hacia un campus universitario inteligente en la Universidad del Valle

Mauricio Edilberto Rincón-Romero, Wilmer Muñoz Herrera y Rodrigo Leal Guancha<sup>13</sup> publicaron en la Revista EIA el artículo «Hacia un Campus Universitario Inteligente. Caso de Estudio: Aplicación para la Movilidad Dentro del Campus Meléndez de la Universidad del Valle».

Su objetivo fue trasladar el concepto de Ciudad Inteligente a un modelo de Campus Inteligente soportado en geoinformación y tecnologías de la información y la comunicación, con el fin de generar una herramienta de apoyo a la movilidad intracampus. Los autores formulan la pregunta problema en los mismos términos en que la enuncia el usuario final: la herramienta debe resolver «¿en dónde queda?» y «¿cómo llego a…?. La coincidencia con el problema central detectado en el Centro de Investigaciones Santa Lucía es prácticamente literal.

La metodología partió del levantamiento y estructuración de la información espacial del campus Meléndez cien hectáreas y dieciocho kilómetros de caminos y vías en una base de datos espacial destinada a alimentar el sistema de información geográfica. Sobre esa base se construyeron dos productos articulados: un SIG-Web con GeoServer como servidor de mapas, Leaflet como cliente cartográfico y PostgreSQL con la extensión PostGIS como motor de almacenamiento y consulta espacial; y una aplicación móvil Android desarrollada con Apache Cordova y las bibliotecas Framework7 y Leaflet. El procesamiento de una consulta identifica el destino y construye la respuesta calculando la ruta más corta sobre el mapa base de la universidad, junto con la distancia entre origen y destino y el tiempo estimado de recorrido peatonal.

Los resultados son concluyentes en dos frentes. La herramienta responde efectivamente a las dos preguntas planteadas, entregando ubicación, ruta, distancia y tiempo. Y hallazgo de mayor valor para este proyecto la aplicación móvil funciona tanto en línea como sin conexión a internet, lo que acredita la viabilidad técnica de residenciar la cartografía y el grafo de rutas en el propio dispositivo. Los autores presentan UVManos como primer paso hacia un campus inteligente en el que la comunidad universitaria se localiza y se desplaza con autonomía.

La distancia con UniPaz360 es igualmente clara: UVManos se desarrolló para una sola plataforma móvil, opera sobre un campus urbano con cobertura de datos estable, no incorpora modo de ruta accesible para movilidad reducida y no contempla el recorrido virtual entre sus funciones.

### 4.4.2 Smart Map Javeriana: rutas inteligentes sobre un modelo tridimensional del campus

En 2022, Carlos Eduardo Escobar Triana, David Gutiérrez Alarcón, Julián David Tarazona Torres y Fabián Andrés Rojas Molina<sup>14</sup> presentaron ante la Facultad de Ingeniería de la Pontificia Universidad Javeriana, bajo la dirección de Anabel Montero, el trabajo «Smart Map Javeriana: Implementación de un servicio inteligente a través de un aplicativo móvil para desplazamientos dentro del campus».

El objetivo fue proponer una aplicación móvil que, mediante datos de ubicación en tiempo real y un modelo tridimensional de la universidad, ofreciera rutas inteligentes e información geoespacial completa a la comunidad universitaria y a sus visitantes. El problema identificado es la carencia de información sobre los espacios del campus: pese a tratarse de un campus abierto y de edificaciones notables, la universidad solo disponía de un mapa bidimensional estático que enumera y nombra edificios, sin descripción de los espacios ni capacidad alguna de navegación. La pregunta que se desprende es cómo sustituir ese mapa estático por un servicio de navegación e información geoespacial sostenido sobre un modelo tridimensional del campus.

La metodología siguió un ciclo formal de ingeniería de software, documentado mediante los artefactos de cada fase plan de proyecto, especificación de requisitos, diseño del sistema y pruebas de aceptación, anexos al informe final. Este rasgo distingue al trabajo de los antecedentes precedentes, cuya descripción metodológica se concentra en las herramientas de desarrollo antes que en el proceso.

El resultado es un aplicativo que integra el modelo tridimensional del campus con la generación de rutas y la consulta de información geoespacial por espacio, validado mediante pruebas de aceptación. Su limitación deriva directamente del diseño: el servicio depende de datos de ubicación en tiempo real, lo que presupone conectividad y disponibilidad de señal satelital, condiciones que no se cumplen en un campus rural con cobertura intermitente.

Merece mención complementaria el desarrollo QR-UD, elaborado por Ojeda Ramírez y Romero Beltrán<sup>15</sup> en la Facultad de Ingeniería de la Universidad Distrital Francisco José de Caldas, que resuelve la determinación del punto de origen mediante lectura de códigos QR dispuestos en lugares comunes de fácil acceso, a partir de los cuales el sistema genera la ruta óptima hacia el destino. Aunque su alcance se limita a una facultad, aporta evidencia nacional de que la identificación del origen por código QR es una alternativa válida al posicionamiento satelital en interiores decisión que UniPaz360 adopta.

## 4.5 ÁMBITO INTERNACIONAL

La producción internacional aporta lo que la literatura nacional no ofrece: la validación experimental de un sistema concebido íntegramente para operar sin conexión, y la medición empírica de cuánto ayuda realmente una aplicación de navegación a quien recorre un campus.

### 4.5.1 Sistema sin conexión para navegación interior en dos dimensiones

El artículo «Offline System for 2D Indoor Navigation Utilizing Advanced Data Structures», publicado en Informatics por Jorge Luis Veloz, Leo Sebastián Intriago, Jean Carlos Palma y Andrea Katherine Alcívar-Cedeño, de la Facultad de Ciencias Informáticas de la Universidad Técnica de Manabí (Ecuador), junto a Álvaro Antón-Sacho, Pablo Fernández-Arias y Diego Vergara, de la Universidad Católica de Ávila (España), y Edwan Anderson Ariza, de la Universidad del Magdalena (Colombia), es el antecedente más próximo a la restricción técnica central de este proyecto<sup>16</sup>.

El objetivo fue desarrollar y validar un sistema robusto de navegación interior en dos dimensiones capaz de operar por completo sin conexión, atendiendo dos dificultades recurrentes: la complejidad de las distribuciones arquitectónicas y las restricciones de conectividad. La pregunta que orienta el estudio es cómo garantizar una navegación interior confiable, eficiente y satisfactoria en edificaciones de distribución compleja donde la conectividad resulta limitada o inexistente.

La metodología se estructuró sobre un proceso de desarrollo sistemático. La solución integra técnicas avanzadas de modelado espacial para optimizar el cálculo de trayectorias y el consumo de recursos, apoyándose en estructuras de datos ligeras y en componentes modulares orientados a reducir la carga computacional y favorecer la escalabilidad. La validación se resolvió mediante diseño experimental comparativo, contrastando los métodos tradicionales de orientación frente al sistema propuesto sobre tres criterios: usabilidad, eficiencia de búsqueda y satisfacción del usuario.

Los resultados demuestran que el sistema sin conexión mejora significativamente el desempeño de la navegación y la experiencia del usuario, en particular en entornos de conectividad limitada, y que la operación autónoma del dispositivo incrementa la accesibilidad de la herramienta en escenarios educativos y en otros contextos de distribución compleja. Los autores proyectan extender el enfoque hacia la adaptabilidad dinámica y hacia los sectores de salud y servicios públicos. Este trabajo respalda directamente la decisión de arquitectura adoptada en UniPaz360: resolver mapa, búsqueda y cálculo de rutas con los datos residentes en el dispositivo.

### 4.5.2 Efecto de la ayuda de navegación y de las habilidades espaciales en el recorrido de un campus

Rabail Tahir y John Krogstie<sup>17</sup>, de la Universidad Noruega de Ciencia y Tecnología, publicaron en Applied Sciences el artículo «Impact of Navigation Aid and Spatial Ability Skills on Wayfinding Performance and Workload in Indoor-Outdoor Campus Navigation: Challenges and Design».

El estudio persigue tres objetivos: comparar la efectividad de Google Maps, aplicación de navegación exterior, frente a MazeMap, aplicación de navegación combinada interior-exterior, sobre el desempeño de orientación y la carga de trabajo percibida; determinar el efecto de las habilidades espaciales del usuario sobre ambas variables, con independencia de la aplicación empleada; y caracterizar los desafíos de la orientación interior-exterior en campus universitarios. La pregunta que articula la investigación es qué efecto tienen la ayuda de navegación y las habilidades espaciales del usuario sobre su desempeño y su carga cognitiva al recorrer un campus que combina trayectos interiores y exteriores.

La metodología consistió en un experimento controlado con veintidós participantes, distribuidos en un grupo de control que empleó Google Maps y un grupo experimental que empleó MazeMap. Los participantes ejecutaron una tarea de orientación cronometrada en el campus Gløshaugen, en Trondheim, sin preparación ni conocimiento previo del recorrido. La recolección combinó pruebas estandarizadas de habilidad espacial, cuestionarios de carga mental y entrevistas, articulando evidencia cuantitativa y cualitativa.

Tres hallazgos resultan relevantes. Primero, no se encontraron diferencias estadísticamente significativas entre ambas aplicaciones en desempeño ni en carga percibida, lo que indica que la sola incorporación de cartografía interior no garantiza por sí misma una mejor experiencia de orientación. Segundo, se identificó correlación negativa entre la puntuación global de habilidad espacial y la carga de trabajo percibida, así como entre el sentido de la orientación y la indecisión durante el recorrido. Tercero, el análisis cualitativo agrupó en cinco categorías las dificultades del usuario en campus con trayectos interiores y exteriores.

La lectura para este proyecto es doble: confirma la vigencia internacional del problema y advierte que el valor de una herramienta de esta naturaleza no reside en la disponibilidad del mapa, sino en el diseño de la interacción y en la calidad de las indicaciones entregadas criterio que UniPaz360 traduce en la fase de evaluación funcional y de usabilidad prevista en sus objetivos específicos.

## 4.6 SÍNTESIS DE LA REVISIÓN Y VACÍO IDENTIFICADO

La revisión evidencia una progresión técnica sostenida durante la última década. Del reconocimiento visual del entorno mediante realidad aumentada sobre puntos georreferenciados<sup>18</sup> se pasó a la navegación asistida con accesibilidad sonora<sup>19</sup>; de allí al cálculo de rutas peatonales soportado en infraestructura de información geográfica con operación desconectada<sup>20</sup>; luego a la generación de rutas sobre modelos tridimensionales del campus<sup>21</sup>; y finalmente a sistemas de navegación interior concebidos íntegramente para operar sin conexión y validados experimentalmente<sup>22</sup>. Cada trabajo resuelve una limitación del anterior, pero ninguno cierra el conjunto.

De ese recorrido se desprenden cuatro constataciones que delimitan el aporte de UniPaz360.

Primera. Ningún trabajo revisado integra en una sola herramienta las cuatro funciones que este proyecto se propone: localización de espacios, cálculo de rutas peatonales sin conexión, modo de ruta accesible para movilidad reducida y recorrido virtual de las instalaciones. Los antecedentes que resuelven la navegación no ofrecen recorrido virtual, y los recorridos virtuales identificados institucionales y comunicativos operan desacoplados de toda función de localización o enrutamiento.

Segunda. La accesibilidad aparece atendida de forma parcial y siempre orientada a la discapacidad visual, mediante guía sonora y reconocimiento del habla<sup>23</sup>. No se identificó ningún antecedente que pondere el grafo por desnivel y condición de accesibilidad para ofrecer rutas que eviten escaleras y privilegien rampas, pese a las obligaciones que imponen la Ley 1618 de 2013<sup>24</sup> y la Resolución 1519 de 2020 del Ministerio de Tecnologías de la Información y las Comunicaciones<sup>25</sup>.

Tercera. Los desarrollos nacionales y departamentales revisados se implantaron en campus urbanos, con cobertura de datos estable y sobre una sola plataforma. La operación sin conexión, cuando aparece, figura como prestación adicional<sup>26</sup> y no como la restricción de diseño que impone un campus rural con señal intermitente. Ningún antecedente colombiano adopta un desarrollo multiplataforma que atienda simultáneamente la heterogeneidad de dispositivos Android, iOS y de escritorio de una comunidad universitaria.

Cuarta. En el ámbito municipal no existe proyecto alguno académico ni institucional que aborde la orientación dentro de un campus mediante localización de espacios, cálculo de rutas o reconocimiento remoto de instalaciones. La única iniciativa cartográfica digital hallada en Barrancabermeja opera a escala urbana, con propósito divulgativo, sin enrutamiento ni operación desconectada.

El vacío que UniPaz360 viene a ocupar queda así definido: no existe, ni en el Distrito de Barrancabermeja ni en el conjunto de los trabajos revisados, una herramienta que integre localización de espacios, cálculo de rutas peatonales sin conexión, rutas accesibles y recorrido virtual, construida sobre una única base de código multiplataforma, diseñada para un campus rural con conectividad intermitente y con la información de los espacios bajo control de la propia institución. Los antecedentes acreditan que cada una de estas capacidades es técnicamente realizable por separado; el aporte de este proyecto consiste en articularlas en una sola solución y llevarla a un contexto —el Centro de Investigaciones Santa Lucía del Instituto Universitario de la Paz— donde ninguna se encuentra hoy disponible.

# BIBLIOGRAFÍA

ALCALDÍA DE BARRANCABERMEJA. El Distrito de Barrancabermeja ya cuenta con nueva Sede Electrónica y APP Móvil [en línea]. Barrancabermeja: Alcaldía de Barrancabermeja, 14 de enero de 2021. [Consultado el 1 de octubre de 2026]. Disponible en: https://www.barrancabermeja.gov.co/publicaciones/1064/el-distrito-de-barrancabermeja-ya-cuenta-con-nueva-sede-electronica-y-app-movil/

COLOMBIA. CONGRESO DE LA REPÚBLICA. Ley 1618 (27, febrero, 2013). Por medio de la cual se establecen las disposiciones para garantizar el pleno ejercicio de los derechos de las personas con discapacidad. Diario Oficial. Bogotá, D.C., 2013. no. 48717.

COLOMBIA. MINISTERIO DE TECNOLOGÍAS DE LA INFORMACIÓN Y LAS COMUNICACIONES. Resolución 1519 (24, agosto, 2020). Por la cual se definen los estándares y directrices para publicar la información señalada en la Ley 1712 del 2014 y se definen los requisitos materia de acceso a la información pública, accesibilidad web, seguridad digital, y datos abiertos. Diario Oficial. Bogotá, D.C., 2020. no. 51521.

DÍAZ ARANDA, Carlos Enrique y PÉREZ ARENAS, Gabriel Fernando. Desarrollo de una aplicación móvil basada en la realidad aumentada para la ubicación geolocalizada de lugares de interés al interior de la Universidad Industrial de Santander [en línea]. Bucaramanga, 2013. Trabajo de grado (Ingeniero de Sistemas). Universidad Industrial de Santander. Facultad de Ingenierías Fisicomecánicas. Escuela de Ingeniería de Sistemas e Informática. [Consultado el 1 de octubre de 2026]. Disponible en: https://noesis.uis.edu.co/handle/20.500.14071/29213

ESCOBAR TRIANA, Carlos Eduardo, et al. Smart Map Javeriana: implementación de un servicio inteligente a través de un aplicativo móvil para desplazamientos dentro del campus [en línea]. Bogotá, 2022. Trabajo de grado (Ingeniero de Sistemas). Pontificia Universidad Javeriana. Facultad de Ingeniería. [Consultado el 1 de octubre de 2026]. Disponible en: http://hdl.handle.net/10554/63576

ESTUDIANTES crean aplicación para ubicarse en la UIS. En: Vanguardia [en línea]. Bucaramanga. (7, junio, 2015). [Consultado el 1 de octubre de 2026]. Disponible en: https://www.vanguardia.com/mundo/ciencia/2015/06/07/estudiantes-crean-aplicacion-para-ubicarse-en-la-uis/

INSTITUTO UNIVERSITARIO DE LA PAZ – UNIPAZ. Misión, visión e historia [en línea]. Barrancabermeja: UNIPAZ. [Consultado el 1 de octubre de 2026]. Disponible en: https://unipaz.edu.co/transparencia/mision-vision-e-historia/

OJEDA RAMÍREZ, Johan Sebastián y ROMERO BELTRÁN, Jeisson Andrés. QR-UD: movilidad en la Facultad de Ingeniería de la Universidad Distrital [en línea]. Bogotá, 2016. Trabajo de grado (Especialista en Sistemas de Información Geográfica). Universidad Distrital Francisco José de Caldas. Facultad de Ingeniería. [Consultado el 1 de octubre de 2026]. Disponible en: https://repository.udistrital.edu.co/handle/11349/5259

REYES CORREA, Marcelo y SANABRIA PALENCIA, Jefry Alejandro. Desarrollo de un sistema de información geográfico móvil para la navegación dentro del campus universitario [en línea]. Bucaramanga, 2015. Trabajo de grado (Ingeniero de Sistemas). Universidad Industrial de Santander. Facultad de Ingenierías Fisicomecánicas. Escuela de Ingeniería de Sistemas e Informática. [Consultado el 1 de octubre de 2026]. Disponible en: https://noesis.uis.edu.co/handle/20.500.14071/32616

RINCÓN-ROMERO, Mauricio Edilberto; MUÑOZ HERRERA, Wilmer y LEAL GUANCHA, Rodrigo. Hacia un campus universitario inteligente. Caso de estudio: aplicación para la movilidad dentro del campus Meléndez de la Universidad del Valle. En: Revista EIA [en línea]. Vol. 20, no. 39 (ene.-jun., 2023). [Consultado el 1 de octubre de 2026]. Disponible en: https://doi.org/10.24050/reia.v20i39.1607

TAHIR, Rabail y KROGSTIE, John. Impact of navigation aid and spatial ability skills on wayfinding performance and workload in indoor-outdoor campus navigation: challenges and design. En: Applied Sciences [en línea]. Vol. 13, no. 17 (ago., 2023); art. 9508. [Consultado el 1 de octubre de 2026]. Disponible en: https://doi.org/10.3390/app13179508

TOLOSA HERAZO, Jaime Camilo. Mapa interactivo de Barrancabermeja [en línea]. Mi Barrancabermeja, 11 de septiembre de 2022. [Consultado el 1 de octubre de 2026]. Disponible en: https://mibarrancabermeja.co/mapa-interactivo-de-barrancabermeja/

UNIVERSIDAD DE SANTANDER. Recorrido virtual [en línea]. Bucaramanga: UDES. [Consultado el 1 de octubre de 2026]. Disponible en: https://udes.edu.co/planta-fisica/recorrido-virtual

VELOZ, Jorge Luis, et al. Offline system for 2D indoor navigation utilizing advanced data structures. En: Informatics [en línea]. Vol. 12, no. 2 (mar., 2025); art. 34. [Consultado el 1 de octubre de 2026]. Disponible en: https://doi.org/10.3390/informatics12020034

1. INSTITUTO UNIVERSITARIO DE LA PAZ – UNIPAZ. Misión, visión e historia [en línea]. Barrancabermeja: UNIPAZ. [Consultado el 1 de octubre de 2026]. Disponible en: https://unipaz.edu.co/transparencia/mision-vision-e-historia/
2. RINCÓN-ROMERO, Mauricio Edilberto; MUÑOZ HERRERA, Wilmer y LEAL GUANCHA, Rodrigo. Hacia un campus universitario inteligente. Caso de estudio: aplicación para la movilidad dentro del campus Meléndez de la Universidad del Valle. En: Revista EIA [en línea]. Vol. 20, no. 39 (ene.-jun., 2023). [Consultado el 1 de octubre de 2026]. Disponible en: https://doi.org/10.24050/reia.v20i39.1607
3. COLOMBIA. CONGRESO DE LA REPÚBLICA. Ley 1618 (27, febrero, 2013). Por medio de la cual se establecen las disposiciones para garantizar el pleno ejercicio de los derechos de las personas con discapacidad. Diario Oficial. Bogotá, D.C., 2013. no. 48717.
4. COLOMBIA. MINISTERIO DE TECNOLOGÍAS DE LA INFORMACIÓN Y LAS COMUNICACIONES. Resolución 1519 (24, agosto, 2020). Por la cual se definen los estándares y directrices para publicar la información señalada en la Ley 1712 del 2014 y se definen los requisitos materia de acceso a la información pública, accesibilidad web, seguridad digital, y datos abiertos. Diario Oficial. Bogotá, D.C., 2020. no. 51521.
5. VELOZ, Jorge Luis, et al. Offline system for 2D indoor navigation utilizing advanced data structures. En: Informatics [en línea]. Vol. 12, no. 2 (mar., 2025); art. 34. [Consultado el 1 de octubre de 2026]. Disponible en: https://doi.org/10.3390/informatics12020034
6. RINCÓN-ROMERO, MUÑOZ HERRERA y LEAL GUANCHA. Op. cit.
7. TOLOSA HERAZO, Jaime Camilo. Mapa interactivo de Barrancabermeja [en línea]. Mi Barrancabermeja, 11 de septiembre de 2022. [Consultado el 1 de octubre de 2026]. Disponible en: https://mibarrancabermeja.co/mapa-interactivo-de-barrancabermeja/
8. ALCALDÍA DE BARRANCABERMEJA. El Distrito de Barrancabermeja ya cuenta con nueva Sede Electrónica y APP Móvil [en línea]. Barrancabermeja: Alcaldía de Barrancabermeja, 14 de enero de 2021. [Consultado el 1 de octubre de 2026]. Disponible en: https://www.barrancabermeja.gov.co/publicaciones/1064/el-distrito-de-barrancabermeja-ya-cuenta-con-nueva-sede-electronica-y-app-movil/
9. DÍAZ ARANDA, Carlos Enrique y PÉREZ ARENAS, Gabriel Fernando. Desarrollo de una aplicación móvil basada en la realidad aumentada para la ubicación geolocalizada de lugares de interés al interior de la Universidad Industrial de Santander [en línea]. Bucaramanga, 2013. Trabajo de grado (Ingeniero de Sistemas). Universidad Industrial de Santander. Facultad de Ingenierías Fisicomecánicas. Escuela de Ingeniería de Sistemas e Informática. [Consultado el 1 de octubre de 2026]. Disponible en: https://noesis.uis.edu.co/handle/20.500.14071/29213
10. REYES CORREA, Marcelo y SANABRIA PALENCIA, Jefry Alejandro. Desarrollo de un sistema de información geográfico móvil para la navegación dentro del campus universitario [en línea]. Bucaramanga, 2015. Trabajo de grado (Ingeniero de Sistemas). Universidad Industrial de Santander. Facultad de Ingenierías Fisicomecánicas. Escuela de Ingeniería de Sistemas e Informática. [Consultado el 1 de octubre de 2026]. Disponible en: https://noesis.uis.edu.co/handle/20.500.14071/32616
11. ESTUDIANTES crean aplicación para ubicarse en la UIS. En: Vanguardia [en línea]. Bucaramanga. (7, junio, 2015). [Consultado el 1 de octubre de 2026]. Disponible en: https://www.vanguardia.com/mundo/ciencia/2015/06/07/estudiantes-crean-aplicacion-para-ubicarse-en-la-uis/
12. UNIVERSIDAD DE SANTANDER. Recorrido virtual [en línea]. Bucaramanga: UDES. [Consultado el 1 de octubre de 2026]. Disponible en: https://udes.edu.co/planta-fisica/recorrido-virtual
13. RINCÓN-ROMERO, MUÑOZ HERRERA y LEAL GUANCHA. Op. cit.
14. ESCOBAR TRIANA, Carlos Eduardo, et al. Smart Map Javeriana: implementación de un servicio inteligente a través de un aplicativo móvil para desplazamientos dentro del campus [en línea]. Bogotá, 2022. Trabajo de grado (Ingeniero de Sistemas). Pontificia Universidad Javeriana. Facultad de Ingeniería. [Consultado el 1 de octubre de 2026]. Disponible en: http://hdl.handle.net/10554/63576
15. OJEDA RAMÍREZ, Johan Sebastián y ROMERO BELTRÁN, Jeisson Andrés. QR-UD: movilidad en la Facultad de Ingeniería de la Universidad Distrital [en línea]. Bogotá, 2016. Trabajo de grado (Especialista en Sistemas de Información Geográfica). Universidad Distrital Francisco José de Caldas. Facultad de Ingeniería. [Consultado el 1 de octubre de 2026]. Disponible en: https://repository.udistrital.edu.co/handle/11349/5259
16. VELOZ et al. Op. cit.
17. TAHIR, Rabail y KROGSTIE, John. Impact of navigation aid and spatial ability skills on wayfinding performance and workload in indoor-outdoor campus navigation: challenges and design. En: Applied Sciences [en línea]. Vol. 13, no. 17 (ago., 2023); art. 9508. [Consultado el 1 de octubre de 2026]. Disponible en: https://doi.org/10.3390/app13179508
18. DÍAZ ARANDA y PÉREZ ARENAS. Op. cit.
19. REYES CORREA y SANABRIA PALENCIA. Op. cit.
20. RINCÓN-ROMERO, MUÑOZ HERRERA y LEAL GUANCHA. Op. cit.
21. ESCOBAR TRIANA et al. Op. cit.
22. VELOZ et al. Op. cit.
23. REYES CORREA y SANABRIA PALENCIA. Op. cit.
24. COLOMBIA. CONGRESO DE LA REPÚBLICA. Ley 1618 de 2013. Op. cit.
25. COLOMBIA. MINISTERIO DE TECNOLOGÍAS DE LA INFORMACIÓN Y LAS COMUNICACIONES. Resolución 1519 de 2020. Op. cit.
26. RINCÓN-ROMERO, MUÑOZ HERRERA y LEAL GUANCHA. Op. cit.