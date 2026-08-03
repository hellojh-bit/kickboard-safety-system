# Kickboard Safety System

## 1. 프로젝트 소개

이 저장소는 **개인형 이동장치 통합 안전 제어 시스템** 프로젝트의 코드와 문서 자료를 정리한 저장소입니다.

본 프로젝트는 전동 킥보드와 같은 개인형 이동장치 이용 시 발생할 수 있는 **안전모 미착용**과 **다인 탑승** 문제를 사전에 감지하고, 위험 상황이 확인되면 주행을 제한하여 사용자의 안전을 확보하는 것을 목표로 합니다.

시스템은 크게 다음 요소로 구성됩니다.

* Flutter 모바일 앱을 통한 사용자 인증 및 헬멧 인증 요청
* QR 코드를 이용한 사용자와 킥보드 연결
* 모바일 카메라를 이용한 사용자 얼굴 위치 확인 및 이미지 촬영
* Flask 서버를 통한 API 처리 및 데이터 관리
* YOLO 기반 안전모 착용 여부 판별
* Google Colab을 이용한 YOLO 헬멧 감지 모델 학습
* SQLite 기반 사용자 및 주행 로그 저장
* 라즈베리파이 기반 로드셀 하중 분석
* 다인 탑승 감지 시 LED, 경고음, 모터 제어
* 웹 대시보드를 통한 실시간 하중 데이터 확인

현재 저장소는 서버, 인공지능 모델, YOLO 모델 학습 코드, 라즈베리파이 제어 코드, 모바일 애플리케이션 소스 코드, 논문 및 보고서 자료를 보관하기 위한 목적으로 구성되어 있습니다.

---

## 2. 프로젝트 목적

개인형 이동장치의 보급이 확대되면서 안전모 미착용, 다인 탑승, 조향 불안정 등으로 인한 사고 위험이 증가하고 있습니다.

기존의 안전 관리는 사용자의 자율적인 준수나 사후 단속에 의존하는 경우가 많습니다. 본 프로젝트는 이러한 한계를 줄이기 위해 주행 시작 전과 주행 중에 사용자의 안전 상태를 실시간으로 확인하고, 위험 상황이 발생하면 물리적으로 주행을 제한하는 통합 안전 시스템을 구현하는 것을 목적으로 합니다.

특히 다음 두 가지 문제를 중점적으로 해결하고자 했습니다.

1. 안전모를 착용하지 않은 사용자의 주행 제한
2. 2인 이상 다인 탑승이 감지될 경우 주행 제한 및 경고

이를 위해 모바일 애플리케이션, Flask 서버, YOLO 인공지능 모델, SQLite 데이터베이스, 라즈베리파이, 로드셀 센서, 모터 제어 장치와 웹 대시보드를 하나의 시스템으로 연결했습니다.

---

## 3. 주요 기능

### 1) 사용자 인증 및 계정 관리

* 사용자 회원가입
* 사용자 로그인
* 자동 로그인 상태 저장
* 이름과 전화번호를 이용한 아이디 찾기
* 사용자 정보 확인 후 비밀번호 재설정
* 로그인한 사용자 ID를 모바일 기기에 저장
* 로그아웃 시 저장된 사용자 정보 초기화

### 2) 사용자 및 킥보드 연결

* 모바일 앱을 이용한 킥보드 QR 코드 스캔
* QR 코드에서 킥보드 ID 추출
* 사용자 ID와 킥보드 ID를 Flask 서버로 전송
* 킥보드 연결 상태를 모바일 화면에 표시
* 딥링크를 통한 킥보드 연결 처리
* 연결 완료 시 음성 안내 제공

### 3) 모바일 카메라 기반 촬영 안내

* 전면 카메라를 이용한 사용자 얼굴 촬영
* ML Kit 얼굴 감지를 이용한 얼굴 위치 확인
* 얼굴이 한 명만 촬영되고 있는지 확인
* 얼굴이 카메라와 너무 가깝지 않은지 확인
* 얼굴이 화면 중앙에 위치하는지 확인
* 사용자가 정면을 바라보고 있는지 확인
* 헬멧이 보일 수 있도록 얼굴 위쪽 공간 확보 여부 확인
* 촬영 조건이 충족되면 자동 촬영 진행
* 촬영 상황에 따라 화면 문구와 음성으로 안내

### 4) AI 기반 헬멧 착용 판별

* 모바일 앱에서 촬영한 이미지를 Flask 서버로 전송
* 로그인한 사용자 ID와 촬영 이미지를 함께 전송
* YOLO 모델을 이용하여 이미지에서 헬멧 객체 감지
* 헬멧 착용 여부를 서버에서 판별
* 헬멧 착용이 확인된 경우에만 주행 시작 단계로 진행
* 인증 성공 또는 실패 결과를 모바일 앱에 전달
* 인증 결과를 화면, 음성 및 진동으로 안내

### 5) YOLO 헬멧 감지 모델 학습

* Google Drive에 저장된 VOC 형식 데이터셋 불러오기
* VOC XML 라벨을 YOLO TXT 형식으로 변환
* 이미지와 라벨을 YOLO 표준 폴더 구조로 구성
* `data.yaml` 데이터셋 설정 파일 생성
* `hat`, `person` 클래스를 이용한 객체 감지 모델 학습
* 학습 완료 후 최적 가중치 `best.pt` 생성
* 테스트 이미지에서 헬멧 객체 감지 여부 확인
* 헬멧 감지 시 `Y`, 미감지 시 `N` 출력

### 6) 로드셀 기반 다인 탑승 감지

