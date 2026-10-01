-- Keep credit balances server-managed. Requires service_role for grants.
DROP POLICY IF EXISTS "update_own_credits" ON public.user_credits;
REVOKE INSERT, UPDATE, DELETE ON public.user_credits FROM anon, authenticated;
REVOKE ALL ON FUNCTION public.adjust_credits(uuid, int, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.adjust_credits(uuid, int, text, text) TO service_role;
