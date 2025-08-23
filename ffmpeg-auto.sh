#!/bin/bash

showHelp() {
    #also include a tip for using the program. Like recommended to only use
    echo "Usage: $0 [OPTION...]"
    echo
    echo "  -h, --help                          show this help text"
    echo "  -d, --destination                   select destination directory, default is current directory"
    echo "  -o, --origin                        select origin directory, default is current directory"
    echo "      --max-framerate                 maximum framerate"
    echo "      --min-framerate                 minimun framerate"
    echo "      --max-resolution                maximum resolution"
    echo "      --ratio-16:9-max-resolution     maximum resolution for only 16:9 ratio video"
    echo "      --ratio-9:16-max-resolution     maximum resolution for only 9:16 ratio video"
    echo "      --ratio-1-max-resolution        maximum resolution for only 1.0 ratio video"
    echo "      --ratio-2-max-resolution        maximum resolution for only 2.0 ratio video"
    echo
    echo "If maximum resolution or framerate is exceeded then a new option is inlcuded that set the formatted video"
    echo "to the maximum specified. The same happens with minimum framerate, but just the otherway."
    echo
    echo "Ratio specific maximum only apply if the input video has the specified aspect ratio and it is over the"
    echo "maximum, otherwise if no specific ratio resolution options are set or the video just does not have the"
    echo "correct aspect ratio, then the max-resolution value is used if it was set."
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

ffmpeg_supported_extensions=("str" "aa" "aac" "aax" "ac3" "acm" "adf" "adp" "dtk" "ads" "ss2" "adx" "aea" "afc" "aix" "al" "ape" "apl" "mac" "aptx" "aptxhd" "aqt" "ast" "obu" "avi" "avr" "avs" "avs2" "avs3" "bfstm" "bcstm" "binka" "bit" "bitpacked" "bmv" "brstm" "cdg" "cdxl" "xl" "c2" "302" "daud" "dfpwm" "dav" "dss" "dts" "dtshd" "dv" "dif" "cdata" "eac3" "paf" "fap" "flm" "flac" "flv" "fsb" "fwse" "g722" "722" "tco" "rco" "g723_1" "g729" "genh" "gsm" "h261" "h26l" "h264" "264" "avc" "hca" "hevc" "h265" "265" "idf" "ifv" "cgi" "ipu" "sf" "ircam" "ivr" "kux" "669" "amf" "ams" "dbm" "digi" "dmf" "dsm" "dtm" "far" "gdm" "ice" "imf" "it" "j2b" "m15" "mdl" "med" "mmcmp" "mms" "mo3" "mod" "mptm" "mt2" "mtm" "nst" "okt" "plm" "ppm" "psm" "pt36" "sptm" "s3m" "sfx" "sfx2" "st26" "stk" "stm" "stp" "ult" "umx" "wow" "xm" "xpk" "dat" "lvf" "m4v" "mkv" "mk3d" "mka" "mks" "webm" "mca" "mcc" "mjpg" "mjpeg" "mpo" "j2k" "mlp" "mods" "moflex" "mov" "mp4" "m4a" "3gp" "3g2" "mj2" "psp" "m4b" "ism" "ismv" "isma" "f4v" "avif" "mp2" "mp3" "m2a" "mpa" "mpc" "mpl2" "sub" "msf" "mtaf" "ul" "musx" "mvi" "mxg" "v" "nist" "sph" "nsp" "nut" "ogg" "oma" "omg" "aa3" "pjs" "pvf" "yuv" "cif" "qcif" "rgb" "rt" "rsd" "rsd" "rso" "sw" "sb" "smi" "sami" "sbc" "msbc" "sbg" "scc" "sdr2" "sds" "sdx" "ser" "sga" "shn" "vb" "son" "imx" "sln" "stl" "sub" "sub" "sup" "svag" "svs" "tak" "thd" "tta" "ans" "art" "asc" "diz" "ice" "nfo" "vt" "ty" "ty+" "uw" "ub" "v210" "yuv10" "vag" "vc1" "rcv" "viv" "idx" "vpk" "txt" "vqf" "vql" "vqe" "vtt" "wsd" "xmv" "xvag" "yop" "y4m" "wav")

origin="."
destination="."

TEMP=$(getopt --options hd:o: --longoptions help,destination:,origin:,max-framerate:,min-framerate:,max-resolution:,ratio-16:9-max-resolution:,ratio-9:16-max-resolution:,ratio-1-max-resolution:,ratio-2-max-resolution: -n 'ffmpeg-auto' -- "$@")

exit_code=$?

if [ $exit_code != 0 ]; then
    echo "Getopt failed. Terminating." >&2;
    exit 1;
fi

# Note the quotes around '$TEMP': they are essential!
eval set -- "$TEMP"

# It could be possible to use a custom ratio, by snipping the option --ratio-RATIO-max-resolution=xxxx.
# Look for string manipulation etc.

# Another idea about correct resolution is to specify the range when a specific resolution is used;
# like if ratio is 2, but the resolution is high in specified bounds then use high resolution and
# if ratio is the same 2, but the resolution is not withing the specified bounds then use standard resolution
# either specified ratio-2.0-max-resolution or max-resolution in that order.

# Consider making an option for constant rate factor

# An option for custom ratio with a specific resolution. Can be invoked multiple times, each invokation adds to two arrays:
# custom_ratios, and custom_resolutions, where custom_ratios index is the same as custom_resolutions

# Make new options for ratio-4:3 and ratio-3:4

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
    --ratio-1-max-resolution)
        ratio_1_max_resolution="$2"
        shift 2
        ;;
    --ratio-2-max-resolution)
        ratio_2_max_resolution="$2"
        shift 2
        ;;
    --ratio-16:9-max-resolution)
        ratio_169_max_resolution="$2"
        shift 2
        ;;
    --ratio-9:16-max-resolution)
        ratio_916_max_resolution="$2"
        shift 2
        ;;
    --ratio-4:3-max-resolution)
        ratio_43_max_resolution="$2"
        shift 2
        ;;
    --ratio-3:4-max-resolution)
        ratio_34_max_resolution="$2"
        shift 2
        ;;
    --) shift
        break
        ;;
    * ) break
        ;;
  esac
