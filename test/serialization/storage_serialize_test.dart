import 'package:monero_dart/src/serialization/storage_format/types/entry.dart';
import 'package:test/test.dart';

void main() {
  _test();
}

void _test() {
  test("json to binary", () {
    final json = {"jafar": 2};
    final storage = MoneroStorage.fromJson(json);
    expect(
      storage.serializeHex(),
      "01110101010102010104056a61666172050200000000000000",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 1", () {
    final storage = MoneroStorage.fromJson({"key": []});
    expect(storage.serializeHex(), "01110101010102010100");
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 2", () {
    final storage = MoneroStorage.fromJson({"key": [], "key1": null});
    expect(storage.serializeHex(), "01110101010102010100");
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 3", () {
    final storage = MoneroStorage.fromJson({
      "key": [],
      "key1": null,
      "key3": 2,
    });
    expect(
      storage.serializeHex(),
      "01110101010102010104046b657933050200000000000000",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 4", () {
    final storage = MoneroStorage.fromJson({
      "key1": [1, 2, 3, 4, 5],
    });
    expect(
      storage.serializeHex(),
      "01110101010102010104046b657931851401000000000000000200000000000000030000000000000004000000000000000500000000000000",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 5", () {
    final storage = MoneroStorage.fromJson({"key1": true});
    expect(storage.serializeHex(), "01110101010102010104046b6579310b01");
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 6", () {
    final storage = MoneroStorage.fromJson({"key1": false});
    expect(storage.serializeHex(), "01110101010102010104046b6579310b00");
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 7", () {
    final storage = MoneroStorage.fromJson({"key1": "value1"});
    expect(
      storage.serializeHex(),
      "01110101010102010104046b6579310a1876616c756531",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 8", () {
    final storage = MoneroStorage.fromJson({
      "key1":
          "j7FYwb7FSWSDSEZvCzgaG1aMEnffld8NMmcLJdE2wPc6RcnsxptrBFGxuN3pmEs3",
    });
    expect(
      storage.serializeHex(),
      "01110101010102010104046b6579310a01016a374659776237465357534453455a76437a67614731614d456e66666c64384e4d6d634c4a6445327750633652636e737870747242464778754e33706d457333",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 9", () {
    final storage = MoneroStorage.fromJson({
      "key1": ["string1", "string2", "string3"],
    });
    expect(
      storage.serializeHex(),
      "01110101010102010104046b6579318a0c1c737472696e67311c737472696e67321c737472696e6733",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 10", () {
    final storage = MoneroStorage.fromJson({
      "key1": ["A", "B", "C"],
      "key2": 1,
      "key3": "C",
      "key4": [1, 2, 3, 4],
    });
    expect(
      storage.serializeHex(),
      "01110101010102010110046b6579318a0c044104420443046b657932050100000000000000046b6579330a0443046b65793485100100000000000000020000000000000003000000000000000400000000000000",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 11", () {
    final storage = MoneroStorage.fromJson({
      "key1": {"number1": 1},
    });
    expect(
      storage.serializeHex(),
      "01110101010102010104046b6579310c04076e756d62657231050100000000000000",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 12", () {
    final storage = MoneroStorage.fromJson({
      "key1": {
        "number1": 1,
        "value1": [1, 2],
        "value3": ["A", "E"],
        "value4": null,
      },
      "key2": 12,
      "key3": false,
      "key4": 1.23,
    });
    expect(
      storage.serializeHex(),
      "01110101010102010110046b6579310c0c076e756d626572310501000000000000000676616c7565318508010000000000000002000000000000000676616c7565338a0804410445046b657932050c00000000000000046b6579330b00046b65793409ae47e17a14aef33f",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 13", () {
    final storage = MoneroStorage.fromJson({
      "AAA1": [
        {"number": 1},
      ],
    });
    expect(
      storage.serializeHex(),
      "0111010101010201010404414141318c0404066e756d626572050100000000000000",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 14", () {
    final storage = MoneroStorage.fromJson({
      "AAA1": [
        {
          "number": 1,
          "stringa": "A",
          "doubleB": 1233.9999,
          "array1": [1, 2, 3],
          "struct": {"number": 25},
        },
      ],
    });
    expect(
      storage.serializeHex(),
      "0111010101010201010404414141318c041406617272617931850c01000000000000000200000000000000030000000000000007646f75626c654209151dc9e5ff479340066e756d62657205010000000000000007737472696e67610a0441067374727563740c04066e756d626572051900000000000000",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 15", () {
    final storage = MoneroStorage.fromJson({
      "AAA1": [{}],
    });
    expect(storage.serializeHex(), "0111010101010201010404414141318c0400");
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 16", () {
    final storage = MoneroStorage.fromJson({"AAA1": -1});
    expect(
      storage.serializeHex(),
      "01110101010102010104044141413101ffffffffffffffff",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 17", () {
    final storage = MoneroStorage.fromJson({
      "AAA1": [-1, -2, -3, -12],
    });
    expect(
      storage.serializeHex(),
      "0111010101010201010404414141318110fffffffffffffffffefffffffffffffffdfffffffffffffff4ffffffffffffff",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
  test("json to binary 18", () {
    final storage = MoneroStorage.fromJson({
      'user': {
        'id': 12345,
        'name': 'Alice',
        'address': {
          'street': '123 Main St',
          'city': 'Wonderland',
          'zip': '12345',
          'coordinates': {'latitude': 35.6895, 'longitude': 139.6917},
        },
        'preferences': {
          'theme': 'dark',
          'notifications': {'email': true, 'sms': false, 'push': true},
        },
      },
      'orders': [
        {
          'orderId': 'OD001',
          'products': [
            {
              'productId': 'P001',
              'name': 'Laptop',
              'quantity': 1,
              'price': 999.99,
              'attributes': {'color': 'Gray', 'warranty': '2 years'},
            },
            {
              'productId': 'P002',
              'name': 'Mouse',
              'quantity': 2,
              'price': 25.99,
              'attributes': {'color': 'Black', 'warranty': '1 year'},
            },
          ],
          'shipping': {
            'method': 'Express',
            'address': {
              'street': '456 Tech Ave',
              'city': 'Innoville',
              'zip': '98765',
            },
          },
          'totalPrice': 1051.97,
        },
        {
          'orderId': 'OD002',
          'products': [
            {
              'productId': 'P003',
              'name': 'Headphones',
              'quantity': 1,
              'price': 199.99,
              'attributes': {'color': 'White', 'warranty': '2 years'},
            },
          ],
          'shipping': {
            'method': 'Standard',
            'address': {
              'street': '789 Music Ln',
              'city': 'BeatTown',
              'zip': '45678',
            },
          },
          'totalPrice': 199.99,
        },
      ],
      'wishlist': [
        {'productId': 'P004', 'name': 'Smartphone', 'price': 799.99},
        {'productId': 'P005', 'name': 'Tablet', 'price': 499.99},
      ],
      'settings': {
        'language': 'English',
        'currency': 'USD',
        'accountType': 'Premium',
        'features': {
          'cloudBackup': true,
          'multiFactorAuth': true,
          'adFree': false,
        },
      },
      'activityLog': [
        {
          'activityId': 'A001',
          'timestamp': '2024-10-04T08:30:00Z',
          'action': 'Logged in',
          'device': {
            'type': 'Desktop',
            'os': 'Windows 10',
            'location': {'city': 'Wonderland', 'country': 'MagicLand'},
          },
        },
        {
          'activityId': 'A002',
          'timestamp': '2024-10-04T09:00:00Z',
          'action': 'Placed an Order',
          'orderId': 'OD001',
        },
      ],
    });
    expect(
      storage.serializeHex(),
      "011101010101020101140b61637469766974794c6f678c081006616374696f6e0a244c6f6767656420696e0a616374697669747949640a1041303031066465766963650c0c086c6f636174696f6e0c0804636974790a28576f6e6465726c616e6407636f756e7472790a244d616769634c616e64026f730a2857696e646f777320313004747970650a1c4465736b746f700974696d657374616d700a50323032342d31302d30345430383a33303a30305a1006616374696f6e0a3c506c6163656420616e204f726465720a616374697669747949640a1041303032076f7264657249640a144f443030310974696d657374616d700a50323032342d31302d30345430393a30303a30305a066f72646572738c0810076f7264657249640a144f443030310870726f64756374738c08140a617474726962757465730c0805636f6c6f720a10477261790877617272616e74790a1c32207965617273046e616d650a184c6170746f700570726963650952b81e85eb3f8f400970726f6475637449640a1050303031087175616e74697479050100000000000000140a617474726962757465730c0805636f6c6f720a14426c61636b0877617272616e74790a18312079656172046e616d650a144d6f757365057072696365093d0ad7a370fd39400970726f6475637449640a1050303032087175616e74697479050200000000000000087368697070696e670c0807616464726573730c0c04636974790a24496e6e6f76696c6c65067374726565740a30343536205465636820417665037a69700a143938373635066d6574686f640a1c457870726573730a746f74616c5072696365097b14ae47e16f904010076f7264657249640a144f443030320870726f64756374738c04140a617474726962757465730c0805636f6c6f720a1457686974650877617272616e74790a1c32207965617273046e616d650a284865616470686f6e65730570726963650948e17a14aeff68400970726f6475637449640a1050303033087175616e74697479050100000000000000087368697070696e670c0807616464726573730c0c04636974790a2042656174546f776e067374726565740a30373839204d75736963204c6e037a69700a143435363738066d6574686f640a205374616e646172640a746f74616c50726963650948e17a14aeff68400873657474696e67730c100b6163636f756e74547970650a1c5072656d69756d0863757272656e63790a0c5553440866656174757265730c0c066164467265650b000b636c6f75644261636b75700b010f6d756c7469466163746f72417574680b01086c616e67756167650a1c456e676c69736804757365720c1007616464726573730c1004636974790a28576f6e6465726c616e640b636f6f7264696e617465730c08086c6174697475646509c74b378941d84140096c6f6e6769747564650995d4096822766140067374726565740a2c313233204d61696e205374037a69700a143132333435026964053930000000000000046e616d650a14416c6963650b707265666572656e6365730c080d6e6f74696669636174696f6e730c0c05656d61696c0b0104707573680b0103736d730b00057468656d650a106461726b08776973686c6973748c080c046e616d650a28536d61727470686f6e650570726963650952b81e85ebff88400970726f6475637449640a10503030340c046e616d650a185461626c657405707269636509a4703d0ad73f7f400970726f6475637449640a1050303035",
    );
    final decode = MoneroStorage.deserialize(storage.serialize());
    expect(storage.serializeHex(), decode.serializeHex());
  });
}
