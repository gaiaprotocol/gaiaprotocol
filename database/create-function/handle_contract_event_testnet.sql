CREATE OR REPLACE FUNCTION "public"."handle_contract_event"() RETURNS "trigger"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$
BEGIN
  -- ClanEmblems
  IF NEW.contract_address = '0x9322C4A5E5725262C9960aDE87259d1cE2812412' THEN
    IF NEW.name = 'ClanCreated' THEN
      IF EXISTS (SELECT 1 FROM pending_clans WHERE metadata_hash = NEW.args->>'metadataHash') THEN
        INSERT INTO clans (id, owner, name, logo_image_url, logo_thumbnail_url, description)
        SELECT NEW.args->>'clanId', NEW.args->>'clanOwner', pc.name, pc.logo_image_url, pc.logo_thumbnail_url, pc.description
        FROM pending_clans pc
        WHERE pc.metadata_hash = NEW.args->>'metadataHash'
        ON CONFLICT (id) DO UPDATE
        SET owner = NEW.args->>'clanOwner', deleted_at = NULL;

        DELETE FROM pending_clans
        WHERE metadata_hash = NEW.args->>'metadataHash';
      ELSE
        INSERT INTO clans (id, owner, name)
        VALUES (NEW.args->>'clanId', NEW.args->>'clanOwner', 'Unnamed Clan')
        ON CONFLICT (id) DO UPDATE
        SET owner = NEW.args->>'clanOwner', deleted_at = NULL;
      END IF;

    ELSIF NEW.name = 'ClanDeleted' THEN
      UPDATE clans 
      SET deleted_at = NOW()
      WHERE id = NEW.args->>'clanId'
        AND deleted_at IS NULL;
    END IF;
  END IF;

  -- MaterialFactory
  IF NEW.contract_address = '0xc78c189C24379857A80635624877E02306de3EE1' THEN
    IF NEW.name = 'MaterialCreated' THEN
      IF EXISTS (SELECT 1 FROM pending_materials WHERE metadata_hash = NEW.args->>'metadataHash') THEN
        INSERT INTO materials (address, game_id, owner, name, symbol, logo_image_url, logo_thumbnail_url, description)
        SELECT NEW.args->>'materialAddress', NEW.args->>'materialOwner', NEW.args->>'name', NEW.args->>'symbol', pm.game_id, pm.logo_image_url, pm.logo_thumbnail_url, pm.description
        FROM pending_materials pm
        WHERE pm.metadata_hash = NEW.args->>'metadataHash'
        ON CONFLICT (address) DO UPDATE
        SET owner = NEW.args->>'materialOwner', deleted_at = NULL;

        DELETE FROM pending_materials
        WHERE metadata_hash = NEW.args->>'metadataHash';
      ELSE
        INSERT INTO materials (address, owner, name, symbol)
        VALUES (NEW.args->>'materialAddress', NEW.args->>'materialOwner', NEW.args->>'name', NEW.args->>'symbol')
        ON CONFLICT (address) DO UPDATE
        SET owner = NEW.args->>'materialOwner', deleted_at = NULL;
      END IF;

    ELSIF NEW.name = 'MaterialDeleted' THEN
      UPDATE materials
      SET deleted_at = NOW()
      WHERE address = NEW.args->>'materialAddress'
        AND deleted_at IS NULL;
    END IF;
  END IF;

  RETURN NEW;
END;$$;

ALTER FUNCTION "public"."handle_contract_event"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "service_role";
