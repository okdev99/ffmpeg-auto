#!/usr/bin/env bash


# TODO:
# 1. when ffmpeg asks to overwrite a file, if the given answer is no, then do not crash the program, but skip that file and move on to the next item on the list
# 1.1 better yet, make a new filename for the formatted file
#
# It would be better to incorporate these different mediainfo calls into a single call
# 1. is it possible to use multiple inform options on a single call
# 2. figure a way to use these calls: if it comes back as a single string -> split by rule, into array


shopt -s extglob

showHelp() {
    # also include a tip for using the program. Like recommended to only use etc.
    echo "Usage: $0 [OPTION...]"
    echo
    echo "  -h, --help                          show this help text"
    echo "  -d, --destination                   select destination directory, default is current directory"
    echo "  -o, --origin                        select origin directory, default is current directory"
    echo "  -e, --erase                         erase the original file of the formatted files"
    echo "  -m, --move                          move the unformatted files instead of copying them"
    echo "      --max-framerate                 maximum framerate"
    echo "      --min-framerate                 minimun framerate"
    echo "      --max-resolution                maximum resolution"
    echo "      --ratio-16:9-max-resolution     maximum resolution for only 16:9 ratio video"
    echo "      --ratio-9:16-max-resolution     maximum resolution for only 9:16 ratio video"
    echo "      --ratio-1-max-resolution        maximum resolution for only 1.0 ratio video"
    echo "      --ratio-2-max-resolution        maximum resolution for only 2.0 ratio video"
    echo "      --ratio-4:3-max-resolution      maximum resolution for only 4:3 ratio video"
    echo "      --ratio-3:4-max-resolution      maximum resolution for only 3:4 ratio video"
	echo "  -l, --loop                          target duration of formatted video in minutes, achieved by looping"
	echo "  -r, --rename                        add a running number (x) to the end of the filename when there is already a file with the same name"
	echo "      --overwrite                     overwrite the existing file if it has the same filename"
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
    tmp_aspect_ratio_string=$(mediainfo --Inform="Video;%DisplayAspectRatio/String%" "$1")
    echo "${tmp_aspect_ratio_string/":"/"-"}"
}

getWidth() {
    mediainfo --Inform="Video;%Width%" "$1"
}

getHeight() {
    mediainfo --Inform="Video;%Height%" "$1"
}

getFramerate() {
    # FrameRate -> string ex. "60.000"
    # FrameRate_Num -> number ex. 60
    mediainfo --Inform="Video;%FrameRate_Num%" "$1"
}

getBitrate() {
	mediainfo --inform="Video;%BitRate%" "$1"
}

getDuration() {
	milliseconds=$(mediainfo --inform="Video;%Duration%" "$1")
	seconds=$((milliseconds/1000))
	echo "$seconds"
}

runningNumberGenerator() {
	filename="$1"
	# regular expression matching *whitespaces(<numerics>).<alphanumerics>
	re="^.*\s+\([0-9]+\)\.[A-Za-z0-9]+$"
	while [[ -f $filename ]]; do
		without_ext="${filename%.*}"
		ext="${filename##*.}"
		if [[ $filename =~  $re ]]; then
			# this following sequence only works on strings that have *([0-9]).*
			# luckily this blocks conditional regex makes sure it has it :3
			TMP="${filename##*\(}"
			running_number="${TMP%%\)*}"
			((running_number++))
			filename="${filename%\ \(+([0-9])\).*}" # remove the running number and file ext
			filename="$filename"" (""$running_number"").""$ext"
		else
			filename="$without_ext"" (1).""$ext"
		fi
	done
	echo "$filename"
}


