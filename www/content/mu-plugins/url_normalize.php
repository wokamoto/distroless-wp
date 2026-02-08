<?php
/*
Plugin Name: URL Normalize
Plugin URI: 
Description: 
Version: 0.0.1
Author: 
Author URI: 
License: GPLv2 or later
*/
if (!defined('ABSPATH')) {
    exit; // don't access directly
};

/**
 * URL Normalize
 */
function __url_normalize($content) {
    if (is_user_logged_in()) {
        return $content;
    }
    $url_normalize = function($url) {
        $parsed_url  = parse_url($url);
        $scheme      = $parsed_url['scheme'];
        $host_name   = $parsed_url['host'];
        $server_name = $host_name . (isset($parsed_url['port']) ? ':'.$parsed_url['port'] : '');
        return "{$scheme}://{$server_name}";
    };
    $home_url = $url_normalize(home_url());
    $site_url = $url_normalize(site_url());
    return preg_replace(
        '#'.preg_quote($site_url).'#' ,
        $home_url,
        $content
    );
}
add_action(
    'init',
    function () {
        add_filter(
            'upload_dir',
            function ($uploads) {
                /** @var string[] */
                if (isset($uploads['url'])) {
                    $uploads['url'] = __url_normalize($uploads['url']);
                }
                if (isset($uploads['baseurl'])) {
                    $uploads['baseurl'] = __url_normalize($uploads['baseurl']);
                }
                return $uploads;
            }
        );
        add_filter('plugins_url', '__url_normalize');
        add_filter('theme_file_uri', '__url_normalize');
        add_filter('the_editor_content', '__url_normalize');
        add_filter('the_content', '__url_normalize');
    }
);