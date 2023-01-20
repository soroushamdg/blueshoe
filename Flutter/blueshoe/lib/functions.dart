import 'dart:math';

int hexSnapshot2Dec(List<int> data) {
  int result = 0;

  data.reversed.toList().asMap().forEach((int index, int value) {
    result += (value * pow(16, index * 2).toInt());
  });
  return result;
}
