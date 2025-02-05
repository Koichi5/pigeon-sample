import 'package:pigeon_sample/preference/preference.g.dart';

class SharedPreferencesPigeon {
  final PreferenceApi _api = PreferenceApi();

  Future<bool> setValue(String key, Object value) async {
    return _api.setValue(Preference(key: key, value: value));
  }

  Future<bool> remove(String key) async {
    return _api.remove(key);
  }

  Future<bool> clear() async {
    return _api.clear();
  }

  Future<Map<String, Object>> getAll() async {
    List<Preference> prefs = await _api.getAll();
    return { for (var pref in prefs) pref.key: pref.value! };
  }
}