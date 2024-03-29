# You may add here your
# server {
#	...
# }
# statements for each of your virtual hosts to this file

##
# You should look at the following URL's in order to grasp a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# http://wiki.nginx.org/Pitfalls
# http://wiki.nginx.org/QuickStart
# http://wiki.nginx.org/Configuration
#
# Generally, you will want to move this file somewhere, and start with a clean
# file but keep this around for reference. Or just disable in sites-enabled.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##

server {
	listen 80;
	listen [::]:80;
	#listen 80 default_server;
	#listen [::]:80 default_server ipv6only=on;

	# Make site accessible from http://localhost/
	server_name scirelli.com;
	
	add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

	return 301 https://$host$request_uri;

	root /var/www/html/scirelli.com/html;
	index index.html index.htm index.php;

	access_log /var/log/nginx/scirelli.com/access.log;
	error_log /var/log/nginx/scirelli.com/error.log;

	gzip on;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files $uri $uri/ =404;
		# Uncomment to enable naxsi on this location
		# include /etc/nginx/naxsi.rules
	}

	# Only for nginx-naxsi used with nginx-naxsi-ui : process denied requests
	#location /RequestDenied {
	#	proxy_pass http://127.0.0.1:8080;
	#}
    
	location /apigotinder/{
		#proxy_ssl_session_reuse off;
		proxy_pass https://api.gotinder.com;
	}

	location /facebook/{
		proxy_pass http://www.facebook.com/;
	}

	#location /switch_1/{
	#	proxy_pass http://Touch_P5.cirelli.lan:8080/;
	#}

	#Set headers for these to proxy files. Fake files created because requests are being made for them
	location /wpad.dat {
		default_type "application/x-ns-proxy-autoconfig";
	}
	location /proxy.pac {
		default_type "application/x-ns-proxy-autoconfig";
	}

	error_page 404 /404.html;

	# redirect server error pages to the static page /50x.html
	#
	error_page 500 502 503 504 /50x.html;
	location = /50x.html {
		root /var/www/html/scirelli.com/html;
	}

	# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
	#
	#location ~ \.php$ {
	#	try_files $uri =404;
	#	fastcgi_split_path_info ^(.+\.php)(/.+)$;
		# NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
	
		# With php5-cgi alone:
		#fastcgi_pass 127.0.0.1:9000;
		# With php5-fpm:
	#	fastcgi_pass unix:/var/run/php5-fpm.sock;
	#	fastcgi_index index.php;
	#	include fastcgi_params;
	#}
    
	#Force tinderbot to be https
	location /tinderbot{
		rewrite ^ https://$http_host$request_uri? permanent;
	}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	#location ~ /\.ht {
	#	deny all;
	#}
}


# another virtual host using mix of IP-, name-, and port-based configuration
#
#server {
#	listen 8000;
#	listen somename:8080;
#	server_name somename alias another.alias;
#	root html;
#	index index.html index.htm;
#
#	location / {
#		try_files $uri $uri/ =404;
#	}
#}


# HTTPS server
#
server {
	listen 443 ssl;

	# Make site accessible from https://localhost/
	server_name scirelli.com;

	add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

	root /var/www/html/scirelli.com/html;
	index index.html index.htm index.php;

	ssl on;
	#ssl_certificate /etc/nginx/ssl/scirelli.com/self-ssl.crt; #cert.pem;
	#ssl_certificate_key /etc/nginx/ssl/scirelli.com/self-ssl.key; #cert.key;
	ssl_certificate /etc/nginx/ssl/cert.pem;
	ssl_certificate_key /etc/nginx/ssl/key.pem;

	ssl_session_cache   shared:SSL:10m;
	ssl_session_timeout 5m;
	keepalive_timeout   60;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	#ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
	ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
	ssl_prefer_server_ciphers on;

	access_log /var/log/nginx/scirelli.com/ssl_scirelli.com_access.log;
	error_log /var/log/nginx/scirelli.com/ssl_scirelli.com_error.log;
	#log_format compression '$remote_addr - $remote_user [$time_local] ' '"$request" $status $bytes_sent ' '"$http_referer" "$http_user_agent" "$gzip_ratio"' '"$request_body_file"';

	location /apigotinder/{
        #proxy_ssl_session_reuse off;
		proxy_pass https://api.gotinder.com;
	}

	location /facebook/{
		#proxy_ssl_session_reuse off;
		#proxy_ignore_headers X-Accel-Redirect;
		#proxy_set_header Host $host;
		#proxy_set_header X-Real-IP $remote_addr;
		#proxy_set_header Cookie "datr=lzj_U8fjKk6fRDpKJ0T_1Gp2; lu=RA-kIgLyZpFYVFsLDxsKs2BA; x-referer=%2Fphoto.php%3Ffbid%3D10100941470926828%26id%3D31701236%26set%3Decnf.31701236%26source%3D49%26refid%3D17%23%2Fvictoria.smutek%3Ffref%3Dfc_search; a11y=%7B%22sr%22%3A0%2C%22sr-ts%22%3A1413504846990%2C%22jk%22%3A0%2C%22jk-ts%22%3A1413504846990%2C%22kb%22%3A0%2C%22kb-ts%22%3A1422551314002%2C%22hcm%22%3A0%2C%22hcm-ts%22%3A1413504846990%7D; act=1422679486609%2F69; p=-2; presence=EM422745708EuserFA2587466835A2EstateFDsb2F1422679322807Et2F_5b_5dElm2FnullEuct2F1422679322807EtrFA2loadA2EtwF4269705620EatF1422745441626G422745708051CEchFDp_5f587466835F3CC; c_user=587466835; fr=0YoDriSSxk9MRqY8k.AWVtF8aj6sRu0o90wdPeofJ_DuM.BT_zlN.Zu.FTN.0.AWXKaZtU; xs=51%3AYWCBKuSX3oSgyQ%3A2%3A1409235277%3A15982; csm=2; s=Aa5ln5gAdKe1KObk.BUuUzK";
		#client_body_in_file_only on;
		proxy_pass https://www.facebook.com/;
		proxy_redirect off;
		# Tells the browser this origin may make cross-origin requests
		add_header 'Access-Control-Allow-Origin' "https://www.facebook.com";
		add_header 'Access-Control-Allow-Methods' "POST, GET, OPTIONS";
		# Tells the browser it may show the response, when XmlHttpRequest.withCredentials=true.
		add_header 'Access-Control-Allow-Credentials' 'true';
	}

	location / {
		try_files $uri $uri/ =404;
	}

	#location /switch_1/{
	#	proxy_pass http://Touch_P5.cirelli.lan:8080/;
	#}

	error_page 404 /404.html;

	# redirect server error pages to the static page /50x.html
	#
	error_page 500 502 503 504 /50x.html;
	location = /50x.html {
		root /var/www/html/scirelli.com/html;
	}

	# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
	#
	#location ~ \.php$ {
	#	try_files $uri =404;
	#	fastcgi_split_path_info ^(.+\.php)(/.+)$;
		# NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
	
		# With php5-cgi alone:
		#fastcgi_pass 127.0.0.1:9000;
		# With php5-fpm:
	#	fastcgi_pass unix:/var/run/php5-fpm.sock;
	#	fastcgi_index index.php;
	#	include fastcgi_params;
	#}
}
