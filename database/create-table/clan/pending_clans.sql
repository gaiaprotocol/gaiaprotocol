CREATE TABLE IF NOT EXISTS "public"."pending_clans" (
  "metadata_hash" text DEFAULT "generate_metadata_hash"() NOT NULL,
  "name" text NOT NULL,
  "logo_image_url" text,
  "logo_thumbnail_url" text,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."pending_clans" OWNER TO "postgres";

ALTER TABLE ONLY "public"."pending_clans"
  ADD CONSTRAINT "pending_clans_pkey" PRIMARY KEY ("metadata_hash");

ALTER TABLE "public"."pending_clans" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."pending_clans" TO "anon";
GRANT ALL ON TABLE "public"."pending_clans" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_clans" TO "service_role";
