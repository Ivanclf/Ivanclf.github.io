---
title: 指令集和 Linux 杂记
date: 2024-11-16 19:51:38
tags: 速查
---

## latex的碎片化使用

### 希腊字母

需要大写的希腊字母时，首字母大写即可

|显示|命令|显示|命令|显示|命令|
|-|-|-|-|-|-|
|$\alpha$|`\alpha`|$\beta$|`\beta`|$\gamma$|`\gamma`|
|$\delta$|`\delta`|$\epsilon$|`\epsilon`|$\zeta$|`\zeta`|
|$\eta$|`\eta`|$\theta$|`\theta`|$\iota$|`\iota`|
|$\kappa$|`\kappa`|$\lambda$|`\lambda`|$\mu$|`\mu`|
|$\nu$|`\nu`|$\xi$|`\xi`|$\pi$|`\pi`|
|$\rho$|`\rho`|$\sigma$|`\sigma`|$\tau$|`\tau`|
|$\upsilon$|`\upsilon`|$\phi$|`\phi`|$\chi$|`\chi`|
|$\psi$|`\psi`|$\omega$|`\omega`|||

### 常见符号

|显示|命令|显示|命令|
|-|-|-|-|
|$^{a}$|`^{a}`|$_{a}$|`_{a}`|
|$\dot{x}$|`\dot{x}`|$\ddot{x}$|`\ddot{x}`|
|$\breve{x}$|`\breve{x}`|$\acute{x}$|`\acute{x}`|
|$\check{x}$|`\check{x}`|$\grave{x}$|`\grave{x}`|
|$\tilde{x}$|`\tilde{x}`|$\hat{x}$|`\hat{x}`|
|$\bar{x}$|`\bar{x}`|$\overline{x}$|`\overline{x}`|
|${x}\cdot{y}$|`{x}\cdot{y}`|${x}*{y}$|`{x}*{y}`|
|${x}\times{y}$|`{x}\times{y}`|||
|${x}\colon{y}$|`{x}\colon{y}`|${x}.{y}$|`{x}.{y}`|
|${x},{y}$|`{x},{y}`|${x}\over{y}$|`{x}\over{y}`|
|${x}\dotsm{y}$|`{x}\dotsm{y}`|${x}\dotso{y}$|`{x}\dotso{y}`|
|$\vec{xy}$|`\vec{xy}`|||
|$\widehat{xxx}$|`\widehat{xxx}`|$\widetilde{xxx}$|`\widetilde{xxx}`|
|$\neq$|`\neq`|$\leq$|`\leq`|
|$\geq$|`\geq`|$\pm$|`\pm`|
|$\approx$|`\approx`|$\equiv$|`\equiv`|
|$\vdots$|`\vdots`|$\ddots$|`\ddots`|
|$\cdots$|`\cdots`|||
|$\backslash$|`\backslash`|$\smallsetminus$|`\smallsetminus`|
|$\lbrace$|`\lbrace`|$\rbrace$|`\rbrace`|
|$\lgroup$|`\lgroup`|$\rgroup$|`\rgroup`|
|$\langle$|`\langle`|$\rangle$|`\rangle`|
|$\lmoustache$|`\lmoustache`|$\rmoustache$|`\rmoustache`|
|$\lVert$|`\lVert`|$\rVert$|`\rVert`|
|$\lvert$|`\lvert`|$\rvert$|`\rvert`|
|$\lfloor$|`\lfloor`|$\rfloor$|`\rfloor`|
|$\lceil$|`\lceil`|$\rceil$|`\rceil`|
|$\subseteq$|`\subseteq`|$\cap$|`\cap`|
|$\cup$|`\cup`|$\in$|`\in`|
|$\forall$|`\forall`|$\exists$|`\exists`|
|$\infty$|`\infty`|||

### 公式示例

|示例|命令|示例|命令|
|-|-|-|-|
|$\frac{n}{n-1}$|`\frac{n}{n-1}`|$\sqrt[n]{ab}$|`\sqrt[n]{ab}`|
|$\log_{a}{b}$|`\log_{a}{b}`|$\lg{ab}$|`\lg{ab}`|
|$\text{d}x$|`\text{d}x`|$\int_{a}^{b}$|`\int_{a}^{b}`|
|$\lim$|`\lim`|$\sum$|`\sum`|
|$\prod$|`\prod`|

