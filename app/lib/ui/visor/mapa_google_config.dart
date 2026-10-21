/// La clave se inyecta al compilar con --dart-define y debe restringirse por dominio.
const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

const _coordenadasUnipaz = '7.066153703270713,-73.74487959820672';

Uri get googleMapsEmbedUri => googleMapsApiKey.isNotEmpty
    ? Uri.https('www.google.com', '/maps/embed/v1/place', {
        'key': googleMapsApiKey,
        'q': _coordenadasUnipaz,
        'zoom': '16',
        'language': 'es',
      })
    : Uri.https('www.google.com', '/maps', {
        'q': _coordenadasUnipaz,
        'z': '16',
        'output': 'embed',
        'hl': 'es',
      });
