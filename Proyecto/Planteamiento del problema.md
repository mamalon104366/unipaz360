---
tags: [unipaz360, proyecto]
---
# Planteamiento del problema

## Contexto
- UNIPAZ: establecimiento público departamental (Decreto Ordenanzal 0331 de 1987), sede en Barrancabermeja.
- Campus principal: [[Centro de Investigaciones Santa Lucía]], zona rural, km 14 vía Barrancabermeja–Bucaramanga.
- Población que rota cada semestre; uso generalizado de smartphones; **cobertura de datos irregular**.

## Problema
No hay herramienta digital de orientación: ni mapa interactivo, ni buscador de aulas, oficinas o laboratorios, ni cálculo de rutas. Todo depende de la señalización física y de preguntar.
Corresponde a las dos preguntas de [[UVManos]]: **"¿en dónde queda?"** y **"¿cómo llego a…?"**. Los aspirantes no tienen [[Recorrido virtual]].

## Efectos
- Pérdida de tiempo y retrasos (sobre todo en primeros semestres).
- Los mapas genéricos exigen conexión, no tienen interiores ni pisos y no conocen la nomenclatura institucional.
- El conocimiento es oral y se pierde cuando los estudiantes se gradúan; porterías y secretarías atienden consultas de ubicación.
- Las personas con movilidad reducida no saben si una ruta es transitable → [[Ruta accesible]], [[Normativa de accesibilidad]].

## Cuatro limitaciones técnicas
1. Planos estáticos → hay que modelar el campus como [[Grafo del campus]].
2. Conectividad intermitente → [[Rutas sin conexión]] (respaldo: [[Veloz 2025 - Navegación interior offline]]).
3. GPS impreciso bajo techo y sin pisos → origen manual o [[Origen por código QR]].
4. Mapas de terceros sin interiores ni nomenclatura + diversidad de dispositivos → [[Flutter multiplataforma]].

Ver también [[Justificación]] · [[Objetivos]] · [[Ficha del proyecto]]
