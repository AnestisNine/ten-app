import type { Mail } from './mailer.js';

// Bilingual until users pick a language; templates become editable in the Orders phase.

export function inviteEmail(name: string, to: string, link: string): Mail {
  return {
    to,
    subject: 'Πρόσκληση στο TBN Manager / Invitation to TBN Manager',
    text: [
      `Γεια σου ${name},`,
      '',
      'Σου δημιουργήθηκε λογαριασμός στο TBN Manager. Όρισε τον κωδικό σου εδώ (ισχύει 48 ώρες):',
      link,
      '',
      '---',
      `Hi ${name}, an account was created for you on TBN Manager. Set your password here (valid for 48 hours):`,
      link,
      '',
      'Αν δεν το περίμενες, αγνόησε αυτό το email. / If you did not expect this, ignore this email.',
    ].join('\n'),
  };
}

export function resetPasswordEmail(name: string, to: string, link: string): Mail {
  return {
    to,
    subject: 'Επαναφορά κωδικού TBN Manager / Password reset',
    text: [
      `Γεια σου ${name},`,
      '',
      'Για νέο κωδικό πάτησε εδώ (ισχύει 48 ώρες):',
      link,
      '',
      '---',
      `Hi ${name}, to choose a new password open this link (valid for 48 hours):`,
      link,
      '',
      'Αν δεν το ζήτησες εσύ, αγνόησε αυτό το email. / If you did not request this, ignore this email.',
    ].join('\n'),
  };
}
