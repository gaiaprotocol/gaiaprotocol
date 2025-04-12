CREATE TABLE IF NOT EXISTS "public"."persona_posts" (
  "persona_owner" "text" NOT NULL,
  "id" bigint NOT NULL,
  "title" "text" NOT NULL,
  "content" "text" NOT NULL,
  "rich" "jsonb",
  "reactions" "jsonb"[],
  "ip_address" "inet" NOT NULL,
  "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
  "edited_at" timestamp with time zone
);

ALTER TABLE "public"."persona_posts" OWNER TO "postgres";

ALTER TABLE ONLY "public"."persona_posts"
    ADD CONSTRAINT "persona_posts_pkey" PRIMARY KEY ("persona_owner", "id");

ALTER TABLE "public"."persona_posts" ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE "public"."persona_posts" TO "anon";
GRANT ALL ON TABLE "public"."persona_posts" TO "authenticated";
GRANT ALL ON TABLE "public"."persona_posts" TO "service_role";

CREATE OR REPLACE FUNCTION "public"."trigger_before_persona_posts_insert"() RETURNS "trigger"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$
DECLARE
  v_new_id INT;
BEGIN
  UPDATE public.personas
  SET last_post_id = last_post_id + 1
  WHERE wallet_address = NEW.persona_owner
  RETURNING last_post_id INTO v_new_id;

  NEW.id = v_new_id;
  RETURN NEW;
END;$$;

ALTER FUNCTION "public"."trigger_before_persona_posts_insert"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."trigger_before_persona_posts_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_before_persona_posts_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_before_persona_posts_insert"() TO "service_role";

CREATE TRIGGER "trigger_before_persona_posts_insert" BEFORE INSERT ON "public"."persona_posts" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_before_persona_posts_insert"();

CREATE POLICY "Allow read access for all users" ON public.persona_posts FOR SELECT USING (true);

CREATE POLICY "Allow update for post persona owner" ON public.persona_posts FOR UPDATE
USING (persona_owner = ("auth"."jwt"() ->> 'wallet_address'::text))
WITH CHECK (
  length("title") <= 256 AND length("content") <= 40000
);

CREATE POLICY "Allow delete for post persona owner" ON public.persona_posts FOR DELETE
USING (persona_owner = ("auth"."jwt"() ->> 'wallet_address'::text));
