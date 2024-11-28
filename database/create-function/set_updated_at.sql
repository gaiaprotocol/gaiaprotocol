CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
LANGUAGE "plpgsql" SECURITY DEFINER
AS $$BEGIN
  new.updated_at := now();
  RETURN new;
END;$$;

ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";
