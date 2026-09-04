import 'dart:io';

void main() async {
  final webDir = Directory('build/web');
  if (!webDir.existsSync()) {
    stdout.writeln('build/web not found!');
    return;
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  stdout.writeln('CampusOS Web Running at http://localhost:8080');

  // Open in browser
  Process.run('cmd', ['/c', 'start', 'http://localhost:8080']);

  await for (HttpRequest request in server) {
    var path = request.uri.path;
    if (path == '/' || path.isEmpty) path = '/index.html';
    final file = File('build/web$path');

    if (await file.exists()) {
      final ext = path.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'html' => ContentType.html,
        'js' => ContentType('application', 'javascript', charset: 'utf-8'),
        'css' => ContentType('text', 'css', charset: 'utf-8'),
        'json' => ContentType.json,
        'png' => ContentType('image', 'png'),
        'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
        'svg' => ContentType('image', 'svg+xml'),
        'wasm' => ContentType('application', 'wasm'),
        _ => ContentType.binary,
      };
      request.response.headers.contentType = mime;
      request.response.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      request.response.headers.set('Pragma', 'no-cache');
      request.response.headers.set('Expires', '0');
      await request.response.addStream(file.openRead());
    } else {
      // Fallback to index.html for SPA routing
      final indexFile = File('build/web/index.html');
      request.response.headers.contentType = ContentType.html;
      request.response.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      await request.response.addStream(indexFile.openRead());
    }
    await request.response.close();
  }
}
