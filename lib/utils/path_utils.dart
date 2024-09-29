import 'constants.dart';

class PathUtils {
  static bool isUrl(String pathOrUrl) {
    return pathOrUrl.startsWith(Constants.HTTP_OR_HTTPS_REGEX);
  }
}
