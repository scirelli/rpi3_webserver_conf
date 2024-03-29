map $http_upgrade $connection_upgrade {
	default upgrade;
	'' close;
} 
#upstream forcegraph_websocket {
#	server localhost:8282;
#}

server {
	listen 80;
	listen [::]:80;

	server_name auction.ebidlocal.com.cirelli.org;

	return 302 https://$host$request_uri;

	access_log /var/log/nginx/auction.ebidlocal.com/access.log;
	error_log /var/log/nginx/auction.ebidlocal.com/error.log;

	gzip on;

	#root /var/www/auction.ebidlocal.com.cirelli.org/html;

	location /.well-known/ {
		alias /var/www/cirelli.org/html/.well-known/;
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files $uri $uri/ =404;
		# Uncomment to enable naxsi on this location
		# include /etc/nginx/naxsi.rules
	}

	location / {
		proxy_pass http://auction.ebidlocal.com/;
	}
}

# HTTPS server
#
server {
	listen 443 ssl;
	listen [::]:443 ssl;

	server_name auction.ebidlocal.com.cirelli.org;

	access_log /var/log/nginx/auction.ebidlocal.com/ssl_access.log;
	error_log /var/log/nginx/auction.ebidlocal.com/ssl_error.log;

	ssl on;

	ssl_certificate /etc/nginx/ssl/fullchain.pem;
	ssl_certificate_key /etc/nginx/ssl/key.pem;

	ssl_session_cache   shared:SSL:10m;
	ssl_session_timeout 5m;
	keepalive_timeout   60;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	#ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
	ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
	ssl_prefer_server_ciphers on;

	#root /var/www/auction.ebidlocal.com.cirelli.org/html;

	location /.well-known/ {
		alias /var/www/cirelli.org/html/.well-known/;
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files $uri $uri/ =404;
		# Uncomment to enable naxsi on this location
		# include /etc/nginx/naxsi.rules
	}

	location / {
		try_files $uri $uri/ @auction;
	}

	location @auction {
		proxy_pass https://auction.ebidlocal.com;
	}
}
