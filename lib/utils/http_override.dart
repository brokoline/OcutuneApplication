import 'dart:io';

/// 🌐 Bruges til at logge alle HTTP-kald og ignorere certifikatfejl (kun i udvikling)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final baseClient = super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;

    return _LoggingHttpClient(baseClient);
  }
}

class _LoggingHttpClient implements HttpClient {
  final HttpClient _inner;

  _LoggingHttpClient(this._inner);

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    print('🌐 [GET] $url');
    return _inner.getUrl(url);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    print('📡 [POST] $url');
    return _inner.postUrl(url);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    print('🧩 [OPEN $method] $url');
    return _inner.openUrl(method, url);
  }

  @override
  void close({bool force = false}) {
    _inner.close(force: force);
  }

  // Send alle andre kald videre til original klient
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Function.apply(_inner.noSuchMethod, [invocation]);
}
