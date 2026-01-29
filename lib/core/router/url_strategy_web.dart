import 'package:flutter_web_plugins/url_strategy.dart';

/// Use hash URL strategy on web so refresh and direct links work in Chrome
/// without requiring the server to rewrite all paths to index.html.
void useHashUrlStrategy() {
  setUrlStrategy(const HashUrlStrategy());
}
