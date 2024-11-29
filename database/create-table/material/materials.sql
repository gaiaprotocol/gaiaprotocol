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

CREATE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."materials" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
