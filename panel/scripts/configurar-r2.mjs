// Configura el CORS del bucket R2 para que:
//   · el panel suba fotos y videos directo a R2 con URL firmadas (PUT), sin pasar por Vercel
//     (Vercel limita el cuerpo de una petición a 4,5 MB y una foto 360° suele pesar más);
//   · la app web pueda leer los medios públicos (GET).
// Las URL firmadas caducan a los 10 minutos y cubren un solo objeto: son ellas las que autorizan.
//
// Uso (una sola vez):  node scripts/configurar-r2.mjs
// Lee R2_* del entorno o de ~/dev/unipaz360.secretos.env.
import os from 'node:os';
import path from 'node:path';
import { existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { AwsClient } from 'aws4fetch';

const secretos = process.env.UNIPAZ_SECRETOS ?? path.join(os.homedir(), 'dev', 'unipaz360.secretos.env');
if (!process.env.R2_ENDPOINT && existsSync(secretos)) process.loadEnvFile(secretos);

const r2 = new AwsClient({
  accessKeyId: process.env.R2_ACCESS_KEY_ID,
  secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  service: 's3',
  region: 'auto',
});
const base = `${process.env.R2_ENDPOINT.replace(/\/$/, '')}/${process.env.R2_BUCKET}`;

const cuerpo = `<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>HEAD</AllowedMethod>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedHeader>content-type</AllowedHeader>
    <ExposeHeader>ETag</ExposeHeader>
    <MaxAgeSeconds>3600</MaxAgeSeconds>
  </CORSRule>
</CORSConfiguration>`;

const md5 = createHash('md5').update(cuerpo).digest('base64');
const r = await r2.fetch(`${base}?cors`, {
  method: 'PUT',
  body: cuerpo,
  headers: { 'Content-Type': 'application/xml', 'Content-MD5': md5 },
});
console.log(r.ok ? 'CORS del bucket configurado.' : `Error ${r.status}: ${await r.text()}`);
const v = await r2.fetch(`${base}?cors`);
console.log('Verificación:', v.status, v.ok ? 'regla activa' : await v.text());
process.exit(r.ok ? 0 : 1);