### 辅助符号

|示例|命令|说明|
|-|-|-|
|$\displaystyle \sum$|`\displaystyle`|显示模式，适合于式子太小需要换行显示或加大的情况|
|$\boxed{E=mc^2}$|`\boxed{}`|在指定位置加方框|
|$\text{p=mv}$|`\text{}`|插入文本|
|$\overbrace{E=mc^2}^{\text{质量能量转换}}$|`\overbrace{}^{\text}`|指定上括号|
|$\underbrace{E=mc^2}_{\text{质量能量转换}}$|`\underbrace{}_{\text}`|指定下括号|
|$a\ b$|`\ `|空出一格|
|$a\quad b$|`\quad`|空出四格|
||`\\`|换行|

### 矩阵

`\begin{matrix} 1 & 5 \\\\ 4 & 6 \end{matrix}`

$$\begin{matrix} 1 & 5 \\\\ 4 & 6 \end{matrix}$$

花括号中的`matrix`可变化，由此给矩阵套上不同的括号(为`matrix`时没有括号)

`pmatrix`

$$\begin{pmatrix} 1 & 5 \\\\ 4 & 6 \end{pmatrix}$$

`bmatrix`

$$\begin{bmatrix} 1 & 5 \\\\ 4 & 6 \end{bmatrix}$$

`Bmatrix`

$$\begin{Bmatrix} 1 & 5 \\\\ 4 & 6 \end{Bmatrix}$$

`vmatrix`

$$\begin{vmatrix} 1 & 5 \\\\ 4 & 6 \end{vmatrix}$$

## vim指令

### 底线模式

在命令模式下输入 `:` 即可进入底线命令模式，用于执行文件相关操作。

|命令|说明|
|-|-|
|`:w`|保存文件|
|`:q`|退出|
|`wq`|保存并退出|
|`q!`|强制退出|

### 命令模式

