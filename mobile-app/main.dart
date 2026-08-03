import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'qr_service.dart';
import 'auth_storage.dart';
import 'statue_view.dart';
import 'my_camera_view.dart';
import 'register_view.dart';
import 'find_id_view.dart';
import 'reset_password_view.dart';

String? currentUserId;
late List<CameraDescription> _cameras;

DateTime? _stableStartTime;
DateTime? _lastUpdateTime;

// 카메라 목록 불러온 후 앱 실행
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화
  try {
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint('카메라 로드 실패: $e');
    _cameras = [];
  }
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()),
  );
}

// 스플래시 화면 (앱 시작 시 로고 및 로딩 UI 표시 -> 메인 화면)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2.5초 후 메인 화면 전환
    Timer(const Duration(milliseconds: 2500), () async {
      // 필요한 모든 상태를 가져옵니다.
      String? userId = await AuthStorage.getUserId();
      bool isAutoLogin = await AuthStorage.loadAuthState();

      // 현재 주행 중인지 확인하는 값을 가져옵니다.
      // (AuthStorage에 주행 상태 저장 로직이 필요합니다)
      bool isRenting = await AuthStorage.getRentalStatus();

      if (!mounted) return;

      // 조건 판단
      // 상황 A: 자동 로그인이 켜져 있음
      // 상황 B: 자동 로그인은 꺼져 있지만, 현재 '주행 중'임 (강제 유지)
      if (userId != null && userId.isNotEmpty && (isAutoLogin || isRenting)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HelmetApp()),
        );
      } else {
        // 주행 중도 아니고 자동 로그인도 아니면 로그인 화면으로
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color mainPointColor = Color.fromARGB(255, 24, 1, 61);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFb5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    bottom: 0,
                    child: Icon(
                      Icons.electric_scooter, // 플러터 기본 아이콘
                      size: 100,
                      color: mainPointColor,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 35,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFFb5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        size: 45,
                        color: mainPointColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Safety kickBoard\n"
              "헬멧을 착용해주세요",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isAutoLogin = false;

  Future<void> _onLoginPressed() async {
    //테스트용: 본 서버 통신 건너뛰기 (변경 : ture > false)
    const bool isTestMode = false;
    if (isTestMode) {
      String loginId = _idController.text;

      if (loginId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("아이디를 입력해주세요")));
        return;
      }

      await AuthStorage.saveUserId(loginId);
      await AuthStorage.saveAuthState(_isAutoLogin);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HelmetApp()),
      );

      return;
    } 

    // 핫스팟 서버 연결 (변경 : 서버주소 > 10.42.0.1)
    try {
      Dio dio = Dio();

      final response = await dio.post(
        'http://10.42.0.1:5000//auth/login',
        data: {'user_id': _idController.text, 'password': _pwController.text},
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['result'] == 'SUCCESS') {
        String loginId = _idController.text;

        await AuthStorage.saveUserId(loginId);
        await AuthStorage.saveAuthState(_isAutoLogin);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HelmetApp()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("아이디 또는 비밀번호가 올바르지 않습니다.")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("로그인 실패")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFb5), // 노란색 배경
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "로그인",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  hintText: "아이디",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "비밀번호",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D191),
                  ), // 이미지와 같은 민트색
                  child: const Text(
                    "로그인",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isAutoLogin,
                    onChanged: (v) => setState(() => _isAutoLogin = v!),
                  ),
                  const Text("자동로그인"),
                ],
              ),
              const SizedBox(height: 20, width: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FindIdView()),
                      );
                    },
                    child: const Text(
                      "아이디 찾기",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordView(),
                        ),
                      );
                    },
                    child: const Text(
                      "비밀번호 찾기",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterView()),
                      );
                    },
                    child: const Text(
                      "회원가입",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 메인 앱 화면
class HelmetApp extends StatefulWidget {
  const HelmetApp({super.key});
  @override
  State<HelmetApp> createState() => _HelmetAppState();
}

class _HelmetAppState extends State<HelmetApp> with WidgetsBindingObserver {
  // 카메라 제어
  CameraController? controller;
  // 얼굴 인식 객체 (ML Kit)
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );
  // 음성 안내
  final FlutterTts tts = FlutterTts();
  bool isUserLoggedIn = false; // 로그인 성공 여부 (ID 노출용)
  bool isRiding = false; // 헬멧 인증 완료 후 실제 주행 여부 (UI 전환용)
  int _cameraSessionId = 0;
  bool isProcessing = false;
  bool isSessionLocked = false;
  bool _isStreamRunning = false;
  bool _isAnalyzing = false;
  String? connectedScooterId; // 킥보드 id 저장 변수
  bool isAuthenticated = false; // 주행 상태를 저장할 변수
  bool isFaceValid = false;
  String lastSpokenMessage = "";
  bool isSpeaking = false;
  Timer? _rideTimer;
  int _rideSeconds = 0;
  bool isRentalStarted = false;
  bool _isInitializing = false; // 현재 카메라를 켜는 중인지 확인
  String statusMessage = "헬멧을 착용한 후 가이드라인에 얼굴을 맞춰주세요";
  Color popupBgColor = const Color.fromARGB(255, 201, 255, 178);
  final Color pointColor = const Color(0xFFFFFFb5);
  final Color mainPointColor = const Color.fromARGB(255, 0, 0, 0);

  @override
  void initState() {
    super.initState();
    AuthStorage.loadAuthState().then((value) {
      setState(() {
        isUserLoggedIn = value; // 로그인만 된 상태!
      });
    });
    AuthStorage.getRentalStatus().then((isRenting) async {
      final savedScooterId = await AuthStorage.getSavedId();
      final startTime = await AuthStorage.getRideStartTime();

      if (!mounted) return;

      setState(() {
        isRiding = isRenting;

        if (isRenting) {
          isAuthenticated = true;
          connectedScooterId = savedScooterId;

          if (startTime != null) {
            _rideSeconds = DateTime.now().difference(startTime).inSeconds;
          } else {
            _rideSeconds = 0;
          }
        }
      });

      if (isRenting) {
        _startRideTimer();
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _initTts();
    _initCamera();
    ScooterConnector().init(
      onIdReceived: (id) {
        setState(() {
          connectedScooterId = id;
        });
      },
    );
  }

  // 주행 타이머 시작
  void _startRideTimer() {
    _rideTimer?.cancel();
    _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _rideSeconds++);
    });
  }

  // 주행 타이머 정지
  void _stopRideTimer() {
    _rideTimer?.cancel();
  }

  // 초 단위 시간을 00:00 형식으로 변환
  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  void _initTts() async {
    await tts.setLanguage("ko-KR");
    await tts.setSpeechRate(0.5);
    await tts.awaitSpeakCompletion(false);
    // TTS 상태 리스너 등록
    tts.setStartHandler(() {
      if (mounted) setState(() => isSpeaking = true);
    });
    tts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
    tts.setErrorHandler((msg) {
      if (mounted) setState(() => isSpeaking = false);
    });
  }

  Future<void> speakSafe(String message) async {
    if (isSpeaking || lastSpokenMessage == message) return;
    lastSpokenMessage = message;
    await tts.speak(message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) lastSpokenMessage = "";
    });
  }

  Future<void> _initCamera() async {
    if (_cameras.isEmpty || _isInitializing) return;
    if (controller != null && controller!.value.isInitialized) {
      debugPrint("이미 카메라가 초기화되어 있습니다. 스트리밍만 확인합니다.");
      if (!_isStreamRunning) {
        _startStreaming();
      }
      return;
    }
    _isInitializing = true;
    _isStreamRunning = false;

    try {
      // 완전히 새로 시작해야 하는 경우에만 기존 것 정리
      if (controller != null) {
        await controller!.dispose();
        controller = null;
        if (mounted) setState(() {});
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras[0],
      );
      _cameraSessionId++;
      controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      // 신규 초기화 실행
      await controller!.initialize();

      if (!mounted) return;

      //await Future.delayed(const Duration(milliseconds: 1000));

      if (controller != null && controller!.value.isInitialized) {
        _startStreaming();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("카메라 초기화 실패: $e");
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startStreaming() async {
    if (controller == null || !controller!.value.isInitialized) return;
    if (isSessionLocked || isProcessing || _isStreamRunning) return;
    _isStreamRunning = true;
    await controller!.startImageStream((image) {
      if (!isProcessing && !isSessionLocked && !_isAnalyzing) {
        _analyzeImage(image);
      }
    });
  }

  Future<void> _analyzeImage(CameraImage image) async {
    if (isSessionLocked || _isAnalyzing) return;
    _isAnalyzing = true;
    try {
      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation:
              InputImageRotationValue.fromRawValue(
                controller!.description.sensorOrientation,
              ) ??
              InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty || faces.length > 1) {
        _stableStartTime = null; // 시간 초기화
        setState(() => isFaceValid = false);
        _updateUI(
          faces.length > 1 ? "한 분만 촬영해 주세요." : "헬멧을 착용한 후 가이드라인에 얼굴을 맞춰주세요",
          const Color.fromARGB(255, 201, 255, 178),
        );
        return;
      }

      final face = faces.first;

      // 상세 판정 로직
      final double faceWidthRatio = face.boundingBox.width / image.width;
      final bool isNotTooClose = faceWidthRatio < 0.40; // 거리를 헬멧이 보이게
      final bool frontal =
          (face.headEulerAngleY ?? 0).abs() < 25 &&
          (face.headEulerAngleZ ?? 0).abs() < 25;

      final double faceCenterX = face.boundingBox.center.dx;
      final double faceCenterY = face.boundingBox.center.dy;

      // UI 가이드라인 하단 이동(0.25)을 반영한 중앙 판정
      final bool isCentered =
          faceCenterX > (image.width * 0.2) &&
          faceCenterX < (image.width * 0.8) &&
          faceCenterY > (image.height * 0.3) &&
          faceCenterY < (image.height * 0.9);

      // 헬멧 공간 확보 체크
      final bool hasHelmetSpace = face.boundingBox.top > (image.height * 0.2);

      // 모든 조건 합치기
      bool isValid = isNotTooClose && frontal && isCentered && hasHelmetSpace;

      // 가이드라인 색상 업데이트
      setState(() => isFaceValid = isValid);

      // 시간 기반 촬영 및 메시지 로직
      if (isValid) {
        // 유효한 순간 시간 기록 시작
        _stableStartTime ??= DateTime.now();
        final duration = DateTime.now().difference(_stableStartTime!).inSeconds;

        if (duration >= 2) {
          if (!isProcessing && !isSessionLocked) {
            _stableStartTime = null; // 촬영 직전 초기화
            _updateUI("", popupBgColor);
            _triggerCapture(); // 촬영 트리거 실행
          }
        } else {
          // 카운트다운 메시지 표시
          _updateUI("잠시만 그대로 계세요", const Color.fromARGB(255, 201, 255, 178));
        }
      } else {
        _stableStartTime = null; // 조건 깨지면 즉시 초기화

        // 구체적인 안내 메시지 생성
        String msg = "가이드라인에 얼굴을 맞춰주세요";
        if (!isNotTooClose) {
          msg = "조금 더 멀리서 찍어주세요.";
        } else if (!isCentered) {
          msg = "가이드라인 중앙으로 오세요";
        } else if (!frontal) {
          msg = "정면을 봐주세요";
        } else if (!hasHelmetSpace) {
          msg = "헬멧이 보이게 폰을 조금 높게 들어주세요";
        }

        _updateUI(msg, const Color.fromARGB(255, 201, 255, 178));
      }
    } catch (e) {
      debugPrint("분석 중 오류: $e");
    } finally {
      _isAnalyzing = false;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  Future<void> _triggerCapture() async {
    if (connectedScooterId == null || connectedScooterId!.isEmpty) {
      _updateUI("먼저 킥보드 QR을 스캔해주세요", Colors.redAccent.shade400);
      return;
    }
    if (isProcessing || isSessionLocked || !isFaceValid) return;
    speakSafe("촬영합니다.");
    setState(() {
      isProcessing = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isStreamRunning && controller != null) {
        await controller!.stopImageStream();
        _isStreamRunning = false;
      }
      final file = await controller!.takePicture();
      await _sendToServer(file);
    } catch (e) {
      _handleResult(false, "촬영 오류 발생");
    }
  }

  Future<void> _sendRentalStartToServer(String scooterId) async {
    try {
      Dio dio = Dio();
      await dio.post(
        //서버 (변경 : 서버주소 > 10.42.0.1)
        'http://10.42.0.1:5000/start_rental', // 대여 시작 전용 엔드포인트
        data: {
          'scooter_id': scooterId,
          'user_id': currentUserId,
          'start_time': DateTime.now().toIso8601String(), // 실제 인증 성공 시점의 시간
          'status': 'RENTING',
        },
      );
    } catch (e) {
      debugPrint("대여 시작 서버 전송 실패: $e");
    }
  }

Future<void> _sendToServer(XFile file) async {
    BaseOptions options = BaseOptions(
      connectTimeout: const Duration(seconds: 7),
      receiveTimeout: const Duration(seconds: 5),
    );
    Dio dio = Dio(options);
    
    try {
      // 1. 유저 ID 가져오기
      currentUserId ??= await AuthStorage.getUserId();
      
      // 2. FormData에 파일과 user_id를 모두 포함
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: 'helmet.jpg'),
        'user_id': currentUserId ?? 'test_user', // 👈 서버로 ID를 전송합니다!
      });
      
      // 3. 서버 요청 (경로를 서버와 맞춤: /auth/helmet)
      final response = await dio.post(
        'http://10.42.0.1:5000/auth/helmet', 
        data: formData,
      );
      
      // 4. [중요] 응답 처리 (대소문자 및 결과값 확인)
      // 서버에서 보내준 JSON의 'result'가 'success'인지 확인
      if (response.statusCode == 200 && response.data['result'] == 'success') {
        final bool helmetDetected = response.data['helmet_detected'] ?? false;
        
        if (helmetDetected) {
          // 헬멧 착용 성공 로직
          if (connectedScooterId != null) {
            await _sendRentalStartToServer(connectedScooterId!);
          }
          _handleResult(true, "인증 성공: 헬멧 착용 확인됨");
          
          await Future.delayed(const Duration(seconds: 2));
          await AuthStorage.saveAuthState(true);
          await AuthStorage.saveRentalStatus(true);
          await AuthStorage.saveRideStartTime(DateTime.now());
          await AuthStorage.saveId(connectedScooterId!);
          
          if (!mounted) return;
          setState(() {
            isAuthenticated = true;
            isRiding = true;
          });
          _startRideTimer();
        } else {
          _handleResult(false, "인증 실패: 헬멧 미착용");
        }
      } else {
        _handleResult(false, "서버 응답 오류: ${response.data['message'] ?? '알 수 없음'}");
      }
    } on DioException catch (e) {
      debugPrint("네트워크 에러: $e");
      _handleResult(false, "서버 연결 실패");
    }
  }
  
  // 반납 처리 함수
  void _handleReturn() async {
    //테스트용 (변경 : ture > false)
    const bool isTestMode = false;

    if (isTestMode) {
      _stopRideTimer();

      await AuthStorage.saveAuthState(false);
      await AuthStorage.saveRentalStatus(false);
      await AuthStorage.saveId("");
      await AuthStorage.clearRideStartTime();
      if (!mounted) return;

      setState(() {
        isAuthenticated = false;
        isRiding = false;
        _rideSeconds = 0;
        isSessionLocked = false;
        isProcessing = false;
        isFaceValid = false;
        connectedScooterId = null;
        statusMessage = "정상적으로 반납되었습니다.";
        popupBgColor = Colors.blueAccent;
        _stableStartTime = null;
      });

      await speakSafe("반납이 완료되었습니다.");
      await Future.delayed(const Duration(milliseconds: 300));
      await _initCamera();

      return;
    } //테스트용

    currentUserId ??= await AuthStorage.getUserId();
    if (connectedScooterId == null || currentUserId == null) {
      debugPrint("반납 실패: 필수 데이터 누락 (ID: $currentUserId)");
      speakSafe("반납 정보를 확인할 수 없습니다.");
      return;
    }

    try {
      // 1. qr서비스.dart에 있는 ReturnService를 사용하여 서버에 알림
      final returnService = ReturnService();
      await returnService.returnScooter(connectedScooterId!, currentUserId!);
      await speakSafe("반납이 완료되었습니다. 이용해 주셔서 감사합니다.");

      // 2. 서버 전송 성공 후 앱 상태 초기화 (기존 로직)
      _stopRideTimer();
      await AuthStorage.saveAuthState(false);
      await AuthStorage.saveRentalStatus(false);
      await AuthStorage.saveId("");
      await AuthStorage.clearRideStartTime();
      setState(() {
        isAuthenticated = false;
        isRiding = false;
        _rideSeconds = 0;
        isSessionLocked = false;
        isProcessing = false;
        isFaceValid = false;
        connectedScooterId = null;
        statusMessage = "정상적으로 반납되었습니다.";
        popupBgColor = Colors.blueAccent;
        _stableStartTime = null;
      });
      
await Future.delayed(
  const Duration(milliseconds: 300),
);
      await _initCamera();
    } catch (e) {
      // 서버 전송 실패 시 처리
      debugPrint("반납 에러: $e");
      speakSafe("서버 통신 오류로 반납에 실패했습니다.");
    }
  }

  Future<void> _handleLogout() async {
    if (isRiding || isRentalStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("주행 중에는 로그아웃할 수 없습니다. 먼저 반납해주세요.")),
      );
      return;
    }
    await AuthStorage.saveAuthState(false);
    await AuthStorage.saveRentalStatus(false);
    await AuthStorage.saveId("");
    await AuthStorage.clearUserId();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  // 인증 결과에 따른 후속 처리
  void _handleResult(bool success, String message) {
    if (!mounted) return;
    setState(() {
      isProcessing = false;
      statusMessage = message;
      // 결과에 따라 팝업 색 변경
      popupBgColor = success
          ? Colors.greenAccent.shade400
          : Colors.redAccent.shade400;
      // 성공 시 세션 잠금으로 중복 실행 방지
      if (success) isSessionLocked = true;
    });
    // 음성 안내 (성공, 실패)
    if (success) {
      speakSafe("인증 완료. 안전하게 주행을 시작하세요.");
    } else {
      speakSafe("인증 실패.");
    }
    // 진동 안내
    success
        ? Vibration.vibrate(pattern: [0, 100, 50, 100])
        : Vibration.vibrate(duration: 800);
    // 실패 시 처리 (재시도)
    if (!success) {
      // 3초 후 에러 팝업 사라지게함
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !isSessionLocked) {
          setState(() {
            statusMessage = "헬멧을 착용한 후 가이드라인에 얼굴을 맞춰주세요"; // 기본 안내로 복구
            popupBgColor = const Color.fromARGB(
              255,
              201,
              255,
              178,
            ); // 기본 노란색으로 복구
          });
        }
      });
      // 3초 후 카메라 재시작
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !isSessionLocked) {
          setState(() => isProcessing = false);
          _startStreaming();
        }
      });
    }
  }

  void _updateUI(String msg, Color color) {
    final now = DateTime.now();
    // 2초가 안 지났고, 새 메시지가 빈 값이 아니라면 무시
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inMilliseconds < 2000 &&
        msg.isNotEmpty) {
      return;
    }
    if (statusMessage == msg && popupBgColor == color) return;
    setState(() {
      statusMessage = msg;
      popupBgColor = color;
      _lastUpdateTime = now;
    });
  }

  // 화면 나갈 때 자원 정리
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    controller = null;
    _faceDetector.close();
    tts.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // 앱이 화면에서 사라질 때
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_isStreamRunning) {
        await controller?.stopImageStream();
        _isStreamRunning = false;
      }
      await controller?.pausePreview(); // 죽이지 않고 재우기
    }
    // 앱으로 다시 돌아올 때
    else if (state == AppLifecycleState.resumed) {
      await controller?.resumePreview(); // 깨우기
      if (!_isStreamRunning && !isSessionLocked && !isAuthenticated) {
        _startStreaming();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 카메라 활성 전 로딩 화면
    if (controller == null || !controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: pointColor, // 배경색을 노란색으로 통일
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.black), // 로딩 아이콘
              const SizedBox(height: 20),
              Text(
                "카메라를 준비 중입니다...",
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (isRiding) {
      return Scaffold(
        body: SafeArea(child: _buildRidingScreen()), // 아래 새로 만든 노란 화면 함수 호출
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    // 메인 화면
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFb5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 18),
                Text(
                  "Safety KickBoard\n"
                  "헬멧을 착용해주세요",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                FutureBuilder<String?>(
                  future: AuthStorage.getUserId(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          //사용자
                          "${snapshot.data}님 환영합니다.",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Expanded(
                  flex: 15,
                  child: Center(
                    child: Container(
                      width: screenWidth,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: ClipRect(
                        // 가이드라인이 영역 밖으로 나가지 않게 제한
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 카메라 프리뷰
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: controller!.value.previewSize!.height,
                                  height: controller!.value.previewSize!.width,
                                  child: CameraPreview(
                                    controller!,
                                    key: ValueKey(
                                      'camera_session_$_cameraSessionId',
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 얼굴 가이드라인 (상태별 색상 변경)
                            IgnorePointer(
                              child: Container(
                                width: screenWidth * 0.65, // 가이드 너비
                                height: screenWidth * 0.85, // 가이드 높이
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(150),
                                  border: Border.all(
                                    color: _getGuideColor(), // 색상 결정 로직 호출
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),

                            // 상태 팝업 메시지
                            if (statusMessage.isNotEmpty && !isSessionLocked)
                              Positioned(
                                top: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: popupBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusMessage,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // 하단 버튼 섹션
                Container(
                  height: 135,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap:
                        (isProcessing ||
                            isSessionLocked ||
                            !isFaceValid ||
                            connectedScooterId == null ||
                            connectedScooterId!.isEmpty)
                        ? null
                        : _triggerCapture,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFaceValid
                                  ? Colors.greenAccent
                                  : Colors.grey.withValues(alpha: .5),
                              width: 4,
                            ),
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/helmet_icon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) =>
                                  Icon(Icons.camera_alt, color: mainPointColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 분석 중 오버레이 및 성공 오버레이
            if (isProcessing && !isSessionLocked)
              _buildProcessingOverlay(context),
            if (isSessionLocked) _buildSuccessOverlay(),
            Positioned(
              bottom: 50,
              right: 25,
              child: GestureDetector(
                onTap: _handleLogout,
                child: const Text(
                  "로그아웃",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

            //킥보드 qr코드 인식
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: ScooterStatusView(
                connectedId: connectedScooterId, // 메인의 변수 전달
                onTap: () async {
                  final navigator = Navigator.of(context);
                  String? savedId = await AuthStorage.getUserId();
                  currentUserId = savedId; // 전역 변수 최신화
                  if (currentUserId == null || currentUserId!.isEmpty) {
                    await speakSafe("로그인이 필요합니다.");
                    if (!mounted) return;
                    navigator.push(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                    return;
                  }
                  await speakSafe("QR 코드를 스캔해 주세요.");
                  await Future.delayed(const Duration(milliseconds: 1000));
                  if (_isStreamRunning) {
                    await controller?.stopImageStream();
                    _isStreamRunning = false;
                  }
                  await controller?.dispose();
                  controller = null;

                  final String? scannedData = await navigator.push(
                    MaterialPageRoute(builder: (_) => const MyCameraView()),
                  );
                  if (!mounted) return;

                  _isStreamRunning = false;
                  _isAnalyzing = false;
                  isProcessing = false;
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _initCamera();
                  if (scannedData != null) {
                    String extractedId = "";
                    try {
                      extractedId =
                          Uri.parse(scannedData).queryParameters['id'] ?? "";
                    } catch (e) {
                      debugPrint("QR 파싱 에러: $e");
                    }

                    if (extractedId.isNotEmpty) {
                      // 서버 전송 (사용자 ID 포함)
                      ScooterConnector().handleLink(
                        scannedData,
                        userId: currentUserId,
                      );

                      if (!mounted) return;

                      setState(() {
                        connectedScooterId = extractedId;
                        isSessionLocked = false;
                        statusMessage = "헬멧을 착용한 후 가이드라인에 맞춰주세요";
                      });
                    }
                  }
                },
                // onTap 종료
              ), // ScooterStatusView 종료
            ),
          ],
        ),
      ),
    );
  }

  // 상태에 따른 가이드라인 색상을 반환하는 함수
  Color _getGuideColor() {
    if (popupBgColor == Colors.redAccent.shade400) {
      return Colors.black;
    }
    if (isProcessing) return Colors.black; // 분석 중일 때: 검정색
    if (isFaceValid) return Colors.greenAccent; // 얼굴이 올바르게 위치할 때: 초록색
    return Colors.redAccent.withValues(alpha: .5); // 기본/잘못된 위치일 때: 빨간색(반투명)
  }

  // 로딩 오버레이 UI
  Widget _buildProcessingOverlay(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 15),
              Text(
                "이미지 분석 중...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 성공 오버레이 UI
  Widget _buildSuccessOverlay() {
    return Container(
      color: mainPointColor.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.greenAccent,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              "인증 완료",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "안전하게 주행을 시작하세요!",
              style: TextStyle(
                color: Color.fromARGB(179, 253, 253, 253),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidingScreen() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFFb5), // 노란색 배경
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "주행시간", // 상단 가운데 검정 글씨
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white, // 흰색 네모칸
              borderRadius: BorderRadius.circular(20), // 끝이 둥근 형태
            ),
            child: Text(
              _formatDuration(_rideSeconds), // 큰 검정 글씨 시간
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 80),
          GestureDetector(
            onTap: _handleReturn,
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6), // 검정 반투명 네모칸
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: const Text(
                "반납하기", // 흰색 글씨
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
