CREATE OR REPLACE FUNCTION "public"."parse_material_trade_contract_event"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    IF new.contract = 'MaterialTrade' THEN
        IF new.event = 'MaterialCreated' THEN
            insert into materials (
                chain,
                owner,
                address,
                name,
                symbol
            ) values (
                new.chain,
                new.args[1],
                new.args[2],
                new.args[3],
                new.args[4]
            );
        END IF;
        IF new.event = 'Trade' THEN
            update materials set
                supply = new.args[8]::numeric
            where
                chain = new.chain and
                address = new.args[2];
        END IF;
    END IF;
    RETURN NULL;
end;$$;

ALTER FUNCTION "public"."parse_material_trade_contract_event"() OWNER TO "postgres";

GRANT ALL ON FUNCTION "public"."parse_material_trade_contract_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."parse_material_trade_contract_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."parse_material_trade_contract_event"() TO "service_role";

CREATE TRIGGER "parse_contract_event" AFTER INSERT ON "public"."contract_events" FOR EACH ROW EXECUTE FUNCTION "public"."parse_material_trade_contract_event"();