[参考来源](https://www.runoob.com/linux/linux-vim.html)

刚启动Vim时，进入的就是命令模式

|命令|说明|
|-|-|
|`i`|进入输入模式|
|`x`|删除光标所在字符|
|`dd`|剪切当前行|
|`yy`|复制当前行|
|`p`|粘贴到光标下方|
|`u`|撤销|
|`Ctrl+r`|撤销上一次撤销|
|`o`|在当前上方插入新行|
|`O`|在当前下方插入新行|

![更详细的指令](vi-vim-cheat-sheet-sch.gif)

## Linux上的bash指令

学习 OS 和服务器维护需要，现列出部分指令

### 基础操作

|命令|说明|
|-|-|
|`ls`|显示该目录下的所有文件<br>`-a` 所有文件，包括隐藏文件<br>`-h` 人类可读的文件大小<br>`-t` 按时间排序|
|`ll`|`ls -l` 的别名，查看该目录下的所有目录和文件的详细信息|
|`cd`|打开该目录<br>`/` 表示根目录<br>`..` 表示上一级目录|
|`cp file1 file2`|将 file1 中的内容复制到 file2 中<br>`-i` 覆盖前提示确认|
|`mv file1 file2`|将 file1 中的内容移动到 file2 中|
|`rm`|删除文件<br>`-r` 表示递归删除文件夹下的所有文件<br>`-f` 表示强制删除文件|
|`find <path> <expression>`|在指定目录下寻找文件和目录<br>`-name` 文字名称过滤<br>`-type` 按类型过滤（如 `f` 文件，`d` 目录）<br>`-exec` 对找到的文件执行命令|
|`pwd`|显示当前工作目录的路径|
|`touch`|创建新文件或更新已存在文件的时间戳<br>`-a` 仅更改访问时间<br>`-m` 仅访问修改时间|
|`ln`|创建硬链接，软连接需要加参数 `-s`|
|`cat` `more` `less` `tail`|文件的查看<br>`cat` 为一次性输出。`-n` 显示行号，`-b` 显示非空行行号<br>`more` 为分页输出（只能向下分页）<br>`less` 分页输出（功能更丰富） `S` 禁用换行<br>`tail` 查看文件末尾的内容。`-n` 指定行数，`-f` 实时监控日志|
|`tar <input> <output>`|打包并压缩文件<br>`-z` 调用 gzip 压缩命令进行压缩<br>`-c` 打包文件，`-v` 显示运行过程<br>`-f` 指定文件名<br>`-x` 解压|
|`scp <input> <output>`|通过 SSH 协议传输<br>`p` 指定远程端口|
|`chmod <auth> <file>`|修改权限|
|`chown`|修改所有者或所属组|
|`top`|实时查看系统的 CPU 使用率、内存使用率、进程信息等|
|`htop`|相比 `top` 提供了友好的界面|
|`uptime`|查看系统运行事件和系统的平均负载|
|`vmstat`|显示虚拟内存状态，也可以报告关于进程、内存、I/O 等系统状态<br>`-a` 显示活动/非活动内存<br>`-s` 显示内存统计摘要|
|`free`| 查看系统的内存使用情况<br>`-h` 以人类可读单位显示<br>`-s` 仅显示统计，不显示子目录|
|`df`|查看系统的磁盘空间使用情况|
|`du`|查看指定目录或文件的磁盘空间使用情况|
|`sar <time> <repeat>`|收集、报告和分析系统的性能统计信息<br>`-u` 显示 CPU 使用率<br>`-r` 显示内存使用率<br>`-n` 网络统计|
|`systemctl <order> <name>`|管理系统的服务单元，查看系统服务的状态信息<br>`start` 启动服务<br>`stop`停止服务<br>`status` 查看服务状态|
|`netstat` `ss`|查看系统的网络连接状态和网络统计信息<br>`-t` 仅显示 TCP<br>`-u` 仅显示 UDP<br> `l` 显示端口|
|`grep <content> <filepath>`|根据指定的字符串或正则表达式在文件或命令输出中进行匹配查找<br>`-i` 忽略大小写<br>`-v` 反向匹配|
|`kill -9`|杀死进程|
|`useradd <name>`|创建账号|
|`userdel <name>`|删除账号|
|`passwd <name>`|设置用户的认证信息，包括认证密码，密码过期时间等<br>`-S` 显示账密<br>`-d` 删除用户密码，导致用户无法登录<br>无参时修改用户密码|
|`su <name>`|切换用户|
|`groupadd <user group>`|增加一个新用户组|
|`groupdel <user group>`|删除一个用户组|
|`groupmod <user group>`|修改一个用户组的属性|

{% note success %}
Linux 中打包文件一般是以 `.tar` 结尾的，压缩的命令一般是以 `.gz` 结尾的。而一般情况下打包和压缩是一起进行的。
{% endnote %}

{% note success %}
使用 `ll` 指令能看到文件的权限。文件的权限如下

![示意图](Linux权限解读-BGnXOuG0.png)

文件的类型栏中，`d` 代表目录，`-` 代表文件，`l` 代表软链接

属主指文件的创建者，属组指用户创建文件后该文件所在的组

{% endnote %}

{% note info %}
以下为一些具体应用
- `ps aux --sort=-%cpu | head -5` 查看 CPU 使用率最高的5个进程
- `watch -n 1 "netstat -an | grep ':8080' | grep ESTABLISHED | wc -l"` 统计 8080 端口每秒的请求数

{% endnote %}

### gcc

|命令|说明|
|-|-|
|`gcc example.c -o example`|编译C语言文件`example.c`，生成可执行文件`example`|

## Linux 文件

用户级别的环境变量存储在 `~/.bashrc` `~/.bash_profile`；系统级别的环境变量存储在`/etc/environment` `/etc/profile` `/etc/profile.d` `/etc/bashrc` 。可以通过`export` 或 `env` 命令输出当前系统定义的所有环境变量。

系统的日志文件存在 `/var/log/syslog` `/var/log/messages` 中。

使用 `useradd` 命令建立的常昊存在 `/etc/passwd` 文件中。对用户组的增删改查就是在 `/etc/group` 文件的更新。