import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
from supabase import create_client
from typing import List, Optional

load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
AVG_SERVICE_MINUTES = int(os.getenv("AVG_SERVICE_MINUTES", "2"))

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError("Missing Supabase credentials")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
app = FastAPI(title="QueueLess Backend")

class JoinRequest(BaseModel):
    Name: str
    Phone: Optional[str] = None
    Email: Optional[str] = None
    business_id: Optional[int] = None

class PositionResponse(BaseModel):
    id: int
    position: int
    estimated_wait_minutes: int

def estimate_wait(position: int, avg_per_person: int = AVG_SERVICE_MINUTES) -> int:
    return position * avg_per_person

@app.post("/join", response_model=PositionResponse)
def join_queue(req: JoinRequest):
    payload = {
        "Name": req.Name,
        "Phone": req.Phone,
        "Email": req.Email,
        "Status": "Waiting",
        "business_id": req.business_id
    }
    res = supabase.table("Queue").insert(payload).execute()
    if res.error:
        raise HTTPException(status_code=500, detail=res.error.message)
    row = res.data[0]
    created_at = row.get("Created_at")
    q = supabase.table("Queue").select("id").eq("Status","Waiting").lte("Created_at", created_at).execute()
    if q.error:
        raise HTTPException(status_code=500, detail=q.error.message)
    position = len(q.data)
    return {"id": row["id"], "position": position, "estimated_wait_minutes": estimate_wait(position)}

@app.get("/queue", response_model=List[dict])
def get_queue(limit: int = 100, business_id: Optional[int] = None):
    query = supabase.table("Queue").select("*").eq("Status","Waiting").order("Created_at", {"ascending": True}).limit(limit)
    if business_id is not None:
        query = query.eq("business_id", business_id)
    res = query.execute()
    if res.error:
        raise HTTPException(status_code=500, detail=res.error.message)
    return res.data
