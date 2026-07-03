<?php
$eloc = "U6VNSE";
$apiKey = "cxtvvrmhlvdiwftzifhzmqpuoxsrenpusqqh";
$url = "https://atlas.mappls.com/api/places/detail?eloc=" . $eloc . "&key=" . $apiKey;

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

echo $response;
