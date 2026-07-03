<?php
$address = "One4 All Sports Hub, Souhrdha Nagar, Stadium Nettayakoanam, Near Green Field, Thiruvananthapuram, Kerala, 695581";
$apiKey = "cxtvvrmhlvdiwftzifhzmqpuoxsrenpusqqh";
$url = "https://search.mappls.com/search/address/geocode?address=" . urlencode($address) . "&access_token=" . $apiKey;

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Referer: https://sportigo.com"
]);
$response = curl_exec($ch);
curl_close($ch);

print_r(json_decode($response, true));
