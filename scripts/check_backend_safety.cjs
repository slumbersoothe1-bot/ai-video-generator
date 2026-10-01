const fs = require('node:fs');
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const read = f => fs.readFileSync(path.join(root, f), 'utf8');
for (const file of ['videos-generate', 'assistant']) {
  const code = read(`supabase/functions/${file}/index.ts`);
  const tokenLine = code.split('\n').find(l => l.includes('replace(/^Bearer'));
  const expression = tokenLine.trim().slice('const token = '.length).replace(/;$/, '');
  const actual = new Function('authHeader', 'req', `return ${expression}`)('Bearer TEST_TOKEN', {headers: new Headers({Authorization:'Bearer TEST_TOKEN'})});
  assert.equal(actual, 'TEST_TOKEN', `${file}: Bearer parser`);
  assert(code.includes('ENABLE_EXTERNAL_AI'), `${file}: no-cost guard`);
}
const video = read('supabase/functions/videos-generate/index.ts');
assert(video.indexOf('generation_disabled') < video.indexOf('balance - 1'), 'guard precedes credit deduction');
assert(video.includes('External AI is disabled'), 'guard protects polling existing jobs');
const billing = read('supabase/functions/billing/index.ts');
assert(billing.includes('payments_not_configured'));
assert(!billing.includes('newBalance') && !billing.includes('.upsert('), 'no simulated paid grants');
const sql = read('supabase/migrations/20261001150000_lock_credit_writes.sql');
assert(sql.includes('DROP POLICY IF EXISTS "update_own_credits"'));
assert(sql.includes('FROM PUBLIC, anon, authenticated'));
assert(sql.includes('TO service_role'));
console.log('Backend safety source checks passed. No network calls or credits used.');
