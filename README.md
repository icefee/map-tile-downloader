# map-tile-downloader
a console application for download baidu map tile
用于下载百度地图贴图的命令行工具

# 编译
运行 dart compile 来编译成可执行文件

#调用
bin.exe <左上角的经纬度> <右下角的经纬度> <缩放范围> <地图类型> -thread=<线程数>
调用举例: tile.exe 120.32338749495037,31.459797398558216 120.42227296548874,31.514240051697797 1,19 normal,sate,mix -thread=20
