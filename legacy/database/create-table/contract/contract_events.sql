CREATE TABLE IF NOT EXISTS "public"."contract_events" (
  "contract_address" text NOT NULL,
  "block_number" bigint NOT NULL,
  "log_index" bigint NOT NULL,
  "transaction_hash" text NOT NULL,
  "name" text NOT NULL,
  "args" "jsonb" NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."contract_events" OWNER TO "postgres";

ALTER TABLE ONLY "public"."contract_events"
  ADD CONSTRAINT "contract_events_pkey" PRIMARY KEY ("contract_address", "block_number", "log_index");

ALTER TABLE "public"."contract_events" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."contract_events" TO "anon";
GRANT ALL ON TABLE "public"."contract_events" TO "authenticated";
GRANT ALL ON TABLE "public"."contract_events" TO "service_role";

CREATE TRIGGER "handle_contract_event" AFTER INSERT ON "public"."contract_events" FOR EACH ROW EXECUTE FUNCTION "public"."handle_contract_event"();
