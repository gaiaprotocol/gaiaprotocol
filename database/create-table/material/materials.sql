CREATE TABLE IF NOT EXISTS "public"."materials" (
  "address" text NOT NULL,
  "game_id" bigint,
  "owner" text NOT NULL,
  "name" text NOT NULL,
  "symbol" text NOT NULL,
  "logo_image_url" text,
  "logo_thumbnail_url" text,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone,
  "deleted_at" timestamp with time zone
);

ALTER TABLE "public"."materials" OWNER TO "postgres";

ALTER TABLE ONLY "public"."materials"
  ADD CONSTRAINT "materials_pkey" PRIMARY KEY ("address");

ALTER TABLE "public"."materials" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."materials" TO "anon";
GRANT ALL ON TABLE "public"."materials" TO "authenticated";
GRANT ALL ON TABLE "public"."materials" TO "service_role";

CREATE INDEX ON "public"."materials" ("game_id");

CREATE POLICY "Allow read access for all users" ON "public"."materials" FOR SELECT USING (true);

CREATE POLICY "Allow update for material owner" ON "public"."materials" FOR UPDATE
USING (
  owner = (auth.jwt() ->> 'wallet_address'::text)
)
WITH CHECK (
  owner = ("auth"."jwt"() ->> 'wallet_address'::text)
  AND (description IS NULL OR LENGTH(description) <= 1000)
);

CREATE OR REPLACE FUNCTION "public"."trigger_before_material_update"() RETURNS "trigger"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$BEGIN
  -- Prevent updates to address, owner, game_id, name, symbol, created_at, and updated_at
  IF NEW.address IS DISTINCT FROM OLD.address THEN
    NEW.address := OLD.address;
  END IF;

  IF NEW.owner IS DISTINCT FROM OLD.owner THEN
    NEW.owner := OLD.owner;
  END IF;

  IF NEW.game_id IS DISTINCT FROM OLD.game_id THEN
    NEW.game_id := OLD.game_id;
  END IF;

  IF NEW.name IS DISTINCT FROM OLD.name THEN
    NEW.name := OLD.name;
  END IF;

  IF NEW.symbol IS DISTINCT FROM OLD.symbol THEN
    NEW.symbol := OLD.symbol;
  END IF;

  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    NEW.created_at := OLD.created_at;
  END IF;

  IF NEW.updated_at IS DISTINCT FROM OLD.updated_at THEN
    NEW.updated_at := OLD.updated_at;
  END IF;

  -- Automatically set updated_at to current timestamp
  NEW.updated_at := NOW();

  RETURN NEW;
END;$$;

ALTER FUNCTION "public"."trigger_before_material_update"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."trigger_before_material_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_before_material_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_before_material_update"() TO "service_role";

CREATE TRIGGER "trigger_before_material_update" BEFORE UPDATE ON "public"."materials" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_before_material_update"();
