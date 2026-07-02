import os
os.environ["SDL_AUDIODRIVER"] = "alsa"
os.environ["AUDIODEV"] = "default"

import lgpio
import time
import threading
from collections import deque
import statistics
import pygame
import serial
import requests  # Flask 서버 통신용 모듈 추가

# =================================================================
# 1. 로드셀 핀 설정
# =================================================================
SCK_710 = 4
DT_710 = [17, 27, 22, 5]

PINS_711 = {
    5: (6, 12),
    6: (13, 16),
    7: (19, 20),
    8: (21, 26)
}

# =================================================================
# 2. 스위치 / LED 핀 설정
# =================================================================
SWITCH_PIN = 14

LED_R = 23
LED_Y = 24
LED_G = 25

# =================================================================
# 3. DDSM115 바퀴 설정
# USB-RS485 2개 사용
# 둘 다 새 제품이면 모터 ID는 보통 1
# =================================================================
LEFT_DDSM_PORT = "/dev/ttyUSB0"
RIGHT_DDSM_PORT = "/dev/ttyUSB1"

DDSM_BAUD = 115200
MOTOR_ID = 1

DRIVE_RPM = 30

# 방향이 이상하면 RIGHT_DIRECTION을 1로 바꾸기
LEFT_DIRECTION = 1
RIGHT_DIRECTION = -1

# =================================================================
# 4. 로드셀 / 사운드 / 서버 통신 설정
# =================================================================
SAMPLE_SIZE = 10
CALIBRATION_FACTORS = [-34000.0] * 8
SOUND_FILE = "/home/user2/Downloads/0002.mp3"

# 서버 통신 설정 (우분투 노트북 핫스팟 환경)
SERVER_URL = "http://10.42.0.1:5000/rpi_status"
USER_ID = "unknown_user"
SCOOTER_ID = "SCOOTER1"
is_ride_allowed = False
is_motor_unlocked = False
motor_toggle = False
server_connected = False
server_status_msg = "🔴 서버 통신 전 / 주행 차단"


# =================================================================
# DDSM115 바퀴 제어 클래스
# USB-RS485 2개를 각각 열어서 바퀴 2개 동시 제어
# =================================================================
class DDSM115Motor:
    def __init__(self, port, baud=DDSM_BAUD):
        self.port = port

        try:
            self.ser = serial.Serial(
                port=port,
                baudrate=baud,
                timeout=0.1
            )
            print(f"✅ DDSM115 RS485 연결 성공: {port}")

        except Exception as e:
            self.ser = None
            print(f"❌ DDSM115 RS485 연결 실패: {port} / {e}")
            print("👉 포트 확인: ls /dev/ttyUSB*")

    def crc8_maxim(self, data):
        crc = 0x00

        for byte in data:
            crc ^= byte

            for _ in range(8):
                if crc & 0x01:
                    crc = (crc >> 1) ^ 0x8C
                else:
                    crc >>= 1

        return crc & 0xFF

    def set_velocity_mode(self, motor_id=MOTOR_ID):
        if self.ser is None:
            return

        frame = [
            motor_id,
            0xA0,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x02
        ]

        self.ser.write(bytes(frame))
        time.sleep(0.05)

    def set_speed(self, rpm, motor_id=MOTOR_ID):
        if self.ser is None:
            return

        rpm = max(-100, min(100, int(rpm)))

        if rpm < 0:
            rpm_value = (1 << 16) + rpm
        else:
            rpm_value = rpm

        high = (rpm_value >> 8) & 0xFF
        low = rpm_value & 0xFF

        frame = [
            motor_id,
            0x64,
            high,
            low,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00
        ]

        frame.append(self.crc8_maxim(frame))
        self.ser.write(bytes(frame))

    def brake(self, motor_id=MOTOR_ID):
        if self.ser is None:
            return

        frame = [
            motor_id,
            0x64,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0xFF,
            0x00
        ]

        frame.append(self.crc8_maxim(frame))
        self.ser.write(bytes(frame))

    def close(self):
        try:
            self.brake()
            time.sleep(0.1)

            if self.ser is not None:
                self.ser.close()

            print(f"✅ DDSM115 연결 종료: {self.port}")

        except Exception:
            pass


class DDSM115MotorController:
    def __init__(self):
        self.left = DDSM115Motor(LEFT_DDSM_PORT)
        self.right = DDSM115Motor(RIGHT_DDSM_PORT)

    def set_velocity_mode_all(self):
        self.left.set_velocity_mode()
        self.right.set_velocity_mode()

    def start_all(self, rpm):
        self.left.set_speed(rpm * LEFT_DIRECTION)
        self.right.set_speed(rpm * RIGHT_DIRECTION)

    def brake_all(self):
        self.left.brake()
        self.right.brake()

    def close(self):
        self.brake_all()
        self.left.close()
        self.right.close()


