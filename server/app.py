from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import os
from datetime import datetime
from AI_Helmet import predict_helmet
from DB import init_db, insert_helmet_log, insert_weight_log, get_latest_weight_log
import sqlite3

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

init_db()

# 킥보드별 현재 상태
scooter_sessions = {}

# =========================
# QR 연결
# =========================
@app.route('/connect', methods=['POST'])
@app.route('/auth/connect', methods=['POST'])
def connect_scooter():
    data = request.json or {}

    scooter_id = data.get('scooter_id', 'SCOOTER1')
    user_id = data.get('user_id', 'unknown_user')

    scooter_sessions[scooter_id] = {
        "user_id": user_id,
        "helmet_verified": False
    }

    print(f"🔗 QR 연결: scooter={scooter_id}, user={user_id}")

    return jsonify({
        "result": "SUCCESS",
        "message": "킥보드 연결 승인",
        "scooter_id": scooter_id,
        "user_id": user_id
    })


# =========================
# 회원가입
# =========================
@app.route('/auth/register', methods=['POST'])
def register():
    data = request.json or {}

    user_id = data.get('user_id')
    password = data.get('password')
    name = data.get('name')
    phone = data.get('phone')

    if not all([user_id, password, name, phone]):
        return jsonify({"result": "FAIL", "message": "모든 항목을 입력해야 합니다."}), 400

    try:
        conn = sqlite3.connect('kickboard.db')
        cursor = conn.cursor()

        cursor.execute("SELECT user_id FROM users WHERE user_id = ?", (user_id,))
        if cursor.fetchone():
            conn.close()
            return jsonify({"result": "FAIL", "message": "이미 존재하는 아이디입니다."})

        cursor.execute(
            "INSERT INTO users (user_id, password, name, phone) VALUES (?, ?, ?, ?)",
            (user_id, password, name, phone)
        )

        conn.commit()
        conn.close()

        return jsonify({"result": "SUCCESS", "message": "회원가입 완료"})

    except Exception as e:
        return jsonify({"result": "FAIL", "message": f"DB 오류: {e}"}), 500


# =========================
# 로그인
# =========================
@app.route('/auth/login', methods=['POST'])
def login():
    data = request.json or {}

    user_id = data.get('user_id')
    password = data.get('password')

    try:
        conn = sqlite3.connect('kickboard.db')
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT password, name FROM users WHERE user_id = ?", (user_id,))
        user = cursor.fetchone()
        conn.close()

        if user and user['password'] == password:
            return jsonify({
                "result": "SUCCESS",
                "name": user['name'],
                "message": f"{user['name']}님 환영합니다."
            })

        return jsonify({"result": "FAIL", "message": "아이디 또는 비밀번호가 일치하지 않습니다."})

    except Exception as e:
        return jsonify({"result": "FAIL", "message": f"로그인 오류: {e}"}), 500


# =========================
# 아이디 찾기
# =========================
@app.route('/auth/find_id', methods=['POST'])
def find_id():
    data = request.json or {}

    name = data.get('name')
    phone = data.get('phone')

    try:
        conn = sqlite3.connect('kickboard.db')
        cursor = conn.cursor()

        cursor.execute("SELECT user_id FROM users WHERE name = ? AND phone = ?", (name, phone))
        user = cursor.fetchone()
        conn.close()

        if user:
            return jsonify({"result": "SUCCESS", "user_id": user[0]})

        return jsonify({"result": "FAIL", "message": "일치하는 회원 정보가 없습니다."})

    except Exception as e:
        return jsonify({"result": "FAIL", "message": f"서버 오류: {e}"}), 500


# =========================
# 비밀번호 재설정
# =========================
@app.route('/auth/reset_password', methods=['POST'])
def reset_password():
    data = request.json or {}

    user_id = data.get('user_id')
    name = data.get('name')
    phone = data.get('phone')
    new_password = data.get('new_password')

    try:
        conn = sqlite3.connect('kickboard.db')
        cursor = conn.cursor()

        cursor.execute(
            "SELECT user_id FROM users WHERE user_id = ? AND name = ? AND phone = ?",
            (user_id, name, phone)
        )

        if cursor.fetchone():
            cursor.execute("UPDATE users SET password = ? WHERE user_id = ?", (new_password, user_id))
            conn.commit()
            conn.close()
            return jsonify({"result": "SUCCESS", "message": "비밀번호가 변경되었습니다."})

        conn.close()
        return jsonify({"result": "FAIL", "message": "회원 정보가 일치하지 않습니다."})

    except Exception as e:
        return jsonify({"result": "FAIL", "message": f"서버 오류: {e}"}), 500


# =========================
# 헬멧 인증
# =========================
@app.route('/helmet', methods=['POST'])
@app.route('/predict', methods=['POST'])
@app.route('/auth/helmet', methods=['POST'])
@app.route('/auth/predict', methods=['POST'])
def upload_image():
    if 'image' in request.files:
        file = request.files['image']
    elif 'file' in request.files:
        file = request.files['file']
    else:
        return jsonify({"result": "FAIL", "message": "이미지 파일이 없습니다."}), 400

    user_id = request.form.get('user_id', 'unknown_user')
    scooter_id = request.form.get('scooter_id', 'SCOOTER1')

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"auth_{user_id}_{timestamp}.jpg"
    file_path = os.path.join(UPLOAD_FOLDER, filename)

    file.save(file_path)

    try:
        is_helmet = predict_helmet(file_path)

        insert_helmet_log(user_id, file_path, is_helmet)

        # 핵심 수정 부분
        scooter_sessions[scooter_id] = {
            "user_id": user_id,
            "helmet_verified": bool(is_helmet)
        }

        print(f"🪖 헬멧 인증: scooter={scooter_id}, user={user_id}, helmet={is_helmet}")

        return jsonify({
            "result": "success",
            "helmet_detected": bool(is_helmet),
            "message": "인증 성공" if is_helmet else "안전모를 착용해 주세요."
        })

    except Exception as e:
        return jsonify({"result": "fail", "message": f"AI 오류: {e}"}), 500


