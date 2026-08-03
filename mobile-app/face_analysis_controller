import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // WriteBuffer 사용을 위해 필수

class FaceAnalysisController {
  // 1. ML Kit Face Detector 설정 (속도 우선 모드)
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  // 2. 상태 관리 변수
  bool _isAnalyzing = false; // 중복 분석 방지용 플래그

  /// [핵심 기능] CameraImage(NV21 등)를 ML Kit용 InputImage로 변환합니다.
  /// main.dart에 있던 복잡한 변환 로직을 모듈 내부로 캡슐화했습니다.
  InputImage _convertCameraImage(CameraImage image, int rotation) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: allBytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation:
            InputImageRotationValue.fromRawValue(rotation) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  /// [핵심 기능] 이미지를 분석하여 감지된 얼굴 리스트를 반환합니다.
  /// 판정 로직(isValid)과 시간 로직은 main.dart에서 처리하므로, 여기서는 Face 데이터만 넘겨줍니다.[cite: 1]
  Future<List<Face>?> processImage(
    CameraImage image,
    int sensorOrientation,
  ) async {
    // 이미 분석 중이면 새로운 요청을 무시합니다.[cite: 1]
    if (_isAnalyzing) return null;
    _isAnalyzing = true;

    try {
      // 1. 이미지 변환 수행[cite: 1]
      final inputImage = _convertCameraImage(image, sensorOrientation);

      // 2. 얼굴 인식 수행 및 결과 반환[cite: 1]
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      debugPrint("얼굴 인식 모듈 에러: $e");
      return null;
    } finally {
      // 분석이 완료되면 플래그를 해제하여 다음 프레임을 받을 수 있게 합니다.[cite: 1]
      _isAnalyzing = false;
    }
  }

  /// 자원 해제: main.dart의 dispose()에서 호출해야 합니다.[cite: 1]
  void dispose() {
    _faceDetector.close();
  }
}