# =================================================================
# 8채널 로드셀 시스템
# =================================================================
class Integrated_8CH_WeightSystem:
    def __init__(self):
        self.history = [deque(maxlen=SAMPLE_SIZE) for _ in range(8)]
        self.offsets = [0] * 8

        try:
            self.h = lgpio.gpiochip_open(4)
        except Exception:
            self.h = lgpio.gpiochip_open(0)

        lgpio.gpio_claim_output(self.h, SCK_710)

        for pin in DT_710:
            lgpio.gpio_claim_input(self.h, pin)

        for ch, pins in PINS_711.items():
            lgpio.gpio_claim_input(self.h, pins[0])
            lgpio.gpio_claim_output(self.h, pins[1])

        try:
            lgpio.gpio_claim_input(self.h, SWITCH_PIN, lgpio.SET_PULL_UP)
        except Exception:
            lgpio.gpio_claim_input(self.h, SWITCH_PIN)

        lgpio.gpio_claim_output(self.h, LED_R)
        lgpio.gpio_claim_output(self.h, LED_Y)
        lgpio.gpio_claim_output(self.h, LED_G)

        lgpio.gpio_write(self.h, LED_R, 0)
        lgpio.gpio_write(self.h, LED_Y, 0)
        lgpio.gpio_write(self.h, LED_G, 0)

    def is_710_ready(self):
        for pin in DT_710:
            if lgpio.gpio_read(self.h, pin):
                return False
        return True

    def is_711_ready(self, dt_pin):
        return lgpio.gpio_read(self.h, dt_pin) == 0

    def read_all_raw(self):
        raw_data = [0] * 8

        while not self.is_710_ready():
            time.sleep(0.001)

        counts_710 = [0, 0, 0, 0]

        for _ in range(24):
            lgpio.gpio_write(self.h, SCK_710, 1)

            for i, pin in enumerate(DT_710):
                counts_710[i] = (counts_710[i] << 1) | lgpio.gpio_read(self.h, pin)

            lgpio.gpio_write(self.h, SCK_710, 0)

        lgpio.gpio_write(self.h, SCK_710, 1)
        lgpio.gpio_write(self.h, SCK_710, 0)

        for i in range(4):
            if counts_710[i] & 0x800000:
                counts_710[i] -= 0x1000000

            raw_data[i] = counts_710[i]

        for idx, ch in enumerate(range(5, 9)):
            dt, sck = PINS_711[ch]

            while not self.is_711_ready(dt):
                time.sleep(0.001)

            count_711 = 0

            for _ in range(24):
                lgpio.gpio_write(self.h, sck, 1)
                count_711 = (count_711 << 1) | lgpio.gpio_read(self.h, dt)
                lgpio.gpio_write(self.h, sck, 0)

            lgpio.gpio_write(self.h, sck, 1)
            lgpio.gpio_write(self.h, sck, 0)

            if count_711 & 0x800000:
                count_711 -= 0x1000000

            raw_data[4 + idx] = count_711

        return raw_data

    def get_filtered_raw(self):
        raw = self.read_all_raw()
        filtered_results = []

        for i in range(8):
            self.history[i].append(raw[i])
            sorted_history = sorted(list(self.history[i]))

            trim = max(1, len(sorted_history) // 5)
            trimmed = sorted_history[trim:-trim] if len(sorted_history) > 4 else sorted_history

            avg = sum(trimmed) / len(trimmed)
            filtered_results.append(avg)

        return filtered_results

    def tare(self):
        print("\n[안내] 8채널 통합 영점 조절 중... 발판을 완전히 비워주세요.")

        temp_offsets = [0] * 8

        for _ in range(20):
            val = self.read_all_raw()

            for i in range(8):
                temp_offsets[i] += val[i]

            time.sleep(0.05)

        self.offsets = [o / 20 for o in temp_offsets]
        print(f"✅ 8채널 영점 조절 완료: {self.offsets}")

    def get_weights(self):
        raw_filtered = self.get_filtered_raw()
        weights = []

        for i in range(8):
            w = (raw_filtered[i] - self.offsets[i]) / CALIBRATION_FACTORS[i]

            if abs(w) < 0.05:
                w = 0.0

            if w < 0:
                w = 0.0

            weights.append(w)

        return weights

    def cleanup(self):
        lgpio.gpio_write(self.h, LED_R, 0)
        lgpio.gpio_write(self.h, LED_Y, 0)
        lgpio.gpio_write(self.h, LED_G, 0)
        lgpio.gpiochip_close(self.h)


sys_8ch = Integrated_8CH_WeightSystem()
ddsm_motor = DDSM115MotorController()

ddsm_motor.set_velocity_mode_all()


# =================================================================
# LED 제어
# =================================================================
def set_led_state(state):
    lgpio.gpio_write(sys_8ch.h, LED_R, 0)
    lgpio.gpio_write(sys_8ch.h, LED_Y, 0)
    lgpio.gpio_write(sys_8ch.h, LED_G, 0)

    if state == "red":
        lgpio.gpio_write(sys_8ch.h, LED_R, 1)
    elif state == "yellow":
        lgpio.gpio_write(sys_8ch.h, LED_Y, 1)
    elif state == "green":
        lgpio.gpio_write(sys_8ch.h, LED_G, 1)


# =================================================================
# 바퀴 ON / OFF
# =================================================================
def motor_on():
    global is_motor_unlocked

    ddsm_motor.start_all(DRIVE_RPM)
    is_motor_unlocked = True


def motor_off():
    global is_motor_unlocked

    ddsm_motor.brake_all()
    is_motor_unlocked = False


def control_wheel(server_unlocked_cmd):
    global is_ride_allowed, server_connected, motor_toggle

    if server_unlocked_cmd:
        server_connected = True
        is_ride_allowed = True

    else:
        server_connected = False
        is_ride_allowed = False
        motor_toggle = False
        motor_off()
        set_led_state("red")


# =================================================================
# 사운드
# =================================================================
try:
    pygame.mixer.init()
    pygame.mixer.music.load(SOUND_FILE)

except Exception as e:
    print(f"[오디오 에러] 사운드 파일 로드 실패: {e}")


def play_warning_sound():
    try:
        if not pygame.mixer.music.get_busy():
            pygame.mixer.music.play(-1)

    except Exception as e:
        print(f"\n[스피커 오류] 소리 재생 실패: {e}")


def stop_warning_sound():
    try:
        if pygame.mixer.music.get_busy():
            pygame.mixer.music.stop()

    except Exception:
        pass


# =================================================================
# 서버 실시간 통신부 (백그라운드 스레드 실행)
# =================================================================
def send_data_to_server(weights, total_all, active_cells, std_dev, is_multiple):
    global server_status_msg, USER_ID

    payload = {
        "user_id": USER_ID,
        "scooter_id": SCOOTER_ID,
        "weights": [round(w, 2) for w in weights],
        "total_weight": round(total_all, 2),
        "active_cells": active_cells,
        "std_dev": round(std_dev, 2),
        "is_multiple_riders": is_multiple,
        "is_unlocked": is_motor_unlocked
    }

    try:
        response = requests.post(SERVER_URL, json=payload, timeout=0.5)

        if response.status_code == 200:
            res_data = response.json()

            print("\n[서버 응답]", res_data)

            # 서버가 user_id를 보내주면 라즈베리파이 USER_ID 갱신
            USER_ID = res_data.get("user_id", USER_ID)

            server_unlocked = res_data.get("is_unlocked", False)

            control_wheel(server_unlocked)

            if server_unlocked:
                server_status_msg = f"\033[1;32m🟢 서버 승인 / 사용자:{USER_ID} / 주행 허용 / 버튼 대기\033[0m"
            else:
                server_status_msg = f"\033[1;31m🔴 서버 차단 / 사용자:{USER_ID} / 헬멧 미인증 또는 다인탑승\033[0m"

        else:
            control_wheel(False)
            server_status_msg = f"\033[1;31m🔴 서버 HTTP 오류: {response.status_code}\033[0m"

    except requests.exceptions.Timeout:
        control_wheel(False)
        server_status_msg = "\033[1;33m🟡 서버 통신 지연 (Timeout)\033[0m"

    except Exception as e:
        control_wheel(False)
        print(f"[서버 오류] {e}")
        server_status_msg = "\033[1;31m🔴 서버 연결 실패 (네트워크 확인)\033[0m"

# =================================================================
# 메인 루프
# =================================================================
def display_loop():
    global motor_toggle

    print("\n[측정 시작] 로드셀 기반 다인 탑승 감지 + DDSM115 2개 제어 시작")
    print("[안내] Ctrl + C 입력 시 안전 종료\n")

    warning_start_time = None
    last_send_time = time.time()
    button_locked = False

    try:
        while True:
            w = sys_8ch.get_weights()

            sum_710 = sum(w[0:4])
            sum_711 = sum(w[4:8])
            total_all = sum_710 + sum_711

            active_weights = [ch_w for ch_w in w if ch_w >= 2.0]
            active_cells = len(active_weights)
            std_dev = statistics.stdev(active_weights) if active_cells >= 2 else 0.0

            is_multiple_riders = False

            if total_all >= 140.0:
                is_multiple_riders = True

            elif total_all >= 85.0 and active_cells >= 5 and std_dev <= 12.0:
                is_multiple_riders = True

            switch_value = lgpio.gpio_read(sys_8ch.h, SWITCH_PIN)
            switch_pressed = switch_value == 0

            if switch_pressed and not button_locked:
                if is_ride_allowed and server_connected and not is_multiple_riders:
                    motor_toggle = not motor_toggle

                button_locked = True

            elif not switch_pressed:
                button_locked = False

            if is_multiple_riders:
                motor_toggle = False
                motor_off()
                set_led_state("red")

                warning_msg = f"\033[1;31m🚨 [경고] 다인탑승입니다. 센서:{active_cells}개 / 편차:{std_dev:.2f}\033[0m"

                if warning_start_time is None:
                    warning_start_time = time.time()

                if time.time() - warning_start_time >= 2.0:
                    play_warning_sound()

            else:
                warning_msg = "                                                                    "
                warning_start_time = None
                stop_warning_sound()

                if not server_connected:
                    motor_toggle = False
                    motor_off()
                    set_led_state("red")

                elif is_ride_allowed and motor_toggle:
                    motor_on()
                    set_led_state("green")

                elif is_ride_allowed and not motor_toggle:
                    motor_off()
                    set_led_state("yellow")

                else:
                    motor_toggle = False
                    motor_off()
                    set_led_state("red")

            current_time = time.time()

            # 1초에 한 번씩 서버로 상태 전송 (비동기 스레드)
            if current_time - last_send_time >= 1.0:
                threading.Thread(
                    target=send_data_to_server,
                    args=(w, total_all, active_cells, std_dev, is_multiple_riders),
                    daemon=True
                ).start()

                last_send_time = current_time

            print(f"\r[CH 1~4 (710A)] {w[0]:5.2f}kg | {w[1]:5.2f}kg | {w[2]:5.2f}kg | {w[3]:5.2f}kg  (소계: {sum_710:6.2f}kg)")
            print(f"[CH 5~8 (711) ] {w[4]:5.2f}kg | {w[5]:5.2f}kg | {w[6]:5.2f}kg | {w[7]:5.2f}kg  (소계: {sum_711:6.2f}kg)")
            print(f"📊 [활성화 로드셀 개수]: {active_cells} / 8 개")
            print(f"📈 [활성화 무게 표준편차]: {std_dev:.2f}")
            print(f"👉 🔥 [전체 결합 총합 무게]: {total_all:6.2f} Kg")
            print(f"📡 [상태]: {server_status_msg}")

            if is_multiple_riders:
                motor_txt = "🚨 다인탑승 차단 / LED 빨강 / 바퀴 2개 OFF"

            elif not server_connected:
                motor_txt = "🔴 주행 미허용 / LED 빨강 / 바퀴 2개 OFF"

            elif is_ride_allowed and motor_toggle:
                motor_txt = "🟢 주행 중 / LED 초록 / 바퀴 2개 ON"

            elif is_ride_allowed and not motor_toggle:
                motor_txt = "🟡 주행 대기 / LED 노랑 / 바퀴 2개 OFF"

            else:
                motor_txt = "🔴 미인증 또는 반납 / LED 빨강 / 바퀴 2개 OFF"

            print(f"⚙️ [모터 구동 제어 상태]: {motor_txt}")
            print(f"🚗 [설정 속도]: {DRIVE_RPM} rpm")
            print(f"🔘 [스위치 상태]: {'눌림' if switch_pressed else '안 눌림'}")
            print(f"{warning_msg}")

            print("\033[10A", end="", flush=True)
            time.sleep(0.1)

    except Exception as e:
        print(f"\n표시 에러: {e}")


# =================================================================
# 실행부
# =================================================================
try:
    sys_8ch.tare()

    t = threading.Thread(target=display_loop, daemon=True)
    t.start()

    while True:
        time.sleep(1)

except KeyboardInterrupt:
    print("\n\n[안내] 전체 시스템을 안전하게 종료합니다.")

finally:
    stop_warning_sound()
    motor_off()
    ddsm_motor.close()
    set_led_state("off")
    sys_8ch.cleanup()
    print("✅ 안전 종료 완료") 
