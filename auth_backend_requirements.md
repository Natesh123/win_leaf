# Authentication Backend Requirements (Mobile App)

To enable **Login** and **Signup** features in the mobile app, the backend team needs to install and configure a specific plugin for WordPress.

## 1. Required Plugin
Install the **[JWT Authentication for WP REST API](https://wordpress.org/plugins/jwt-authentication-for-wp-rest-api/)** plugin.

## 2. Configuration Steps (Important)
After installing the plugin, the backend team must add the following lines to the `wp-config.php` and `.htaccess` files:

### A. Update `wp-config.php`
Add these two constants to your `wp-config.php` file:
```php
define('JWT_AUTH_SECRET_KEY', 'your-top-secret-key-logic');
define('JWT_AUTH_CORS_ENABLE', true);
```
*(Replace `your-top-secret-key-logic` with a long random string. You can get one from [here](https://api.wordpress.org/secret-key/1.1/salt/)).*

### B. Update `.htaccess`
To allow the "Authorization" header to pass through to WordPress, add this to your `.htaccess` file:
```apache
RewriteEngine on
RewriteCond %{HTTP:Authorization} ^(.*)
RewriteRule ^(.*) - [E=HTTP_AUTHORIZATION:%1]
```

## 3. Endpoints to be Tested
Once configured, the app will use these endpoints:
1.  **Login**: `POST /wp-json/jwt-auth/v1/token`
2.  **Signup (Register)**: `POST /wp-json/wp/v2/users`
3.  **Validate Token**: `POST /wp-json/jwt-auth/v1/token/validate`

## 4. User Registration
Ensure that "Anyone can register" is enabled in **Settings > General > Membership**.
