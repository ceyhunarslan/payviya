from typing import List, Dict, Optional
import aiohttp
import json
from datetime import datetime

class OSMService:
    OVERPASS_API_URL = "https://overpass-api.de/api/interpreter"
    
    # OSM shop tag'lerini kampanya kategorilerine eşleştirme
    SHOP_TO_CATEGORY_MAP = {
        # GROCERY
        "supermarket": "GROCERY",
        "convenience": "GROCERY",
        "grocery": "GROCERY",
        "butcher": "GROCERY",
        "bakery": "GROCERY",
        "greengrocer": "GROCERY",
        "deli": "GROCERY",

        # ELECTRONICS
        "electronics": "ELECTRONICS",
        "mobile_phone": "ELECTRONICS",
        "computer": "ELECTRONICS",
        "hifi": "ELECTRONICS",
        "camera": "ELECTRONICS",
        "video": "ELECTRONICS",
        "video_games": "ELECTRONICS",

        # FASHION
        "clothes": "FASHION",
        "shoes": "FASHION",
        "jewelry": "FASHION",
        "bag": "FASHION",
        "boutique": "FASHION",
        "accessories": "FASHION",
        "leather": "FASHION",
        "watches": "FASHION",

        # FUEL
        "fuel": "FUEL",
        "gas": "FUEL",

        # HEALTH
        "health": "HEALTH",
        "pharmacy": "HEALTH",
        "optician": "HEALTH",
        "medical_supply": "HEALTH",
        "herbalist": "HEALTH",
        "nutrition": "HEALTH",

        # ENTERTAINMENT
        "cinema": "ENTERTAINMENT",
        "theatre": "ENTERTAINMENT",
        "music": "ENTERTAINMENT",
        "games": "ENTERTAINMENT",
        "sports": "ENTERTAINMENT",
        "hobby": "ENTERTAINMENT",
        "books": "ENTERTAINMENT",
        "ticket": "ENTERTAINMENT",

        # TRAVEL
        "travel_agency": "TRAVEL",
        "ticket_agent": "TRAVEL"
    }

    # Mapping for amenity tags to categories
    AMENITY_TO_CATEGORY_MAP = {
        # RESTAURANT
        "restaurant": "RESTAURANT",
        "cafe": "RESTAURANT",
        "fast_food": "RESTAURANT",
        "food_court": "RESTAURANT",
        "pub": "RESTAURANT",
        "bar": "RESTAURANT",
        "ice_cream": "RESTAURANT",

        # ENTERTAINMENT
        "cinema": "ENTERTAINMENT",
        "theatre": "ENTERTAINMENT",
        "arts_centre": "ENTERTAINMENT",
        "nightclub": "ENTERTAINMENT",
        "gambling": "ENTERTAINMENT",
        "casino": "ENTERTAINMENT",
        "social_centre": "ENTERTAINMENT",

        # HEALTH
        "pharmacy": "HEALTH",
        "clinic": "HEALTH",
        "doctors": "HEALTH",
        "dentist": "HEALTH",
        "hospital": "HEALTH",

        # TRAVEL
        "bus_station": "TRAVEL",
        "car_rental": "TRAVEL",
        "bicycle_rental": "TRAVEL",
        "taxi": "TRAVEL"
    }

    # Mapping for tourism tags to categories
    TOURISM_TO_CATEGORY_MAP = {
        "hotel": "TRAVEL",
        "motel": "TRAVEL",
        "hostel": "TRAVEL",
        "guest_house": "TRAVEL",
        "apartment": "TRAVEL",
        "camp_site": "TRAVEL",
        "caravan_site": "TRAVEL"
    }

    @staticmethod
    async def get_nearby_businesses(latitude: float, longitude: float, radius: int = 50) -> List[Dict]:
        """
        Get nearby businesses using Overpass API
        """
        print(f"\n=================== OVERPASS API REQUEST ===================")
        print(f"Parameters:")
        print(f"  Latitude: {latitude}")
        print(f"  Longitude: {longitude}")
        print(f"  Radius: {radius} meters")
        print(f"  Timestamp: {datetime.now().isoformat()}")

        # Expanded Overpass QL query to include more business types
        query = f"""
        [out:json][timeout:25];
        (
          node["shop"](around:{radius},{latitude},{longitude});
          node["amenity"~"^(restaurant|cafe|fast_food|food_court|pub|bar|cinema|theatre|pharmacy|clinic|doctors|hospital|bus_station|car_rental)$"](around:{radius},{latitude},{longitude});
          node["tourism"~"^(hotel|motel|hostel|guest_house|apartment)$"](around:{radius},{latitude},{longitude});
        );
        out body;
        """
        
        print(f"\nOverpass QL Query:")
        print(query)

        try:
            async with aiohttp.ClientSession() as session:
                print(f"\nSending request to: {OSMService.OVERPASS_API_URL}")
                start_time = datetime.now()
                
                async with session.post(OSMService.OVERPASS_API_URL, data={"data": query}) as response:
                    end_time = datetime.now()
                    response_time = (end_time - start_time).total_seconds()
                    
                    print(f"\nResponse Info:")
                    print(f"  Status: {response.status}")
                    print(f"  Response Time: {response_time:.2f} seconds")
                    print(f"  Content Type: {response.headers.get('content-type', 'unknown')}")
                    print(f"  Content Length: {response.headers.get('content-length', 'unknown')} bytes")
                    
                    if response.status != 200:
                        error_text = await response.text()
                        print(f"Error response from Overpass API: {error_text}")
                        return []
                    
                    data = await response.json()
                    print(f"\nResponse Data Analysis:")
                    print(f"  Data Type: {type(data)}")
                    print(f"  Has 'elements' key: {'elements' in data}")
                    
                    elements = data.get("elements", [])
                    print(f"  Number of elements: {len(elements)}")
                    
                    if elements:
                        print("\nElement Types Found:")
                        type_counts = {}
                        for element in elements:
                            tags = element.get("tags", {})
                            if "shop" in tags:
                                type_counts[f"shop:{tags['shop']}"] = type_counts.get(f"shop:{tags['shop']}", 0) + 1
                            if "amenity" in tags:
                                type_counts[f"amenity:{tags['amenity']}"] = type_counts.get(f"amenity:{tags['amenity']}", 0) + 1
                            if "tourism" in tags:
                                type_counts[f"tourism:{tags['tourism']}"] = type_counts.get(f"tourism:{tags['tourism']}", 0) + 1
                        
                        for type_name, count in type_counts.items():
                            print(f"    {type_name}: {count}")
                    
                    if not data or not elements:
                        print("No elements found in response")
                        return []

                    businesses = []
                    for element in elements:
                        tags = element.get("tags", {})
                        
                        # Try to match category from different tag types
                        category = None
                        
                        # Check shop tags first
                        if "shop" in tags:
                            category = OSMService.SHOP_TO_CATEGORY_MAP.get(tags["shop"])
                        
                        # If no match, check amenity tags
                        if not category and "amenity" in tags:
                            category = OSMService.AMENITY_TO_CATEGORY_MAP.get(tags["amenity"])
                        
                        # If still no match, check tourism tags
                        if not category and "tourism" in tags:
                            category = OSMService.TOURISM_TO_CATEGORY_MAP.get(tags["tourism"])
                        
                        # Skip if no category match found
                        if not category:
                            continue
                        
                        # Get the business name
                        name = tags.get("name", "")
                        if not name:
                            name = tags.get("brand", "Unnamed Business")
                        
                        business = {
                            "id": str(element["id"]),
                            "name": name,
                            "type": category,
                            "latitude": element["lat"],
                            "longitude": element["lon"],
                            "tags": tags
                        }
                        businesses.append(business)

                    print(f"\nProcessed Results:")
                    print(f"  Total elements found: {len(elements)}")
                    print(f"  Matched businesses: {len(businesses)}")
                    if businesses:
                        print("\nMatched Categories:")
                        category_counts = {}
                        for business in businesses:
                            category_counts[business["type"]] = category_counts.get(business["type"], 0) + 1
                        for category, count in category_counts.items():
                            print(f"    {category}: {count}")
                    
                    print("=======================================================\n")
                    return businesses

        except Exception as e:
            print(f"\nError fetching nearby businesses from OSM:")
            print(f"Exception type: {type(e)}")
            print(f"Exception message: {str(e)}")
            print(f"Stack trace:")
            import traceback
            print(traceback.format_exc())
            print(f"=======================================================\n")
            return []

    @staticmethod
    def match_business_type(tags: Dict) -> Optional[str]:
        """
        Match OSM tags to campaign categories
        """
        if "shop" in tags and tags["shop"] in OSMService.SHOP_TO_CATEGORY_MAP:
            return OSMService.SHOP_TO_CATEGORY_MAP[tags["shop"]]
        
        if "amenity" in tags:
            amenity = tags["amenity"]
            if amenity in ["restaurant", "cafe", "fast_food"]:
                return "RESTAURANT"
        
        return None 