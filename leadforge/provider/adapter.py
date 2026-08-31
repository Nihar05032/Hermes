"""
LeadForge AI — Business Provider Adapter Interface

All data providers implement this interface so the system
can swap between Google Places, OpenStreetMap, Yelp, etc.
"""

from abc import ABC, abstractmethod
from typing import List, Optional
from pydantic import BaseModel


class BusinessResult(BaseModel):
    """Standardized output from all providers."""
    external_id: str
    name: str
    category: str
    description: Optional[str] = None
    address: str
    city: str
    state: Optional[str] = None
    country: str
    postal_code: Optional[str] = None
    latitude: float
    longitude: float
    phone: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    rating: Optional[float] = None
    review_count: Optional[int] = None
    source: str = "unknown"


class BusinessProviderAdapter(ABC):
    """Abstract base class for all business data providers."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Provider identifier (e.g., 'google_places', 'openstreetmap')."""
        pass

    @abstractmethod
    async def search(
        self,
        country: str,
        city: str,
        category: str,
        radius_km: int = 20,
        min_rating: float = 0.0,
        min_reviews: int = 0,
        website_filter: str = "all",  # all, has_website, no_website
    ) -> List[BusinessResult]:
        """Search for businesses matching the criteria."""
        pass

    @abstractmethod
    async def get_details(self, external_id: str) -> Optional[BusinessResult]:
        """Get detailed information for a single business."""
        pass

    @abstractmethod
    async def get_reviews(self, external_id: str, limit: int = 50) -> List[dict]:
        """Get reviews for a business. Returns list of review dicts."""
        pass


# ============================================
# Provider Implementations (stubs)
# ============================================

class GooglePlacesProvider(BusinessProviderAdapter):
    """Google Places API provider — requires GOOGLE_PLACES_API_KEY."""

    @property
    def name(self) -> str:
        return "google_places"

    async def search(self, country, city, category, radius_km=20, min_rating=0, min_reviews=0, website_filter="all"):
        # Implementation: call Places API Text Search + Nearby Search
        # https://developers.google.com/maps/documentation/places/web-service/text-search
        raise NotImplementedError("Implement with Google Places API")

    async def get_details(self, external_id):
        raise NotImplementedError

    async def get_reviews(self, external_id, limit=50):
        raise NotImplementedError


class OpenStreetMapProvider(BusinessProviderAdapter):
    """OpenStreetMap/Overpass API provider — free, no API key."""

    @property
    def name(self) -> str:
        return "openstreetmap"

    async def search(self, country, city, category, radius_km=20, min_rating=0, min_reviews=0, website_filter="all"):
        # Implementation: use Overpass API to query OSM data
        raise NotImplementedError

    async def get_details(self, external_id):
        raise NotImplementedError

    async def get_reviews(self, external_id, limit=50):
        return []  # OSM doesn't have reviews


class GoogleMapsScraperProvider(BusinessProviderAdapter):
    """Google Maps Scraper (gosom/google-maps-scraper) — runs locally via Docker."""

    @property
    def name(self) -> str:
        return "gmaps_scraper"

    async def search(self, country, city, category, radius_km=20, min_rating=0, min_reviews=0, website_filter="all"):
        # Implementation: write queries to file, run scraper, parse CSV output
        # See: https://github.com/gosom/google-maps-scraper
        raise NotImplementedError

    async def get_details(self, external_id):
        raise NotImplementedError

    async def get_reviews(self, external_id, limit=50):
        raise NotImplementedError


# ============================================
# Provider Registry
# ============================================

PROVIDERS = {
    "google_places": GooglePlacesProvider,
    "openstreetmap": OpenStreetMapProvider,
    "gmaps_scraper": GoogleMapsScraperProvider,
}


def get_provider(name: str) -> BusinessProviderAdapter:
    """Get a provider instance by name."""
    if name not in PROVIDERS:
        raise ValueError(f"Unknown provider: {name}. Available: {list(PROVIDERS.keys())}")
    return PROVIDERS[name]()