CREATE OR REPLACE FUNCTION "public"."handle_contract_event"() RETURNS "trigger"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$BEGIN
  -- ClanEmblems
  IF NEW.contract_address = '0x9322C4A5E5725262C9960aDE87259d1cE2812412' THEN
    IF NEW.event_name = 'ClanCreated' THEN
      INSERT INTO clans (chain_id, id, owner, name, logo_image_url, logo_thumbnail_url, description, created_at)
      SELECT NEW.chain_id, NEW.event_arguments[1]::bigint, NEW.event_arguments[0], pc.name, pc.logo_image_url, pc.logo_thumbnail_url, pc.description, NOW()
      FROM pending_clans pc
      WHERE pc.metadata_hash = NEW.event_arguments[2];

      DELETE FROM pending_clans
      WHERE metadata_hash = NEW.event_arguments[2];
    END IF;
  END IF;

  -- MaterialFactory
  IF NEW.contract_address = '0xc78c189C24379857A80635624877E02306de3EE1' THEN
    IF NEW.event_name = 'MaterialCreated' THEN
      INSERT INTO materials (chain_id, address, owner, name, symbol, logo_image_url, logo_thumbnail_url, description, created_at)
      SELECT NEW.chain_id, NEW.contract_address, NEW.event_arguments[0], pm.name, pm.symbol, pm.logo_image_url, pm.logo_thumbnail_url, pm.description, NOW()
      FROM pending_materials pm
      WHERE pm.metadata_hash = NEW.event_arguments[2];

      DELETE FROM pending_materials
      WHERE metadata_hash = NEW.event_arguments[2];
    END IF;
  END IF;

  RETURN NEW;
END;$$;

ALTER FUNCTION "public"."handle_contract_event"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_contract_event"() TO "service_role";