* 라즈베리파이에 연결된 8채널 로드셀 데이터를 수집
* 각 로드셀의 개별 하중 측정
* 전체 센서의 총 하중 계산
* 일정 기준 이상 활성화된 센서 개수 확인
* 센서별 하중 분포 분석
* 하중 데이터의 표준편차 분석
* 다인 탑승 가능성이 있는지 판단
* 다인 탑승으로 판단되면 모터 정지 및 경고 상태로 전환

### 7) 주행 허용 및 차단 제어

* 서버에서 헬멧 인증 여부 확인
* 서버에서 다인 탑승 여부 확인
* 헬멧 인증과 탑승 상태를 종합하여 최종 주행 가능 여부 판단
* 라즈베리파이가 서버 응답을 받아 모터 상태 제어
* 정상 상태에서는 주행 허용
* 위험 상태에서는 주행 차단
* LED를 이용하여 현재 상태 표시
* 다인 탑승 또는 위험 상태 발생 시 경고음 출력

### 8) 대여 시작 및 반납 처리

* 헬멧 인증 성공 후 대여 시작 정보 서버 전송
* 사용자 ID, 킥보드 ID, 대여 시작 시간 저장
* 현재 주행 상태를 모바일 기기에 저장
* 앱이 다시 실행되더라도 주행 상태 유지
* 주행 중 경과 시간을 모바일 화면에 표시
* 반납 시 서버에 사용자와 킥보드 정보 전송
* 반납 완료 후 저장된 주행 상태 및 시간 초기화
* 주행 중에는 로그아웃을 제한하여 상태 유실 방지

### 9) 실시간 대시보드

* 최신 로드셀 데이터를 웹 화면에 표시
* 전체 하중 변화 그래프 제공
* 8개 로드셀 센서 값을 개별적으로 표시
* 센서별 하중을 히트맵 형태로 시각화
* 다인 탑승 감지 상태 표시
* 일정 주기로 서버 API를 호출하여 화면 갱신

---

## 4. 파일 구성

| 경로                                         | 파일명                             | 설명                                                                                 |
| ------------------------------------------ | ------------------------------- | ---------------------------------------------------------------------------------- |
| `server/app.py`                            | `app.py`                        | Flask 서버 메인 파일입니다. 회원가입, 로그인, 헬멧 인증, 킥보드 연결, 라즈베리파이 상태 수신 및 대시보드 API를 처리합니다.       |
| `server/DB.py`                             | `DB.py`                         | SQLite 데이터베이스 생성 및 로그 저장을 담당합니다. 사용자 정보, 헬멧 인증 로그, 로드셀 하중 로그와 주행 로그를 관리합니다.        |
| `server/AI_Helmet.py`                      | `AI_Helmet.py`                  | YOLO 모델을 이용하여 이미지에서 헬멧 착용 여부를 판별합니다.                                               |
| `server/models/best.pt`                    | `best.pt`                       | 학습 완료 후 Flask 서버에서 헬멧 착용 여부를 판별할 때 사용하는 YOLO 가중치 파일입니다.                            |
| `server/templates/dashboard.html`          | `dashboard.html`                | 실시간 하중 데이터와 다인 탑승 여부를 보여주는 웹 대시보드 화면입니다.                                           |
| `raspberry-pi/rpi_algorithm.py`            | `rpi_algorithm.py`              | 라즈베리파이에서 실행되는 하드웨어 제어 코드입니다. 로드셀, 모터, LED, 스위치, 경고음 및 서버 통신을 담당합니다.                |
| `mobile-app/main.dart`                     | `main.dart`                     | Flutter 모바일 애플리케이션의 시작 파일입니다. 로그인, 카메라 촬영, 헬멧 인증, 주행 시작, 반납 및 화면 전환을 관리합니다.        |
| `mobile-app/auth_api.dart`                 | `auth_api.dart`                 | 회원가입, 아이디 찾기 및 비밀번호 재설정 API 요청을 처리합니다.                                             |
| `mobile-app/auth_storage.dart`             | `auth_storage.dart`             | 로그인 상태, 사용자 ID, 사용자 이름, 킥보드 ID, 주행 상태 및 주행 시작 시간을 모바일 기기에 저장합니다.                   |
| `mobile-app/register_view.dart`            | `register_view.dart`            | 사용자 회원가입 화면과 회원가입 요청을 처리합니다.                                                       |
| `mobile-app/find_id_view.dart`             | `find_id_view.dart`             | 이름과 전화번호를 이용한 사용자 아이디 찾기 화면입니다.                                                    |
| `mobile-app/reset_password_view.dart`      | `reset_password_view.dart`      | 아이디, 이름, 전화번호 확인 후 새로운 비밀번호를 설정하는 화면입니다.                                           |
| `mobile-app/statue_view.dart`              | `statue_view.dart`              | 연결된 킥보드 ID와 연결 상태를 모바일 화면에 표시합니다.                                                  |
| `mobile-app/my_camera_view.dart`           | `my_camera_view.dart`           | 모바일 카메라를 이용하여 킥보드 QR 코드를 인식합니다.                                                    |
| `mobile-app/qr_service.dart`               | `qr_service.dart`               | QR 코드 및 딥링크를 통한 킥보드 연결과 반납 서버 통신을 처리합니다.                                           |
| `mobile-app/face_analysis_controller.dart` | `face_analysis_controller.dart` | 카메라 이미지를 ML Kit 입력 형식으로 변환하고 얼굴 감지를 수행합니다.                                         |
| `training/yolo/train_helmet_yolo_colab.py` | `train_helmet_yolo_colab.py`    | Google Colab에서 VOC XML 라벨을 YOLO 형식으로 변환하고, 데이터셋을 구성한 뒤 헬멧 감지 모델을 학습하고 테스트하는 코드입니다. |
| `docs/paper.hwp`                           | `paper.hwp`                     | 개인형 이동장치 통합 안전 제어 시스템 논문 파일입니다.                                                    |
| `docs/capstone_final_report.hwp`           | `capstone_final_report.hwp`     | 캡스톤 디자인 최종보고서 또는 발표자료입니다. 코드 분석 대상이 아닌 참고 문서입니다.                                   |
| `analysis/code-analysis.md`                | `code-analysis.md`              | 주요 코드 파일의 역할과 기능을 정리한 분석 문서입니다.                                                    |
| `requirements.txt`                         | `requirements.txt`              | Flask 서버 실행에 필요한 Python 패키지 목록입니다.                                                 |

