// ignore_for_file: avoid_print
//
// Syncs secrets from config/secrets.json (or .example) into assets/config/secrets.json
// so the Flutter app can load the API key at runtime.
//
// Run from project root: dart run tool/sync_secrets.dart
// Then: flutter run

import 'dart:io';

void main() {
  final projectRoot = Directory.current;
  final configSecrets = File('${projectRoot.path}/config/secrets.json');
  final configExample = File('${projectRoot.path}/config/secrets.json.example');
  final assetsDir = Directory('${projectRoot.path}/assets/config');
  final assetSecrets = File('${projectRoot.path}/assets/config/secrets.json');

  final File source;
  if (configSecrets.existsSync()) {
    source = configSecrets;
    print('Using config/secrets.json');
  } else if (configExample.existsSync()) {
    source = configExample;
    print('config/secrets.json not found; using config/secrets.json.example (empty key)');
  } else {
    print('Error: neither config/secrets.json nor config/secrets.json.example found.');
    exit(1);
  }

  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }
  source.copySync(assetSecrets.path);
  print('Wrote assets/config/secrets.json. Run: flutter run');
}
