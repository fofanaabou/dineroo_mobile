int parseToInt(dynamic value) {
  switch (value) {
    case int i:
      return i;
    case String s:
      return int.tryParse(s) ?? 0;
    case double d:
      return d.toInt();
    default:
      return 0;
  }
}

double parseToDouble(dynamic value) {
  switch (value) {
    case num n:
      return n.toDouble();
    case String s:
      return double.tryParse(s) ?? 0.0;
    default:
      return 0.0;
  }
}
