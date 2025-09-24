<?php
/**
 * WordPress Configuration File
 * 
 * This file contains the WordPress configuration settings for the Docker environment.
 * It includes database settings, security keys, and performance optimizations.
 */

// ** Database settings ** //
define('DB_NAME', getenv('WORDPRESS_DB_NAME') ?: 'wordpress');
define('DB_USER', getenv('WORDPRESS_DB_USER') ?: 'wordpress');
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: 'wordpress_password');
define('DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'postgres:5432');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// ** Table prefix ** //
$table_prefix = getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_';

// ** WordPress security keys ** //
define('AUTH_KEY',         getenv('WORDPRESS_AUTH_KEY') ?: 'your_auth_key_here');
define('SECURE_AUTH_KEY',  getenv('WORDPRESS_SECURE_AUTH_KEY') ?: 'your_secure_auth_key_here');
define('LOGGED_IN_KEY',    getenv('WORDPRESS_LOGGED_IN_KEY') ?: 'your_logged_in_key_here');
define('NONCE_KEY',        getenv('WORDPRESS_NONCE_KEY') ?: 'your_nonce_key_here');
define('AUTH_SALT',        getenv('WORDPRESS_AUTH_SALT') ?: 'your_auth_salt_here');
define('SECURE_AUTH_SALT', getenv('WORDPRESS_SECURE_AUTH_SALT') ?: 'your_secure_auth_salt_here');
define('LOGGED_IN_SALT',   getenv('WORDPRESS_LOGGED_IN_SALT') ?: 'your_logged_in_salt_here');
define('NONCE_SALT',       getenv('WORDPRESS_NONCE_SALT') ?: 'your_nonce_salt_here');

// ** WordPress debugging ** //
define('WP_DEBUG', filter_var(getenv('WORDPRESS_DEBUG') ?: 'false', FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_LOG', filter_var(getenv('WORDPRESS_DEBUG_LOG') ?: 'false', FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_DISPLAY', false);

// ** Security settings ** //
define('DISALLOW_FILE_EDIT', true);
define('DISALLOW_FILE_MODS', false);
define('FORCE_SSL_ADMIN', true);

// ** Performance settings ** //
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
define('WP_CACHE', true);

// ** Database optimizations ** //
define('WP_POST_REVISIONS', 3);
define('AUTOSAVE_INTERVAL', 300);
define('WP_CRON_LOCK_TIMEOUT', 60);

// ** File permissions ** //
define('FS_METHOD', 'direct');

// ** Multisite settings (uncomment if using multisite) ** //
// define('WP_ALLOW_MULTISITE', true);

// ** Custom settings ** //
define('WP_HOME', 'https://' . (getenv('DOMAIN_NAME') ?: 'localhost'));
define('WP_SITEURL', 'https://' . (getenv('DOMAIN_NAME') ?: 'localhost'));

// ** SSL settings ** //
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// ** Database driver for PostgreSQL ** //
define('DB_DRIVER', 'pgsql');

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
