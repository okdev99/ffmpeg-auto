# ffmpeg-auto
A script that tries to automate option handling to ffmpeg using mediainfo.

Currently only supports framerate, resolution and some aspect ratio specific resolution options.
Script seems to work, but it has not been used much so it might be buggy.

Necessary programs:
- ffmpeg
- mediainfo
- bc

Program help blurp:
```
Usage: ffmpeg-auto [OPTION...]

  -h, --help                          show this help text
  -d, --destination                   select destination directory, default is current directory
  -o, --origin                        select origin directory, default is current directory
  -e, --erase                         erase the original file of the formatted files
  -m, --move                          move the unformatted files instead of copying them
      --max-framerate                 maximum framerate
      --min-framerate                 minimun framerate
      --max-resolution                maximum resolution
      --ratio-16:9-max-resolution     maximum resolution for only 16:9 ratio video
      --ratio-9:16-max-resolution     maximum resolution for only 9:16 ratio video
      --ratio-1-max-resolution        maximum resolution for only 1.0 ratio video
      --ratio-2-max-resolution        maximum resolution for only 2.0 ratio video
      --ratio-4:3-max-resolution      maximum resolution for only 4:3 ratio video
      --ratio-3:4-max-resolution      maximum resolution for only 3:4 ratio video
  -l, --loop                          target duration of formatted video in minutes, achieved by looping
  -r, --rename                        add a running number (x) to the end of the filename when there is already a file with the same name
      --overwrite                     overwrite the existing file if it has the same filename

If maximum resolution or framerate is exceeded then a new option is inlcuded that set the formatted video
to the maximum specified. The same happens with minimum framerate, but just the otherway.

Ratio specific maximum only apply if the input video has the specified aspect ratio and it is over the
maximum, otherwise if no specific ratio resolution options are set or the video just does not have the
correct aspect ratio, then the max-resolution value is used if it was set.

If destination folder has a file with the same as input file and there is no option given [--rename, --overwrite] then the program asks
user input whether to rename the input file or overwrite the file in destination folder.
```
