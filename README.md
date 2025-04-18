# PayViya Payment Assistant API

PayViya is a payment assistant API that recommends the best credit cards for a purchase, helping users maximize savings through card benefits and promotional campaigns.

## Features

- **Card Recommendation Engine**: Analyzes shopping cart details to recommend the best credit cards
- **Campaign Database**: Stores bank promotions, discounts, and special offers
- **Campaign Enrollment**: Automatically enrolls users in bank campaigns via bank APIs
- **RESTful API**: JSON-based API for easy integration with e-commerce platforms
- **Admin Panel**: For campaign management and performance tracking

## API Usage

### Card Recommendation

```bash
# Get card recommendations for a purchase
curl -X POST "http://localhost:8000/api/v1/recommendations" \
  -H "Content-Type: application/json" \
  -d '{
    "cart_amount": 1500.50,
    "cart_category": "electronics",
    "merchant_name": "TechStore",
    "user_cards": [1, 3, 5]
  }'
```

### Campaign Enrollment

```bash
# Enroll a user in a bank campaign
curl -X POST "http://localhost:8000/api/v1/banks/campaigns/5/enroll" \
  -H "Content-Type: application/json" \
  -d '{
    "masked_card_number": "1234",
    "phone_number": "+90555123456"
  }'
```

## Architecture

- **FastAPI**: High-performance API framework
- **SQLAlchemy**: ORM for database interactions
- **PostgreSQL**: Main database
- **Pydantic**: Data validation and settings management

## Development Setup

1. Create a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

3. Set up environment variables:
   ```
   cp .env.example .env  # Then edit the .env file with your settings
   ```

4. Initialize the database:
   ```
   alembic upgrade head
   ```

5. Run the development server:
   ```
   uvicorn app.main:app --reload
   ```

6. Visit the API documentation:
   ```
   http://localhost:8000/docs
   ```

## E-commerce Integration

PayViya provides React components and plugins for major e-commerce platforms:

- Shopify plugin
- WooCommerce plugin
- React widget for custom integrations

## License

Proprietary - All rights reserved.

## Contact

For more information, please contact Ceyhun, Founder @ PayViya. 