// Mobile menu + highlight of the section in view (separate file so the CSP can forbid inline scripts).
const toggle = document.querySelector('.menu-toggle');
const nav = document.getElementById('site-nav');
if (toggle && nav) {
  toggle.addEventListener('click', () => {
    const open = nav.classList.toggle('open');
    toggle.setAttribute('aria-expanded', String(open));
  });
  // Close the mobile menu after choosing a section.
  nav.addEventListener('click', (e) => {
    if (e.target.closest('a[data-section]')) {
      nav.classList.remove('open');
      toggle.setAttribute('aria-expanded', 'false');
    }
  });
}

// Highlight the menu item of the section currently under the sticky menu.
const links = new Map([...document.querySelectorAll('.nav a[data-section]')].map((a) => [a.dataset.section, a]));
const sections = [...links.keys()].map((id) => document.getElementById(id)).filter(Boolean);
let ticking = false;
function updateActive() {
  ticking = false;
  const line = (document.querySelector('.site-header')?.getBoundingClientRect().bottom ?? 0) + 24;
  let current = sections[0];
  for (const section of sections) if (section.getBoundingClientRect().top <= line) current = section;
  // At the very bottom, the last section is the one being read.
  if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) current = sections[sections.length - 1];
  for (const [id, a] of links) a.classList.toggle('active', current?.id === id);
}
if (sections.length) {
  addEventListener('scroll', () => {
    if (!ticking) {
      ticking = true;
      requestAnimationFrame(updateActive);
    }
  }, { passive: true });
  updateActive();
}
