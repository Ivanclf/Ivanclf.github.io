---
title: 操作系统额外内容 - 基本 TCP 套接字编程
date: 2026-03-16 13:47:06
tags: [日常,碎片知识]
category: OS
---

参考书籍：UNIX网络编程卷1：套接字联网API（第3版）

参考文献
- [https://zhuanlan.zhihu.com/p/367591714](https://zhuanlan.zhihu.com/p/367591714)
- [https://www.bilibili.com/video/BV1qJ411w7du](https://www.bilibili.com/video/BV1qJ411w7du)

## 基本 TCP 套接字编程

![基本 TCP 客户端/服务器常用函数](socket-function.png)

### `sockaddr` 结构体

往下的 `sockaddr` 为一个通用的地址结构体，为多种通信域提供一个统一的接口。我们一般使用它的"子类"。它的内容为

```c
struct sockaddr {
    sa_family_t sa_family;  // 地址族（如 AF_INET、AF_UNIX、AF_INET6）
    char        sa_data[14];// 存放具体的地址数据（IP+端口/本地路径等），长度14字节
};
```

IPv4 专用的“子类”为

```c
struct sockaddr_in {
    sa_family_t    sin_family;   // 必须设为 AF_INET（IPv4 地址族）
    in_port_t      sin_port;     // 端口号（网络字节序，2字节）
    struct in_addr sin_addr;     // IPv4 地址（4字节）
    unsigned char  sin_zero[8];  // 填充字节，使整体大小和 sockaddr 一致（8+8=16字节）
};

// 嵌套的 in_addr 结构体（存放 IPv4 地址）
struct in_addr {
    in_addr_t s_addr;  // IPv4 地址（32位无符号整数，网络字节序）
};
```

`sin_zero` 一般直接 `memset()` 置0即可。

IPv6 则使用 `sockaddr_in6`，本地 Unix 域通信则为 `sockaddr_un`。

网络字节序是大端序，但主机的字节则可能是大端序或小端序。因此必须通过函数转换（`htons` 转端口，`htonl` 转 IP）而不能直接赋值。直接赋值可能导致通信失败。

### `socket`

为了执行网络 IO，一个进程必须要做的第一件事就是调用 socket 函数，指定期望的通信协议类型。它为所有 UNIX 客户端/服务端创建网络通信的端点。但它仅创建端点，需要配合其他函数才能完成完整的通信流程。

```c
#include<sys/socket.h>
int socket (
    int family, // 协议簇，也叫协议域
    int type, // 套接字类型
    int protocol // 某个协议类型常值
);
```

|`family`|说明|
|-|-|
|`AF_INET`|IPv4 协议|
|`AF_INET6`|IPv6 协议|
|`AF_LOCAL`|Unix 域协议|
|`AF_ROUTE`|路由套接字|

|`type`|说明|
|-|-|
|`SOCK_STREAM`|TCP 传输|
|`SOCK_DGRAM`|UDP 传输|
|`SOCK_RAW`|原始套接字|

当 `type` 为 `SOCK_RAW` 时，`protocol` 常值需要填写常值。其余时候填0。

|`AF_INET`/`AF_INET6` 的 `protocol` 常值|说明|
|-|-|
|`IPPROTO_TCP`|TCP|
|`IPPROTO_UDP`|UDP|
|`IPPROTO_SCTP`|SCTP|
|`IPPROTO_ICMP`|ICMP|

若成功，则为非负描述符，和文件描述符类似，成为套接字描述符；若出错，则为-1。

`AF_` 前缀表示地址结构体，`PF_` 前缀表示创建套接字，二者如今已经没什么区别。

### `connect`

该函数用于建立与 TCP 服务器的连接。

```c
#include<sys/socket.h>
int connect (
    int sockfd, // socket 函数返回的套接字描述符
    const struct sockaddr *sockaddr, // 套接字地址结构的指针
    socklen_t addrlen // 该结构的大小
);
```

函数若成功则返回0；出错则返回-1。

客户端在调用 connect 函数前不一定需要调用 bind 函数，因为内核会确定源 IP 地址并选择一个临时端口作为源端口。如果是 TCP，该函数将激发 [TCP 的三次握手过程](https://ivanclf.github.io/2025/11/15/networking-3/#%E5%BB%BA%E7%AB%8B%E9%93%BE%E6%8E%A5)，并且在建立成功或出错后才返回。
1. 若 TCP 客户没有收到 SYN 报文段的回应，则在一定时间后重发。重发一定次数后仍未回应，则返回 `ETIMEDOUT` 错误。
2. 若对 SYN 的响应是 RST （复位），则表明服务器主机在我们指定的端口上没有进程，则立即返回 `ECONNREFUSED` 错误。
3. SYN 在某个路由器上引发了一个 destination unreachable 这种 ICMP 错误，若是硬错误则快速失败，软错误则客户主机内核保存该信息，并在和第一种情况相同的时间间隔下重发。若仍是这种情况则返回 `EHOSTUNREACH` (主机不可达) 或 `ENETUNREACH` (网络不可达) 错误。

该函数会导致当前 socket 从 CLOSED 状态转为 SYN_SENT 状态，若成功则转为 ESTABLISHED 状态，失败则转为 CLOSED 状态。失败时最好先 close 当前的套接字描述符并重新调用 socket，因为在早期的 BSD 系统中只能这么做。但在现代 Linux 系统中，失败后重新调用该函数即可。

### `bind`

该函数将本地协议地址绑定到套接字描述符 `sockfd`。

```c
#include<sys/socket.h>
int bind (
    int sockfd, // socket 函数返回的套接字描述符
    const struct sockaddr *myaddr, // 指向特定于协议的地址结构的指针
    socklen_t addrlen // 该地址结构的长度
);
```

成功返回0，失败返回-1。

使用该函数，可以指定一个端口号，可以指定一个 IP 地址，也可以两个都不指定。服务端不指定时，listen 函数调用后，内核会为其自动给一个通配 IP + 临时端口。但一般不这么做，因为服务器一般是通过一个知名端口来被访问的。

服务端一般指定端口 + `0.0.0.0` IP （使用 `INADDR_ANY` 表示）。

### `listen`

该函数仅由 TCP 服务器调用，主要做两件事情：
1. socket 函数默认是主动套接字（用于发起链接），调用 listen 后转换成被动套接字（只能接收链接），指示内核监听并接受指向该套接字的连接请求。调用该函数会使得套接字从 closed 状态转为 listen 状态。
    {% note info %}
    主动套接字仅能调用 `connect()` 发起连接；被动套接字仅能通过 `accept()` 接受连接。
    {% endnote %}
2. 设置内核为该套接字维护的连接队列最大长度：


```c
#include<sys/socket.h>
int listen (
    int sockfd, // socket 函数返回的套接字描述符
    int backlog
);
```

`backlog` 参数在早期 BSD 系统中是所有队列的总上限，常用值为 5/10，而在现代系统中一般是“已完成连接队列”的上限，常用值 128/256。

成功时返回0，失败时返回-1。

{% note info %}
**未完成连接队列** 指客户端发送 SYN 后，三路握手未完成的连接。这些套接字处于 SYN_RCVD 状态。
**已完成连接队列** 三路握手完成，等待 `accept` 取走的链接。这些套接字处于 ESTABLISHED 状态。
{% endnote %}

当来自客户的 SYN 到达时，若未完成队列未满，则 TCP 在未完成连接队列中创建一个新项，然后进行三路握手中的回应。当三路握手中的第三次到达后，该项就从未完成连接队列移到已完成连接队列的末尾。当进程调用 accept 时，已完成连接队列中的队头项将返回给进程。

### `accept`

该函数由 TCP 服务器调用，用于从已完成连接队列队头返回下一个已完成连接。若此队列为空则进程被投入睡眠。

```c
#include <sys/socket.h>
int accept (
    int sockfd,
    struct sockaddr *cliaddr,
    socklen_t *addrlen
);
```

第一个参数需要始终处于 listen 状态，不会随着客户端关闭而关闭。

第二个参数是输出型参数，函数返回时，内核会把发起连接的客户端的 IP 地址、端口等信息填充到这个结构体中。若不需要这个地址，可传 `null`，但此时的第三个参数也要填 `null`。

第三个参数输入输出都要用，输入时，告诉内核 `*cliaddr` 这个结构体的大小；输出时，内核返回实际填充的地址结构体长度。

若该函数执行成功，其返回值就是有内核自动生成的一个全新描述符，代表与所返回客户的 TCP 链接。第一个叫做**监听套接字**，返回值为**已连接套接字**。当服务器完成对某个给定客户的服务时，相应的已连接套接字就被关闭。错误时返回-1。

{% note info %}
该函数的第三个参数称为 **值-结果参数**。该概念指某个参数是“双向的”，既能给函数传值，又能从函数拿结果。内核设计这个机制，核心是解决缓冲区大小不固定的问题。网络编程中，地址结构体有很多种，内核又不知道你给这个函数的结构体是什么，所以需要先手动指定。内核写完后，需要告知“实际写了多少”，避免其他程序读取超出实际数据长度的内容。
{% endnote %}

### `close`

关闭一个 socket。更深入一点，该函数调用后，会将套接字描述符的引用次数减1。当且仅当引用次数为0时，才会触发 TCP 的四次挥手（发送 FIN 报文段）。

因此该函数执行后，并不一定会关闭链接。

```c
#include<unistd.h>
int close (int sockfd);
```

成功返回0，出错返回-1。

### `getsockname` 和 `getpeername` 函数

这两个函数返回和某个套接字关联的本地协议地址，或者和某个套接字关联的对端协议地址。

`getsockname()` 函数用于字客户端未调用 `bind` 时，获取内核自动分配的临时端口；服务器绑定通配 IP 时，获取实际接受连接的网卡 IP。也就是**本地绑定**的 IP + 端口。

`getpeername()` 函数用于服务端需要直到连接的客户端 IP/端口；进程通过 `fork`/`exec` 后，获取对端地址。也就是**对端**的IP + 端口。

```c
#include<sys/socket.h>
int getsockname(int sockfd, struct sockaddr *localaddr, socklen_t *addrlen);
int getpeername(int sockfd, struct sockaddr *peeraddr, socklen_t *addrlen);
```

成功则返回0，失败返回-1。这两个函数的最后一个参数都是值-结果参数。

## 程序示例

在该示例中，我们将实现一个简单的回射服务器，其数据流向如下：

![简单的回射客户/服务器](example1.png)

### 服务器程序：`main`

```c
#include    "unp.h"

int
main(int argc, char **argv)
{
    int     listenfd, connfd;
    pid_t   childpid;
    socklen_t clilen;
    struct sockaddr_in cliaddr, servaddr;

    listenfd = Socket(AF_INET, SOCK_STREAM, 0);

    bzero(&servaddr, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    servaddr.sin_port = htons(SERV_PORT);

    Bind(listenfd, (SA *) &servaddr, sizeof(servaddr));

    Listen(listenfd, LISTENQ);

    for ( ; ; ) {
        clilen = sizeof(cliaddr);
        connfd = Accept(listenfd, (SA *) &cliaddr, &clilen);

        if ( (childpid = Fork()) == 0) {    /* 子进程 */
            Close(listenfd);    /* 关闭监听状态下的 socket */
            str_echo(connfd);   /* 处理请求 */
            exit(0);
        }
        Close(connfd);          /* 父进程关闭 socket */
    }
}
```

首先通过 `socket`、`bind`、`listen` 方法创建一个监听套接字 `listenfd`，该套接字始终由父进程持有，用于持续接受新连接。

`fork` 后，子进程会复制父进程的所有 FD。
- 操作后，父进程持有 `listenfd` (引用次数 = 1)、`connfd`（引用次数 = 1）；子进程持有 `listenfd`（引用次数 = 2），`connfd`（引用次数 = 2）。
- 子进程 `Close` 后，销毁自己的 `listenfd` 引用，引用次数从2到1。
- 父进程 `Close` 后，销毁自己的 `connfd` 引用，引用次数从2到1。
- 子进程 `str_echo` 执行函数，完成后 `exit(0)`。
- 子进程退出时，内核自动关闭其持有的所有 FD，`connfd` 从1到0，该 TCP 开始四次挥手。


### 服务器程序：`str_echo`

```c
#include    "unp.h"

void
str_echo(int sockfd)
{
    ssize_t n;
    char    buf[MAXLINE]; // MAXLINE：UNP 宏，默认 4096 字节

again:
    while ((n = read(sockfd, buf, MAXLINE)) > 0)
        Writen(sockfd, buf, n);

    if (n < 0 && errno == EINTR)
        goto again;
    else if (n < 0)
        err_sys("str_echo: read error");
}
```

其中，`read` 函数表示从传入的已连接套接字 `sockfd` 中读取最多 `MAXLINE` 字节的数据缓冲区中，返回实际读取的字节数 `n`。然后再 `writen` 写回去。

### 客户端程序

`main` 函数：

```c
#include    "unp.h"

int
main(int argc, char **argv)
{
    int                 sockfd;
    struct sockaddr_in  servaddr;

    if (argc != 2)
        err_quit("usage: tcpcli <IPaddress>");

    sockfd = Socket(AF_INET, SOCK_STREAM, 0);

    bzero(&servaddr, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(SERV_PORT);
    Inet_pton(AF_INET, argv[1], &servaddr.sin_addr);

    Connect(sockfd, (SA *) &servaddr, sizeof(servaddr)); // SA 是 UNP 宏，替换 struct sockaddr

    str_cli(stdin, sockfd);    /* 全干了 */

    exit(0);
}
```

此处没有循环不代表客服端只发一条消息，因为 `str_cli` 函数包含循环，在此处会将用户输入逐行发送给服务器。

`str_cli` 函数

```c
#include    "unp.h"

void
str_cli(FILE *fp, int sockfd)
{
    char    sendline[MAXLINE], recvline[MAXLINE];

    while (Fgets(sendline, MAXLINE, fp) != NULL) {

        Writen(sockfd, sendline, strlen(sendline));

        if (Readline(sockfd, recvline, MAXLINE) == 0)
            err_quit("str_cli: server terminated prematurely");

        Fputs(recvline, stdout);
    }
}
```

### 处理 `SIGCHLD` 信号

然而这个简单的实现存在一个问题：在服务器子进程终止时，会给父进程发送一个 `SIGCHLD` 信号。然而，父进程没有捕获这一信号，子进程进入**僵死**(zombie) 状态。该状态下的子进程会占用内核资源。

要解决这个问题，核心是让父进程捕获该信号，并再信号处理函数中调用 `waitpid()` 回收所有终止的子进程。

#### `wait` 和 `waitpid`

```c
pid_t wait (int *statloc);
pid_t waitpid (pid_t pid, int *statloc, int options);
```

这两个函数均用于在等待某个子进程停止后回收资源并返回其 pid。这两个函数均返回两个值：出参返回的是已终止子进程的 pid 号，以及通过 `statloc` 指针返回的子进程终止状态，为一个整数。这个整数辨别子进程是正常终止、由某个进程杀死还是由作业控制停止。

`waitpid` 的 `pid` 参数的取值范围如下

|`pid`|说明|
|-|-|
|`pid > 0`|等待的 pid 等于该值的子进程|
|`pid = 0`|等待与当前进程同组的子进程|
|`pid = -1`|等待任意子进程|
|`pid < -1`|等待组 id 等于 pid 绝对值的任意子进程|

`option` 参数有以下几种：

|`option`|说明|
|-|-|
|`WNOHANG`|非阻塞模式，若子进程未终止，直接返回0，不阻塞|
|`WUNTRACED`|除了终止的子进程，还会返回被暂停（如信号 `SIGSTOP`）的子进程的状态|
|`WCONTINUED`|返回因收到 `SIGCONT` 信号恢复运行的子进程状态，需结合信号使用|

二者的差别如下

|特性|`wait`|`waitpid`|
|-|-|-|
|等待范围|任意子进程|可指定特定 pid/进程组的子进程|
|阻塞行为|始终阻塞，直到有进程组终止|可实现非阻塞|
|返回值|终止子进程的 pid，若无子进程则返回-1|终止子进程的 pid，非阻塞无终止进程返回0，出错返回-1|
|灵活性|仅能等任意子进程|可筛选、非阻塞、监控暂停/恢复状态|

`wait` 只能等待简单场景，但 `waitpid` 适用于需要等待特定子进程，非阻塞，需要监控状态等场景。

#### 信号处理函数

```c
void sig_chld(int signo)
{
    pid_t pid;
    int stat;
    // WNOHANG：非阻塞模式，回收所有已终止的子进程，不阻塞等待
    while ((pid = waitpid(-1, &stat, WNOHANG)) > 0) {
        printf("child %d terminated\n", pid);
    }
    return;
}
```

同时在主函数的适当地方（循环外，初始化过程中），使用 `signal` 函数注册 `SIGCHLD` 信号处理函数。

```c
Signal(SIGCHLD, sig_chld);
```

### `accept` 返回前链接终止

三次握手完成，链接建立后，客户端发了一个 RST。在服务端视角来看，就是在该链接已经在全连接队列里，等着服务器调用 `accept` 时 RST 到达。也就是说，此时客户端主动终止连接，内核中该链接会被清理。当服务器后续调用 `accept` 时，由于该连接握手未完成就被重置，内核会返回 `ECONNABORTED` 错误。

解决方案也很简单，在 `accept` 处增加错误判断，若捕获到这个报错就直接跳过本次，重新 `accept` 即可。

### 服务器进程直接终止

客户端一直阻塞在 `while(Fgets(...))` 循环中，等待用户信息。然而此时服务器被直接 `kill -9` 了，没有主动调用 `close(sockfd)`，此时客户端就一直被卡在了等待信息这一栏。

原因是“服务器挂了”是网络层的事，但 `fgets` 是本地输入层的事，二者默认互不干扰。

其全过程如下

|阶段|服务器端|客户端端|关键说明|
|-|-|-|-|
|初始状态|服务器正常运行，和客户端已建立 TCP 连接|客户端执行到 `str_cli` 的 `Fgets` 行，阻塞等待用户从键盘输入|此时客户端的阻塞是正常的———它本来就该等用户输入，和服务器无关|
|服务器被终止|管理员执行 `kill -9` 服务器 PID，服务器进程直接被内核终止；内核清理服务器的套接字资源，给客户端发送 RST 包|客户端内核收到 FIN 包，标记客户端的 sockfd 为 “连接重置” 状态；但客户端进程还卡在 `Fgets` 处，完全没感知到这个变化|客户端进程的执行流还没走到 “网络操作”（读 / 写 sockfd），所以不知道连接已断|
|客户端持续阻塞|服务器已彻底退出，TCP 连接已失效|客户端依然阻塞在 `Fgets`，直到用户主动输入内容 / 按 `Ctrl+D`；|`Fgets` 只关心键盘，不管网络 —— 哪怕连接断了，只要用户不输入，就一直堵着|
|（补充）用户输入后才会发现异常|-|用户终于输入一行内容并回车，`Fgets` 返回，客户端执行 Writen 向 sockfd 写数据；此时客户端内核发现 sockfd 已被重置，服务器内核收到数据后回复 RST，第二次写时触发 `EPIPE` 错误（Broken pipe）|只有当客户端尝试写网络时，才会发现 “连接已断”—— 但在这之前，`Fgets` 早就堵死了|

这里的问题在于，客户实际上正在同时应对两个描述符——套接字和用户输入，它不能单纯阻塞在这两个源中某个特定源的输入上。而是应该阻塞在任意一个源的输入上。事实上这正是 `select`、`poll` 和 `epoll` 这三个函数的目的之一。

当进程向已收到 RST 的套接字执行写操作时，第一次写就会触发 SIGPIPE 信号，同时返回 EPIPE。SIGPIPE 默认行为是终止进程；即使捕获信号，写操作仍返回 EPIPE。

### 服务器主机崩溃或关机

服务器主机崩溃时，已有的网络链接上不发出任何东西。此时的客户端发出一行文本，等待回答。但此时客户会一直尝试重传，直到超时。

若为崩溃后重启，服务器的 TCP 丢失了崩溃前的所有链接信息，因此服务器 TCP 对所有的客户数据分节均回复 RST，从而使客户端收到 `ECONNRESET` 错误。若需要实现即使客户不主动发送数据也要能检测出来，就需要采用其他技术，如心跳机制等。

若为客户端主动关机，则 Unix 系统的 `init`/`systemd` 会先给所有进程发送 SIGTERM 信号，等待一段固定的时间，然后给所有仍在运行的进程发送 SIGKILL 信号，该信号不能被捕获。如果部门不捕获 SIGTERM 信号并终止，我们的服务器将由 SIGKILL 信号终止。需要注意[客户端在服务端终止后的情况](#服务器进程直接终止)
