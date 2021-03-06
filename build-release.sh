#!/bin/bash

project=Literate  
  
while getopts ":t:" Option
do
  case $Option in
      t ) tag=$OPTARG;;
  esac
done
shift $(($OPTIND - 1))
  
if [ "$tag" == "" ]; then
	echo "No tag specified"
	exit
fi
 
# Configuration
final_builds=~/Develop/$project/Releases
code_folder=~/Develop/$project/Desktop
build_folder=~/Develop/$code_folder/build
keys_folder=~/Develop/$project/PrivateKeys
 
if [ ! -d  $final_builds ]; then
	mkdir $final_builds
fi
   
echo "Fetching tag $tag"
git pull github master
git fetch github --tags
git checkout "$tag"
 
echo "Updating version"
sed -i "" 's/__VERSION__/'$tag'/g' Info.plist
 
echo "Building $project..."
xcodebuild -target $project -configuration Release OBJROOT=$build_folder SYMROOT=$build_folder OTHER_CFLAGS=""
 
if [ $? != 0 ]; then
	echo "Bad build for $project"
else
 
   mv $build_folder/Release/$project.app $final_builds
 
	# make the zip file
	cd $final_builds
	zip -r $project-$tag.zip $project.app
 
	rm -rf $project.app
 
	# get values for appcast
	dsasignature=`$keys_folder/sign_update.rb $final_builds/$project-$tag.zip $keys_folder/dsa_priv.pem`
	filesize=`stat -f %z $final_builds/$project-$tag.zip`
	pubdate=`date "+%a, %d %h %Y %T %z"`
 
 	cd $code_folder
 
 	cfbundleversion=`agvtool what-version -terse`
 
	#output appcast item
	echo
	echo "Put the following text in your appcast"
	echo "<item>"
	echo "<title>Version $tag</title>"
	echo "<sparkle:releaseNotesLink>"
	echo "$release_notes_webfolder/$project.html"
	echo "</sparkle:releaseNotesLink>"
	echo "<pubDate>$pubdate</pubDate>"
	echo "<enclosure url=\"$downloads_webfolder/$project-$tag.zip\""
	echo "sparkle:version=\"$cfbundleversion\""
	echo "sparkle:shortVersionString=\"$tag\""
	echo "sparkle:dsaSignature=\"$dsasignature\""
	echo "length=\"$filesize\""
	echo "type=\"application/octet-stream\" />"
	echo "</item>"
	
	open $final_builds 
fi
 
cd $code_folder
git checkout Info.plist
