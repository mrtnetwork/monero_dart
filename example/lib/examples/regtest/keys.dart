// Monero regtest: keys and addresses (offline, no chain access).

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/examples/local/monero_node.dart';
import 'package:monero_dart/monero_dart.dart';

void main() {
  print('Monero regtest: keys and addresses');

  /// Deterministic accounts: the same index always yields the same address.
  final alice = moneroAccountKeys(0);
  final bob = moneroAccountKeys(1);

  print('');
  print('alice (index 0)');
  print(field('primary', alice.primaryAddress().address));
  print(
    field(
      'subaddress 1/0',
      alice.subAddress(const MoneroSubIndex.unsafe(minor: 1)).address,
    ),
  );
  print(
    field(
      'subaddress 2/0',
      alice.subAddress(const MoneroSubIndex.unsafe(minor: 2)).address,
    ),
  );
  print(field('spend pub', _hex(alice.account.pubSkey.toBytes())));
  print(field('view pub', _hex(alice.account.pubVkey.toBytes())));

  print('');
  print('bob (index 1)');
  print(field('primary', bob.primaryAddress().address));
  print(field('spend pub', _hex(bob.account.pubSkey.toBytes())));

  print('');
  print('same seed, different indexes give unrelated accounts:');
  print(field(
      'same address', '${alice.primaryAddress() == bob.primaryAddress()}'));

  print('');
  print('an integrated address embeds a payment id:');
  final paymentId = List<int>.generate(8, (i) => i + 1);
  final integrated = alice.integratedAddress(paymentId: paymentId);
  print(field('payment id', BytesUtils.toHexString(paymentId)));
  print(field('address', integrated.address));
  print(
    field(
      'decodes back',
      '${MoneroAddress(integrated.address).address == integrated.address}',
    ),
  );

  print('');
  print('an address carries its own network and type:');
  final decoded = MoneroAddress(alice.primaryAddress().address);
  print(field('network', '${decoded.network}'));
  print(field('type', '${decoded.type}'));
  print(field('is subaddress', '${decoded.isSubaddress}'));
  print(field('is standard', '${decoded.isStdAddress}'));
}

String _hex(List<int> bytes) => BytesUtils.toHexString(bytes);
