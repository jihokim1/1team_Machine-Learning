from fastapi import FastAPI
from hakhyun import router as hakhyun_router
from inhwan import router as inhwan_router
from jiho import router as jiho_router


app = FastAPI() 
app.include_router(hakhyun_router,prefix="/hakhyun")
app.include_router(inhwan_router,prefix="/inhwan")
app.include_router(jiho_router,prefix="/jiho")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app,host='127.0.0.1',port=8000)
