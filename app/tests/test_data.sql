-- Insert test merchant
INSERT INTO merchants (id, name, categories, logo_url, latitude, longitude, address, city, country, phone, website)
VALUES (
    9999,
    'Test Merchant',
    'Restaurant,Cafe',
    'https://example.com/logo.png',
    40.991884,
    29.126472,
    'Test Address',
    'Istanbul',
    'Turkey',
    '+901234567890',
    'https://example.com'
);

-- Insert test campaign category
INSERT INTO campaign_categories (id, enum, name, icon_url, color)
VALUES (
    9999,
    'TEST_CATEGORY',
    'Test Category',
    'https://example.com/icon.png',
    '#FF0000'
);

-- Insert test campaign
INSERT INTO campaigns (
    id, name, description, category_id, discount_type, discount_value,
    min_amount, max_discount, start_date, end_date, merchant_id, is_active
)
VALUES (
    9999,
    'Test Campaign',
    'Test campaign description',
    9999,
    'PERCENTAGE',
    20.0,
    100.0,
    50.0,
    NOW(),
    NOW() + INTERVAL '30 days',
    9999,
    true
);

-- Insert test notifications
DO $$
DECLARE
    i INTEGER;
    current_time TIMESTAMP WITH TIME ZONE;
BEGIN
    current_time := NOW();
    
    FOR i IN 1..15 LOOP
        INSERT INTO notification_history (
            user_id,
            merchant_id,
            campaign_id,
            latitude,
            longitude,
            location_hash,
            category_id,
            title,
            body,
            is_read,
            sent_at
        ) VALUES (
            6, -- Mevcut user_id
            9999,
            9999,
            40.991884,
            29.126472,
            'test_location_hash',
            9999,
            'Test Notification ' || i,
            'This is test notification body ' || i,
            CASE WHEN i <= 5 THEN true ELSE false END,
            current_time - (INTERVAL '1 hour' * i)
        );
    END LOOP;
END $$; 