---

## 5. 폴더 구조

```text
kickboard-safety-system/
├── README.md
├── .gitignore
├── requirements.txt
├── server/
│   ├── app.py
│   ├── DB.py
│   ├── AI_Helmet.py
│   ├── models/
│   │   └── best.pt
│   └── templates/
│       └── dashboard.html
├── raspberry-pi/
│   └── rpi_algorithm.py
├── mobile-app/
│   ├── main.dart
│   ├── auth_api.dart
│   ├── auth_storage.dart
│   ├── register_view.dart
│   ├── find_id_view.dart
│   ├── reset_password_view.dart
│   ├── statue_view.dart
│   ├── my_camera_view.dart
│   ├── qr_service.dart
│   └── face_analysis_controller.dart
├── training/
│   └── yolo/
│       └── train_helmet_yolo_colab.py
├── docs/
│   ├── paper.hwp
│   └── capstone_final_report.hwp
├── analysis/
│   └── code-analysis.md
└── assets/
    └── images/
```

---

## 6. 실행 방법

이 저장소는 프로젝트의 코드와 자료를 보관하고 분석하기 위한 저장소입니다.

Flask 서버와 라즈베리파이 코드는 필요한 실행 환경이 준비된 경우 사용할 수 있습니다. 모바일 애플리케이션 코드는 Dart 소스 코드 보관용으로 저장되어 있으며, 현재 저장소에는 완전한 Flutter 프로젝트 구조가 포함되어 있지 않습니다.

YOLO 학습 코드는 Google Colab 환경을 기준으로 작성되어 있습니다.

### 1) Flask 서버 실행

Python 환경에서 필요한 라이브러리를 설치한 뒤 서버 파일을 실행합니다.

```bash
pip install -r requirements.txt
python server/app.py
```

`requirements.txt`를 사용하지 않는 경우 필요한 패키지를 직접 설치할 수 있습니다.

```bash
pip install flask flask-cors ultralytics
```

서버 실행 후 기본적으로 다음 기능을 사용할 수 있습니다.

* 회원가입 API
* 로그인 API
* 아이디 찾기 API
* 비밀번호 재설정 API
* 킥보드 연결 API
* 헬멧 인증 이미지 업로드 API
* 대여 시작 및 반납 API
* 라즈베리파이 상태 수신 API
* 실시간 대시보드 API

### 2) 대시보드 접속

Flask 서버 실행 후 브라우저에서 다음 주소로 접속합니다.

```text
http://서버IP:5000/dashboard
```

예시:

```text
http://10.42.0.1:5000/dashboard
```

서버가 실행되는 장치의 IP 주소나 포트가 변경된 경우 실제 환경에 맞게 주소를 수정해야 합니다.

### 3) 라즈베리파이 코드 실행

라즈베리파이에 로드셀, 모터, LED, 스위치 및 통신 장치가 연결되어 있어야 합니다.

```bash
python raspberry-pi/rpi_algorithm.py
```

라즈베리파이 코드 실행 전 확인해야 할 사항은 다음과 같습니다.

* 로드셀 8채널 연결 상태
* HX710A 또는 HX711 센서 모듈 연결 상태
* DDSM115 모터 컨트롤러 연결 상태
* USB-RS485 통신 장치 연결 상태
* `/dev/ttyUSB0`, `/dev/ttyUSB1` 포트 설정
* Flask 서버 IP 주소 및 포트
* 경고음 파일 경로
* GPIO 핀 번호 설정
* `lgpio`, `pygame`, `pyserial`, `requests` 설치 여부

필요한 라이브러리는 다음과 같이 설치할 수 있습니다.

```bash
pip install lgpio pygame pyserial requests
```

### 4) 모바일 애플리케이션 코드 활용

`mobile-app/` 폴더는 Flutter 모바일 애플리케이션의 Dart 소스 코드를 보관하기 위한 폴더입니다.

현재 저장소에는 다음과 같은 Flutter 프로젝트 구성 파일이 포함되어 있지 않습니다.

* `pubspec.yaml`
* `android/`
* `ios/`
* `web/`
* `test/`
* Flutter 플랫폼별 설정 파일

따라서 `mobile-app/` 폴더에 저장된 코드만으로는 애플리케이션을 바로 실행하거나 APK 파일을 빌드할 수 없습니다.

실제로 애플리케이션을 실행하려면 별도의 Flutter 프로젝트를 생성한 뒤 `mobile-app/` 폴더의 Dart 파일을 Flutter 프로젝트의 `lib/` 폴더에 복사해야 합니다.

예시:

