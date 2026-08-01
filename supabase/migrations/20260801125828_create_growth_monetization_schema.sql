/*
# Create Growth & Monetization Schema

1. Overview
   This migration adds the infrastructure for the app's viral growth engine
   and self-contained monetization system. It introduces four new tables:

   - `user_credits` — tracks each user's AI token balance and subscription tier.
   - `credit_transactions` — an immutable ledger of every credit
     grant/deduction so users can audit their balance history.
   - `referrals` — the referral graph: who referred whom, reward status.
   - `referral_codes` — unique shareable codes per user for the viral loop.

   The app authenticates via Supabase auth (edge functions create real
   auth.users rows and return the access token), so RLS uses `auth.uid()`.

2. New Tables

   ### user_credits
   - `user_id` uuid PK, references app_users(id) ON DELETE CASCADE
   - `balance` int NOT NULL DEFAULT 10  (free tier starting balance)
   - `total_granted` int NOT NULL DEFAULT 10 (lifetime credits received)
   - `total_consumed` int NOT NULL DEFAULT 0 (lifetime credits spent)
   - `subscription_tier` text NOT NULL DEFAULT 'free' (free|starter|pro|studio)
   - `subscription_status` text NOT NULL DEFAULT 'active'
   - `subscription_renews_at` timestamptz (null for free tier)
   - `monthly_credits_granted` int NOT NULL DEFAULT 0 (credits granted this cycle)
   - `updated_at` timestamptz NOT NULL DEFAULT now()

   ### credit_transactions
   - `id` uuid PK default gen_random_uuid()
   - `user_id` uuid NOT NULL DEFAULT auth.uid(), references app_users
   - `amount` int NOT NULL (positive = grant, negative = deduction)
   - `type` text NOT NULL (signup_bonus|referral_reward|subscription_grant|
     generation_cost|admin_adjustment|daily_bonus)
   - `description` text
   - `referral_id` uuid (nullable, links to referrals table for referral rewards)
   - `created_at` timestamptz NOT NULL DEFAULT now()

   ### referral_codes
   - `user_id` uuid PK, references app_users(id) ON DELETE CASCADE
   - `code` text UNIQUE NOT NULL (8-char alphanumeric, generated server-side)
   - `created_at` timestamptz NOT NULL DEFAULT now()

   ### referrals
   - `id` uuid PK default gen_random_uuid()
   - `referrer_id` uuid NOT NULL, references app_users(id) ON DELETE CASCADE
   - `referred_id` uuid NOT NULL, references app_users(id) ON DELETE CASCADE
   - `code` text NOT NULL (the code that was used)
   - `status` text NOT NULL DEFAULT 'completed' (completed|rewarded)
   - `referrer_rewarded` boolean NOT NULL DEFAULT false
   - `referred_rewarded` boolean NOT NULL DEFAULT false
   - `created_at` timestamptz NOT NULL DEFAULT now()

3. Indexes
   - credit_transactions(user_id, created_at) for history queries
   - referrals(referrer_id) for "who did I invite" queries
   - referrals(referred_id) for dedup checks

4. Security
   - RLS enabled on all four tables.
   - user_credits: owner can SELECT and UPDATE own row. INSERT is done
     via edge function (service role), so no client INSERT policy.
   - credit_transactions: owner can SELECT own ledger. INSERT/UPDATE/
     DELETE restricted to service role (edge functions) — no client
     write policies.
   - referral_codes: owner can SELECT own code. INSERT via edge function.
   - referrals: referrer can SELECT their own referral rows.

5. Notes
   - `user_id` columns default to `auth.uid()` where the client may insert.
   - Credit mutations (balance changes, transaction inserts) are performed
     by edge functions using the service role key, which bypasses RLS.
     The client only reads its own data.
   - The starting balance of 10 credits gives new users enough to
     experience the product before hitting the paywall.
   - Idempotent: safe to re-run (IF NOT EXISTS, DROP POLICY IF EXISTS).
*/

-- ── user_credits ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_credits (
  user_id uuid PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
  balance int NOT NULL DEFAULT 10,
  total_granted int NOT NULL DEFAULT 10,
  total_consumed int NOT NULL DEFAULT 0,
  subscription_tier text NOT NULL DEFAULT 'free',
  subscription_status text NOT NULL DEFAULT 'active',
  subscription_renews_at timestamptz,
  monthly_credits_granted int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_credits" ON user_credits;
CREATE POLICY "select_own_credits" ON user_credits FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "update_own_credits" ON user_credits;
CREATE POLICY "update_own_credits" ON user_credits FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ── credit_transactions ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS credit_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES app_users(id) ON DELETE CASCADE,
  amount int NOT NULL,
  type text NOT NULL,
  description text,
  referral_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_transactions" ON credit_transactions;
CREATE POLICY "select_own_transactions" ON credit_transactions FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS credit_transactions_user_created_idx
  ON credit_transactions(user_id, created_at);

-- ── referral_codes ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS referral_codes (
  user_id uuid PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
  code text UNIQUE NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_referral_code" ON referral_codes;
CREATE POLICY "select_own_referral_code" ON referral_codes FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

-- ── referrals ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  referred_id uuid NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  code text NOT NULL,
  status text NOT NULL DEFAULT 'completed',
  referrer_rewarded boolean NOT NULL DEFAULT false,
  referred_rewarded boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_referrals" ON referrals;
CREATE POLICY "select_own_referrals" ON referrals FOR SELECT
  TO authenticated USING (auth.uid() = referrer_id);

CREATE INDEX IF NOT EXISTS referrals_referrer_idx ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS referrals_referred_idx ON referrals(referred_id);
