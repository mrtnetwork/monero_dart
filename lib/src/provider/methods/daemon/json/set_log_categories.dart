import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Set the daemon log categories. Categories are represented as a comma separated list of
/// <Category>:<level> (similarly to syslog standard <Facility>:<Severity-level>
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#set_log_categories
class DaemonRequestSetLogCategories extends MoneroDaemonRequestParam<
    DaemonSetLogCategoriesResponse, Map<String, dynamic>> {
  const DaemonRequestSetLogCategories(this.categories);
  final String categories;

  @override
  String get method => "set_log_categories";
  @override
  Map<String, dynamic> get params => {"categories": categories};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonSetLogCategoriesResponse onResonse(Map<String, dynamic> result) {
    return DaemonSetLogCategoriesResponse.fromJson(result);
  }
}
