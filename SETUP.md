# SkillBridge auth: Supabase setup

The published preview runs in **demo mode** (browser-only accounts, simulated email links). It cannot reach Supabase from inside the preview sandbox, so the Supabase path is written but untested here.

1. Create a project at supabase.com. Copy Project URL and the **anon** public key (Settings > API). Never put the service_role key in frontend code.
2. SQL Editor: run `supabase_schema.sql`.
3. Authentication > Providers > Email: enable it and turn **Confirm email** ON. Set minimum password length to 8 and require upper/lower case plus digits.
4. Authentication > URL Configuration: set Site URL to your deployed URL (for example https://skillbridge.vercel.app) and add the same URL, plus http://localhost:5173, to Redirect URLs. Verification and reset links return there (PKCE flow, `?code=`).
5. Authentication > Email Templates: keep the default Confirm signup and Reset password templates, or customise them. Supabase's built-in mailer is rate-limited; configure custom SMTP (Resend, Brevo) for real use.
6. Put the URL and anon key in the app: in `skillbridge.html` set `CFG={url:"...",key:"..."}`. In a Vite port use `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `.env` and in Vercel > Project Settings > Environment Variables.
7. Deploy (Vercel or any static host). Test: sign up, open the email link, finish onboarding, log out, log in, refresh, reset password.
8. Optional: restrict sign-ups to college domains with a `before insert` trigger on auth.users or an Auth Hook.

Known gaps: doubts, sessions, notifications and karma are still stored in the browser; only accounts and profiles use Supabase. Avatars are stored as a small data URL (96px); use Supabase Storage for larger images.