# =========================
# 대여 시작
# =========================
@app.route('/start_rental', methods=['POST'])
@app.route('/auth/start_rental', methods=['POST'])
def start_rental():
    data = request.json or {}

    scooter_id = data.get('scooter_id', 'SCOOTER1')
    user_id = data.get('user_id', 'unknown_user')

    if scooter_id not in scooter_sessions:
        scooter_sessions[scooter_id] = {
            "user_id": user_id,
            "helmet_verified": False
        }
    else:
        scooter_sessions[scooter_id]["user_id"] = user_id

    print(f"🛴 대여 시작: scooter={scooter_id}, user={user_id}")

    return jsonify({"result": "success", "message": "대여가 시작되었습니다."})


# =========================
# 반납
# =========================
@app.route('/return', methods=['POST'])
@app.route('/auth/return', methods=['POST'])
def return_scooter():
    data = request.json or {}

    scooter_id = data.get('scooter_id', 'SCOOTER1')

    if scooter_id in scooter_sessions:
        scooter_sessions[scooter_id]["helmet_verified"] = False

    print(f"🏁 반납 완료: scooter={scooter_id}")

    return jsonify({"result": "success", "message": "반납이 완료되었습니다."})


# =========================
# 라즈베리파이 상태 수신
# =========================
@app.route('/rpi_status', methods=['POST'])
def receive_rpi_status():
    data = request.json

    if not data:
        return jsonify({"result": "FAIL", "message": "데이터가 없습니다."}), 400

    scooter_id = data.get('scooter_id', 'SCOOTER1')
    weights = data.get('weights', [0.0] * 8)
    total_weight = data.get('total_weight', 0.0)
    is_multiple = data.get('is_multiple_riders', False)

    w = weights + [0.0] * (8 - len(weights))

    session = scooter_sessions.get(scooter_id, {
        "user_id": "unknown_user",
        "helmet_verified": False
    })

    current_user = session["user_id"]
    helmet_verified = session["helmet_verified"]

    # 최종 주행 허용 조건
    is_unlocked = helmet_verified and (not is_multiple)

    # 앱 없이 라즈베리 단독 테스트할 때만 아래로 바꾸기
    # is_unlocked = not is_multiple

    print(
        f"📡 RPi 수신 | scooter={scooter_id} | user={current_user} | "
        f"helmet={helmet_verified} | total={total_weight}kg | "
        f"multiple={is_multiple} | unlocked={is_unlocked}"
    )

    try:
        insert_weight_log(
            current_user,
            w[0], w[1], w[2], w[3],
            w[4], w[5], w[6], w[7],
            total_weight,
            is_multiple
        )
    except Exception as e:
        print(f"❌ DB 저장 오류: {e}")

    return jsonify({
        "result": "SUCCESS",
        "user_id": current_user,
        "helmet_verified": helmet_verified,
        "is_unlocked": is_unlocked
    }), 200


# =========================
# 앱 상태 조회
# =========================
@app.route('/api/status', methods=['GET'])
def get_riding_status():
    user_id = request.args.get('user_id')

    if not user_id:
        return jsonify({"result": "FAIL", "message": "user_id가 필요합니다."}), 400

    try:
        conn = sqlite3.connect('kickboard.db')
        cursor = conn.cursor()

        cursor.execute('''
            SELECT total_weight, is_multiple_riders
            FROM weight_logs
            WHERE user_id = ?
            ORDER BY timestamp DESC
            LIMIT 1
        ''', (user_id,))

        row = cursor.fetchone()
        conn.close()

        if row:
            return jsonify({
                "result": "SUCCESS",
                "total_weight": row[0],
                "is_multiple_riders": bool(row[1])
            })

        return jsonify({
            "result": "SUCCESS",
            "total_weight": 0.0,
            "is_multiple_riders": False
        })

    except Exception as e:
        return jsonify({"result": "FAIL", "message": f"조회 오류: {e}"}), 500

# ==========================================
# 📊 실시간 하중 시각화 웹 대시보드
# ==========================================

@app.route('/dashboard')
def dashboard():
    """웹 브라우저에서 접속 시 dashboard.html 화면을 띄워줍니다."""
    return render_template('dashboard.html')

@app.route('/api/realtime-weight', methods=['GET'])
def api_realtime_weight():
    """웹페이지의 자바스크립트가 1초마다 호출하여 최신 데이터를 가져가는 API입니다."""
    latest_data = get_latest_weight_log()
    
    if latest_data:
        return jsonify({"result": "SUCCESS", "data": latest_data})
    else:
        return jsonify({"result": "FAIL", "message": "아직 데이터가 없습니다."}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
