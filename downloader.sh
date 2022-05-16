#!/bin/bash

url="$1";

folderToDownload="$HOME/Videos/";
if [[ ! -d "$folderToDownload" ]]
then
	mkdir -r "$folderToDownload"
fi
masterPlaylistUrl="";
masterPlaylist=""
streamPlaylistUrl="";
highestBandwithPlaylist="";
streamPlaylistBaseUrl="";
title="";

function downloadPlaylist() {
	length=$(echo "$highestBandwithPlaylist" | wc -l);
	index=0;
	echo "# Downloading $title by $url url...";
	for seg in ${highestBandwithPlaylist[@]}
	do
		segemntUrl="$streamPlaylistBaseUrl$seg";
		wget --no-check-certificate --quiet "$segemntUrl" -O ->> "${folderToDownload}${title}.ts"
		((index=index+1));
		((persentage=index*100/length));
		echo "$persentage";
	done
}

function downloadTortugaAshdiByIndexPlaylist() {
	highestBandwithPlaylist=$(curl --insecure --silent $streamPlaylistUrl | grep -i "seg");
	streamPlaylistBaseUrl=$(echo "$streamPlaylistUrl" | sed -e 's#index.m3u8##g');
	title=$(echo "$streamPlaylistBaseUrl" | sed -e 's#.*films/##g' -e 's#.*trailers/##g' -e 's#.*serials/##g' -e 's#.*chest/##g' -e 's#[_0-9]\+/hls.*##g' -e 's#.*/##g' -e 's#\.$##g');
	if [[ -f "${folderToDownload}${title}.ts" ]]; then
		timeStamp=$(date +%s);
		title="$title.$timeStamp"
	fi
	downloadPlaylist
}

function downloadTortugaAshdiByMasterPlaylist() {
	masterPlaylist=$(curl --insecure --silent $masterPlaylistUrl);
	highestBandwith=$(echo "$masterPlaylist" | grep -i "BANDWIDTH" | sed -e 's/.*BANDWIDTH=//g' | sort -n | tail -1);
	highestBandwithSuburl=$(echo "$masterPlaylist" | grep -A 1 "BANDWIDTH=$highestBandwith" | tail -1 | sed -e 's/^\.//g');
	playlistBaseUrl=$(echo "$masterPlaylistUrl" | sed -e 's#/index.m3u8##g');
	streamPlaylistUrl="$playlistBaseUrl$highestBandwithSuburl";
	downloadTortugaAshdiByIndexPlaylist
}

function downloadTortugaAshdi() {
	html=$(curl --insecure --silent $url);
	masterPlaylistUrl=$(echo "$html" | grep "file:\"http" | sed -e 's#^.*file:"http#http#g' -e 's/m3u8.*/m3u8/g');
	downloadTortugaAshdiByMasterPlaylist
}

if [[ "$url" == *"://ashdi.vip/"* ]] || [[ "$url" == *"://tortuga.wtf/"* ]]; then
	downloadTortugaAshdi
elif [[ "$url" == *"ashdi.vip"* ]] && [[ "$url" == *".m3u8"* ]]; then
	playlist=$(curl --insecure --silent $url);
	lines=$(echo "$playlist" | wc -l);
	if (( $lines < 21 )); then
		masterPlaylistUrl="$url";
		downloadTortugaAshdiByMasterPlaylist
	else
		streamPlaylistUrl="$url";
		downloadTortugaAshdiByIndexPlaylist
	fi
elif [[ "$url" == *"tortuga.wtf"* ]] && [[ "$url" == *".m3u8"* ]]; then
	playlist=$(curl --insecure --silent $url);
	lines=$(echo "$playlist" | wc -l);
	if (( $lines < 21 )); then
		masterPlaylistUrl="$url";
		downloadTortugaAshdiByMasterPlaylist
	else
		streamPlaylistUrl="$url";
		downloadTortugaAshdiByIndexPlaylist
	fi
