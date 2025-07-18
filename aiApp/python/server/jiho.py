from fastapi import APIRouter
from pydantic import BaseModel
import pandas as pd
import joblib
import os
import math
# Motor: 비동기 MongoDB 드라이버. AsyncIOMotorClient를 통해 MongoDB에 비동기로 접속 가능
from motor.motor_asyncio import AsyncIOMotorClient

# Pydantic: 데이터 검증 및 직렬화를 도와주는 라이브러리. BaseModel을 상속하여 데이터 모델 정의에 사용
from pydantic import BaseModel


router = APIRouter()
ip = "127.0.0.1"

# 모델 폴더 경로 지정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_dir = os.path.join(BASE_DIR, "../h5")
csv_path = os.path.join(BASE_DIR, "../Data/서울시 역사마스터 정보.csv")
Station = pd.read_csv(csv_path, encoding='euc-kr')
DATA5_PATH = os.path.join(BASE_DIR, '../Data/학교서울.csv')
seoul_school_df = pd.read_csv(DATA5_PATH)


def haversine(lat1, lon1, lat2, lon2):
    R = 6371000  # 지구 반지름(m)
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi / 2)**2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def find_nearest_station(lat, lng, station_df):
    min_distance = float('inf')
    nearest_station = None
    nearest_line = None

    for _, st in station_df.iterrows():
        st_lat = st['위도']
        st_lng = st['경도']
        if pd.isna(st_lat) or pd.isna(st_lng):
            continue

        dist = haversine(lat, lng, st_lat, st_lng)

        if dist < min_distance:
            min_distance = dist
            nearest_station = st['역사명']
            nearest_line = st['호선']

    return nearest_station, nearest_line, min_distance


def find_nearest_station1(lat, lng, df):
    min_distance1 = float('inf')

    for _, st in df.iterrows():
        st_lat = st['위도']
        st_lng = st['경도']
        if pd.isna(st_lat) or pd.isna(st_lng):
            continue

        dist = haversine(lat, lng, st_lat, st_lng)

        if dist < min_distance1:
            min_distance1 = dist

    return min_distance1
# 입력 스키마 정의
class InputData(BaseModel):
    동이름: str
    접수년도: int
    층: int
    임대면적: float
    건축년도: int
    위도: float
    경도: float

# 예측 API
@router.post("/predict")
def predict(data: InputData):
    raw = data.dict()
    dong = raw.pop("동이름")  # 동 이름만 분리
    model_path = os.path.join(model_dir, f"{dong}_xgb.h5")

    # 모델 존재 여부 확인
    if not os.path.exists(model_path):
        return {"error": f"{dong}에 해당하는 모델이 존재하지 않습니다."}

    try:

        # 가까운 역과 거리 계산
        nearest_station, nearest_line, distance = find_nearest_station(
            data.위도, data.경도, Station
        )
        distance_to_school = find_nearest_station1(data.위도, data.경도, seoul_school_df)
        # 동 이름에 맞는 모델 로드
        model = joblib.load(model_path)

        # 입력값 DataFrame 변환
        df = pd.DataFrame([{
            '접수년도': data.접수년도,
            '층': data.층,
            '임대면적': data.임대면적,
            '건축년도': data.건축년도,
            '거리(m)': distance,
            '햑교와의 거리(m)': distance_to_school,
            '수급동향': 100.3,
            '신규계약구분_num': 0,
        }])

        # 예측 수행
        prediction = model.predict(df)[0]
        return {
            "predicted_보증금": float(prediction),
            "nearest_station": nearest_station,
            "nearest_line": nearest_line,
            "distance_m": distance
            }
    
    except Exception as e:
        return {"error": f"예측 실패: {str(e)}"}










MONGO_URI = "mongodb://localhost:27017"
client = AsyncIOMotorClient(MONGO_URI) 
db = client['map_info']
gangseo_collection = db['gangseo_info']
mapo_collection = db['mapo_info']
nowon_collection = db['nowon_info']

class Address(BaseModel):
    id: str
    aptname: str
    area: str
    floor: str
    way: str
    room: str
    js: str
    address: str
    lat: float
    lng: float
    dong: str

@router.get("/gangseo_select")
async def select():
    infos = await gangseo_collection.find().to_list(None)
    for info in infos:
        info["_id"] = str(info["_id"])
    return{"results" : infos}

@router.get("/mapo_select")
async def select():
    infos = await mapo_collection.find().to_list(None)
    for info in infos:
        info["_id"] = str(info["_id"])
    return{"results" : infos}

@router.get("/nowon_select")
async def select():
    infos = await nowon_collection.find().to_list(None)
    for info in infos:
        info["_id"] = str(info["_id"])
    return{"results" : infos}


# # 실행
# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(router, host="0.0.0.0", port=8000)  # 모바일 연결 위해 0.0.0.0