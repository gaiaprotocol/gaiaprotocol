CREATE TABLE IF NOT EXISTS "public"."persona_holder_chat_messages" (
  "id" bigint NOT NULL,
  "author" "text" NOT NULL,
  "content" "text",
  "rich" "jsonb",
  "reactions" "jsonb"[],
  "ip_address" "inet" NOT NULL,
  "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
  "edited_at" timestamp with time zone
);

ALTER TABLE "public"."persona_holder_chat_messages" OWNER TO "postgres";

ALTER TABLE ONLY "public"."persona_holder_chat_messages"
    ADD CONSTRAINT "persona_holder_chat_messages_pkey" PRIMARY KEY ("id");

ALTER TABLE "public"."persona_holder_chat_messages" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."persona_holder_chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."persona_holder_chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."persona_holder_chat_messages" TO "service_role";

CREATE OR REPLACE FUNCTION "public"."trigger_before_persona_holder_chat_messages_insert"() RETURNS "trigger"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$
DECLARE
  v_new_id INT;
BEGIN
  UPDATE public.personas
  SET last_chet_message_id = last_chet_message_id + 1
  WHERE wallet_address = NEW.author
  RETURNING last_chet_message_id INTO v_new_id;

  NEW.id = v_new_id;
  RETURN NEW;
END;$$;

ALTER FUNCTION "public"."trigger_before_persona_holder_chat_messages_insert"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."trigger_before_persona_holder_chat_messages_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_before_persona_holder_chat_messages_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_before_persona_holder_chat_messages_insert"() TO "service_role";

CREATE TRIGGER "trigger_before_persona_holder_chat_messages_insert" BEFORE INSERT ON "public"."persona_holder_chat_messages" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_before_persona_holder_chat_messages_insert"();

CREATE POLICY "Allow read access for all users" ON public.persona_holder_chat_messages FOR SELECT USING (true);

CREATE POLICY "Allow update for message author" ON public.persona_holder_chat_messages FOR UPDATE
USING (author = ("auth"."jwt"() ->> 'wallet_address'::text))
WITH CHECK (
  ("content" IS NOT NULL AND "content" != '' AND length("content") <= 4096)
  OR
  ("content" IS NULL AND "rich" IS NOT NULL)
);

CREATE POLICY "Allow delete for message author" ON public.persona_holder_chat_messages FOR DELETE
USING (author = ("auth"."jwt"() ->> 'wallet_address'::text));
