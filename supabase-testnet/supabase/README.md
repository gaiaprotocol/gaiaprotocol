## Deploy Edge Function

```
supabase secrets set --env-file ./supabase/.env

supabase functions deploy generate-wallet-login-nonce
supabase functions deploy wallet-login
supabase functions deploy verify-wallet-login-token

supabase functions deploy upload-profile-image
supabase functions deploy get-user-nfts
supabase functions deploy get-user-ens-name
supabase functions deploy get-user-basename

supabase functions deploy process-contract-events

supabase functions deploy save-persona
supabase functions deploy reload-persona-name
supabase functions deploy write-persona-post

supabase functions deploy upload-clan-logo
supabase functions deploy create-pending-clan-data

supabase functions deploy upload-game-thumbnail
supabase functions deploy upload-game-screenshot

supabase functions deploy upload-material-logo
supabase functions deploy create-pending-material-data
supabase functions deploy sync-material-metadata-to-db
supabase functions deploy add-material-to-game

supabase functions deploy upload-user-image
```

## Postgres Cron

```sql
select * from cron.job;
select * from cron.job_run_details;

SELECT cron.unschedule(1);
```
