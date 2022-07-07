# How to show maintenance page

## Configure setting for maitenance

### If the error document exists in the same directory with document root

`$ sudo vi /etc/httpd/conf.d/rewrite.conf`

``` bash
<IfModule mod_rewrite.c>
RewriteEngine on
ErrorDocument 503 /maintenance/index.html
RewriteCond %{REQUEST_URI} !=/maintenance/index.html
RewriteCond %{REMOTE_ADDR} !^(10.0.2.3|192.168.11.[1-254]|127.0.0.1)$
RewriteRule ^(.*) - [R=503,L]
</IfModule>
```

- "{REMOTE_ADDR}" is allowed to access without access control


### If the error document exists in the other directory with document root

`$ sudo vi /etc/httpd/conf.d/rewrite.conf`

```bash
<IfModule mod_rewrite.c>
RewriteEngine on
Alias /maintenance/index.html /var/www/error/maintenance.html
ErrorDocument 503 /maintenance/index.html
RewriteCond %{REQUEST_URI} !=/maintenance/index.html
RewriteCond %{REMOTE_ADDR} !^(10.0.2.3|192.168.11.[1-254]|127.0.0.1)$
RewriteRule ^(.*) - [R=503,L]
</IfModule>
```

- "{REMOTE_ADDR}" is allowed to access without access control
- "Alias" specifies error document place

## Configure setting for non existence page

### If web content is not found, display the specified page

`$ sudo vi /etc/httpd/conf.d/rewrite.conf`

```bash
<IfModule mod_rewrite.c>
RewriteEngine on
ErrorDocument 404 /404.html
RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URL} !-f
RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URL} !-d
RewriteRule ^(.*)$ /404.html [R=404,L]
</IfModule>
```

- ErrorDocument directive shows error web page
