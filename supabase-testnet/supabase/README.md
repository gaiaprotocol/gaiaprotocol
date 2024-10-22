## Deploy Edge Function

```
supabase secrets set --env-file ./supabase/.env

supabase functions deploy generate-wallet-login-nonce
supabase functions deploy wallet-login
supabase functions deploy verify-wallet-login-token
```
