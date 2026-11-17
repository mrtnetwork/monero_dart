/// Shared suite body for all levels (L1 VM-dart, L2 web-dart, L3 VM-ffi,
/// L4 web-wasm). Backend must be selected before calling (see
/// `one_shot_test.dart` / `one_shot_browser_*_test.dart` entries).
library;

import 'address_test.dart' as f0;
import 'provider_encodable_params_test.dart' as f1;
import 'rct/bullet_proof_plus/interop_rust_test.dart' as f18;
import 'rct/proof_test.dart' as f2;
import 'rct/clsag/cslag_fast_test.dart' as f3;
import 'rct/clsag/cslag_test.dart' as f4;
import 'rct/bullet_proof_plus/bullet_proof_test.dart' as f5;
import 'crypto/debug_test.dart' as f6;
import 'crypto/derive_public_key_test.dart' as f7;
import 'crypto/generate_key_image_test.dart' as f8;
import 'crypto/hash_to_ec_test.dart' as f9;
import 'crypto/key_drivation_test.dart' as f10;
import 'crypto/op_test.dart' as f11;
import 'crypto/signature_test.dart' as f12;
import 'multisig/multisig_test.dart' as f13;
import 'serialization/exception_test.dart' as f14;
import 'serialization/storage_serialize_test.dart' as f15;
import 'serialization/transaction_serialize_test.dart' as f16;
import 'serialization/tx_extra_test.dart' as f17;
import 'backend_identity_test.dart' as f18;

void runOneShotSuite() {
  f18.backendIdentityTest();
  f0.addressTest();
  f1.providerEncodableParamsTest();
  f2.proofTest();
  f3.cslagFastTest();
  f4.cslagTest();
  f5.bulletProofTest();
  f6.debugTest();
  f7.derivePublicKeyTest();
  f8.generateKeyImageTest();
  f9.hashToEcTest();
  f10.keyDrivationTest();
  f11.opTest();
  f12.signatureTest();
  f13.multisigTest();
  f14.exceptionTest();
  f15.storageSerializeTest();
  f16.transactionSerializeTest();
  f17.txExtraTest();
  f18.nativeProof();
}
