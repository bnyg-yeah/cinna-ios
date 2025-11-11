# app.py  — minimal FastAPI backend for Cinna
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Any, Dict

app = FastAPI()

class RecommendationRequest(BaseModel):
    genres: List[str]

@app.get("/")
def root() -> Dict[str, str]:
    return {"status": "Cinna GraphRAG backend is running!"}

@app.post("/recommendations")
def recommend_movies(request: RecommendationRequest) -> Dict[str, Any]:
    # Pretend these came from GraphRAG; format matches TMDbMovie
    movies = [
        {
            "id": 1,
            "title": "Inception",
            "overview": "A thief enters dreams to steal secrets.",
            "release_date": "2010-07-16",
            "poster_path": "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
            "vote_average": 8.8
        },
        {
            "id": 2,
            "title": "Dune: Part Two",
            "overview": "Paul unites with the Fremen against Harkonnen.",
            "release_date": "2024-03-01",
            "poster_path": "/1E5baAaEse26fej7uHcjOgEE2t2.jpg",
            "vote_average": 8.6
        },
        {
            "id": 3,
            "title": "Interstellar",
            "overview": "A crew travels through a wormhole for humanity.",
            "release_date": "2014-11-07",
            "poster_path": "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
            "vote_average": 8.7
        }
    ]
    return {"query": request.genres, "response": movies}

