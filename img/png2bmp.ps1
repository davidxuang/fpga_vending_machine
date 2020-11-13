foreach ($file in (Get-ChildItem *.png)) {
    ffmpeg -i ($file.FullName) -pix_fmt rgb444le ($file.BaseName + '.bmp')
}