```bash
flutter create kickboard_mobile_app
```

생성된 프로젝트의 기본 구조는 다음과 같습니다.

```text
kickboard_mobile_app/
├── android/
├── ios/
├── lib/
├── pubspec.yaml
└── 기타 Flutter 프로젝트 파일
```

이후 `mobile-app/` 폴더의 Dart 파일을 다음 위치에 배치합니다.

```text
kickboard_mobile_app/lib/
```

모바일 코드에서 사용하는 주요 Flutter 패키지는 다음과 같습니다.

```text
camera
dio
vibration
flutter_tts
google_mlkit_face_detection
mobile_scanner
app_links
shared_preferences
```

패키지는 Flutter 프로젝트에서 다음과 같이 추가할 수 있습니다.

```bash
flutter pub add camera
flutter pub add dio
flutter pub add vibration
flutter pub add flutter_tts
flutter pub add google_mlkit_face_detection
flutter pub add mobile_scanner
flutter pub add app_links
flutter pub add shared_preferences
```

모바일 애플리케이션은 카메라, 인터넷, 진동 기능을 사용하므로 Android 또는 iOS 프로젝트에서 별도의 권한 설정이 필요합니다.

또한 코드에서 사용하는 서버 주소를 실제 Flask 서버가 실행되는 IP 주소로 수정해야 합니다.

현재 모바일 코드에서 사용하는 기본 서버 주소는 다음과 같습니다.

```text
http://10.42.0.1:5000
```

### 5) YOLO 헬멧 감지 모델 학습

`training/yolo/train_helmet_yolo_colab.py`는 Google Colab 환경에서 헬멧 감지용 YOLO 가중치 파일을 생성하기 위한 학습 코드입니다.

이 코드는 일반 Python 터미널이 아닌 Google Colab 환경을 기준으로 작성되어 있습니다.

학습 코드는 다음 작업을 순서대로 수행합니다.

1. Ultralytics 패키지 설치
2. Google Drive 연결
3. Google Drive의 `VOC2028.zip` 파일을 Colab 환경으로 복사
4. 데이터셋 압축 해제
5. VOC XML 라벨 검색
6. XML 바운딩 박스를 YOLO 좌표 형식으로 변환
7. YOLO TXT 라벨 파일 생성
8. 이미지와 라벨을 YOLO 표준 폴더 구조로 복사
9. `data.yaml` 파일 생성
10. YOLO 모델 학습
11. 학습된 모델을 이용한 테스트 이미지 분석
12. 헬멧 감지 결과를 `Y` 또는 `N`으로 출력

#### 데이터셋 준비

실행 전 Google Drive의 다음 위치에 데이터셋 압축 파일을 준비해야 합니다.

```text
MyDrive/VOC2028.zip
```

압축 파일 내부에는 VOC 형식의 이미지와 XML 라벨이 포함되어 있어야 합니다.

코드에서 사용하는 주요 경로는 다음과 같습니다.

```text
/content/drive/MyDrive/VOC2028.zip
/content/VOCdevkit/
/content/dataset/images/
/content/dataset/labels/
/content/data.yaml
```

#### 클래스 구성

학습에 사용되는 객체 클래스는 다음과 같습니다.

```text
0: hat
1: person
```

VOC XML 라벨의 객체 이름이 `hat` 또는 `person`인 경우에만 YOLO 라벨로 변환됩니다.

#### 데이터셋 구조

코드는 YOLO가 인식할 수 있도록 다음과 같은 폴더 구조를 생성합니다.

```text
/content/dataset/
├── images/
└── labels/
```

* `images/`: 학습에 사용하는 JPG 이미지
* `labels/`: 이미지와 이름이 동일한 YOLO TXT 라벨

#### 학습 설정

현재 코드에 설정된 학습 조건은 다음과 같습니다.

```text
epochs: 5
image size: 416
device: GPU 0
```

학습 실행 부분은 다음과 같은 형태입니다.

```python
model = YOLO('best.pt')
model.train(
    data='/content/data.yaml',
    epochs=5,
    imgsz=416,
    device=0
)
```

현재 코드는 `YOLO('best.pt')`를 통해 기존 가중치 파일을 먼저 불러오도록 작성되어 있습니다.

따라서 이 코드는 기존 `best.pt`를 기반으로 추가 학습하는 형태로 볼 수 있습니다. 최초 학습을 진행하는 경우에는 실제 사용한 YOLO 사전 학습 가중치 파일명으로 변경해야 합니다.

#### 학습 결과

학습이 완료되면 일반적으로 다음 위치에 최적 가중치가 생성됩니다.

```text
/content/runs/detect/train/weights/best.pt
```

생성된 `best.pt` 파일은 Flask 서버에서 사용할 수 있도록 다음 위치에 저장합니다.

```text
server/models/best.pt
```

Ultralytics의 실행 횟수나 학습 이름에 따라 실제 결과 경로가 다음과 같이 변경될 수 있습니다.

```text
runs/detect/train2/weights/best.pt
runs/detect/train3/weights/best.pt
```

따라서 학습이 완료된 뒤 Colab에서 출력된 실제 저장 경로를 확인해야 합니다.

#### 헬멧 감지 테스트

학습 코드에는 생성된 가중치를 이용하여 이미지를 분석하는 테스트 함수가 포함되어 있습니다.

테스트 함수는 다음 위치의 가중치를 불러옵니다.

```text
/content/runs/detect/train/weights/best.pt
```

테스트 이미지에서 클래스 ID `0`, 즉 `hat` 객체가 감지되면 다음 값을 출력합니다.