done

if [ -n "$max_framerate" ] && [ -n "$min_framerate" ] && ((max_framerate < min_framerate)); then
    echo "Min framerate cannot be higher than max framerate!"
    exit 1
fi

if [ ! "${origin:0-1}" = "/" ]; then
    origin="$origin""/*"
else
    origin="$origin""*"
fi

for filename in $origin; do

    #CHECK HERE IF filename HAS THE CORRECT EXTENSIONS
    if ! echo "${ffmpeg_supported_extensions[@]}" | grep -qw "${filename##*.}"; then
		continue
	fi

    unset scale
    unset options

    aspect_ratio_string=$(getDisplayAspectRatioString "$filename")

	# This command should be moved to the function
    aspect_ratio=$(echo "$(getDisplayAspectRatio "$filename")" | bc)

    width=$(getWidth "$filename")

    height=$(getHeight "$filename")

    framerate=$(getFramerate "$filename")

    if [ ! -d "$destination""/""$aspect_ratio_string" ]; then
        mkdir -p "$destination""/""$aspect_ratio_string""/formatted"
        mkdir "$destination""/""$aspect_ratio_string""/not_formatted"
    fi

    # HOX HOX HOX!
    # THIS DOES NOT WORK PROPERLY WITH RATIO SPECIFIC RESOLUTIONS, WHEN max-resolution IS SET!!!!
    # SOME ISSUE IN LOGIC!!!

    # USE PEN AND PAPER TO SKETCH THE LOGIC OF THIS ABOMINATION OF A IF STATEMENT!!!!!!!!!!

    #
    # Check if a video needs formatting, and if not then move to corresponding "not_formatted folder"
    # Each line checks first if option does not exist, so that using or || operator we can move to the next
    # conditional only when previous failed, so true positive result is flipped to false result so this conditional works.
    if ( [ -z "$max_framerate" ] || ((max_framerate >= framerate)) ) &&
    ( [ -z "$min_framerate" ] || ((min_framerate <= framerate))) &&
    (
        (
            ( [ -z "$ratio_1_max_resolution" ] || ( (( $(echo "$aspect_ratio != 1" | bc -l) )) || ((ratio_1_max_resolution >= height)) ) ) &&
            ( [ -z "$ratio_2_max_resolution" ] || ( (( $(echo "$aspect_ratio != 2" | bc -l) )) || ((ratio_2_max_resolution >= height)) ) ) &&
            ( [ -z "$ratio_169_max_resolution" ] || ( (( $(echo "$aspect_ratio != 1.778" | bc -l) )) || ((ratio_169_max_resolution >= height)) ) ) &&
            ( [ -z "$ratio_916_max_resolution" ] || ( (( $(echo "$aspect_ratio != 0.562" | bc -l) )) || ((ratio_916_max_resolution >= width)) ) ) &&
            ( [ -z "$ratio_43_max_resolution" ] || ( (( $(echo "$aspect_ratio != 1.333" | bc -l) )) || ((ratio_43_max_resolution >= height)) ) ) &&
            ( [ -z "$ratio_34_max_resolution" ] || ( (( $(echo "$aspect_ratio != 0.75" | bc -l) )) || ((ratio_34_max_resolution >= width)) ) )
        ) || (
            ( [ -z "$max_resolution" ] || ( ((max_resolution >= width)) || ((width > height)) ) ) &&
            ( [ -z "$max_resolution" ] || ( ((max_resolution >= height)) || ((width < height)) ) )
        )
    ); then
		# this is echo for testing
        # move the video to the corresponding folder or copy it
        echo mv "$filename" "$destination""/""$aspect_ratio_string""/not_formatted/""${filename##*/}"
        continue
    fi

    # Determine the necessary options for the video
    # if variable is not empty
    if [ -n "$max_framerate" ] && ((max_framerate < framerate)); then
        options="fps=""$max_framerate"
    elif [ -n "$min_framerate" ] && ((min_framerate > framerate)); then
        options="fps=""$min_framerate"
    fi

    # Check here for different ratio options and if they fail move to max_resolution
    if [ -n "$ratio_1_max_resolution" ] && ((aspect_ratio = 1)); then
        if ((ratio_1_max_resolution < width)); then
            tmp_width="$ratio_1_max_resolution"
            width=${tmp_width%.*}

            if ((width % 2 != 0)); then
                ((width++))
            fi
            scale="$width:$width"
        fi
    elif [ -n "$ratio_2_max_resolution" ] && ((aspect_ratio = 2)); then
        if ((ratio_2_max_resolution < height)); then
            tmp_width=$(echo "$aspect_ratio*$ratio_2_max_resolution" | bc)
            width=${tmp_width%.*}

            if ((width % 2 != 0)); then
                ((width++))
            fi
            scale="$width:$ratio_2_max_resolution"
        fi
    elif [ -n "$ratio_169_max_resolution" ] && (( $(echo "$aspect_ratio == 1.778" | bc -l) )); then
        if ((ratio_169_max_resolution < height)); then
            tmp_width=$(echo "$aspect_ratio*$ratio_169_max_resolution" | bc)
            width=${tmp_width%.*}

            if ((width % 2 != 0)); then
                ((width++))
            fi

            scale="$width:$ratio_169_max_resolution"
        fi
    elif [ -n "$ratio_916_max_resolution" ] && (( $(echo "$aspect_ratio == 0.562" | bc -l) )); then
        if ((ratio_916_max_resolution < width)); then
            tmp_height=$(echo "$ratio_916_max_resolution/$aspect_ratio" | bc)
            height=${tmp_height%.*}

            if ((height % 2 != 0)); then
                ((height--))
            fi

            scale="$ratio_916_max_resolution:$height"

        fi
    elif [ -n "$ratio_43_max_resolution" ] && (( $(echo "$aspect_ratio == 1.333" | bc -l) )); then
        if ((ratio_43_max_resolution < height)); then
            tmp_width=$(echo "$aspect_ratio*$ratio_43_max_resolution" | bc)
            width=${tmp_width%.*}

            if ((width % 2 != 0)); then
                ((width++))
            fi

            scale="$width:$ratio_43_max_resolution"
        fi
    elif [ -n "$ratio_34_max_resolution" ] && (( $(echo "$aspect_ratio == 0.75" | bc -l) )); then
        if ((ratio_34_max_resolution < width)); then
            tmp_height=$(echo "$ratio_34_max_resolution/$aspect_ratio" | bc)
            height=${tmp_height%.*}

            if ((height % 2 != 0)); then
                ((height--))
            fi

            scale="$ratio_34_max_resolution:$height"

        fi
    elif [ -n "$max_resolution" ]; then
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
    fi

    if [ -n "$scale" ]; then
        if [ -n "$options" ]; then
            options="$options"",scale=""$scale"
        else
            options="scale=""$scale"
        fi
    fi

    if [ -n "$options" ]; then
        options="-vf ""$options"
    fi

	# This is echo for testing
    echo ffmpeg -i "$filename" $options "$destination""/""$aspect_ratio_string""/formatted/""${filename##*/}"
	exit_code="$?"

    if [ $exit_code != 0 ]; then
        echo "Ffmpeg did not exit normally. Ffmpeg exit code: $exit_code"
        exit 1
    fi
    # Consider making here a delete from origin if the specific option is set, so no duplicates are created and only formatted files remain.
done

