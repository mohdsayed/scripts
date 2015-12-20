zipit(){
    foldername=${PWD##*/}
    cd ../
    mkdir $foldername-backups
    cp -r $foldername $foldername-backups/$foldername
    cd $foldername-backups
    totalzip=$(ls | wc -l)
    totalzip="$(echo -e "${totalzip}" | tr -d '[[:space:]]')"
    newBackupDir=version-0"$totalzip"
    mkdir "$newBackupDir"
    cd $foldername
    rm -rf .git .sass-cache .svn .zip .gitignore .scss-cache bower_components .bower-cache .bower-registry .bower-tmp .idea _book nbproject nbproject/private/ build/ nbbuild/ dist/ nbdist/ nbactions.xml nb-configuration.xml .nb-gradle \*.log node_modules \*.DS_Store Thumbs.db sftp-config.json \*.json \*.sublime-project \*.sublime-workspace \*.gitignore
    zip -r ../$newBackupDir/$foldername.zip . -x \*.DS_Store
    cd ../
    rm -rf $foldername
    cd ../
    cd $foldername
    clear
}
