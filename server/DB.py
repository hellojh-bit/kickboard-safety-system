import sqlite3
import datetime

DB_FILE = 'kickboard.db'

def get_db_connection():
    """SQLite DB 연결 객체를 반환합니다."""
    conn = sqlite3.connect(DB_FILE)
    return conn

def init_db():
    """
    [개선판] 3개의 테이블이 'user_id'를 공통 분모로 공유하는 통합 데이터베이스를 생성합니다.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. 마스터 사용자 테이블 (회원가입 정보)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            user_id TEXT PRIMARY KEY,
            password TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT NOT NULL
        )
    ''')

    # 2. 헬멧 판별 여부 결과 저장 테이블 (users의 user_id 공유)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS helmet_logs (
            log_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,  
            timestamp TEXT NOT NULL,
            image_path TEXT NOT NULL,
            helmet_detected BOOLEAN NOT NULL
        )
    ''')

    # 3. 로드셀 센서 데이터 저장 테이블 (users의 user_id 공유)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS weight_logs (
            log_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,  
            timestamp TEXT NOT NULL,
            w1 REAL NOT NULL,
            w2 REAL NOT NULL,
            w3 REAL NOT NULL,
            w4 REAL NOT NULL,
            w5 REAL NOT NULL,
            w6 REAL NOT NULL,
            w7 REAL NOT NULL,
            w8 REAL NOT NULL,
            total_weight REAL NOT NULL,
            is_multiple_riders BOOLEAN NOT NULL  -- 🚨 수정된 부분 (is_unlocked -> is_multiple_riders)
        )
    ''')

    # 4. 통합 주행 발표용 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS integrated_logs (
            log_id INTEGER PRIMARY KEY AUTOINCREMENT,  
            user_id TEXT NOT NULL,                     
            image_path TEXT,                           
            timestamp TEXT NOT NULL,                   
            helmet_detected BOOLEAN,                   
            max_weight REAL                            
        )
    ''')

    conn.commit()
    conn.close()
    print("✅ [DB.py] 3개 영역 및 최종 통합 발표용 테이블(integrated_logs) 스키마 완공 완료.")


# ==========================================
# 데이터 삽입 및 실시간 스키마 자동 병합 헬퍼 함수
# ==========================================

def insert_helmet_log(user_id, image_path, helmet_detected):
    """AI 헬멧 결과를 개별 로그에 넣고, 통합 테이블에 실시간 결합 세션을 생성합니다."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        now_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 원시 로그 저장
        cursor.execute('''
            INSERT INTO helmet_logs (user_id, timestamp, image_path, helmet_detected)
            VALUES (?, ?, ?, ?)
        ''', (user_id, now_time, image_path, helmet_detected))
        
        # 💡 [통합 테이블 연동] 새로운 주행 세션이 시작된 것으로 판단하여 통합 행 생성
        cursor.execute('''
            INSERT INTO integrated_logs (user_id, image_path, timestamp, helmet_detected, max_weight)
            VALUES (?, ?, ?, ?, 0.0)
        ''', (user_id, image_path, now_time, helmet_detected))
        
        conn.commit()
        conn.close()
        print(f"🗄️ [DB] '{user_id}' 헬멧 검증 완료 -> 통합 주행 대장에 동시 병합 완료.")
    except Exception as e:
        print(f"❌ 헬멧 로그 적재 실패: {e}")

def insert_weight_log(user_id, w1, w2, w3, w4, w5, w6, w7, w8, total_weight, is_multiple):
    """라즈베리 파이로부터 수신한 8채널 로드셀 하중 및 다인승 로그를 DB에 적재하고 통합 테이블을 업데이트합니다."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        now_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # 1. 8채널 센서 원시 데이터 적재
        cursor.execute('''
            INSERT INTO weight_logs (user_id, timestamp, w1, w2, w3, w4, w5, w6, w7, w8, total_weight, is_multiple_riders)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (user_id, now_time, w1, w2, w3, w4, w5, w6, w7, w8, total_weight, is_multiple))

        # 2. 통합 테이블(integrated_logs)의 최고 하중 데이터 갱신
        cursor.execute('''
            UPDATE integrated_logs
            SET max_weight = ?
            WHERE user_id = ? AND ? > max_weight
        ''', (total_weight, user_id, total_weight))

        conn.commit()
        conn.close()
        print(f"🗄️ [DB 저장 완료] 유저: {user_id} | 총 하중: {total_weight}kg | 다인 탑승: {is_multiple}")
    except Exception as e:
        print(f"❌ [DB 하중 로그 적재 실패] 오류 원인: {e}")

def get_latest_weight_log():
    """데이터베이스에서 가장 최신의 하중 로그 1건을 가져옵니다."""
    try:
        conn = get_db_connection()
        # 데이터를 딕셔너리 형태로 편하게 가져오기 위한 설정
        conn.row_factory = sqlite3.Row 
        cursor = conn.cursor()
        
        # log_id를 기준으로 내림차순 정렬하여 가장 위(최신)의 1개만 조회
        cursor.execute("SELECT * FROM weight_logs ORDER BY log_id DESC LIMIT 1")
        row = cursor.fetchone()
        conn.close()
        
        if row:
            return dict(row) # JSON으로 변환하기 쉽도록 딕셔너리로 반환
        return None
    except Exception as e:
        print(f"❌ 최신 하중 데이터 조회 실패: {e}")
        return None


