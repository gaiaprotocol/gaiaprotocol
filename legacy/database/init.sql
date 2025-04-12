SET default_tablespace = '';
SET default_table_access_method = "heap";

CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";