```text
Y
```

헬멧 객체가 감지되지 않으면 다음 값을 출력합니다.

```text
N
```

현재 코드에서는 다음 테스트 이미지를 순서대로 분석합니다.

```text
1.jpg
2.jpg
3.jpg
4.jpg
5.jpg
6.jpg
```

테스트 이미지는 Colab의 현재 작업 경로에 준비해야 합니다.

---

## 7. 코드 파일 설명

### `server/app.py`

Flask 기반 중앙 서버 파일입니다.

모바일 앱, 헬멧 판별 AI, SQLite 데이터베이스, 라즈베리파이 및 웹 대시보드를 연결하는 중심 역할을 합니다.

주요 기능:

* QR 기반 킥보드 연결
* 사용자 회원가입
* 사용자 로그인
* 아이디 찾기
* 비밀번호 재설정
* 헬멧 인증 이미지 업로드
* YOLO 모델을 통한 헬멧 착용 여부 판별
* 대여 시작 정보 저장
* 반납 정보 처리
* 라즈베리파이 상태 수신
* 최종 주행 허용 여부 판단
* 실시간 대시보드 데이터 제공

### `server/DB.py`

SQLite 데이터베이스 관리 파일입니다.

주요 기능:

* 사용자 정보 테이블 생성
* 사용자 정보 저장 및 조회
* 헬멧 인증 로그 저장
* 로드셀 하중 로그 저장
* 통합 주행 로그 저장
* 최신 하중 데이터 조회
* 대여 시작 및 반납 정보 관리

### `server/AI_Helmet.py`

YOLO 기반 헬멧 판별 파일입니다.

주요 기능:

* `best.pt` 모델 로드
* 모바일 앱에서 업로드한 이미지 분석
* 이미지에서 헬멧 객체 감지
* 헬멧 착용 여부 판단
* 헬멧 착용 시 `True`, 미착용 시 `False` 반환

### `server/templates/dashboard.html`

실시간 하중 관제 대시보드 화면입니다.

주요 기능:

* 총 하중 그래프 표시
* 8개 로드셀 센서값 표시
* 센서별 하중 히트맵 표시
* 다인 탑승 감지 상태 표시
* 위험 상태 발생 시 경고 문구 표시
* 일정 주기로 서버 API를 호출하여 화면 갱신

### `raspberry-pi/rpi_algorithm.py`

라즈베리파이 기반 하드웨어 제어 파일입니다.

주요 기능:

* 8채널 로드셀 값 측정
* 총 하중 계산
* 활성화된 로드셀 개수 계산
* 하중 분포 분석
* 표준편차 기반 다인 탑승 판단
* Flask 서버로 현재 상태 전송
* 서버 응답에 따른 모터 제어
* LED를 이용한 상태 표시
* 다인 탑승 감지 시 경고음 재생
* 스위치 입력 처리
* 주행 허용 및 차단 상태 관리

### `mobile-app/main.dart`

Flutter 모바일 애플리케이션의 메인 파일입니다.

애플리케이션 실행, 로그인 화면, 카메라 초기화, 얼굴 감지, 헬멧 인증, 대여 시작, 주행 화면 및 반납 처리를 통합 관리합니다.

주요 기능:

* 애플리케이션 시작 및 스플래시 화면 표시
* 자동 로그인 및 기존 주행 상태 확인
* 로그인 화면 표시
* 회원가입, 아이디 찾기 및 비밀번호 재설정 화면 이동
* 전면 카메라 초기화
* 카메라 이미지 스트리밍
* ML Kit 기반 얼굴 감지
* 얼굴 위치 및 촬영 조건 확인
* 촬영 조건 충족 시 자동 촬영
* 촬영 이미지를 Flask 서버로 전송
* 헬멧 인증 성공 및 실패 처리
* 음성 안내 및 진동 안내
* QR 코드 스캔 화면 이동
* 사용자와 킥보드 연결
* 대여 시작 정보 서버 전송
* 주행 시간 표시
* 반납 처리
* 로그아웃 처리
* 애플리케이션 생명주기에 따른 카메라 관리

### `mobile-app/auth_api.dart`

사용자 계정 관련 Flask API 요청을 처리합니다.

주요 기능:

* 사용자 회원가입 요청
* 이름과 전화번호를 이용한 아이디 찾기 요청
* 사용자 정보 확인 후 비밀번호 재설정 요청
* Dio를 이용한 HTTP 통신
* 서버 응답을 `Map<String, dynamic>` 형식으로 반환

### `mobile-app/auth_storage.dart`

모바일 기기의 로컬 저장소를 관리합니다.

`shared_preferences` 패키지를 이용하여 애플리케이션 상태를 저장하고 불러옵니다.

주요 기능:

* 자동 로그인 상태 저장
* 사용자 ID 저장
* 사용자 이름 저장
* 로그아웃 시 사용자 정보 삭제
* 현재 주행 상태 저장
* 연결된 킥보드 ID 저장
* 주행 시작 시간 저장
* 애플리케이션 재실행 시 기존 주행 정보 복원
* 반납 완료 후 주행 정보 삭제

### `mobile-app/register_view.dart`

사용자 회원가입 화면입니다.

주요 기능:

* 아이디 입력
* 비밀번호 입력
* 이름 입력
* 전화번호 입력
* 미입력 항목 확인
* 회원가입 API 요청
* 회원가입 성공 또는 실패 메시지 표시
* 회원가입 성공 후 로그인 화면으로 이동

### `mobile-app/find_id_view.dart`