ffmpeg_supported_extensions=("str" "aa" "aac" "aax" "ac3" "acm" "adf" "adp" "dtk" "ads" "ss2" "adx" "aea" "afc" "aix" "al" "ape" "apl" "mac" "aptx" "aptxhd" "aqt" "ast" "obu" "avi" "avr" "avs" "avs2" "avs3" "bfstm" "bcstm" "binka" "bit" "bitpacked" "bmv" "brstm" "cdg" "cdxl" "xl" "c2" "302" "daud" "dfpwm" "dav" "dss" "dts" "dtshd" "dv" "dif" "cdata" "eac3" "paf" "fap" "flm" "flac" "flv" "fsb" "fwse" "g722" "722" "tco" "rco" "g723_1" "g729" "genh" "gsm" "h261" "h26l" "h264" "264" "avc" "hca" "hevc" "h265" "265" "idf" "ifv" "cgi" "ipu" "sf" "ircam" "ivr" "kux" "669" "amf" "ams" "dbm" "digi" "dmf" "dsm" "dtm" "far" "gdm" "ice" "imf" "it" "j2b" "m15" "mdl" "med" "mmcmp" "mms" "mo3" "mod" "mptm" "mt2" "mtm" "nst" "okt" "plm" "ppm" "psm" "pt36" "sptm" "s3m" "sfx" "sfx2" "st26" "stk" "stm" "stp" "ult" "umx" "wow" "xm" "xpk" "dat" "lvf" "m4v" "mkv" "mk3d" "mka" "mks" "webm" "mca" "mcc" "mjpg" "mjpeg" "mpo" "j2k" "mlp" "mods" "moflex" "mov" "mp4" "m4a" "3gp" "3g2" "mj2" "psp" "m4b" "ism" "ismv" "isma" "f4v" "avif" "mp2" "mp3" "m2a" "mpa" "mpc" "mpl2" "sub" "msf" "mtaf" "ul" "musx" "mvi" "mxg" "v" "nist" "sph" "nsp" "nut" "ogg" "oma" "omg" "aa3" "pjs" "pvf" "yuv" "cif" "qcif" "rgb" "rt" "rsd" "rsd" "rso" "sw" "sb" "smi" "sami" "sbc" "msbc" "sbg" "scc" "sdr2" "sds" "sdx" "ser" "sga" "shn" "vb" "son" "imx" "sln" "stl" "sub" "sub" "sup" "svag" "svs" "tak" "thd" "tta" "ans" "art" "asc" "diz" "ice" "nfo" "vt" "ty" "ty+" "uw" "ub" "v210" "yuv10" "vag" "vc1" "rcv" "viv" "idx" "vpk" "vqf" "vql" "vqe" "vtt" "wsd" "xmv" "xvag" "yop" "y4m" "wav")

erase_original=false
move=false
origin="."
destination="."
rename=false
overwrite=false

if [ -z "$1" ]; then
    showHelp
    exit 0
fi

TEMP=$(getopt --options hemd:o:l:r --longoptions help,erase,move,destination:,origin:,max-framerate:,min-framerate:,max-resolution:,ratio-16:9-max-resolution:,ratio-9:16-max-resolution:,ratio-1-max-resolution:,ratio-2-max-resolution:,loop:,rename,overwrite -n 'ffmpeg-auto' -- "$@")

exit_code=$?

if [ $exit_code != 0 ]; then
    echo -e "\e[31mGetopt failed. Terminating.\e[0m" >&2;
    exit 1
fi

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

# Add options for:
# - determining if a user wants to delete the original file
# - if user wants to move the non-formatted files instead of copying them
# - crf either implement this with just using certain crf value or/and aim for some specific bit rate
# - custom ratios, see above for ideas

while true; do
  case $1 in
    -h | --help)
        showHelp
        exit 0
        ;;
    -e | --erase)
        erase_original=true
        shift 1
        ;;
    -m | --move)
        move=true
        shift 1
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
	-l | --loop)
		loop_target=$((60*$2))
		shift 2
		;;
	-r | --rename)
		rename=true
		shift 1
		;;
	--overwrite)
		overwrite=true
		shift 1
		;;
    --) shift
        break
        ;;
    * ) break
        ;;
  esac
done

if [ -z "$max_framerate" ] && [ -z "$min_framerate" ] && [ -z "$max_resolution" ] && [ -z "$ratio_1_max_resolution" ] && [ -z "$ratio_2_max_resolution" ] && [ -z "$ratio_169_max_resolution" ] && [ -z "$ratio_916_max_resolution" ] && [ -z "$ratio_43_max_resolution" ] && [ -z "$ratio_34_max_resolution" ] && [ -z "$loop_target" ]; then
    echo -e "\e[1;33mNo options given!\e[0m" >&2
    exit 1
fi

if [ -n "$max_framerate" ] && [ -n "$min_framerate" ] && ((max_framerate < min_framerate)); then
    echo -e "\e[1;33mMin framerate cannot be higher than max framerate!\e[0m" >&2
    exit 1
fi

if [ "$rename" == true ] && [ "$overwrite" == true ]; then
	echo -e "\e[1;33mRename and overwrite options cannot be used at the same time!\e[0m" >&2
	exit 1
fi

if [ ! "${origin:0-1}" == "/" ]; then
    origin="$origin""/*"
else
    origin="$origin""*"
fi

