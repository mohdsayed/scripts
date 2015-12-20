#Installs Wordpresss
iwp()
{
    # Questions
    #
    # Lets see if you want to download the dummy data
    read -rp "What would be the name of your installation? (enter name): " repo

    # Lets see if you want to download the dummy data
    read -rp "Do you want to download some dummy data? (no/online/sample): " dummy

    # creation the post the 1 a 100
    read -rp "You want some post by default? choose between ( 1-100 ): " post

    # What about some plugins?
    read -rp "Do you want to download some developer plugins? (y/n): " plugins

    # What about blank theme?
    read -rp "Do you want to download the blank theme? (y/n): " theme

    # Make a directory by name of it.
    mkdir $repo
    cd $repo

    # Drop data if already exists
    echo "Checking if database exists.."
    mysql -u root -p"root" -e "DROP DATABASE IF EXISTS \`$repo\`;"

    # Create Database
    echo "Creating Database.."
    mysql -u root -p"root" -e "CREATE DATABASE \`$repo\`;"

    # Download WordPress
    echo "Downloading WorpdPress.."
    wp core download

    # Generate wp-config file
    echo 'creating wp-config.php file...'
    wp core config --dbname=$repo --dbuser=root --dbpass=root --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP

    # Install WordPress
    echo 'Installing Wordpress'
    wp core install --url=http://localhost:8888/$repo  --title=$repo --admin_user="admin" --admin_password="admin" --admin_email="sayedwp@gmail.com"

    # Download wordpress test xml file and download its attachment.
    if [ $dummy = "online" ]; then

        echo "Dowloading dummy data..."
        curl -O https://raw.githubusercontent.com/manovotny/wptest/master/wptest.xml

        echo "Dowloading Wordpress Import Plugin..."
        wp plugin install wordpress-importer --activate

        echo "Importing dummy data..."
        wp import wptest.xml --authors=create

        echo "Deleting dummy data file"
        rm wptest.xml

    fi

    #Create some lorem Ipsum Posts
    if [[ $post = *[!0-9]* ]]; then  # if post contains any non-digits
        echo " "
    elif (( post < 0 || post > 100 )); then
        printf >&2 '%d is out of range (0-100)\n' "$post"
    else
        curl http://loripsum.net/api/5 | wp post generate --post_content --count=$post
    fi

    #Download dummy data from local xml file
    if [ $dummy = "sample" ]; then

        echo "Dowloading Wordpress Import Plugin..."
        wp plugin install wordpress-importer --activate

        wp post delete $(wp post list --post_type='page' --format=ids )
        wp post delete $(wp post list --post_type='post' --format=ids )
        wp post delete $(wp post list --post_status=trash --format=ids )

        echo "Importing sample data..."
        wp import ../sample.xml --authors=create
    fi


    #Download Dummy data
    if [ $plugins = "y" ]; then

        SAMPLE_DIRECTORY_EXISTS='../sample'

        if [ -d "$SAMPLE_DIRECTORY_EXISTS" ]; then

            CURRENT_DIR=${PWD}
            cd ../sample/wp-content/plugins/
            wp plugin update --all
            cd $CURRENT_DIR
            rm -R -- wp-content/plugins/*
            cp -r ../sample/wp-content/plugins/ wp-content/plugins/
            wp plugin activate --all
            wp plugin deactivate rtl-tester

        else

            echo "Dowloading debug-bar..."
            wp plugin install debug-bar --activate

            echo "Dowloading monster-widget..."
            wp plugin install monster-widget --activate

            echo "Dowloading regenerate-thumbnails..."
            wp plugin install regenerate-thumbnails --activate

            echo "Dowloading rtl-tester..."
            wp plugin install rtl-tester

            echo "Dowloading theme-check..."
            wp plugin install theme-check --activate

            echo "Dowloading wordpress-reset..."
            wp plugin install wordpress-reset --activate

            echo "Dowloading query-monitor..."
            wp plugin install query-monitor --activate

            echo "Dowloading usersnap..."
            wp plugin install usersnap --activate

            echo "Dowloading quick-navigation-interface..."
            wp plugin install quick-navigation-interface --activate

            #Lets delete the default plugins
            wp plugin delete akismet
            wp plugin delete hello
        fi

    fi

    #Download Blank Theme
    if [ $theme = "y" ]; then

        cd wp-content/themes/
        rm -rf twentyfourteen

        echo "Downloading Blank Theme..."
        curl -LOk https://github.com/sayedwp/blank-theme/archive/master.zip
        unzip master.zip
        rm -rf master.zip
        mv blank-theme-master blank-theme

        echo "Dowloading Blank Theme Generator"
        curl -LOk https://github.com/sayedwp/blank-theme-generator/archive/master.zip
        unzip master.zip
        rm -rf master.zip
        mv blank-theme-generator-master blank-theme-generator

    fi

    #Lets also reset our permalink structure
    # wp option get permalink_structure
    # wp option update permalink_structure '/%postname%'

    echo "All Done Have Fun!"
    open http://localhost:8888/$repo

    # If want to generate a blank theme?
    read -rp "Do you want to generate a blank theme? (y/n): " blank_theme

    if [ $theme = "y" ]; then
        open http://localhost:8888/$repo/wp-content/themes/blank-theme-generator
    fi

}
