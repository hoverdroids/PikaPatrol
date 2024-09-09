import 'package:deepcopy/deepcopy.dart';


extension IterableExtensions<T> on Iterable<T> {

}

extension ListExtenions<T> on List<T> {
  T sum() {
    // 1. initialize sum
    var sum = (T == int ? 0 : 0.0) as T;
    // 2. calculate sum
    for (var current in this) {
      if (current != null) { // only add non-null values
        //TODO - not sure why, but the following is a problem
        //sum += current;
      }
    }
    return sum;
  }

  List<T> clone({bool isDeep = true, bool isSorted = false, bool isReversed = false, bool isUnique = false}) {
    var clone = this;
    if (isDeep) {
      clone = List<T>.from(deepcopy());
    } else {
      clone = List<T>.from(this);
    }

    if (isSorted) {
      clone.sort();
    }

    if (isUnique && isReversed) {
      return clone.reversed.toSet().toList();
    } else if (isReversed) {
      return clone.reversed.toList();
    }
    return clone;
  }

  Set<T> cloneToSet({bool isDeep = true, bool isSorted = false, bool isReversed = false}) {
    var clone = this;
    if (isDeep) {
      clone = List<T>.from(deepcopy());
    } else {
      clone = List<T>.from(this);
    }

    if (isSorted) {
      clone.sort();
    }

    if (isReversed) {
      return clone.reversed.toSet();
    }
    return clone.toSet();
  }
}

extension SetExtenions<T> on Set<T> {
  Set<T> clone({bool isDeep = true}) {
    if (isDeep) {
      return Set<T>.from(deepcopy());
    }
    return Set<T>.from(this);
  }
}

extension MapExtenions<K,V> on Map<K,V> {
  Map<K, V> clone({bool isDeep = true}) {
    if (isDeep) {
      return Map<K, V>.from(deepcopy());
    }
    return Map<K, V>.from(this);
  }
}