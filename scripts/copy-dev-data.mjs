#!/usr/bin/env node
// One-off: copy Firestore documents (incl. subcollections) and Auth users
// (UIDs + password hashes preserved) from the old nelsongrey-sprout-dev
// project to balance-forward-dev. Reads the source only.
//
// Usage:  node scripts/copy-dev-data.mjs           # dry run, counts only
//         node scripts/copy-dev-data.mjs --apply   # actually write
// Needs `gcloud auth login` as an owner of both projects.
import { execSync } from 'node:child_process';

const SRC = 'nelsongrey-sprout-dev';
const DST = 'balance-forward-dev';
const DRY = process.argv[2] !== '--apply';
const T = execSync('gcloud auth print-access-token').toString().trim();

const hdr = (p) => ({
  Authorization: `Bearer ${T}`,
  'x-goog-user-project': p,
  'Content-Type': 'application/json',
});
const fs = (p) => `https://firestore.googleapis.com/v1/projects/${p}/databases/(default)/documents`;

async function j(url, opt) {
  const r = await fetch(url, opt);
  const t = await r.text();
  if (!r.ok) throw new Error(`${r.status} ${url} ${t.slice(0, 300)}`);
  return t ? JSON.parse(t) : {};
}

let docs = 0;
let written = 0;

async function walk(parentPath) {
  const ids =
    (await j(`${fs(SRC)}/${parentPath}:listCollectionIds`, { method: 'POST', headers: hdr(SRC), body: '{}' }))
      .collectionIds || [];
  for (const cid of ids) {
    let page = '';
    do {
      const r = await j(`${fs(SRC)}/${parentPath ? parentPath + '/' : ''}${cid}?pageSize=300${page}`, {
        headers: hdr(SRC),
      });
      for (const d of r.documents || []) {
        docs++;
        const rel = d.name.split('/documents/')[1];
        // Rewrite document references that embed the source project id.
        const body = JSON.stringify({ fields: d.fields || {} }).replaceAll(`projects/${SRC}/`, `projects/${DST}/`);
        if (!DRY) {
          await j(`${fs(DST)}/${rel.split('/').map(encodeURIComponent).join('/')}`, {
            method: 'PATCH',
            headers: hdr(DST),
            body,
          });
          written++;
        }
        await walk(rel);
      }
      page = r.nextPageToken ? `&pageToken=${encodeURIComponent(r.nextPageToken)}` : '';
    } while (page);
  }
}

await walk('');
console.log(`firestore docs found=${docs} written=${written}`);

const cfg = await j(`https://identitytoolkit.googleapis.com/admin/v2/projects/${SRC}/config`, {
  headers: hdr(SRC),
});
const hc = cfg.signIn.hashConfig;
const users =
  (await j(`https://identitytoolkit.googleapis.com/v1/projects/${SRC}/accounts:batchGet?maxResults=1000`, {
    headers: hdr(SRC),
  })).users || [];
console.log(`auth users found=${users.length}`);

if (!DRY && users.length) {
  // Only import users the destination doesn't have yet, so re-running is safe.
  const have = new Set(
    (
      (await j(`https://identitytoolkit.googleapis.com/v1/projects/${DST}/accounts:batchGet?maxResults=1000`, {
        headers: hdr(DST),
      })).users || []
    ).map((u) => u.localId),
  );
  const missing = users.filter((u) => !have.has(u.localId));
  console.log(`auth users already in destination=${have.size}, to import=${missing.length}`);

  const importUsers = async (list) =>
    j(`https://identitytoolkit.googleapis.com/v1/projects/${DST}/accounts:batchCreate`, {
      method: 'POST',
      headers: hdr(DST),
      body: JSON.stringify({
        users: list,
        hashAlgorithm: 'SCRYPT',
        hashKey: hc.signerKey,
        saltSeparator: hc.saltSeparator,
        rounds: hc.rounds,
        memoryCost: hc.memoryCost,
      }),
    });

  if (missing.length) {
    const r = await importUsers(missing);
    const failed = (r.error || []).map((e) => ({ idx: e.index, msg: e.message }));
    console.log('auth import errors:', JSON.stringify(failed));
    if (failed.length) {
      // Retry failures without linked-provider entries whose federated ID the
      // import API rejects. The user keeps email/password and UID; a social
      // provider re-links by verified email on next sign-in.
      const retry = failed.map(({ idx }) => {
        const u = { ...missing[idx] };
        console.log(`retrying uid=${u.localId} dropping providers:`, (u.providerUserInfo || []).map((x) => x.providerId));
        delete u.providerUserInfo;
        return u;
      });
      const r2 = await importUsers(retry);
      console.log('retry result', JSON.stringify(r2));
    }
  }
}
