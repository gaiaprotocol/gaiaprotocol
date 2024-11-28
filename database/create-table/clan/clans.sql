CREATE TABLE IF NOT EXISTS "public"."clans" (
  "chain_id" bigint NOT NULL,
  "id" bigint NOT NULL,
  "owner" text NOT NULL,
  "name" text NOT NULL,
  "logo_image_url" text,
  "logo_thumbnail_url" text,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone
);

ALTER TABLE "public"."clans" OWNER TO "postgres";

ALTER TABLE ONLY "public"."clans"
  ADD CONSTRAINT "clans_pkey" PRIMARY KEY ("chain_id", "id");

ALTER TABLE "public"."clans" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."clans" TO "anon";
GRANT ALL ON TABLE "public"."clans" TO "authenticated";
GRANT ALL ON TABLE "public"."clans" TO "service_role";

CREATE POLICY "Allow read access for all users" ON "public"."clans" FOR SELECT USING (true);

CREATE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."clans" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
