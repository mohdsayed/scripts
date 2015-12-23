
#Installs Wordpresss
iwp()
{
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

    START=$(date +%s)

    # Go to htdocs
    cd '/Applications/MAMP/htdocs/'

    # Make a directory by name of it.
    mkdir $repo
    cd $repo

    #Create Database
    createDatabase $repo

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
    	importOnlineData
    fi

    #Create some lorem Ipsum Posts
    createDummyPosts $post

    #Download dummy data from local xml file
    if [ $dummy = "sample" ]; then
        importSampleData
    fi

    #Download Dummy data
    if [ $plugins = "y" ]; then
        loadPlugins
    fi

    #Download Blank Theme
    if [ $theme = "y" ]; then
    	loadBlankTheme
    fi

    END=$(date +%s)
    DIFF=$(( $END - $START ))
    DIFF=$(( $DIFF / 60 ))

    greenText "All Done Have Fun! Total time taken : $DIFF min"
    open http://localhost:8888/$repo
}

createDatabase()
{
	repo=$1

	# Drop data if already exists
    echo "Checking if database exists.."
    mysql -u root -p"root" -e "DROP DATABASE IF EXISTS \`$repo\`;"

    # Create Database
    echo "Creating Database.."
    mysql -u root -p"root" -e "CREATE DATABASE \`$repo\`;"

    if [ $? -ne 0 ]; then
    	redText "Could not create database. Probablay your bin path is not set in .bash_profile. ";
    	exit
    fi;

    greenText "Database $repo created."
}

createDummyPosts()
{
	post=$1

	yellowText "Creating some dummy posts"

	if [[ $post = *[!0-9]* ]]; then  # if post contains any non-digits
	    echo " "
	elif (( post < 0 || post > 100 )); then
	    printf >&2 '%d is out of range (0-100)\n' "$post"
	else
	    curl http://loripsum.net/api/5 | wp post generate --post_content --count=$post
	fi

	greenText "$post dummy posts created"
}

importOnlineData()
{
	yellowText "Dowloading dummy data..."
	curl -O https://raw.githubusercontent.com/manovotny/wptest/master/wptest.xml

	echo "Dowloading Wordpress Import Plugin..."
	wp plugin install wordpress-importer --activate

	echo "Importing dummy data..."
	wp import wptest.xml --authors=create

	echo "Deleting dummy data file"
	rm wptest.xml

	greenText "All online data imported"
}

importSampleData()
{
	yellowText "Importing sample data from your local sample folder"
    echo "Dowloading Wordpress Import Plugin..."
    wp plugin install wordpress-importer --activate

    wp post delete $(wp post list --post_type='page' --format=ids )
    wp post delete $(wp post list --post_type='post' --format=ids )
    wp post delete $(wp post list --post_status=trash --format=ids )

    echo "Importing sample data..."
    wp import /Applications/MAMP/htdocs/sample/sample.xml --authors=create

    greenText "All sample data imported."
}

loadPlugins()
{
    SAMPLE_DIRECTORY='/Applications/MAMP/htdocs/sample/'
    CURRENT_DIR=${PWD}
    WP_DIR=$(wpDir)
    SAMPLE_PLUGIN_DIR=$SAMPLE_DIRECTORY/wp-content/plugins/
    PLUGIN_DIR=$WP_DIR/wp-content/plugins/

        # If sample directory exists
        if [ -d "$SAMPLE_DIRECTORY" ]; then

        	yellowText "Loading Plugins from sample folder..."

            cd $SAMPLE_PLUGIN_DIR
            wp plugin update --all
            cd $WP_DIR
            rm -R -- $PLUGIN_DIR*
            cp -r $SAMPLE_PLUGIN_DIR $PLUGIN_DIR
            wp plugin activate --all
            wp plugin deactivate rtl-tester

        else

        	yellowText "Dowloading plugins from wordpress.org..."

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

            echo "Dowloading fakerpress..."
            wp plugin install fakerpress --activate

            echo "Dowloading query-monitor..."
            wp plugin install query-monitor --activate

            echo "Dowloading quick-navigation-interface..."
            wp plugin install quick-navigation-interface --activate

            #Lets delete the default plugins
            wp plugin delete akismet
            wp plugin delete hello
        fi

        greenText "All plugins loaded and updated..."

        cd $CURRENT_DIR
}

