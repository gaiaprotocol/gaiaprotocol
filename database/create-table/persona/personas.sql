CREATE TABLE IF NOT EXISTS "public"."personas" (
  "wallet_address" "text" NOT NULL,
  "name" "text",
  "is_ens_name" boolean,
  "is_basename" boolean,
  "is_gaia_name" boolean,
  "profile_image_url" "text",
  "profile_thumbnail_url" "text",
  "profile_nft_address" "text",
  "profile_nft_token_id" numeric,
  "bio" "text",
  "last_post_id" bigint DEFAULT 0 NOT NULL,
  "last_chet_message_id" bigint DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
  "updated_at" timestamp with time zone
);

ALTER TABLE "public"."personas" OWNER TO "postgres";

ALTER TABLE ONLY "public"."personas"
  ADD CONSTRAINT "personas_pkey" PRIMARY KEY ("wallet_address");

ALTER TABLE "public"."personas" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."personas" TO "anon";
GRANT ALL ON TABLE "public"."personas" TO "authenticated";
GRANT ALL ON TABLE "public"."personas" TO "service_role";

CREATE POLICY "Allow read access for all users" ON "public"."personas" FOR SELECT USING (true);

CREATE TRIGGER "set_updated_at" BEFORE UPDATE ON "public"."personas" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();
