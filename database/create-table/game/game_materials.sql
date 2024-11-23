CREATE TABLE IF NOT EXISTS "public"."game_materials" (
    "game" "uuid" NOT NULL,
    "chain" "text" NOT NULL,
    "address" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."game_materials" OWNER TO "postgres";

ALTER TABLE ONLY "public"."game_materials"
    ADD CONSTRAINT "game_materials_pkey" PRIMARY KEY ("game", "chain", "address");

ALTER TABLE ONLY "public"."game_materials"
    ADD CONSTRAINT "game_materials_game_fkey" FOREIGN KEY ("game") REFERENCES "public"."games"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."game_materials"
    ADD CONSTRAINT "game_materials_chain_address_fkey" FOREIGN KEY ("chain", "address") REFERENCES "public"."materials"("chain", "address") ON DELETE CASCADE;

ALTER TABLE "public"."game_materials" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."game_materials" TO "anon";
GRANT ALL ON TABLE "public"."game_materials" TO "authenticated";
GRANT ALL ON TABLE "public"."game_materials" TO "service_role";

CREATE POLICY "view everyone" ON "public"."game_materials" FOR SELECT USING (true);

CREATE POLICY "can create only game owner" ON "public"."game_materials" FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM "public"."games"
        WHERE "games"."id" = "game_materials"."game"
        AND "games"."owner" = ("auth"."jwt"() ->> 'wallet_address'::"text")
    )
);

CREATE POLICY "can update only game owner" ON "public"."game_materials" FOR UPDATE
USING (
    EXISTS (
        SELECT 1
        FROM "public"."games"
        WHERE "games"."id" = "game_materials"."game"
        AND "games"."owner" = ("auth"."jwt"() ->> 'wallet_address'::"text")
    )
);

CREATE POLICY "can delete only game owner" ON "public"."game_materials" FOR DELETE
USING (
    EXISTS (
        SELECT 1
        FROM "public"."games"
        WHERE "games"."id" = "game_materials"."game"
        AND "games"."owner" = ("auth"."jwt"() ->> 'wallet_address'::"text")
    )
);