CREATE TABLE IF NOT EXISTS "public"."topics" (
  "topic" text NOT NULL,
  "logo_image_url" text,
  "logo_thumbnail_url" text,
  "description" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone
);

ALTER TABLE "public"."topics" OWNER TO "postgres";

ALTER TABLE ONLY "public"."topics"
  ADD CONSTRAINT "topics_pkey" PRIMARY KEY ("topic");

ALTER TABLE "public"."topics" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."topics" TO "anon";
GRANT ALL ON TABLE "public"."topics" TO "authenticated";
GRANT ALL ON TABLE "public"."topics" TO "service_role";

CREATE POLICY "Allow read access for all users" ON "public"."topics" FOR SELECT USING (true);

CREATE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."topics" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
