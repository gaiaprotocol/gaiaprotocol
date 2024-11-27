CREATE TABLE IF NOT EXISTS "public"."games" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "owner" "text" DEFAULT ("auth"."jwt"() ->> 'wallet_address'::"text") NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."games" OWNER TO "postgres";

ALTER TABLE ONLY "public"."games"
    ADD CONSTRAINT "games_pkey" PRIMARY KEY ("id");

ALTER TABLE "public"."games" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."games" TO "anon";
GRANT ALL ON TABLE "public"."games" TO "authenticated";
GRANT ALL ON TABLE "public"."games" TO "service_role";

CREATE POLICY "view everyone" ON "public"."games" FOR SELECT USING (true);

CREATE POLICY "can create only authed" ON "public"."games" FOR
    INSERT WITH CHECK (("auth"."jwt"() ->> 'wallet_address' :: "text") = "owner");
