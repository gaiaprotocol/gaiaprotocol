CREATE TABLE IF NOT EXISTS "public"."contract_event_sync_status" (
  "contract_address" text NOT NULL,
  "last_synced_block_number" bigint NOT NULL,
  "last_synced_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE "public"."contract_event_sync_status" OWNER TO "postgres";

ALTER TABLE ONLY "public"."contract_event_sync_status"
  ADD CONSTRAINT "contract_event_sync_status_pkey" PRIMARY KEY ("contract_address");

ALTER TABLE "public"."contract_event_sync_status" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."contract_event_sync_status" TO "anon";
GRANT ALL ON TABLE "public"."contract_event_sync_status" TO "authenticated";
GRANT ALL ON TABLE "public"."contract_event_sync_status" TO "service_role";
