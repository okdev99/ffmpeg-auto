#!/bin/bash

showHelp() {
    echo "Usage: $0 [-opts]"
    echo
    echo "-opt1  lorem ipsum"
}

getDisplayAspectRatio() {
    mediainfo --Inform="Video;%DisplayAspectRatio%" "$1"
}

getDisplayAspectRatioString() {
    mediainfo --Inform="Video;%DisplayAspectRatio/String%" "$1"
}

getWidth() {
    mediainfo --Inform="Video;%Width%" "$1"
}

getHeight() {
    mediainfo --Inform="Video;%Height%" "$1"
}

getFramerate() {
    #FrameRate -> string ex. 60.000
    #FrameRate_Num -> number ex. 60
    mediainfo --Inform="Video;%FrameRate_Num%" "$1"
}

#Make options for target framerate, width, and height
# minimun framerate, width and height
# and maximum framerate, width and height.

origin="."
destination="."
max_framerate=
min_framerate=
max_resolution=
options=
scale=

TEMP=$(getopt --options hd:o: --longoptions help,destination:,origin:,max-framerate:,min-framerate:,max-resolution: -n 'ffmpeg-auto' -- "$@")

exit_code=$?

if [ $exit_code != 0 ]; then
    echo "Getopt failed. Terminating." >&2;
    exit 1;
fi

# Note the quotes around '$TEMP': they are essential!
eval set -- "$TEMP"

# Possible options
# --max-framerate
# --min-framerate
# --max-resolution (is inputted as 1280:720, but if only inputted 720, then whatever is the smallest of the resolution component is formatted to 720, for example: 1920:1080 -> 1280:720)
# --max-width
# --max-height
#
# Think of a way to convey the option of smallest width/height like formatting 2d video to 720p

while true; do
  case $1 in
    -h | --help)
        showHelp
        exit 0
        ;;
    -d | --destination)
        destination="$2"
        shift 2
        ;;
    -o | --origin)
        origin="$2"
        shift 2
        ;;
    --max-framerate)
        max_framerate="$2"
        shift 2
        ;;
    --min-framerate)
        min_framerate="$2"
        shift 2
        ;;
    --max-resolution)
        max_resolution="$2"
        shift 2
        ;;
    --) shift
        break
        ;;
    * ) break
        ;;
    
  esac
done

origin="$origin""/*"

for filename in $origin; do
    unset scale
    unset options

    aspect_ratio_string=$(getDisplayAspectRatioString "$filename")

    aspect_ratio=$(getDisplayAspectRatio "$filename")

    width=$(getWidth "$filename")
    
    height=$(getHeight "$filename")

    framerate=$(getFramerate "$filename")

    if [ ! -d "$destination""/""$aspect_ratio_string" ]; then
        mkdir "$destination""/""$aspect_ratio_string"
        mkdir "$destination""/""$aspect_ratio_string""/formatted"
        mkdir "$destination""/""$aspect_ratio_string""/not_formatted"

        #Test
        #echo "Folder created! Cause: $filename"
    #else
        #echo "Folder not created! Cause: $filename"
    fi

    #Check if a video needs formatting, and if not then move to corresponding "not_formatted folder"
    if false; then
        #move the video to the corresponding folder or copy it
        continue
    fi

    #Determine the necessary options for the video
    #if variable is not empty
    if [ -n "$max_framerate" ] && ((max_framerate < framerate)); then
        options="fps=""$max_framerate"
    elif [ -n "$min_framerate" ] && ((min_framerate > framerate)); then
        options="fps=""$min_framerate"
    fi

    if [ -n "$max_resolution" ]; then
        if ((height < width)) && ((height > max_resolution)); then
            tmp_width=$(echo "$aspect_ratio*$max_resolution" | bc)
            width=${tmp_width%.*}
            if ((width % 2 != 0)); then
                ((width++))
            fi
            scale="$width:$max_resolution"
        elif ((width <= height)) && ((width > max_resolution)); then
            tmp_height=$(echo "$max_resolution/$aspect_ratio" | bc)
            height=${tmp_height%.*}
            if ((height % 2 != 0)); then
                ((height--))
            fi
            scale="$max_resolution:$height"
        fi

        if [ -n "$scale" ]; then
            if [ -n "$options" ]; then
                options="$options"",scale=""$scale"
            else
                options="scale=""$scale"
            fi
        fi
    fi

    if [ -n "$options" ]; then
        options="-vf ""$options"
    fi

    echo ffmpeg -i "$filename" "$options" "$destination""/""$aspect_ratio_string""/formatted/""${filename##*/}"
done