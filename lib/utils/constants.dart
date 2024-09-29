// ignore_for_file: constant_identifier_names
class Constants {
  static const bool SUCCESS = true;
  static const bool FAILED = false;

  static const LOCALHOST = "localhost";
  static const LOCALHOST_ANDROID = "10.0.2.2";

  static const HTTP_URL_PREFIX = "http://";
  static const HTTPS_URL_PREFIX = "https://";

  static final HTTP_OR_HTTPS_REGEX = RegExp(r'^https?://', multiLine: true, caseSensitive: false);//using raw string, i.e. r''
}