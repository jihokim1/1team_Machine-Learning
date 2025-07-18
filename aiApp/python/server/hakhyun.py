# FastAPI 프레임워크 임포트: 웹 서버 및 REST API 서버를 쉽게 구축할 수 있게 해주는 라이브러리
from fastapi import APIRouter, HTTPException

# Motor: 비동기 MongoDB 드라이버. AsyncIOMotorClient를 통해 MongoDB에 비동기로 접속 가능
from motor.motor_asyncio import AsyncIOMotorClient

# Pydantic: 데이터 검증 및 직렬화를 도와주는 라이브러리. BaseModel을 상속하여 데이터 모델 정의에 사용
from pydantic import BaseModel, Field

# typing 모듈: 선택적 타입 힌팅을 위해 Optional 사용 (값이 있을 수도, 없을 수도 있음)
from typing import Optional


import math
import os
import joblib
import pandas as pd

router = APIRouter()
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, '../Data/마포구_상암동_xgb.h5')
MODEL_PATH1 = os.path.join(BASE_DIR, '../Data/공릉동_xgb.h5')
DATA_PATH = os.path.join(BASE_DIR, '../Data/서울시 역사마스터 정보.csv')
DATA1_PATH = os.path.join(BASE_DIR, '../Data/서울특별시 마포구_관내 병원 현황_20241101.xlsx')
DATA2_PATH = os.path.join(BASE_DIR, '../Data/서울특별시 마포구_동주민센터 공간정보데이터_20250701.xlsx')
DATA3_PATH = os.path.join(BASE_DIR, '../Data/서울특별시 마포구_학교 현황_20241101.xlsx')
DATA4_PATH = os.path.join(BASE_DIR, '../Data/서울특별시_마포구_어린이공원현황_20250319.xlsx')
DATA5_PATH = os.path.join(BASE_DIR, '../Data/학교서울.csv')
상암동 = joblib.load(MODEL_PATH)
공릉동 = joblib.load(MODEL_PATH1)
MONGO_URI = "mongodb://localhost:27017"
client = AsyncIOMotorClient(MONGO_URI) 
db = client['map_info']
gangseo_collection = db['gangseo_info']
mapo_collection = db['mapo_info']
nowon_collection = db['nowon_info']
Station = pd.read_csv(DATA_PATH, encoding='euc-kr')
hospital_df = pd.read_excel(DATA1_PATH)
center_df = pd.read_excel(DATA2_PATH)
school_df = pd.read_excel(DATA3_PATH)
park_df = pd.read_excel(DATA4_PATH)
seoul_school_df = pd.read_csv(DATA5_PATH)


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

class ApartmentFeatures(BaseModel):
    층: int
    임대면적: float
    건축년도: int
    접수년도: int
    # 병원과의거리_m: Optional[float] = Field(None, alias="병원과의거리(m)")
    # 공원과의거리_m: Optional[float] = Field(None, alias="공원과의거리(m)")
    # 학교와의거리_m: Optional[float] = Field(None, alias="학교와의거리(m)")
    # 주민센터와의거리_m: Optional[float] = Field(None, alias="주민센터와의거리(m)")
    위도: Optional[float] = None
    경도: Optional[float] = None
    # 노후도: Optional[float] = None

class ApartmentFeatures1(BaseModel):
    # 동이름: str
    접수년도: int
    층: int
    임대면적: float
    건축년도: int
    # 거리_m: Optional[float] = Field(None, alias="거리(m)")
    # 학교거리_m: Optional[float] = Field(None, alias="햑교와의 거리(m)")
    수급동향: int
    신규계약구분_num: int
    위도: Optional[float] = None
    경도: Optional[float] = None


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

@router.post("/sang_predict")
def predict(data: ApartmentFeatures):
    try:
        distance_to_hospital = find_nearest_station1(data.위도, data.경도, hospital_df)
        # data.병원과의거리_m = distance_to_hospital
        distance_to_park = find_nearest_station1(data.위도, data.경도, park_df)
        # data.공원과의거리_m = distance_to_park
        distance_to_center = find_nearest_station1(data.위도, data.경도, center_df)
        # data.주민센터와의거리_m = distance_to_center
        distance_to_school = find_nearest_station1(data.위도, data.경도, school_df)
        # data.학교와의거리_m = distance_to_school
        # 가까운 역과 거리 계산
        nearest_station, nearest_line, distance = find_nearest_station(
            data.위도, data.경도, Station
        )
        if data.접수년도==0:
            data.접수년도 = 2025
        a_노후도 = data.접수년도 - data.건축년도
        

        # 입력 데이터 프레임 생성
        input_df = pd.DataFrame([{
            "접수년도": data.접수년도,
            "층": data.층,
            "임대면적": data.임대면적,
            "건축년도": data.건축년도,
            "병원과의거리(m)": distance_to_hospital,
            "공원과의거리(m)": distance_to_park,
            "학교와의거리(m)": distance_to_school,
            "주민센터와의거리(m)": distance_to_center,
            "노후도": a_노후도
        }])

        prediction = 상암동.predict(input_df)

        return {
            "predicted_보증금": float(prediction[0]),
            "nearest_station": nearest_station,
            "nearest_line": nearest_line,
            "distance_m": distance
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/gong_predict")
def predict(data: ApartmentFeatures1):
    raw = data.dict()
    # dong = raw.pop("동이름")  # 동 이름만 분리

    try:
        # 동 이름에 맞는 모델 로드
        # model = joblib.load(MODEL_PATH1)
        # nearest_station, nearest_line, distance = find_nearest_station(
        #     data.위도, data.경도, Station
        # )


        # 2. 노후도 계산
        _, _, distance_to_station = find_nearest_station(data.위도, data.경도, Station)
        # data.거리_m = distance_to_station
        distance_to_seoul_school = find_nearest_station1(data.위도, data.경도, seoul_school_df)
        # data.학교거리_m = distance_to_seoul_school

        if data.접수년도==0:
            data.접수년도 = 2025
            
        df = pd.DataFrame([{
            '접수년도': raw['접수년도'],
            '층': raw['층'],
            '건축년도': raw['건축년도'],
            '임대면적': raw['임대면적'],
            '거리(m)': distance_to_station,
            '햑교와의 거리(m)': distance_to_seoul_school,
            '수급동향': raw['수급동향'],
            '신규계약구분_num': raw['신규계약구분_num'],
        }])

        # 예측 수행
        prediction = 공릉동.predict(df)
        return {
            "predicted_보증금": float(prediction[0]),
            # "nearest_station": nearest_station,
            # "nearest_line": nearest_line,
            # "distance_m": distance
        }
    
    except Exception as e:
        return {"error": f"예측 실패: {str(e)}"}





