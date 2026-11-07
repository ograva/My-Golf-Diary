{{flutter_js}}
{{flutter_build_config}}

// Golf Diary registers pwa_service_worker.js from index.html.
// Omitting serviceWorkerSettings keeps Flutter from installing the
// deprecated worker that unregisters itself and reloads every client.
_flutter.loader.load();
