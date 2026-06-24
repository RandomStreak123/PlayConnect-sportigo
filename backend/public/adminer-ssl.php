<?php
if (!function_exists('adminer_object')) {
    function adminer_object() {
        class AdminerSsl extends Adminer {
            function connectSsl() {
                // Returning an array forces Adminer to use SSL for the connection
                return array(
                    "key" => null,
                    "cert" => null,
                    "ca" => null,
                    "capath" => null,
                    "cipher" => null,
                );
            }
        }
        return new AdminerSsl;
    }
}

// Include the original Adminer script
include __DIR__ . '/adminer.php';
