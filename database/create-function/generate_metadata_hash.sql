CREATE OR REPLACE FUNCTION generate_metadata_hash()
RETURNS text AS $$
BEGIN
    RETURN substring(md5(random()::text), 1, 32);
END;
$$ LANGUAGE plpgsql;
