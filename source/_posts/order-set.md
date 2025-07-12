---
title: 指令集
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
|$\cup$|`\cup`|||
|$\infty$|`\infty`|

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

![更详细的指令](./order-set/vi-vim-cheat-sheet-sch.gif)

## Linux上的bash指令

学习OS需要，现列出部分指令

### 基础操作

|命令|说明|
|-|-|
|`ls`|显示该目录下的所有文件|
|`cd`|打开该目录|
|`cd /`|打开根目录下的文件|
|`cd ..`|打开上一级目录|
|`vi file` `vim example`|在当前目录下，用vim新建或打开某个文件|
|`cp file1 file2`|将file1中的内容复制到file2中|
|`rm file1 file2`|删除file1与file2|
|`rm -r dir`|删除dir文件夹下的所有文件|
|`rm -f file`|强行删除file|

### gcc

|命令|说明|
|-|-|
|`gcc example.c -o example`|编译C语言文件`example.c`，生成可执行文件`example`|