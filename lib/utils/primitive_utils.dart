extension NullableStringExtension on String? {
  bool get isNullOrEmpty {
    final value = this;
    return value == null || value.isEmpty;
  }
}