사용자 아이디 찾기 화면입니다.

주요 기능:

* 이름 입력
* 전화번호 입력
* 아이디 찾기 API 요청
* 조회 중 상태 표시
* 찾은 사용자 아이디 화면 표시
* 조회 실패 및 서버 연결 실패 메시지 표시

### `mobile-app/reset_password_view.dart`

비밀번호 재설정 화면입니다.

주요 기능:

* 사용자 아이디 입력
* 사용자 이름 입력
* 전화번호 입력
* 새로운 비밀번호 입력
* 사용자 정보 확인 요청
* 비밀번호 변경 성공 또는 실패 메시지 표시
* 비밀번호 변경 완료 후 로그인 화면으로 이동

### `mobile-app/statue_view.dart`

연결된 킥보드의 상태를 표시하는 화면 구성 파일입니다.

주요 기능:

* 연결된 킥보드 ID 표시
* 킥보드가 연결되지 않은 경우 안내 문구 표시
* 킥보드 미연결 상태에서 QR 스캔 기능 실행
* 연결 여부에 따라 글자 색상 및 밑줄 상태 변경

현재 파일명은 소스 코드의 import 경로에 맞춰 `statue_view.dart`로 저장되어 있습니다.

파일명을 `status_view.dart`로 변경하려면 `main.dart`의 import문도 함께 수정해야 합니다.

### `mobile-app/my_camera_view.dart`

킥보드 QR 코드를 인식하는 카메라 화면입니다.

주요 기능:

* `mobile_scanner`를 이용한 QR 코드 인식
* QR 코드에서 문자열 데이터 추출
* 중복 인식 방지
* QR 코드 인식 후 카메라 정지
* 인식한 값을 이전 화면으로 전달
* 화면 종료 시 카메라 자원 해제

### `mobile-app/qr_service.dart`

킥보드 연결 및 반납 관련 서버 통신을 처리합니다.

주요 기능:

* 앱이 종료된 상태에서 들어온 초기 딥링크 확인
* 앱 실행 중 들어오는 딥링크 감시
* 링크에서 킥보드 ID 추출
* 사용자 ID와 킥보드 ID를 서버에 전송
* 킥보드 연결 완료 음성 안내
* 반납 정보를 Flask 서버에 전송
* 딥링크 구독 해제

### `mobile-app/face_analysis_controller.dart`

카메라 이미지와 ML Kit 얼굴 감지를 연결하는 컨트롤러 파일입니다.

주요 기능:

* 카메라 이미지의 여러 Plane 데이터 결합
* 카메라 이미지를 ML Kit의 `InputImage` 형식으로 변환
* 카메라 회전 방향 적용
* 얼굴 감지 요청
* 중복 이미지 분석 방지
* 얼굴 목록 반환
* 얼굴 감지 객체 자원 해제

현재 모바일 메인 코드에도 일부 얼굴 감지 로직이 포함되어 있으므로, 실제 프로젝트에 적용할 때는 중복되는 로직을 정리하거나 컨트롤러 파일을 중심으로 구조를 분리할 수 있습니다.

### `training/yolo/train_helmet_yolo_colab.py`

Google Colab 환경에서 헬멧 감지용 YOLO 모델을 학습하고 테스트하는 코드입니다.

주요 기능:

* Ultralytics 패키지 설치
* Google Drive 연결
* `VOC2028.zip` 데이터셋 복사
* VOC 데이터셋 압축 해제
* XML 라벨 파일 검색
* XML 바운딩 박스를 YOLO 좌표로 변환
* `hat`, `person` 클래스 ID 설정
* YOLO TXT 라벨 파일 생성
* 이미지와 라벨을 YOLO 표준 구조로 복사
* `data.yaml` 파일 자동 생성
* YOLO 모델 학습
* 최적 가중치 `best.pt` 생성
* 테스트 이미지 분석
* 헬멧 감지 시 `Y`, 미감지 시 `N` 출력

현재 코드는 다음과 같은 Google Colab 전용 요소를 사용합니다.

```text
!pip
!cp
!mkdir
!unzip
!ls
/content/ 경로
google.colab.drive
```

따라서 일반 Python 환경에서 그대로 실행할 수 없으며 Google Colab에서 실행하는 것을 기준으로 합니다.

---

## 8. 논문 및 발표자료

### 논문 파일

`docs/paper.hwp`는 본 프로젝트의 연구 목적, 시스템 구조, 구현 방식 및 실험 결과를 정리한 논문 파일입니다.

논문에서는 다음 내용을 중심으로 프로젝트를 설명합니다.

* 개인형 이동장치 안전 문제
* 안전모 미착용 문제
* 다인 탑승 문제
* YOLO 기반 안전모 착용 판별
* YOLO 헬멧 감지 모델 학습
* 로드셀 기반 하중 분포 분석
* Flask 서버와 라즈베리파이 기반 통합 제어 구조
* 모바일 애플리케이션과 서버의 연동
* 실시간 주행 허용 및 차단 로직

### 발표자료 및 최종보고서

`docs/capstone_final_report.hwp`는 캡스톤 디자인 최종보고서 또는 발표자료입니다.

이 파일은 코드 분석 대상이 아니라 다음 내용을 설명하기 위한 참고자료입니다.

* 프로젝트 개발 배경
* 시스템 설계 의도
* 하드웨어 구성
* 소프트웨어 구성
* 주요 기능 구현 과정
* 인공지능 모델 학습 과정
* 실험 및 테스트 결과
* 최종 프로젝트 결과

---

