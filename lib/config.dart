/// 服务器配置
class ServerConfig {
  static const String defaultBaseUrl = 'https://morax.kdns.fr';

  String baseUrl = defaultBaseUrl;

  String urlFor(String path) {
    if (path.startsWith('http')) return path;
    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }
}
