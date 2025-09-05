<?php

// Nutzer-Agenten von Bots und Crawlern
$bots = [
    'googlebot', 'bingbot', 'slurp', 'duckduckbot', 'baiduspider', 'yandexbot', 'sogou',
    'exabot', 'facebot', 'ia_archiver', 'mj12bot', 'ahrefsbot', 'semrushbot', 'bot', 'crawler', 'spider'
];

// Nutzer-Agent überprüfen
$user_agent = strtolower($_SERVER['HTTP_USER_AGENT']);
foreach ($bots as $bot) {
    if (strpos($user_agent, $bot) !== false) {
        header("HTTP/1.1 403 Forbidden");
        exit();
    }
}

// IP-Adresse des Besuchers ermitteln
$ip = $_SERVER['REMOTE_ADDR'];
$geo_info = @json_decode(file_get_contents("http://ip-api.com/json/" . $ip . "?fields=status,countryCode"), true);

// Zugriff nur aus Deutschland - TEMPORARILY DISABLED FOR TESTING
// if (!$geo_info || $geo_info['status'] !== 'success' || $geo_info['countryCode'] !== 'DE') {
//     header("Location: https://google.de");
//     exit();
// }

// Zugriff nur von mobilen Geräten mit Android oder iPhone - TEMPORARILY DISABLED FOR TESTING
// if (!preg_match('/android|iphone/i', $user_agent)) {
//     header("Location: https://google.de");
//     exit();
// }

// Zusätzliche Sicherheitsmaßnahmen
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: no-referrer-when-downgrade");
header("Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'");

?>