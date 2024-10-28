## Deploy Edge Function

```
supabase secrets set --env-file ./supabase/.env

supabase functions deploy generate-wallet-login-nonce
supabase functions deploy wallet-login
supabase functions deploy verify-wallet-login-token
supabase functions deploy get-user-nfts
supabase functions deploy get-user-ens-names
supabase functions deploy get-user-basenames
supabase functions deploy get-user-gaia-names
```