## 9. 사용 기술

| 구분            | 기술                                       |
| ------------- | ---------------------------------------- |
| 모바일 애플리케이션    | Flutter, Dart                            |
| 모바일 UI        | Flutter Material                         |
| 모바일 카메라       | camera, mobile_scanner                   |
| 모바일 얼굴 감지     | Google ML Kit Face Detection             |
| 모바일 통신        | Dio, HTTP, REST API, JSON                |
| 모바일 로컬 저장소    | shared_preferences                       |
| 모바일 음성 및 알림   | flutter_tts, vibration                   |
| 모바일 딥링크       | app_links                                |
| 서버            | Python, Flask, Flask-CORS                |
| 데이터베이스        | SQLite                                   |
| AI 모델         | YOLO, Ultralytics                        |
| AI 모델 학습 환경   | Google Colab, Python                     |
| 학습 데이터 형식     | Pascal VOC XML, YOLO TXT                 |
| 데이터셋 설정       | YAML                                     |
| 하드웨어 제어       | Raspberry Pi 5, GPIO, lgpio              |
| 센서            | Load Cell, HX710A, HX711                 |
| 모터 제어         | DDSM115, USB-RS485, Serial 통신            |
| 웹 대시보드        | HTML, Tailwind CSS, Chart.js, JavaScript |
| 전체 시스템 통신     | HTTP, REST API, JSON                     |
| 버전 관리 및 코드 보관 | Git, GitHub                              |

---

## 10. 참고 사항

이 저장소는 캡스톤 디자인 프로젝트의 코드, 논문, 발표자료, 모바일 애플리케이션 소스 및 YOLO 모델 학습 코드를 정리하기 위한 저장소입니다.

활용 목적은 다음과 같습니다.

* 프로젝트 코드 백업
* GitHub 제출용 정리
* 캡스톤 디자인 결과물 보관
* 포트폴리오 정리
* 코드 분석 및 유지보수 참고자료 보관
* 모바일, 서버, 인공지능 및 하드웨어 코드의 통합 구조 확인
* YOLO 가중치 생성 과정 기록
* 향후 프로젝트 개선을 위한 참고 자료 보관

### 모바일 애플리케이션 코드

`mobile-app/` 폴더는 Dart 소스 코드 보관용입니다.

완전한 Flutter 프로젝트를 포함하지 않으므로 현재 저장소에서 모바일 앱을 바로 실행하거나 APK로 빌드할 수 없습니다.

실제 실행 시에는 별도의 Flutter 프로젝트 생성, 패키지 설치, 카메라 권한 설정, 인터넷 권한 설정, 딥링크 설정 및 이미지 애셋 등록이 필요합니다.

### YOLO 학습 코드

`training/yolo/train_helmet_yolo_colab.py`는 Google Colab에서 실행하기 위해 작성된 학습 코드입니다.

현재 파일은 Colab에서 자동 생성된 Python 파일을 기반으로 하며, 일반 Python 코드와 Colab 셸 명령어가 함께 포함되어 있습니다.

다음과 같은 명령은 일반 Python 인터프리터에서 직접 실행할 수 없습니다.

```python
!pip install ultralytics
!cp ...
!mkdir ...
!unzip ...
!ls ...
```

일반 로컬 Python 환경에서 실행하려면 해당 명령을 `subprocess`, `os`, `shutil`, `zipfile` 등을 사용하는 코드로 변경해야 합니다.

### YOLO 학습 데이터

학습 데이터셋의 이미지와 라벨 파일은 용량이 크거나 저작권 및 개인정보 문제가 있을 수 있으므로 GitHub 공개 저장소에 직접 업로드하지 않을 수 있습니다.

저장소에는 다음 내용을 중심으로 보관하는 것을 권장합니다.

* YOLO 학습 코드
* 데이터셋 이름
* 데이터셋 출처
* 클래스 구성
* 데이터셋 폴더 구조
* 학습 파라미터
* 최종 가중치 파일
* 모델 평가 결과
* 데이터 사용 조건

현재 학습 코드가 사용하는 데이터셋 압축 파일명은 다음과 같습니다.

```text
VOC2028.zip
```

Google Drive에서는 다음 경로에 파일이 존재해야 합니다.

```text
MyDrive/VOC2028.zip
```

### 학습 및 검증 데이터

현재 생성되는 `data.yaml`에서는 다음과 같이 학습 이미지와 검증 이미지가 동일한 폴더로 설정되어 있습니다.

```yaml
train: images
val: images
```

따라서 현재 코드는 학습용 데이터와 검증용 데이터가 분리되지 않은 상태입니다.

모델의 일반화 성능을 정확하게 평가하려면 추후 다음과 같이 학습용 데이터와 검증용 데이터를 분리하는 것이 좋습니다.

```text
dataset/
├── images/
│   ├── train/
│   └── val/
└── labels/
    ├── train/
    └── val/
```

예시 `data.yaml`:

```yaml
path: /content/dataset
train: images/train
val: images/val

names:
  0: hat
  1: person
```

### 기존 가중치 파일

현재 학습 코드는 다음과 같이 기존 `best.pt` 파일을 불러옵니다.

```python
model = YOLO('best.pt')
```

따라서 Colab의 현재 작업 경로에 `best.pt`가 존재하지 않으면 모델을 불러오지 못할 수 있습니다.

이 코드가 기존 학습 모델을 추가 학습하기 위한 코드라면 기존 `best.pt`를 Colab에 업로드해야 합니다.

처음부터 학습하는 경우에는 실제 사용한 YOLO 사전 학습 가중치로 변경해야 합니다.

