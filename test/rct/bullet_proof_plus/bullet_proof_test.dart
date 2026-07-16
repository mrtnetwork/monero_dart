import '../../utils.dart';
import 'test6.dart';
import 'test5.dart';
import 'test4.dart';
import 'test3.dart';
import 'test2.dart';
import 'test1.dart';

void main() {
  List<Function> testCases = [
    bulletproofsPlus1,
    bulletproofsPlus2,
    bulletproofsPlus3,
    bulletproofsPlus4,
    bulletproofsPlus5,
    bulletproofsPlus6,
  ];
  for (final i in testCases.takeShuffle(2)) {
    i();
  }
}
