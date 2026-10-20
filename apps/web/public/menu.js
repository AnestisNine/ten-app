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

const links = new Map([...document.querySelectorAll('.nav a[data-section]')].map((a) => [a.dataset.section, a]));
const sections = [...links.keys()].map((id) => document.getElementById(id)).filter(Boolean);
if (sections.length && 'IntersectionObserver' in window) {
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        for (const a of links.values()) a.classList.remove('active');
        links.get(entry.target.id)?.classList.add('active');
      }
    },
    { rootMargin: '-45% 0px -50% 0px' },
  );
  sections.forEach((s) => observer.observe(s));
}
