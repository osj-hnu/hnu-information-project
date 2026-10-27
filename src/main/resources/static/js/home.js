'use strict';

const purposeInput = document.querySelector('#purpose');
const keywords = [...document.querySelectorAll('[data-keyword]')];
function syncKeywords() {
  const value = purposeInput?.value.trim() ?? '';
  keywords.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.keyword === value)));
  const purposeLink = document.querySelector('[data-purpose-link]');
  if (purposeLink) {
    const target = new URL(purposeLink.href);
    target.searchParams.set('activity', purposeInput.value);
    purposeLink.href = target.href;
  }
}
keywords.forEach(button => button.addEventListener('click', () => {
  purposeInput.value = button.dataset.keyword;
  purposeInput.dispatchEvent(new Event('input', { bubbles: true }));
  purposeInput.focus();
}));
if (purposeInput) {
  purposeInput.addEventListener('input', () => {
    syncKeywords();
    if (location.pathname.endsWith('/')) {
      const url = new URL(location.href);
      if (purposeInput.value) url.searchParams.set('activity', purposeInput.value);
      else url.searchParams.delete('activity');
      history.replaceState(null, '', url);
    }
  });
  syncKeywords();
}
const accountDialog = document.querySelector('#account-dialog');
document.querySelector('[data-open-account]')?.addEventListener('click', () => accountDialog.showModal());
accountDialog?.addEventListener('click', event => { if (event.target === accountDialog) accountDialog.close(); });
document.querySelectorAll('nav a').forEach(link => {
  if (new URL(link.href).pathname === location.pathname) link.setAttribute('aria-current', 'page');
});
