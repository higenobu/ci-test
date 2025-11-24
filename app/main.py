from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI()


class NumbersRequest(BaseModel):
    numbers: List[int]


@app.get("/")
def read_root():
    return {"message": "Welcome to the API"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.post("/max")
def compute_max(request: NumbersRequest):
    if not request.numbers:
        raise HTTPException(status_code=400, detail="Numbers list cannot be empty")
    return {"max": max(request.numbers)}
