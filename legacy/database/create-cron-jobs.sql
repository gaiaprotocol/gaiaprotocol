
select cron.schedule(
  'track-material-trade-contract-events',
  '3,13,23,33,43,53 * * * *',
  $$
  select net.http_post(
      'https://{SUPABASE_REF_ID}.supabase.co/functions/v1/api/contract/track-events',
      body := '{"chain":"{CHAIN}","contract":"MaterialTrade"}'::JSONB,
      headers := '{"Authorization": "Bearer {SUPABASE_ANON_KEY}"}'::JSONB
  ) AS request_id;
  $$
);
