CREATE TABLE IF NOT EXISTS "public"."materials" (
    "chain" "text" NOT NULL,
    "address" "text" NOT NULL,
    "owner" "text" NOT NULL,
    "name" "text" NOT NULL,
    "symbol" "text" NOT NULL,
    "supply" numeric DEFAULT '0'::numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone
);

ALTER TABLE "public"."materials" OWNER TO "postgres";

ALTER TABLE ONLY "public"."materials"
    ADD CONSTRAINT "materials_pkey" PRIMARY KEY ("chain", "address");

ALTER TABLE "public"."materials" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."materials" TO "anon";
GRANT ALL ON TABLE "public"."materials" TO "authenticated";
GRANT ALL ON TABLE "public"."materials" TO "service_role";

CREATE POLICY "view everyone" ON "public"."materials" FOR SELECT USING (true);