for filename in $origin; do

	# check if directory has any files
	if [ "$filename" == "$origin" ]; then
		echo -e "\e[1;33mOrigin directory is empty!\e[0m" >&2
		exit 1
	fi

    # check if filename has the correct extension and if not then just skip it
    if ! echo "${ffmpeg_supported_extensions[@]}" | grep -qw "${filename##*.}"; then
		continue
	fi

    unset scale
    unset out_options
	unset in_options

    aspect_ratio_string=$(getDisplayAspectRatioString "$filename")

    aspect_ratio=$(echo "$(getDisplayAspectRatio "$filename")" | bc) # I know this is technically wrong, but it works like this and otherwise fails. I have no idea why.

    width=$(getWidth "$filename")

    height=$(getHeight "$filename")

    framerate=$(getFramerate "$filename")

	duration=$(getDuration "$filename")

    if [ ! -d "$destination""/""$aspect_ratio_string" ]; then
        mkdir -p "$destination""/""$aspect_ratio_string""/formatted"
        exit_code1="$?"
        mkdir -p "$destination""/""$aspect_ratio_string""/not_formatted"
        exit_code2="$?"

        if [ $exit_code1 != 0 ] || [ $exit_code2 != 0 ]; then
            echo -e "\e[31mCreation of directories did not work!\e[0m"" First mkdir exit code: $exit_code1, second $exit_code2" >&2
            exit 1
        fi
    fi

    # Determine the necessary options for the video

	# OUT OPTIONS

    if [ -n "$max_framerate" ] && ((max_framerate < framerate)); then
        out_options="fps=""$max_framerate"
    elif [ -n "$min_framerate" ] && ((min_framerate > framerate)); then
        out_options="fps=""$min_framerate"
    fi

    # Check here for different ratio options and if they fail move to max_resolution
	# bc is used here, because aspect_ratio uses has a string with a decimal, like 1.000, so bc has to be used since normal bash doesn't parse it correctly
    if [ -n "$ratio_1_max_resolution" ] && (( $(echo "$aspect_ratio == 1" | bc -l) )); then
        if ((ratio_1_max_resolution < width)); then
            tmp_width="$ratio_1_max_resolution"
            width=${tmp_width%.*}

            if ((width % 2 != 0)); then
                ((width++))
            fi
            scale="$width:$width"
        fi
    elif [ -n "$ratio_2_max_resolution" ] && (( $(echo "$aspect_ratio == 2" | bc -l) )); then
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
        if [ -n "$out_options" ]; then
            out_options="$out_options"",scale=""$scale"
        else
            out_options="scale=""$scale"
        fi
    fi

	# IN OPTIONS

	if [ -n "$loop_target" ] && ((duration < loop_target)); then
		loop=$((loop_target/duration))
		in_options="-stream_loop $loop"
	fi

	# FORMATTING

    if [ -n "$out_options" ]; then
        out_options="-vf ""$out_options"
    elif [ -z "$in_options" ]; then
		output_filename=$( runningNumberGenerator "$destination""/""$aspect_ratio_string""/not_formatted/""${filename##*/}" )

        if [ "$move" = true ]; then
            mv "$filename" "$output_filename"
            exit_code="$?"

            if [ $exit_code != 0 ]; then
                echo -e "\e[31mMove (mv) did not exit normally!\e[0m"" Move exit code: $exit_code" >&2
                exit 1
            fi
        else
            cp "$filename" "$output_filename"
            exit_code="$?"

            if [ $exit_code != 0 ]; then
                echo -e "\e[31mCopy (cp) did not exit normally!\e[0m"" Copy exit code: $exit_code" >&2
                exit 1
            fi
        fi

		echo -e "\e[32mThe file '${filename##*/}' does not need formatting. Skipping.\e[0m"
        continue
    fi


	# IF OUTPUT FILE ALREADY EXISTS, ASK EITHER TO RENAME OR OVERWRITE
	# IF OVERWRITE THEN USE -y option
	# IF RENAME USE running_number_generator FUNCTION AND USE -n OPTIONS

	output_filename="$destination""/""$aspect_ratio_string""/formatted/""${filename##*/}"
	if [[ -f $output_filename ]]; then
		if [[ $rename == true ]]; then
			output_filename=$( runningNumberGenerator "$output_filename" )
			if [[ -n $in_options ]]; then
				in_options="$in_options"" -n"
			else
				in_options="-n"
			fi
		elif [[ $overwrite == true ]]; then
			if [[ -n $in_options ]]; then
				in_options="$in_options"" -y"
			else
				in_options="-y"
			fi
		else
			echo -e "\e[1;33mFile with the same name already exists in destination folder!\e[0m"
			while true; do
				read -rp "Either rename it or overwrite it (rename/overwrite): " input
				input=${input@L} # makes string all lowercase
				if [[ $input == "rename" ]] || [[ $input == "r" ]]; then
					output_filename=$( runningNumberGenerator "$output_filename" )
					if [[ -n $in_options ]]; then
						in_options="$in_options"" -n"
					else
						in_options="-n"
					fi
					break
				elif [[ $input == "overwrite" ]] || [[ $input == "o" ]]; then
					if [[ -n $in_options ]]; then
						in_options="$in_options"" -y"
					else
						in_options="-y"
					fi
					break
				fi
			done
		fi
	fi


    ffmpeg $in_options -i "$filename" $out_options "$output_filename" #output_filename
	exit_code="$?"

    if [ $exit_code != 0 ]; then
        echo -e "\e[31mFfmpeg did not exit normally!\e[0m"" Ffmpeg exit code: $exit_code" >&2
        exit 1
    fi

    if [ "$erase_original" = true ]; then
        rm "$filename"
        exit_code="$?"

        if [ $exit_code != 0 ]; then
            echo -e "\e[31mRemove did not exit normally!\e[0m"" rm exit code: $exit_code" >&2
            exit 1
        fi
    fi
done

