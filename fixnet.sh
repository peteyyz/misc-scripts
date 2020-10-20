#!/bin/bash

RAND_DATE=$(date -d "$(($RANDOM%11+2010))-$(($RANDOM%12+1))-$(($RANDOM%28+1))" '+%Y-%m-%d')

# Fetch random pic:

IMAGE_URL=$(curl "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&date=$RAND_DATE" | jq -r .hdurl)

echo "Image URL: $IMAGE_URL"
if [ -z $IMAGE_URL ] || [ $IMAGE_URL = "null" ]
then
	echo "Houston, we have a problem..."
	IMAGES=(/home/pete/astro/*)
	IMAGE_FILE=$(basename $(printf "%s\n" "${IMAGES[RANDOM % ${#IMAGES[@]}]}"))
	echo "Image file: $IMAGE_FILE"
else
	echo "Connection to NASA established."
	wget $IMAGE_URL -P /home/pete/astro
	IMAGE_FILE="${IMAGE_URL##*/}"
fi

feh -FZ /home/pete/astro/$IMAGE_FILE &

exit 0

