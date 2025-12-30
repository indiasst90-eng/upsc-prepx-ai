"""
crawl4ai VPS Service for UPSC PrepX-AI
Official crawl4ai integration as FastAPI service on port 8105

Allowed domains:
- visionias.in, drishtiias.com, thehindu.com, pib.gov.in
- forumias.com, iasgyan.in, pmfias.com, pwonlyias.com
- byjus.com, insightsonindia.com, upscpdf.com, *.gov.in
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, HttpUrl
from typing import Optional, List
import asyncio
from urllib.parse import urlparse

# Initialize FastAPI app
app = FastAPI(
    title="crawl4ai UPSC Service",
    description="Official crawl4ai integration for UPSC current affairs",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Allowed domains for UPSC content
ALLOWED_DOMAINS = [
    "visionias.in",
    "drishtiias.com",
    "thehindu.com",
    "pib.gov.in",
    "forumias.com",
    "iasgyan.in",
    "pmfias.com",
    "pwonlyias.com",
    "byjus.com",
    "insightsonindia.com",
    "upscpdf.com",
    # Government domains
    "india.gov.in",
    "pmindia.gov.in",
    "mea.gov.in",
    "mha.gov.in",
    "niti.gov.in",
]

# Global crawler instance
_crawler = None

def get_crawler():
    """Get or create crawler instance"""
    global _crawler
    if _crawler is None:
        try:
            from crawl4ai import WebCrawler
            _crawler = WebCrawler()
            _crawler.warmup()
        except ImportError:
            raise HTTPException(
                status_code=500, 
                detail="crawl4ai not installed. Run: pip install crawl4ai"
            )
    return _crawler

def is_allowed_domain(url: str) -> bool:
    """Check if URL is from an allowed domain"""
    try:
        parsed = urlparse(url)
        hostname = parsed.hostname.lower() if parsed.hostname else ""
        
        # Check for government domains
        if hostname.endswith('.gov.in') or hostname.endswith('.nic.in'):
            return True
        
        # Check allowed domains
        for domain in ALLOWED_DOMAINS:
            if hostname == domain or hostname.endswith(f'.{domain}'):
                return True
        
        return False
    except Exception:
        return False

# Request/Response models
class CrawlRequest(BaseModel):
    url: HttpUrl
    extract_links: bool = False
    extract_images: bool = False

class CrawlResponse(BaseModel):
    url: str
    title: str
    content: str
    html: Optional[str] = None
    links: Optional[List[str]] = None
    images: Optional[List[str]] = None
    success: bool
    error: Optional[str] = None

class SearchRequest(BaseModel):
    topic: str
    domains: Optional[List[str]] = None
    max_results: int = 5

class HealthResponse(BaseModel):
    status: str
    service: str
    crawler_ready: bool
    allowed_domains: List[str]

# Endpoints
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    crawler_ready = False
    try:
        get_crawler()
        crawler_ready = True
    except Exception:
        pass
    
    return HealthResponse(
        status="healthy",
        service="crawl4ai-upsc",
        crawler_ready=crawler_ready,
        allowed_domains=ALLOWED_DOMAINS
    )

@app.post("/crawl", response_model=CrawlResponse)
async def crawl_url(request: CrawlRequest):
    """Crawl a single URL (must be from allowed domain)"""
    url = str(request.url)
    
    # Validate domain
    if not is_allowed_domain(url):
        raise HTTPException(
            status_code=403,
            detail=f"Domain not allowed. Only UPSC-approved sources permitted."
        )
    
    try:
        crawler = get_crawler()
        result = crawler.run(url=url, bypass_cache=True)
        
        return CrawlResponse(
            url=url,
            title=result.title or "",
            content=result.extracted_content or result.markdown or "",
            html=result.html if request.extract_links or request.extract_images else None,
            links=result.links if request.extract_links else None,
            images=result.images if request.extract_images else None,
            success=result.success,
            error=None
        )
    except Exception as e:
        return CrawlResponse(
            url=url,
            title="",
            content="",
            success=False,
            error=str(e)
        )

@app.post("/batch")
async def batch_crawl(urls: List[str]):
    """Crawl multiple URLs in batch"""
    results = []
    
    for url in urls[:10]:  # Max 10 URLs per batch
        if not is_allowed_domain(url):
            results.append({
                "url": url,
                "success": False,
                "error": "Domain not allowed"
            })
            continue
        
        try:
            crawler = get_crawler()
            result = crawler.run(url=url, bypass_cache=True)
            results.append({
                "url": url,
                "title": result.title or "",
                "content": result.extracted_content or result.markdown or "",
                "success": result.success
            })
        except Exception as e:
            results.append({
                "url": url,
                "success": False,
                "error": str(e)
            })
    
    return {"results": results, "total": len(results)}

@app.get("/domains")
async def list_allowed_domains():
    """List all allowed domains for crawling"""
    return {
        "domains": ALLOWED_DOMAINS,
        "government_pattern": "*.gov.in, *.nic.in",
        "total": len(ALLOWED_DOMAINS) + 2  # +2 for gov.in patterns
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8105)
