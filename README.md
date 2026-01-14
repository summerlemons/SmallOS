# 从 0 到 1 实现一个精小操作系统

## 1. Makefile 构建
本项目使用 Makefile 构建，使用以下命令编译运行：
```bash
make bochs
```

## 2. bochsrc 配置文件的生成与配置
### 1. 创建 bochsrc 文件
我们使用 bochs 模拟一个 CPU 来运行我们写的 boot.o 里边的命令。首先使用如下命令创建 bochs 配置文件：
```bash
bochs -q
```
上面命令会进入 bochs 的交互式配置界面。
```bash
SmallOS on  main [!?] 
➜ bochs -q
========================================================================
                        Bochs x86 Emulator 2.7
              Built from SVN snapshot on August  1, 2021
                Timestamp: Sun Aug  1 10:07:00 CEST 2021
========================================================================
00000000000i[      ] BXSHARE not set. using compile time default '/usr/local/share/bochs'
00000000000e[      ] Switching off quick start, because no configuration file was found.
------------------------------
Bochs Configuration: Main Menu
------------------------------

This is the Bochs Configuration Interface, where you can describe the
machine that you want to simulate.  Bochs has already searched for a
configuration file (typically called bochsrc.txt) and loaded it if it
could be found.  When you are satisfied with the configuration, go
ahead and start the simulation.

You can also start bochs with the -q option to skip these menus.

1. Restore factory default configuration
2. Read options from...
3. Edit options
4. Save options to...
5. Restore the Bochs state from...
6. Begin simulation
7. Quit now

Please choose one: [2] 
```
这里我们选择 4 保存配置文件 ,然后回车，他会提示你输入配置文件的名字，配置文件名字叫做：`bochsrc`
```bash
Please choose one: [2] 4
Save configuration to what file?  To cancel, type 'none'.
[none] bochsrc
00000000000i[      ] write current configuration to bochsrc
Wrote configuration to 'bochsrc'.
------------------------------
Bochs Configuration: Main Menu
------------------------------

This is the Bochs Configuration Interface, where you can describe the
machine that you want to simulate.  Bochs has already searched for a
configuration file (typically called bochsrc.txt) and loaded it if it
could be found.  When you are satisfied with the configuration, go
ahead and start the simulation.

You can also start bochs with the -q option to skip these menus.

1. Restore factory default configuration
2. Read options from...
3. Edit options
4. Save options to...
5. Restore the Bochs state from...
6. Begin simulation
7. Quit now

Please choose one: [2] 7
00000000000i[SIM   ] quit_sim called with exit code 1
```
配置文件保存在根目录下 `bochsrc`。
### 2. 修改配置文件
我们打开 bochsrc 文件，修改如下内容：
1. 修改配置文件里边 `display_library` 选项，修改完后为 `display_library: x, options="gui_debug"`
2. 修改 `boot: floppy` 选项，修改为 `boot: disk`, 表示使用硬盘启动 (先前的 floppy 选项表示使用软盘启动)。
3. 复制创建硬盘的时候，输出的最后一行内容：
```bash
SmallOS on  main [!?] 
❯ bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat target/hd.img
========================================================================
                                bximage
  Disk Image Creation / Conversion / Resize and Commit Tool for Bochs
         $Id: bximage.cc 14091 2021-01-30 17:37:42Z sshwarts $
========================================================================

Creating hard disk image 'hd.img' with CHS=32/16/63 (sector size = 512)

The following line should appear in your bochsrc:
  ata0-master: type=disk, path="target/hd.img", mode=flat
```
即替换 `ata0-master` 字段，替换为：`ata0-master: type=disk, path="target/hd.img", mode=flat`。
4. 修改 `magic_break` 值，修改完后为： `magic_break: enabled=1`。表示开启断点调试功能。
