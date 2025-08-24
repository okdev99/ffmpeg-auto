# ATTENTION!
Script seems to work, but no actual testing has been done. Please do not use.

# ffmpeg-auto
A script that tries to automate option handling to ffmpeg using mediainfo.

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
      --max-framerate                 maximum framerate
      --min-framerate                 minimun framerate
      --max-resolution                maximum resolution
      --ratio-16:9-max-resolution     maximum resolution for only 16:9 ratio video
      --ratio-9:16-max-resolution     maximum resolution for only 9:16 ratio video
      --ratio-1-max-resolution        maximum resolution for only 1.0 ratio video
      --ratio-2-max-resolution        maximum resolution for only 2.0 ratio video

If maximum resolution or framerate is exceeded then a new option is inlcuded that set the formatted video
to the maximum specified. The same happens with minimum framerate, but just the otherway.

Ratio specific maximum only apply if the input video has the specified aspect ratio and it is over the
maximum, otherwise if no specific ratio resolution options are set or the video just does not have the
correct aspect ratio, then the max-resolution value is used if it was set.
```