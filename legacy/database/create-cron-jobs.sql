select cron.schedule(
  'track-persona-fragments-events',
  '*/10 * * * *',
  $$
  select net.http_post(
      'https://vykzkqqncxcfzflpkcsr.supabase.co/functions/v1/process-contract-events',
      body := '{"chainId":84532,"contract":"PersonaFragments"}'::JSONB,
      headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5a3prcXFuY3hjZnpmbHBrY3NyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk0MDc0OTUsImV4cCI6MjA0NDk4MzQ5NX0.UEGqZvIJ_FPxBk41C0RG4HfHahtR0yUfYVmtiZf61i0"}'::JSONB
  ) AS request_id;
  $$
);

select cron.schedule(
  'track-clan-emblems-events',
  '1,11,21,31,41,51 * * * *',
  $$
  select net.http_post(
      'https://vykzkqqncxcfzflpkcsr.supabase.co/functions/v1/process-contract-events',
      body := '{"chainId":84532,"contract":"ClanEmblems"}'::JSONB,
      headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5a3prcXFuY3hjZnpmbHBrY3NyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk0MDc0OTUsImV4cCI6MjA0NDk4MzQ5NX0.UEGqZvIJ_FPxBk41C0RG4HfHahtR0yUfYVmtiZf61i0"}'::JSONB
  ) AS request_id;
  $$
);

select cron.schedule(
  'track-topic-shares-events',
  '2,12,22,32,42,52 * * * *',
  $$
  select net.http_post(
      'https://vykzkqqncxcfzflpkcsr.supabase.co/functions/v1/process-contract-events',
      body := '{"chainId":84532,"contract":"TopicShares"}'::JSONB,
      headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5a3prcXFuY3hjZnpmbHBrY3NyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk0MDc0OTUsImV4cCI6MjA0NDk4MzQ5NX0.UEGqZvIJ_FPxBk41C0RG4HfHahtR0yUfYVmtiZf61i0"}'::JSONB
  ) AS request_id;
  $$
);

select cron.schedule(
  'track-material-factory-events',
  '3,13,23,33,43,53 * * * *',
  $$
  select net.http_post(
      'https://vykzkqqncxcfzflpkcsr.supabase.co/functions/v1/process-contract-events',
      body := '{"chainId":84532,"contract":"MaterialFactory"}'::JSONB,
      headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5a3prcXFuY3hjZnpmbHBrY3NyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk0MDc0OTUsImV4cCI6MjA0NDk4MzQ5NX0.UEGqZvIJ_FPxBk41C0RG4HfHahtR0yUfYVmtiZf61i0"}'::JSONB
  ) AS request_id;
  $$
);