elif [[ "$url" == *"www.youtube.com"* ]]; then
	# https://www.youtube.com/watch?v=d-mrLkbCwoI
	scriptTag=$(curl --silent $url | tr '\n' ' ' | tr '<' '\n<' | grep videoplayback );
	redundant1=$(echo "$scriptTag" | sed -e 's/{.*//g');
	redundant9=$(echo "$scriptTag" | sed -e 's/.*}//g');
	youtubeData=$(echo "$scriptTag" | sed -e "s*$redundant1**g" -e "s*$redundant9**g");
	title=$(echo "$youtubeData" | jq ".videoDetails.title" | sed -e 's/"//g' -e 's/\W/_/g' -e 's/_\+/_/g' | colrm 64);
	echo "title $title";
	videoMaxBitrate=$(echo "$youtubeData" | jq ".streamingData.adaptiveFormats[] | select(.mimeType|test(\".*video.*\")) | .averageBitrate" | sort -nr | head -1 );
	bestVideoUrl=$(echo "$youtubeData" | jq ".streamingData.adaptiveFormats[] | select(.averageBitrate==$videoMaxBitrate) | .url" | sed -e 's/"//g');
	bestVideoContainer=$(echo "$youtubeData" | jq ".streamingData.adaptiveFormats[] | select(.averageBitrate==$videoMaxBitrate) | .mimeType" | sed -e 's#.*video/##g' -e 's#\W\+codec.*##g');
	echo "bestVideoUrl $bestVideoUrl";
	echo "bestVideoContainer $bestVideoContainer";
	audioMaxBitrate=$(echo "$youtubeData" | jq ".streamingData.adaptiveFormats[] | select(.mimeType|test(\".*audio.*\")) | .averageBitrate" | sort -nr | head -1 );
	bestAudioUrl=$(echo "$youtubeData" | jq ".streamingData.adaptiveFormats[] | select(.averageBitrate==$audioMaxBitrate) | .url" | sed -e 's/"//g');
	bestAudioContainer=$(echo "$youtubeData" | jq ".streamingData.adaptiveFormats[] | select(.averageBitrate==$audioMaxBitrate) | .mimeType" | sed -e 's#.*audio/##g' -e 's#\W\+codec.*##g');
	echo "bestAudioUrl $bestAudioUrl";
	echo "bestAudioContainer $bestAudioContainer";
	videoFilePath="${folderToDownload}${title}_video.$bestVideoContainer";
	audioFilePath="${folderToDownload}${title}_audio.$bestAudioContainer";

	echo "#1/3 Downloading video part for $title";
	wget --no-check-certificate --background "$bestVideoUrl" -O "$videoFilePath"
	inProgress=$(ps axl | grep "$videoFilePath" | grep -v grep | awk '{print $3}');
	while [[ "$inProgress" != "" ]]
	do
		inProgress=$(ps axl | grep "$videoFilePath" | grep -v grep | awk '{print $3}');
		echo "0"; sleep 1; echo "11"; sleep 1; echo "22"; sleep 1; echo "33"; sleep 1;
	done
	echo "#2/3 Downloading audio part for $title";
	wget --no-check-certificate --background "$bestAudioUrl" -O "$audioFilePath"
	inProgress=$(ps axl | grep "$audioFilePath" | grep -v grep | awk '{print $3}');
	while [[ "$inProgress" != "" ]]
	do
		inProgress=$(ps axl | grep "$audioFilePath" | grep -v grep | awk '{print $3}');
		echo "33"; sleep 1; echo "44"; sleep 1; echo "55"; sleep 1; echo "66"; sleep 1;
	done
	echo "#3/3 Merging video and audio parts for $title";
	ffmpeg -i $videoFilePath -i $audioFilePath -c:v copy -c:a libmp3lame -map 0:0 -map 1:0 -b:v $videoMaxBitrate -b:a $audioMaxBitrate "${folderToDownload}${title}.$bestVideoContainer" &
	inProgress=$(ps axl | grep "$audioFilePath" | grep -v grep | awk '{print $3}');
	while [[ "$inProgress" != "" ]]
	do
		inProgress=$(ps axl | grep "$audioFilePath" | grep -v grep | awk '{print $3}');
		echo "66"; sleep 1; echo "77"; sleep 1; echo "88"; sleep 1; echo "99"; sleep 1;
	done
	
	rm -rf $videoFilePath $audioFilePath
	echo "100";
else
	echo "100";
	zenity --width=480 --warning --text="Unable to find video stream by the provided input $1"
fi