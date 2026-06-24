<?php
if (!function_exists('adminer_object')) {
    function adminer_object() {
        include_once "./plugins/plugin.php";
        include_once "./plugins/login-ssl.php";
        
        // Check if the user is attempting to connect to the Aiven cloud database
        $server = isset($_POST['auth']['server']) ? $_POST['auth']['server'] : '';
        $use_ssl = (strpos($server, 'aivencloud.com') !== false || strpos($server, 'cloud') !== false);
        
        $plugins = [];
        if ($use_ssl) {
            // Enable SSL connection for cloud databases
            $plugins[] = new AdminerLoginSsl([
                'ca' => '',
            ]);
        }
        
        return new AdminerPlugin($plugins);
    }
}

include "./adminer-core.php";
