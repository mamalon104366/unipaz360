/**
 * Quién ve un contenido en la app: todos, o solo quien entra con la cuenta institucional
 * (@unipaz.edu.co). Vale para los elementos de las páginas y para los puntos de las fotos 360°.
 *
 * La app oculta ese contenido a los invitados, pero viaja dentro del paquete de datos, que se
 * descarga sin iniciar sesión: sirve para ordenar lo que ve cada quien, no para información
 * confidencial.
 */
export const AUDIENCIAS = ['todos', 'institucional'] as const;
export type Audiencia = (typeof AUDIENCIAS)[number];

export const ETIQUETA_AUDIENCIA: Record<Audiencia, string> = {
  todos: 'Todos',
  institucional: 'Solo con cuenta institucional',
};

/** Lo que no se reconoce es para todos. */
export const audienciaValida = (v: unknown): Audiencia => (v === 'institucional' ? 'institucional' : 'todos');
