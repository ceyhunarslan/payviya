-- Insert test notifications using existing campaigns
DO $$
DECLARE
    i INTEGER;
    notification_time TIMESTAMP WITH TIME ZONE;
    campaign_record RECORD;
BEGIN
    notification_time := NOW();
    
    FOR campaign_record IN 
        SELECT c.id as campaign_id, c.merchant_id, c.name as campaign_name, m.name as merchant_name
        FROM campaigns c
        JOIN merchants m ON c.merchant_id = m.id
        WHERE c.is_active = true
        ORDER BY c.id
        LIMIT 15
    LOOP
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
            campaign_record.merchant_id,
            campaign_record.campaign_id,
            40.991884,
            29.126472,
            'test_location_hash',
            (SELECT id FROM campaign_categories ORDER BY id LIMIT 1), -- İlk kategoriyi kullan
            campaign_record.merchant_name || ' - ' || campaign_record.campaign_name,
            'Yakınınızda bir kampanya var: ' || campaign_record.campaign_name,
            false,
            notification_time - (INTERVAL '1 hour' * i)
        );
    END LOOP;
END $$; 