import pytest
from services.osm_service import OSMService

@pytest.mark.asyncio
async def test_get_nearby_businesses():
    # Test koordinatları (İstanbul, Kadıköy)
    latitude = 40.994522
    longitude = 29.137346
    radius = 100

    businesses = await OSMService.get_nearby_businesses(latitude, longitude, radius)
    
    # Temel kontroller
    assert isinstance(businesses, list)
    
    if businesses:  # Eğer işletme bulunduysa
        business = businesses[0]
        assert "osm_id" in business
        assert "name" in business
        assert "type" in business
        assert "latitude" in business
        assert "longitude" in business
        assert "tags" in business

def test_match_business_type():
    # Süpermarket test
    tags = {"shop": "supermarket"}
    assert OSMService.match_business_type(tags) == "GROCERY"

    # Restaurant test
    tags = {"amenity": "restaurant"}
    assert OSMService.match_business_type(tags) == "RESTAURANT"

    # Desteklenmeyen tag test
    tags = {"shop": "not_supported"}
    assert OSMService.match_business_type(tags) is None 