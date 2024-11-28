CREATE TABLE IF NOT EXISTS "public"."pending_materials" (
  "metadata_hash" "uuid" "gen_random_uuid"() NOT NULL,
  "author" text NOT NULL,
  "logo_image_url" text,
  "logo_thumbnail_url" text,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."pending_materials" OWNER TO "postgres";

ALTER TABLE ONLY "public"."pending_materials"
  ADD CONSTRAINT "pending_materials_pkey" PRIMARY KEY ("id");

ALTER TABLE "public"."pending_materials" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."pending_materials" TO "anon";
GRANT ALL ON TABLE "public"."pending_materials" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_materials" TO "service_role";
