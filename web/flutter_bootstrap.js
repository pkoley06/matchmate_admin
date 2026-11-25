{{flutter_js}}
{{flutter_build_config}}

// The server sends main.dart.js without a Cache-Control header and its name
// never changes, so browsers may keep running an old build after a deploy.
// Give every build its own URL so a reload always gets the new one.
(function () {
  const build = {{flutter_service_worker_version}};
  for (const b of _flutter.buildConfig.builds) {
    if (b.mainJsPath) b.mainJsPath += "?v=" + build;
  }
})();

// No service worker: Flutter's is deprecated, and it only delayed updates.
_flutter.loader.load();
