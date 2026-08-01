/*
# Create adjust_credits RPC function

1. Overview
   A SECURITY DEFINER function that atomically adjusts a user's credit
   balance and records a transaction. Edge functions call this to grant
   referral rewards, daily bonuses, or other credit adjustments without
   exposing the user_credits table to direct client writes.

2. New Function
   - `adjust_credits(p_user_id, p_amount, p_type, p_description)`
   - Atomically updates user_credits.balance and inserts a
     credit_transactions row in a single operation.
   - Creates the user_credits row if it doesn't exist yet.

3. Security
   - SECURITY DEFINER so edge functions (service role) can call it.
   - No client-side access needed — only edge functions call this.
*/

CREATE OR REPLACE FUNCTION adjust_credits(
  p_user_id uuid,
  p_amount int,
  p_type text,
  p_description text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Ensure the user has a credit account.
  INSERT INTO user_credits (user_id, balance, total_granted, total_consumed)
  VALUES (p_user_id, 0, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;

  -- Update balance and totals atomically.
  UPDATE user_credits
  SET
    balance = balance + p_amount,
    total_granted = total_granted + CASE WHEN p_amount > 0 THEN p_amount ELSE 0 END,
    total_consumed = total_consumed + CASE WHEN p_amount < 0 THEN ABS(p_amount) ELSE 0 END,
    updated_at = now()
  WHERE user_id = p_user_id;

  -- Record the transaction.
  INSERT INTO credit_transactions (user_id, amount, type, description)
  VALUES (p_user_id, p_amount, p_type, p_description);
END;
$$;