loadBlankTheme()
{
	CURRENT_DIR=${PWD}
	WP_DIR=$(wpDir)

	cd $WP_DIR
	WP_DIR_NAME=${PWD##*/}

	#Go to themes folder
	cd $WP_DIR/wp-content/themes/

	rm -rf twentyfourteen

	yellowText "Downloading Blank Theme..."

	curl -LOk https://github.com/sayedwp/blank-theme/archive/master.zip
	unzip master.zip
	rm -rf master.zip
	mv blank-theme-master blank-theme

	echo "Dowloading Blank Theme Generator"
	curl -LOk https://github.com/sayedwp/blank-theme-generator/archive/master.zip
	unzip master.zip
	rm -rf master.zip
	mv blank-theme-generator-master blank-theme-generator

	echo "Blank theme and blank theme generator is downloaded."

	cd $CURRENT_DIR

	open http://localhost:8888/$WP_DIR_NAME/wp-content/themes/blank-theme-generator
}

wpDir()
{
	CURRENT_DIR=${PWD}
	plugin_path=$(wp plugin path)
	cd $plugin_path
	cd ../../
	WP_DIR=${PWD}
	cd $CURRENT_DIR
	echo "$WP_DIR"
}

yellowText()
{
	# Define variables:
	txtbld=$(tput bold)       # Bold
	txtylw=$(tput setaf 3)    # Yellow
	txtrst=$(tput sgr0)       # Text reset

	echo "${txtbld}${txtylw}$1${txtylw}${txtrst}"
}

greenText()
{
	txtbld=$(tput bold)       # Bold
	txtgrn=$(tput setaf 2)    # Green
	txtrst=$(tput sgr0)       # Text reset

	echo "${txtbld}${txtgrn}$1${txtgrn}${txtrst}"
}

redText(){
	txtbld=$(tput bold)       # Bold
	txtred=$(tput setaf 1)    # Red
	txtrst=$(tput sgr0)       # Text reset

	echo "${txtbld}${txtred}$1${txtred}${txtrst}"
}

moveTo()
{
	TARGER_DIR=$1

	if [ -z "$1"  ]; then
		echo "Please enter the folder name"
		return
	fi

	THEME_FOLDER=${PWD}
	THEME_FOLDER_NAME=${PWD##*/}
	TARGET_THEMES_FOLDER=/Applications/MAMP/htdocs/$TARGER_DIR/wp-content/themes/

	cd $TARGET_THEMES_FOLDER
	rm -rf $TARGET_THEMES_FOLDER/$THEME_FOLDER_NAME
	cd $THEME_FOLDER
	cp -r $THEME_FOLDER $TARGET_THEMES_FOLDER
	cd $TARGET_THEMES_FOLDER/$THEME_FOLDER_NAME
	cleanit
	cd $THEME_FOLDER

	greenText "Cleaned and moved sucessfully!"
    open http://localhost:8888/$TARGER_DIR/wp-admin/themes.php?page=themecheck
}

cleanit(){
    #Delete all .DS_Store files
    find . -name '.DS_Store' -exec rm {} \;
    rm -rf .git .sass-cache .svn .zip .gitignore .scss-cache bower_components .bower-cache .bower-registry .bower-tmp .idea _book nbproject nbproject/private/ build/ nbbuild/ dist/ nbdist/ nbactions.xml nb-configuration.xml .nb-gradle \*.log node_modules Thumbs.db sftp-config.json \*.json \*.sublime-project \*.sublime-workspace \*.gitignore /s
    greenText "Folder cleared"
}
