/**
 * Stand-alone page for accepting an invitation / resetting a password. Plain HTML so it works
 * from any email client link, independent of the Flutter app. The script is served as a
 * separate file so the page can use a strict CSP without 'unsafe-inline'.
 */
export const setPasswordHtml = `<!doctype html>
<html lang="el">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<title>TBN Manager · Κωδικός</title>
<link rel="stylesheet" href="/auth/auth.css">
</head>
<body>
<main>
  <h1>TBN MANAGER</h1>
  <form id="f" novalidate>
    <p class="lead">Όρισε τον κωδικό σου · Choose your password</p>
    <label>Κωδικός / Password
      <input id="p1" type="password" autocomplete="new-password" minlength="12" required>
    </label>
    <label>Επανάληψη / Repeat
      <input id="p2" type="password" autocomplete="new-password" minlength="12" required>
    </label>
    <p class="hint">Τουλάχιστον 12 χαρακτήρες · At least 12 characters</p>
    <button type="submit">Αποθήκευση / Save</button>
    <p id="msg" role="status"></p>
  </form>
  <div id="done" hidden>
    <p class="lead">✓ Ο κωδικός ορίστηκε · Password set</p>
    <a class="button" href="/">Σύνδεση / Sign in</a>
  </div>
</main>
<script src="/auth/set-password.js"></script>
</body>
</html>`;

export const setPasswordJs = `(() => {
  const token = new URLSearchParams(location.search).get('token');
  history.replaceState(null, '', location.pathname);
  const f = document.getElementById('f');
  const msg = document.getElementById('msg');
  if (!token) { msg.textContent = 'Μη έγκυρος σύνδεσμος · Invalid link'; f.querySelector('button').disabled = true; return; }
  f.addEventListener('submit', async (e) => {
    e.preventDefault();
    const p1 = document.getElementById('p1').value, p2 = document.getElementById('p2').value;
    if (p1.length < 12) { msg.textContent = 'Τουλάχιστον 12 χαρακτήρες · At least 12 characters'; return; }
    if (p1 !== p2) { msg.textContent = 'Οι κωδικοί δεν ταιριάζουν · Passwords do not match'; return; }
    msg.textContent = '…';
    const r = await fetch('/api/auth/reset-password', {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, credentials: 'same-origin',
      body: JSON.stringify({ token, newPassword: p1 }),
    });
    if (r.ok) { f.hidden = true; document.getElementById('done').hidden = false; }
    else { msg.textContent = 'Ο σύνδεσμος έληξε ή χρησιμοποιήθηκε · Link expired or already used'; }
  });
})();`;

export const authCss = `:root{color-scheme:dark;--bg:#0F1115;--card:#171A21;--text:#ECEEF2;--muted:#9AA3B2;--accent:#E0B062;--border:#2A2F3A}
@media (prefers-color-scheme: light){:root{color-scheme:light;--bg:#F6F1E7;--card:#fff;--text:#1B1D22;--muted:#5D6470;--border:#E3DCCD}}
*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--bg);color:var(--text);font:16px/1.5 system-ui,-apple-system,"Segoe UI",Inter,sans-serif;padding:16px}
main{width:100%;max-width:380px}h1{letter-spacing:4px;font-weight:600;font-size:20px;text-align:center;margin:0 0 24px}
form,#done{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:20px}
label{display:block;font-size:13px;color:var(--muted);margin:12px 0 0}input{width:100%;margin-top:6px;padding:12px;border-radius:10px;border:1px solid var(--border);background:transparent;color:var(--text);font-size:16px}
.lead{margin:0 0 4px;font-weight:600}.hint{font-size:12px;color:var(--muted)}#msg{min-height:1.5em;font-size:14px;color:#E57373}
button,.button{display:block;width:100%;margin-top:16px;padding:14px;border:0;border-radius:12px;background:var(--accent);color:#1B1D22;font-weight:600;font-size:16px;text-align:center;text-decoration:none;cursor:pointer}`;
