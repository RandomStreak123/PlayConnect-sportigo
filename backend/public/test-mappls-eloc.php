<?php
$eloc = "U6VNSE";
$url = "https://explore.mappls.com/apis/O2O/entity/" . $eloc;

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

echo $response;
