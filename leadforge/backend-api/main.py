"""
LeadForge AI — Backend API
Serves as the bridge between n8n workflows, Hermes agents, and Supabase.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import os

app = FastAPI(title="LeadForge AI API", version="1.0.0")

# ============================================
# Models
# ============================================

class SearchRequest(BaseModel):
    country: str
    city: str
    category: str
    radius: int = 20
    min_rating: float = 3.5
    min_reviews: int = 10
    website_filter: str = "no_website"

class EnrichmentRequest(BaseModel):
    business_id: str

class ScoringRequest(BaseModel):
    business_id: str

class WebsiteGenerationRequest(BaseModel):
    business_id: str

class OutreachRequest(BaseModel):
    business_id: str

class LeadStatusUpdate(BaseModel):
    business_id: str
    status: str

# ============================================
# Endpoints
# ============================================

@app.get("/health")
async def health():
    return {"status": "ok", "service": "leadforge-api"}

@app.post("/api/search")
async def search_businesses(req: SearchRequest):
    """Trigger business search via configured provider."""
    provider_name = os.getenv("BUSINESS_DATA_PROVIDER", "google_places")
    return {
        "status": "searching",
        "provider": provider_name,
        "params": req.dict()
    }

@app.post("/api/trigger-enrichment")
async def trigger_enrichment(req: EnrichmentRequest):
    """Trigger Hermes Research Agent for a business."""
    return {
        "status": "enrichment_started",
        "business_id": req.business_id,
        "agent": "RESEARCH"
    }

@app.post("/api/trigger-scoring")
async def trigger_scoring(req: ScoringRequest):
    """Trigger Hermes Lead Scoring Agent."""
    return {
        "status": "scoring_started",
        "business_id": req.business_id,
        "agent": "LEAD_SCORING"
    }

@app.post("/api/generate-website")
async def generate_website(req: WebsiteGenerationRequest):
    """Trigger Hermes Website Developer Agent."""
    return {
        "status": "website_generation_started",
        "business_id": req.business_id,
        "agent": "WEBSITE_DEVELOPER"
    }

@app.post("/api/trigger-outreach")
async def trigger_outreach(req: OutreachRequest):
    """Trigger Hermes Outreach Agent."""
    return {
        "status": "outreach_started",
        "business_id": req.business_id,
        "agent": "OUTREACH"
    }

@app.post("/api/update-lead-status")
async def update_lead_status(req: LeadStatusUpdate):
    """Update lead status in Supabase."""
    return {
        "status": "updated",
        "business_id": req.business_id,
        "new_status": req.status
    }

@app.get("/api/leads")
async def get_leads(status: Optional[str] = None, limit: int = 100):
    """Get leads from Supabase."""
    return {
        "status": "ok",
        "filter": status,
        "limit": limit
    }

@app.get("/api/stats")
async def get_stats():
    """Get pipeline statistics."""
    return {
        "total_businesses": 0,
        "total_leads": 0,
        "qualified_leads": 0,
        "websites_generated": 0,
        "emails_sent": 0,
        "replies_received": 0
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3001)