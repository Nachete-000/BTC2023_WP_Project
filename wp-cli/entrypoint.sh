#!/bin/bash

# Setup initial config WordPress
	echo -e "\033[0;34m##################################################"
	echo -e "\033[0;34m# ⚙️   Configuring WordPress parameters...     ⚙️  #"
	echo -e "\033[0;34m##################################################"
	wp core install \
		--url=${WORDPRESS_WEBSITE_URL}:${EXTERNAL_NGINX_PORT} \
		--title=${WORDPRESS_WEBSITE_TITLE} \
		--admin_user=${WORDPRESS_ADMIN_USERNAME} \
		--admin_password=${WORDPRESS_ADMIN_PASSWORD} \
		--admin_email=${WORDPRESS_ADMIN_EMAIL}

# Update Wordpress
	echo -e "\033[0;34m# ⚙️   Updating WordPress...                   ⚙️  #"
	wp core update

# Install the Spanish core language pack.
	echo -e "\033[0;34m# ⚙️   Installing WordPress language...        ⚙️  #"
	wp language core install es_ES
	echo -e "\033[0;34m# ⚙️   Activating WordPress language...        ⚙️  #"

# Activate the Spanish core language pack.
	wp site switch-language es_ES

# Install the Spanish language pack for Twenty Seventeen.
	echo -e "\033[0;34m# ⚙️   Installing WordPress home...            ⚙️  #"
	wp language theme install twentyseventeen es_ES

# Configure wordpress site urls
	echo -e "\033[0;34m# ⚙️   Configuring WordPress home...           ⚙️  #"
	wp option update home ${WORDPRESS_WEBSITE_URL}:${EXTERNAL_NGINX_PORT}
	echo -e "\033[0;34m# ⚙️   Configuring WordPress url...            ⚙️  #"
	wp option update siteurl ${WORDPRESS_WEBSITE_URL}:${EXTERNAL_NGINX_PORT}

# Enable WP Rewrite
	echo -e "\033[0;34m# ⚙️   Configuring WordPress rewrite...        ⚙️  #"
	wp rewrite structure $WORDPRESS_WEBSITE_POST_URL_STRUCTURE

# Enable plugins
	echo -e "\033[0;34m# ⚙️   Configuring WordPress plugins...        ⚙️  #"
	wp plugin activate disable-canonical-redirects
	# Check if plugin wordpress-exporter-prometheus is enabled
	DIRECTORY=/var/www/html/wp-content/plugins/wordpress-exporter-prometheus/
	if [ -d "$DIRECTORY" ]; then
		echo -e "\033[0;34m# ⚙️   WP Prometheus plugin installed, enabling⚙️  #"
  		wp plugin activate wordpress-exporter-prometheus
	else
		echo -e "\033[0;34m# ⚙️   Installing WP Prometheus plugin         ⚙️  #"
		wp plugin install https://github.com/origama/wordpress-exporter-prometheus/archive/master.zip --activate
	fi

#### TEST PLUGINS -- Comment / uncomment next line to test deployment
	 wp plugin deactivate hello
	 wp plugin deactivate akismet
	 # wp plugin activate hello
	 # wp plugin activate akismet


#### Update Plugins
	 wp plugin update --all

# Update site blog name.
	echo -e "\033[0;34m# ⚙️   Configuring WordPress name...           ⚙️  #"
	wp option update blogname ${WORDPRESS_WEBSITE_TITLE}

# Update site blog description.
	echo -e "\033[0;34m# ⚙️   Configuring WordPress description...    ⚙️  #"
	wp option update blogdescription "${WORDPRESS_WEBSITE_TITLE} The Site for DevOps"

# Install wordpress theme
	echo -e "\033[0;34m# ⚙️   Configuring WordPress theme...          ⚙️  #"
	wp theme install visualblogger --activate

# Install the Spanish language pack for theme, visualblogger es_ES version not exists
	# echo -e "\033[0;34m# ⚙️   Installing WordPress theme language...  ⚙️  #"
	# wp language theme install visualblogger es_ES

# Modify default posts
	POST1TEXT="Welcome DevOps, this is the first post in the blog"
	POST2TEXT="A compound of development (Dev) and operations (Ops), DevOps is the union of people, process, and technology to continually provide value to customers.

	What does DevOps mean for teams? DevOps enables formerly siloed roles—development, IT operations, quality engineering, and security—to coordinate and collaborate to produce better, more reliable products. By adopting a DevOps culture along with DevOps practices and tools, teams gain the ability to better respond to customer needs, increase confidence in the applications they build, and achieve business goals faster."

	
	wp post exists 1
	if [ $? == 0 ]; then 
		wp post update 1 --post_content="${POST2TEXT}" --post_title="Hello DevOps 2023" --post_status=publish
		wp media import https://www.suse.com/assets/img/devops-process.png --post_id=1 --featured_image
	fi

	wp post exists 2
	if [ $? == 0 ]; then 
		wp post update 2 --post_content="${POST2TEXT}" --post_title="What is DevOps?" --post_name="what-is-devops" --post_status=publish
	fi

	wp post exists 3
	if [ $? == 0 ]; then 
		wp post update 3 --post_status=publish
	fi

# Conifigure time & format
	echo -e "\033[0;34m# ⚙️   Configure WordPress time settigns...    ⚙️  #"
	wp option update timezone_string "Europe/Madrid"
	wp option update time_format "l, j F, Y - G;i T"

	# Present results
	echo ""
	echo -e "\033[0;92m##################################################"
	echo -e "\033[0;92m### Installed Plugin:                          ###"
	echo -e "\033[0;92m##################################################"
	# WP list all installed plugins
	wp plugin list

	echo -e "\033[0;92m##################################################"
	echo -e "\033[0;92m### Plugin List:                                 #"
	echo -e "\033[0;92m    - Website URL   : "${WORDPRESS_WEBSITE_URL_WITHOUT_HTTP}
	echo -e "\033[0;92m    - Website title : "${WORDPRESS_WEBSITE_TITLE}
	echo -e "\033[0;92m    - WP admin      : "${WORDPRESS_ADMIN_USERNAME}
	echo -e "\033[0;92m    - WP admin mail : "${WORDPRESS_ADMIN_EMAIL}
	echo -e "\033[0;92m    - WP website URL: "${WORDPRESS_WEBSITE_URL}:${EXTERNAL_NGINX_PORT}
	echo -e "\033[0;92m    - WP rewrite str: "$WORDPRESS_WEBSITE_POST_URL_STRUCTURE
	echo -e "\033[0;92m    - WP ext port   : "${EXTERNAL_NGINX_PORT}
	echo -e "\033[0;92m    - WP int port   : "${NGINX_PORT}
	echo -e "\033[0;92m##################################################"
