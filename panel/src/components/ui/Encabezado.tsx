export function Encabezado({ titulo, subtitulo }: { titulo: string; subtitulo?: string }) {
  return (
    <header>
      <h1 className="text-[44px] font-normal leading-tight tracking-tight">{titulo}</h1>
      {subtitulo && <p className="mt-1 text-lg text-tinta-tenue">{subtitulo}</p>}
    </header>
  );
}
