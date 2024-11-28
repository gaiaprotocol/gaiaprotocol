CREATE OR REPLACE FUNCTION "public"."handle_contract_event"() RETURNS "trigger"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$
BEGIN
  -- ClanEmblems
  IF NEW.contract_address = '0x9322C4A5E5725262C9960aDE87259d1cE2812412' THEN
    IF NEW.name = 'ClanCreated' THEN
      IF EXISTS (SELECT 1 FROM pending_clans WHERE metadata_hash = NEW.args->>'metadataHash') THEN
        INSERT INTO clans (chain_id, id, owner, name, logo_image_url, logo_thumbnail_url, description)
        SELECT NEW.chain_id, NEW.args->>'clanId', NEW.args->>'clanOwner', pc.name, pc.logo_image_url, pc.logo_thumbnail_url, pc.description
        FROM pending_clans pc
        WHERE pc.metadata_hash = NEW.args->>'metadataHash'
        ON CONFLICT (chain_id, id) DO UPDATE
        SET owner = NEW.args->>'clanOwner';

        DELETE FROM pending_clans
        WHERE metadata_hash = NEW.args->>'metadataHash';
      ELSE
        INSERT INTO clans (chain_id, id, owner, name)
        VALUES (NEW.chain_id, NEW.args->>'clanId', NEW.args->>'clanOwner', 'Unnamed Clan')
        ON CONFLICT (chain_id, id) DO UPDATE
        SET owner = NEW.args->>'clanOwner';
      END IF;

    ELSIF NEW.name = 'ClanDeleted' THEN
      DELETE FROM clans
      WHERE chain_id = NEW.chain_id
        AND id = NEW.args->>'clanId';
    END IF;
  END IF;

  -- MaterialFactory
  IF NEW.contract_address = '0xc78c189C24379857A80635624877E02306de3EE1' THEN
    IF NEW.name = 'MaterialCreated' THEN
      IF EXISTS (SELECT 1 FROM pending_materials WHERE metadata_hash = NEW.args->>'metadataHash') THEN
        INSERT INTO materials (chain_id, address, owner, name, symbol, logo_image_url, logo_thumbnail_url, description)
        SELECT NEW.chain_id, NEW.args->>'materialAddress', NEW.args->>'materialOwner', NEW.args->>'name', NEW.args->>'symbol', pm.logo_image_url, pm.logo_thumbnail_url, pm.description
        FROM pending_materials pm
        WHERE pm.metadata_hash = NEW.args->>'metadataHash'
        ON CONFLICT (chain_id, address) DO UPDATE
        SET owner = NEW.args->>'materialOwner';

        DELETE FROM pending_materials
        WHERE metadata_hash = NEW.args->>'metadataHash';
      ELSE
        INSERT INTO materials (chain_id, address, owner, name, symbol)
        VALUES (NEW.chain_id, NEW.args->>'materialAddress', NEW.args->>'materialOwner', NEW.args->>'name', NEW.args->>'symbol')
        ON CONFLICT (chain_id, address) DO UPDATE
        SET owner = NEW.args->>'materialOwner';
      END IF;

    ELSIF NEW.name = 'MaterialDeleted' THEN
      DELETE FROM materials
      WHERE chain_id = NEW.chain_id
        AND address = NEW.args->>'materialAddress';
    END IF;
  END IF;

  RETURN NEW;
END;$$;

ALTER FUNCTION "public"."handle_contract_event"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "service_role";
