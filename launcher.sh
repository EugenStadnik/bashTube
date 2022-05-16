#!/bin/bash

width=$(expr $(xrandr --current | grep "*" | uniq | awk '{print $1}' | sed -e 's/x.*//g' | head -1) / 2);
height=$(expr $(xrandr --current | grep "*" | uniq | awk '{print $1}' | sed -e 's/.*x//g' | head -1) / 2);
catalogFile="*Catalog.log";
keyword="";
searchingString="";
selectedTitle="";
url="";

function selectMovieTitleFromList() {
	selectedTitle=$(zenity --width=$width --height=$height --list --title="Choose any from available" --column="Title" $@);
	if [ "$selectedTitle" == "" ]
	then
		enterMovieTitle "$keyword"
	else
		url=$(grep "$selectedTitle" $catalogFile | sed -e 's/.*http/http/g' | head -1);
	fi
}

function enterMovieTitle() {
	keyword=$(zenity --width=$width --entry --title="Enter keyword or URL" --text="Please enter movie keyword or movie URL you'd like to download:" --entry-text="$1");
	searchingString=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | sed -e 's/ /./g');
	if [[ "$keyword" == *"http"* ]]
	then
		url="$keyword";
	elif [ -n "$keyword" ]
	then
		allTitles=$(grep "$searchingString" $catalogFile | grep -v trailer | sed -e 's/ -> http.*//g' -e 's#.*/##g' | sort);
    	selectMovieTitleFromList "$allTitles";
    else
    	exit 0
	fi
}


for i in {0..100500}
do
	enterMovieTitle
	( ./downloader.sh $url ) | zenity --progress --width=$width --auto-close --title="Download" --text="Downloading $selectedTitle by $url url..." --percentage=0 &
done