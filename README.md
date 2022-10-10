# UNISOC_SPRD_PAC_UNPAC

紫光展锐展讯SPRD刷机包pac文件解包提取img文件。

Extract Images from .pac file from Spreadtrum Unisoc SPRD.

# 前置条件
1. pac文件 *1
2. ```Perl```环境

# 工具

展锐官方自带一套分别用Python和Perl实现的将各img打包为pac文件的工具，也实现了对应的解包工具。其中，```pac_tools/unpac_perl/unpac.pl```是```Perl```实现的解包工具，能将pac文件中的各img提取出来。

下载：[地址](https://github.com/NasdaqGodzilla/UNISOC_SPRD_PAC_UNPAC)（Clone源码或下载Release包）

# 使用

- 请根据系统权限机制确保unpac.pl具有执行权限
- 第一个参数为需要提取的pac文件
- 第二个参数为提取产物的存储路径

```
./pac_tools/unpac_perl/unpac.pl ROM/your_pac_file.pac pac_unpac_path/
```

## 添加-S参数加快提取

```unpac.pl```在提取之前会校验pac文件的完整性。它非常耗时，可以在命令的最后追加```-S```跳过CRC校验。

```
./pac_tools/unpac_perl/unpac.pl ROM/your_pac_file.pac pac_unpac_path/ -S
```

-  注意，-S参数必须放在最后面，不能放置️前两个参数之前

# Troubleshooting

在命令的最后添加参数```-D```要求```unpac.pl```打印调试信息。
