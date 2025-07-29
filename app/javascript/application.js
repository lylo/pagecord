import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

import LocalTime from "local-time"

// Configure translations for LocalTime
LocalTime.config.i18n["pt"] = {
  date: {
    dayNames: ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"],
    monthNames: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
                 "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"],
    abbrDayNames: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"],
    abbrMonthNames: ["jan", "fev", "mar", "abr", "mai", "jun",
                     "jul", "ago", "set", "out", "nov", "dez"]
  }
};

LocalTime.config.i18n["es"] = {
  date: {
    dayNames: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"],
    monthNames: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                 "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"],
    abbrDayNames: ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
    abbrMonthNames: ["ene", "feb", "mar", "abr", "may", "jun",
                     "jul", "ago", "sep", "oct", "nov", "dic"]
  }
};

LocalTime.config.i18n["fr"] = {
  date: {
    dayNames: ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"],
    monthNames: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                 "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"],
    abbrDayNames: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
    abbrMonthNames: ["jan", "fév", "mar", "avr", "mai", "juin",
                     "juil", "août", "sep", "oct", "nov", "déc"]
  }
};

LocalTime.config.i18n["de"] = {
  date: {
    dayNames: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"],
    monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni",
                 "Juli", "August", "September", "Oktober", "November", "Dezember"],
    abbrDayNames: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
    abbrMonthNames: ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun",
                     "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
  }
};

// Set locale based on document's lang attribute or default to 'en'
const documentLang = document.documentElement.lang || 'en';
LocalTime.config.locale = documentLang;

LocalTime.start()
document.addEventListener("turbo:morph", () => {
  // Update locale in case it changed
  const currentLang = document.documentElement.lang || 'en';
  LocalTime.config.locale = currentLang;
  LocalTime.run()
})