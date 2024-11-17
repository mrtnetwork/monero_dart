import 'package:monero_dart/src/provider/core/core.dart';

/// Connect the RPC server to a Monero daemon.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#set_daemon
class WalletRequestSetDaemon
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestSetDaemon({
    this.address,
    this.trusted,
    this.sslSupport,
    this.sslPrivateKeyPath,
    this.sslCertificatePath,
    this.sslCaFile,
    this.sslAllowedFingerprints,
    this.sslAllowAnyCert,
    this.username,
    this.password,
    this.proxy,
  });

  final String? address;
  final bool? trusted;
  final String? sslSupport;
  final String? sslPrivateKeyPath;
  final String? sslCertificatePath;
  final String? sslCaFile;
  final List<String>? sslAllowedFingerprints;
  final bool? sslAllowAnyCert;
  final String? username;
  final String? password;
  final String? proxy;

  @override
  String get method => "set_daemon";
  @override
  Map<String, dynamic> get params => {
        "address": address,
        "trusted": trusted,
        "ssl_support": sslSupport,
        "ssl_private_key_path": sslPrivateKeyPath,
        "ssl_certificate_path": sslCertificatePath,
        "ssl_ca_file": sslCaFile,
        "ssl_allowed_fingerprints": sslAllowedFingerprints,
        "ssl_allow_any_cert": sslAllowAnyCert,
        "username": username,
        "password": password,
        "proxy": proxy,
      };

  @override
  void onResonse(Map<String, dynamic> result) {}
}
