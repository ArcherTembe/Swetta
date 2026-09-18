# Proof of Life

A static Supabase-backed check-in and memory dashboard for Swetta.

## Supabase setup

1. Open the linked Supabase project.
2. Enable **Email** under **Authentication > Providers**.
3. Run the complete [`supabase_setup.sql`](supabase_setup.sql) script in **SQL Editor**.
4. Confirm the `memories` Storage bucket exists and is public for image display.
5. Open **Authentication > Users** and select **Add user**.
6. Enter the owner email and set the password there. Enable **Auto Confirm User** if that option is shown.
7. Sign in through the website. Do not add passwords to `supabase_setup.sql` or `swetta.html`.

The browser uses only the Supabase publishable key in [`swetta.html`](swetta.html). Never put a `service_role` or secret key in the HTML.

## GitHub Pages

1. Push this folder to a GitHub repository.
2. In **Settings > Pages**, select **Deploy from a branch**.
3. Select the branch and `/ (root)` folder.
4. Open the published site at:

   `https://YOUR-USER.github.io/YOUR-REPOSITORY/swetta.html`

The page filename is `swetta.html`. The existing `index.html` is a separate page and remains unchanged.

## Vercel

Import the repository into Vercel and deploy it as a static project. The included [`vercel.json`](vercel.json) rewrites the root URL to `swetta.html`, so the deployed app opens at:

`https://YOUR-PROJECT.vercel.app/`

No build command or environment variables are required for the current static setup.

## Authentication note

Visitors can read the dashboard, but only `swettadafelizarda.sf@gmail.com` can sign in and change data. The owner email is enforced again by Supabase RLS policies; the browser check is only a convenience. Never store the password in this repository.
