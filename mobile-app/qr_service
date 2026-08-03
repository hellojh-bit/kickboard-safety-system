import 'dart:async';
import 'package:app_links/app_links.dart'; // 패키지 변경 사유: 구식 패키지 (변경 : uni_links > ani_links)
import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';

class ScooterConnector {
  static final ScooterConnector _instance = ScooterConnector._internal();
  factory ScooterConnector() => _instance;
  ScooterConnector._internal();

  final Dio _dio = Dio();
  final FlutterTts _tts = FlutterTts();
  final _appLinks = AppLinks(); // AppLinks 객체 생성
  StreamSubscription? _sub;

  Function(String)? onIdReceived;

 Future<void> init({required Function(String) onIdReceived}) async {
    this.onIdReceived = onIdReceived;

    // 1. 앱이 꺼져있을 때 QR로 켜진 경우 확인
    try {
      final initialUri = await _appLinks.getInitialLink(); 
      if (initialUri != null) {
        await handleLink(initialUri.toString());
      }
    } catch (e) {
      debugPrint("초기 링크 에러: $e");
    }

    // 2. 앱 실행 중에 실시간으로 들어오는 링크 감시
    _sub = _appLinks.uriLinkStream.listen((uri) {
      handleLink(uri.toString());
    }, onError: (err) => debugPrint("딥링크 리스너 에러: $err"));
  }

  Future<void> _speakAndWait(String text) async {
    Completer completer = Completer();
    _tts.setCompletionHandler(() => completer.complete());
    await _tts.speak(text);
    return completer.future;
  }

  Future<void> handleLink(String link, {String? userId}) async {
    Uri uri = Uri.parse(link);
    String? id = uri.queryParameters['id'];

    if (id != null) {
      onIdReceived?.call(id);

      await _tts.setLanguage("ko-KR");
      await _tts.setSpeechRate(0.6);
      await _speakAndWait("킥보드가 연결되었습니다.");

      try {
        await _dio.post(
          'http://10.42.0.1:5000/connect',
          data: {'user_id': userId, 'scooter_id': id},
        );
      } catch (e) {
        debugPrint("서버 전송 실패: $e");
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

class ReturnService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://10.42.0.1:5000';

  Future<bool> returnScooter(String userId, String scooterId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/return',
        data: {'user_id': userId, 'scooter_id': scooterId},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("반납 서버 통신 에러: $e");
      return false;
    }
  }
}
