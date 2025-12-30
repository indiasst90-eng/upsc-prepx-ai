# Secret Rotation Guide

## Rotate A4F API Key

1. Obtain new API key from A4F dashboard
2. Update local `.env.local`:
   ```
   A4F_API_KEY=new_key_here
   ```
3. Update Supabase Secrets:
   ```bash
   supabase secrets set A4F_API_KEY=new_key_here
   ```
4. Verify all services working
5. Revoke old key in A4F dashboard

## Rotate Supabase Keys

1. Generate new keys in Supabase Dashboard → Settings → API
2. Update local `.env.local`
3. Update Vercel environment variables
4. Update Supabase Secrets if using Edge Functions
5. Test authentication flow
6. Revoke old keys

## Rotation Schedule

| Secret | Rotation Frequency |
|--------|-------------------|
| A4F API Key | Every 90 days |
| Supabase Keys | Every 180 days |
| RevenueCat Keys | Every 90 days |

## Emergency Rotation

If a key is compromised:
1. Immediately revoke the compromised key
2. Generate new key
3. Update all environments
4. Test critical flows
5. Document incident
