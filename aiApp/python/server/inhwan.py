from fastapi import APIRouter, HTTPException # 라우터
from pydantic import BaseModel # Post방식 사용을 위하 모델
from motor.motor_asyncio import AsyncIOMotorClient # Motor: 비동기 MongoDB 드라이버. AsyncIOMotorClient를 통해 MongoDB에 비동기로 접속 가능
import pandas as pd
import joblib # ai모델 불러오기
import os # 경로 찾아 주기위한것

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(BASE_DIR, "../Data/강서구_XGBreg.h5")
seoul_west_model = joblib.load(model_path)
csv_path = os.path.join(BASE_DIR, "../Data/서울시 역사마스터 정보.csv")
Station = pd.read_csv(csv_path, encoding='euc-kr')
school_path = os.path.join(BASE_DIR, "../Data/학교서울.csv")
school = pd.read_csv(school_path)


import math
import pandas as pd

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


# 2. FastAPI 객체 생성
router = APIRouter()
MONGO_URI = "mongodb://localhost:27017"
client = AsyncIOMotorClient(MONGO_URI)
db = client.local
collection = db.gangseo_info
schoolgeo = db.school_info
station = db.station_info

# 3. 입력 데이터 형식 정의 (예: 예측에 필요한 feature들)
class PredictionInput(BaseModel):
    층: int
    임대면적: float
    건축년도: int
    접수년도: int
    위도: float
    경도: float

class aptfor_sale_now(BaseModel):

    아파트이름 : str
    면적 : float
    층수_총층 : str
    방향 : str
    방_욕실 :str
    전세가 : float
    주소 : str
    lat :float
    lng : float
    동 :str

class staion_info(BaseModel):
    역사명 : str
    호선 : str
    lat: float
    lng : float


class school_info(BaseModel):
    학교명 : str
    lat : float
    lng : float



@router.get("/apts")
async def get_apartments():
    results = []
    cursor = collection.find({})
    async for doc in cursor:
        # _id 제거 + 문자열 숫자 처리
        doc.pop("_id", None)
        doc["면적"] = float(doc.get("면적(m²)", "0").replace("㎡", "").strip())
        doc["전세가"] = float(doc.get("전세가(만원)", "0").replace(",", "").replace(" ", ""))
        doc["층수_총층"] = doc.get("층수/총 층", "")
        doc["방_욕실"] = doc.get("방/욕실", "")
        results.append(aptfor_sale_now(**{
            "아파트이름": doc.get("아파트이름"),
            "면적": doc["면적"],
            "층수_총층": doc["층수_총층"],
            "방향": doc.get("방향", ""),
            "방_욕실": doc["방_욕실"],
            "전세가": doc["전세가"],
            "주소": doc.get("주소", ""),
            "lat": doc.get("lat", 0.0),
            "lng": doc.get("lng", 0.0),
            "동": doc.get("동", "")
        }))
    return results

@router.get("/stations")
async def get_stations():
    results = []
    cursor = station.find({})
    async for doc in cursor:
        # _id 제거 + 문자열 숫자 처리
        doc.pop("_id", None)
        results.append(staion_info(**{
            "역사명": doc.get("역사명"),
            "호선": doc.get("호선"),
            "lat": doc.get("위도", 0.0),
            "lng": doc.get("경도", 0.0),
        }))
    return results


@router.get("/schools")
async def get_schools():
    results = []
    cursor = schoolgeo.find({})
    async for doc in cursor:
        # _id 제거 + 문자열 숫자 처리
        doc.pop("_id", None)
        results.append(school_info(**{
            "학교명": doc.get("학교명"),
            "lat": doc.get("위도", 0.0),
            "lng": doc.get("경도", 0.0),
        }))
    return results

# 4. 예측용 API endpoint 작성
@router.post("/predict")
def predict(input_data: PredictionInput):
    try:
        # 가까운 역과 거리 계산
        nearest_station, nearest_line, distance = find_nearest_station(
            input_data.위도, input_data.경도, Station
        )

        # 입력 데이터 프레임 생성
        input_df = pd.DataFrame([{
            '층': input_data.층,
            '임대면적': input_data.임대면적,
            '건축년도': input_data.건축년도,
            '거리(m)': distance,
            '접수년도': input_data.접수년도,
        }])

        prediction = seoul_west_model.predict(input_df)

        return {
            "predicted_보증금": float(prediction[0]),
            "nearest_station": nearest_station,
            "nearest_line": nearest_line,
            "distance_m": distance
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

