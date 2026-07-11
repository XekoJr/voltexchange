import { createI18n } from 'vue-i18n';
import en from './en.json';
import pt from './pt.json';

// Preferência guardada tem prioridade; senão, deteta o idioma do browser
const saved = localStorage.getItem('vx_locale');
const browser = navigator.language?.toLowerCase().startsWith('pt') ? 'pt' : 'en';

const i18n = createI18n({
  legacy: false,
  locale: saved || browser,
  fallbackLocale: 'en',
  messages: { en, pt },
});

export function setLocale(locale) {
  i18n.global.locale.value = locale;
  localStorage.setItem('vx_locale', locale);
}

export default i18n;
