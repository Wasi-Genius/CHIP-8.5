document.addEventListener('DOMContentLoaded', function () {
  var form = document.getElementById('tmdb_form');

  if (form) {
    form.addEventListener('submit', function () {
      console.info('[TMDb] Search submitted', {
        title: form.elements.title.value,
        release_year: form.elements.release_year.value,
        language: form.elements.language.value
      });
    });
  }

  var diagnosticsElement = document.getElementById('tmdb_diagnostics');
  if (diagnosticsElement) {
    var diagnostics = JSON.parse(diagnosticsElement.getAttribute('data-diagnostics'));
    var log = diagnostics.status === 'error' ? console.error : console.info;
    log.call(console, '[TMDb] Search response', diagnostics);
  }
});
