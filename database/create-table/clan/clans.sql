CREATE TABLE IF NOT EXISTS "public"."clans" (
  "id" bigint NOT NULL,
  "owner" text NOT NULL,
  "name" text NOT NULL,
  "logo_image_url" text,
  "logo_thumbnail_url" text,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone,
  "deleted_at" timestamp with time zone
);

ALTER TABLE "public"."clans" OWNER TO "postgres";

ALTER TABLE ONLY "public"."clans"
  ADD CONSTRAINT "clans_pkey" PRIMARY KEY ("id");

ALTER TABLE "public"."clans" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."clans" TO "anon";
GRANT ALL ON TABLE "public"."clans" TO "authenticated";
GRANT ALL ON TABLE "public"."clans" TO "service_role";

CREATE POLICY "Allow read access for all users" ON "public"."clans" FOR SELECT USING (true);

CREATE POLICY "Allow update for clan owner" ON public.clans FOR UPDATE
USING (
  owner = (auth.jwt() ->> 'wallet_address'::text)
)
WITH CHECK (
  owner IS NULL
  AND (name IS NOT NULL AND name != '' AND name = trim(name) AND LENGTH(name) <= 100)
  AND (description IS NULL OR LENGTH(description) <= 1000)
  AND id IS NULL
  AND created_at IS NULL
  AND updated_at IS NULL
);

CREATE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."clans" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
