# WooCommerce Backend Requirements Checklist

Share this list with your backend/web development team so they can provide the necessary details for the Flutter app integration.

## 1. REST API Credentials
The app needs API keys to communicate with WooCommerce.
- **Consumer Key**: (Starts with `ck_`)
- **Consumer Secret**: (Starts with `cs_`)

> [!TIP]
> **How to generate**: In WordPress Admin, go to **WooCommerce > Settings > Advanced > REST API > Add Key**. 
> Set the **Permissions** to **Read/Write** (so users can eventually place orders from the app).

## 2. Base URL
- The full URL of your WordPress site (e.g., `https://idealtraders.co/dev`).
- **Condition**: Must have **HTTPS** enabled. The WooCommerce REST API does not allow non-secure connections.

## 3. Permalinks Configuration
- In WordPress Admin, go to **Settings > Permalinks**.
- **Important**: The permalinks must **NOT** be set to "Plain". Choose "Post name" or any other option.

## 4. API Version
- Ensure the **WooCommerce REST API v3** is active (it usually is by default in recent versions).

## 5. Potential Issues
- **Firewalls/Security Plugins**: Some plugins (like Wordfence or Cloudflare) might block REST API requests. Ensure the API endpoints are white-listed for mobile app access.
