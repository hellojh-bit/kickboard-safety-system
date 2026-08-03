import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _key = 'isAuthenticated';

  // 인증 상태 저장 (인증 성공 시 호출)
  static Future<void> saveAuthState(bool isAuth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isAuth);
  }

  // 인증 상태 불러오기 (앱 실행 시 호출)
  static Future<bool> loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  // 저장된 유저 ID 불러오기 함수
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // 로그아웃 시 유저 ID 삭제 (필요 시 사용)
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }
  // auth_storage.dart 파일 내부

  static const String _rentalKey = "is_renting";

  // 주행 상태 저장하기 (주행 시작 시 true, 반납 시 false)
  static Future<void> saveRentalStatus(bool isRenting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rentalKey, isRenting);
  }

  // 주행 상태 불러오기
  static Future<bool> getRentalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rentalKey) ?? false; // 데이터 없으면 기본값 false
  }

  static const String _scooterIdKey = "saved_scooter_id";

  static Future<void> saveId(String scooterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scooterIdKey, scooterId);
  }

  static Future<String?> getSavedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scooterIdKey);
  }

  static const String _rideStartTimeKey = "ride_start_time";

  static Future<void> saveRideStartTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rideStartTimeKey, time.toIso8601String());
  }

  static Future<DateTime?> getRideStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_rideStartTimeKey);

    if (value == null || value.isEmpty) return null;

    return DateTime.tryParse(value);
  }

  static Future<void> clearRideStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rideStartTimeKey);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<void> clearUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
  }
}
