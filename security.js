// Entwicklertools blockieren, ohne Pop-up-Meldungen
document.onkeydown = function(e) {
    // F12 blockieren
    if (e.keyCode == 123) {
        return false;
    }
    // Strg + Shift + I (Entwicklertools)
    if (e.ctrlKey && e.shiftKey && e.keyCode == 'I'.charCodeAt(0)) {
        return false;
    }
    // Strg + Shift + C (Element untersuchen)
    if (e.ctrlKey && e.shiftKey && e.keyCode == 'C'.charCodeAt(0)) {
        return false;
    }
    // Strg + Shift + J (Konsole)
    if (e.ctrlKey && e.shiftKey && e.keyCode == 'J'.charCodeAt(0)) {
        return false;
    }
    // Strg + U (Seitenquelltext anzeigen)
    if (e.ctrlKey && e.keyCode == 'U'.charCodeAt(0)) {
        return false;
    }
    // Strg + C (Kopieren)
    if (e.ctrlKey && e.keyCode == 'C'.charCodeAt(0)) {
        return false;
    }
    // Strg + X (Ausschneiden)
    if (e.ctrlKey && e.keyCode == 'X'.charCodeAt(0)) {
        return false;
    }
    // Strg + V (Einfügen)
    if (e.ctrlKey && e.keyCode == 'V'.charCodeAt(0)) {
        return false;
    }
};

// Blockieren der Entwicklertools durch Inspektion (ohne Pop-up)
(function() {
    const devtools = function() {};
    devtools.toString = function() {
        // Entfernt die Pop-up-Meldung, lässt aber den Schutz aktiv
        return '';
    };
    console.log('%c ', devtools);
})();

// Rechtsklick blockieren
document.addEventListener('contextmenu', function(e) {
    e.preventDefault();
    return false;
}, false);

// Textauswahl blockieren
document.addEventListener('selectstart', function(e) {
    e.preventDefault();
    return false;
}, false);

// Verhindert das Draggen von Elementen auf der Seite
document.addEventListener('dragstart', function(e) {
    e.preventDefault();
    return false;
}, false);

// Verhindert das Markieren von Text
document.oncopy = document.oncut = document.onpaste = function(e) {
    e.preventDefault();
    return false;
};