예시:

```python
model = YOLO('사전학습_가중치_파일명.pt')
```

실제로 어떤 사전 학습 가중치를 사용했는지는 본 프로젝트의 학습 환경에 맞게 확인해야 합니다.

### YOLO 가중치 파일

학습된 헬멧 판별 모델은 다음 위치에 저장합니다.

```text
server/models/best.pt
```

`server/AI_Helmet.py`에서 모델을 불러올 때 사용하는 경로와 실제 모델 파일 위치가 일치해야 합니다.

가중치 파일의 용량이 GitHub 일반 업로드 제한보다 큰 경우 Git LFS 사용을 고려할 수 있습니다.

### 서버 주소

모바일 코드와 라즈베리파이 코드에는 Flask 서버 주소가 직접 작성되어 있을 수 있습니다.

현재 코드에서 주로 사용되는 서버 주소는 다음과 같습니다.

```text
http://10.42.0.1:5000
```

실행 환경이 변경되는 경우 다음 파일에 포함된 서버 주소를 확인해야 합니다.

* `mobile-app/main.dart`
* `mobile-app/auth_api.dart`
* `mobile-app/qr_service.dart`
* `raspberry-pi/rpi_algorithm.py`

실제 프로젝트에서는 서버 주소를 각 파일에 직접 작성하기보다 환경설정 파일이나 환경변수로 분리하는 것이 좋습니다.

### 모바일 이미지 애셋

모바일 메인 코드에서는 헬멧 아이콘 이미지를 사용할 수 있습니다.

예상되는 이미지 경로는 다음과 같습니다.

```text
assets/images/helmet_icon.png
```

실제 Flutter 프로젝트에서 이 이미지를 사용하려면 이미지 파일을 준비하고 `pubspec.yaml`에 애셋 경로를 등록해야 합니다.

### 보안 및 운영 환경

현재 프로젝트는 캡스톤 디자인 및 기능 구현을 목적으로 작성된 코드입니다.

실제 서비스 환경에 적용하기 위해서는 다음 보완이 필요합니다.

* 사용자 비밀번호 암호화
* 비밀번호 해시 및 Salt 적용
* 사용자 입력값 검증
* 업로드 이미지 파일 형식 및 크기 검증
* 인증 및 세션 관리 강화
* API 접근 권한 관리
* 서버 통신 HTTPS 적용
* 서버 IP 및 포트 환경설정 파일 분리
* 예외 처리 및 오류 로그 관리
* 개인정보 저장 범위 최소화
* SQLite 데이터베이스 백업 및 접근 권한 관리
* YOLO 모델 파일 버전 관리
* 학습 데이터 저작권 및 사용 권한 확인
* 학습 데이터와 검증 데이터 분리
* 모델 정확도, 정밀도, 재현율 및 mAP 평가
* 모바일 앱의 카메라 및 저장 권한 관리
* 라즈베리파이와 서버 사이의 통신 인증
* 라즈베리파이 하드웨어 연결 안정화
* 모터 제어 실패 상황에 대한 안전 처리
* 센서 연결 해제 및 비정상값 감지
* 다양한 사용자 체중과 탑승 자세에 대한 테스트
* 다양한 사용자와 환경에서 다인 탑승 판별 정확도 개선
* 야간, 우천, 역광 환경에서 헬멧 인식 성능 개선
* 모바일 앱과 서버 API의 요청 및 응답 형식 통일
* 대여 및 반납 과정의 사용자 ID와 킥보드 ID 전달 순서 검증

### 파일명 참고

현재 모바일 코드에서는 킥보드 상태 표시 파일을 다음 이름으로 사용합니다.

```text
statue_view.dart
```

일반적으로 상태를 의미하는 영어 단어는 `status`이므로 추후 다음 이름으로 변경할 수 있습니다.

```text
status_view.dart
```

다만 파일명을 변경하는 경우 `main.dart`에 작성된 import 경로도 함께 변경해야 합니다.

### 실행 전 검증

저장된 모바일 코드는 전체 Flutter 프로젝트가 아닌 개별 Dart 소스 파일이므로 실제 실행 여부가 최종 검증된 상태를 의미하지는 않습니다.

YOLO 학습 코드 역시 특정 Google Colab 환경과 데이터셋 경로를 기준으로 작성되어 있습니다.

실제 실행 환경을 구성할 때는 다음 항목을 확인해야 합니다.

* Flutter 및 Dart 버전 호환성
* 사용 중인 Flutter 패키지 버전
* Android 최소 SDK 버전
* 카메라 권한 설정
* 인터넷 통신 권한 설정
* 일반 HTTP 통신 허용 여부
* 딥링크 설정
* 이미지 애셋 경로
* 서버 API 엔드포인트
* API 요청 데이터의 키 이름
* API 응답의 대소문자 및 결과값
* 사용자 ID와 킥보드 ID 전달 순서
* 카메라 이미지 형식과 ML Kit 호환성
* 실제 안드로이드 기기에서의 카메라 동작 여부
* Flask 서버와 모바일 기기가 동일한 네트워크에 연결되어 있는지 여부
* Google Drive의 데이터셋 압축 파일 경로
* VOC XML 파일의 클래스 이름
* 이미지 파일과 라벨 파일의 이름 일치 여부
* 학습에 사용할 기존 가중치 파일 존재 여부
* Colab GPU 사용 가능 여부
* 학습 결과가 저장된 실제 폴더 경로
* 생성된 `best.pt` 파일의 서버 적용 여부
