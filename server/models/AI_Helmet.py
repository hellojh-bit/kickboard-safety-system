from ultralytics import YOLO
import os

# 1. 모델 로드
# 우분투 노트북 Flask_Server 폴더 안에 best.pt
model_path = os.path.join(os.path.dirname(__file__), 'best.pt')
model = YOLO(model_path)

def predict_helmet(image_path):
    """
    조원의 코랩 코드를 기반으로 한 헬멧 판별 함수
    - 리턴값: True (헬멧 감지됨), False (미감지)
    """
    # 2. 이미지 분석 (조원 코드의 conf=0.4 반영)
    results = model.predict(source=image_path, conf=0.4, save=False, verbose=False)

    helmet_detected = False
    
    # 3. 결과 분석
    for r in results:
        # 감지된 모든 객체의 박스를 확인
        for box in r.boxes:
            class_id = int(box.cls[0])
            # 조원 코드 기준 0번이 'hat'(헬멧)입니다.
            if class_id == 0:  
                helmet_detected = True
                break
        if helmet_detected:
            break
                
    return helmet_detected
