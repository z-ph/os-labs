# 操作系统实验与课设执行清单（答辩版）

本清单用于在 Kylin 系统中按阶段完成实验与课程设计验证。每个命令块后均补充“命令与参数解释”，答辩时可直接说明命令作用、关键参数含义和实验现象。

截图原则：配置类命令成功时可能没有输出，不要求截图；截图优先截验证命令的输出，例如 `id`、`ls`、`getfacl`、`ps`、`free`、`docker ps`、`curl` 等。

## 通用符号说明

- `sudo`：以管理员权限执行命令，涉及系统服务、用户管理、Docker、ACL、swap 等操作时需要使用。
- `;`：顺序执行多个命令，不要求前一个命令成功。
- `&&`：前一个命令成功后才执行后一个命令，常用于 Dockerfile 构建步骤。
- `||`：前一个命令失败时执行后一个命令，常用于兼容不同系统命令或忽略非关键错误。
- `|`：管道，把左边命令输出交给右边命令继续处理。
- `>`：输出重定向，把命令输出写入文件。
- `2>/dev/null`：把标准错误输出丢弃，常用于隐藏“文件不存在”“对象已存在”等非关键提示。
- `&`：把命令放到后台运行。
- `$!`：最近一个后台进程的 PID。
- `$变量名`：引用 shell 变量，例如 `$PID_A`。
- `\`：在 shell 中转义特殊字符，或在 Dockerfile 中表示命令换行继续。
- `<<'EOF' ... EOF`：here document，把中间多行内容原样写入前面的命令；单引号表示不展开变量。
- `{1..8}`：shell 大括号展开，生成 1 到 8 的序列。

## 实验选择

建议完成以下 5 个实验，覆盖 9.1、9.2、9.4 三类内容：

1. 9.1.1 基于 Kylin OS 的进程调度与优先级实验
2. 9.2.4 内存回收实验
3. 9.4.1 多用户与权限管理
4. 9.4.2 文件快速定位与管理
5. 9.4.3 数据检索与处理

课程设计选择 9.6.1 容器化负载均衡部署实践。

## 9.1.1 进程调度与优先级

本实验的截图只保留调度验证证据：调整前确认两个进程处于同一 CPU 核心且 NI 相同，调整后确认 NI 发生变化并观察 CPU 占用差异。创建文件、编译程序、启动进程和清理进程属于准备或善后步骤，不作为截图重点。

### 阶段一：准备 pthread 测试程序

```bash
mkdir -p ~/labs/cfs_experiment
cd ~/labs/cfs_experiment
cat > nice-exp.c <<'EOF'
#include <stdio.h>
#include <pthread.h>
#include <sys/types.h>
#include <unistd.h>

void *thread_fun(void *param)
{
    printf("thread pid:%d, tid:%lu\n", getpid(), pthread_self());
    while (1) ;
    return NULL;
}

int main(void)
{
    pthread_t tid;
    int ret;
    printf("main pid:%d, tid:%lu\n", getpid(), pthread_self());
    ret = pthread_create(&tid, NULL, thread_fun, NULL);
    if (ret == -1) {
        perror("cannot create new thread");
        return 1;
    }
    if (pthread_join(tid, NULL) != 0) {
        perror("call pthread_join function fail");
        return 1;
    }
    return 0;
}
EOF
gcc nice-exp.c -o nice-exp -pthread
ls -l nice-exp
```

本阶段用于准备测试程序，通常不需要截图；如果出现编译报错，再记录错误信息用于排查。

命令与参数解释：

- `mkdir -p ~/labs/cfs_experiment`：创建实验目录；`-p` 表示父目录不存在时一起创建，目录已存在也不报错；`~` 表示当前用户主目录。
- `cd ~/labs/cfs_experiment`：进入实验目录，后续文件创建和编译都在该目录完成。
- `cat > nice-exp.c <<'EOF' ... EOF`：把多行 C 代码写入 `nice-exp.c`；`>` 表示写入文件；`<<'EOF'` 表示从下一行开始读入，直到遇到 `EOF` 结束。
- `gcc nice-exp.c -o nice-exp -pthread`：用 GCC 编译程序；`-o nice-exp` 指定输出可执行文件名；`-pthread` 启用 pthread 线程库并链接线程相关支持。
- `ls -l nice-exp`：查看编译结果；`-l` 以长格式显示权限、属主、大小、时间等信息。

代码要点：

- `pthread_create` 创建一个新线程，说明实验程序符合教材的线程调度测试要求。
- `while (1);` 让线程持续占用 CPU，形成 CPU 密集型负载，便于观察调度效果。
- `pthread_join` 等待子线程结束；由于子线程死循环，程序会持续运行，适合作为调度观察对象。

### 阶段二：启动两个进程并绑定到同一 CPU 核心

```bash
cd ~/labs/cfs_experiment
pkill nice-exp 2>/dev/null
taskset -c 0 ./nice-exp >/dev/null &
PID_A=$!
taskset -c 0 ./nice-exp >/dev/null &
PID_B=$!
echo "PID_A=$PID_A PID_B=$PID_B"
```

本阶段只用于得到后续观察所需的 `PID_A` 和 `PID_B`，截图从下一阶段的验证输出开始。

命令与参数解释：

- `cd ~/labs/cfs_experiment`：确保当前目录中存在 `nice-exp` 可执行文件。
- `pkill nice-exp 2>/dev/null`：结束历史遗留的 `nice-exp` 进程；`pkill` 按进程名匹配；`2>/dev/null` 隐藏没有匹配进程时的错误信息。
- `taskset -c 0 ./nice-exp >/dev/null &`：在 CPU 0 上运行 `nice-exp`；`taskset` 设置 CPU 亲和性；`-c 0` 表示使用 CPU 编号 0；`./nice-exp` 表示运行当前目录下程序；`>/dev/null` 隐藏程序标准输出；`&` 放到后台运行。
- `PID_A=$!`：把上一个后台进程的 PID 保存到变量 `PID_A`，后续用它进行查询和调优。
- `PID_B=$!`：同理，保存第二个后台进程的 PID。
- `echo "PID_A=$PID_A PID_B=$PID_B"`：打印两个 PID，确认后续观察对象。

### 阶段三：观察调整前状态

```bash
taskset -cp $PID_A
taskset -cp $PID_B
ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B
```

截图内容：截取 `taskset -cp` 和 `ps` 的输出，重点包含两个进程处于同一 CPU 核心、`NI` 均为 0、CPU 占用接近。

命令与参数解释：

- `taskset -cp $PID_A`：查看已有进程的 CPU 亲和性；`-c` 使用 CPU 编号列表格式；`-p` 表示目标是已经运行的进程；`$PID_A` 是进程号。
- `taskset -cp $PID_B`：查看第二个进程的 CPU 亲和性，确认两个进程都绑定到 CPU 0。
- `ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B`：查看两个进程的调度相关信息；`-o` 指定输出列；`pid` 是进程号；`ni` 是 nice 值；`psr` 是最近运行的 CPU 核心；`pcpu` 是 CPU 占用率；`comm` 是命令名；`-p` 指定查询的 PID 列表。

答辩说明：

- 调整前两个进程 `NI` 都是默认值，一般为 0。
- 两个进程绑定在同一 CPU 核心上，才会产生明显竞争；如果不绑定，多核系统可能让两个进程分别跑在不同核心上，CPU 占用看起来接近。

### 阶段四：调整 nice 值并观察变化

```bash
sudo renice -n -5 -p $PID_A
sleep 8
ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B
top -p $PID_A,$PID_B
```

截图内容：截取 `renice` 返回结果以及 `ps` 或 `top` 的输出，重点包含 `PID_A` 的 `NI=-5`、`PID_B` 的 `NI=0`，并观察 `PID_A` 的 CPU 占用更高或随时间更稳定地占优。

命令与参数解释：

- `sudo renice -n -5 -p $PID_A`：修改进程优先级；`renice` 调整已有进程 nice 值；`-n -5` 把 nice 值设为 `-5`；`-p` 表示后面跟的是进程 PID；nice 值越小，调度权重越高。
- `sleep 8`：等待 8 秒，让调度器有时间重新分配 CPU 时间。
- `ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B`：再次查看两个进程的 `NI` 和 CPU 占用。
- `top -p $PID_A,$PID_B`：动态观察指定进程；`-p` 指定 PID 列表，只显示这两个进程。

答辩说明：

- Linux CFS 调度器会根据进程权重分配 CPU 时间，nice 值越小权重越高。
- `renice -n -5` 后，`PID_A` 的 `NI` 变为 `-5`，理论上会比 `NI=0` 的进程获得更多 CPU 时间。
- 如果 `top` 的瞬时数值仍然接近，可以继续观察数秒或多次执行 `ps`；重点是对比调整前后的 `NI` 和 CPU 时间分配趋势。

### 阶段五：清理测试进程

```bash
pkill nice-exp 2>/dev/null
```

本阶段用于释放 CPU 资源，不作为截图重点。

命令与参数解释：

- `pkill nice-exp 2>/dev/null`：实验结束后清理测试进程；`pkill` 按进程名匹配；`2>/dev/null` 隐藏没有匹配进程时的非关键提示。

## 9.2.4 内存回收实验

### 阶段一：创建并编译测试程序

```bash
mkdir -p ~/labs/oom_experiment
cd ~/labs/oom_experiment
cat > oom.c <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define STEP_SIZE (4 * 1024 * 1024)

int main(void)
{
    long count = 0;
    for (;;) {
        char *memory = (char *)malloc(STEP_SIZE);
        if (!memory) {
            perror("malloc");
            sleep(1);
            continue;
        }
        memset(memory, 0, STEP_SIZE);
        count++;
        if (count % 25 == 0) {
            printf("allocated about %ld MB\n", count * 4);
            fflush(stdout);
        }
        usleep(10000);
    }
    return 0;
}
EOF
gcc oom.c -o oom
ls -l oom
```

命令与参数解释：

- `mkdir -p ~/labs/oom_experiment`：创建内存实验目录；`-p` 允许递归创建并避免目录已存在时报错。
- `cd ~/labs/oom_experiment`：进入实验目录。
- `cat > oom.c <<'EOF' ... EOF`：把 OOM 测试程序写入 `oom.c`。
- `gcc oom.c -o oom`：编译 C 程序；`-o oom` 指定输出可执行文件名为 `oom`。
- `ls -l oom`：确认可执行文件生成；`-l` 显示详细文件属性。

代码要点：

- `malloc(STEP_SIZE)` 每次申请 4 MB 虚拟内存。
- `memset(memory, 0, STEP_SIZE)` 对内存写入，促使系统真正分配物理页。
- 死循环持续申请内存，使系统内存压力不断增大，最终触发 OOM Killer。

### 阶段二：记录初始内存并关闭 swap

```bash
hostname; date; whoami
sudo swapon --show
sudo swapoff -a
free -m
```

命令与参数解释：

- `hostname; date; whoami`：依次输出主机名、当前时间、当前用户；`;` 表示顺序执行。
- `sudo swapon --show`：查看当前 swap 分区或 swap 文件；`--show` 以表格形式显示 swap 状态。
- `sudo swapoff -a`：关闭所有 swap；`-a` 表示 all，即处理 `/etc/fstab` 中的全部 swap 项。
- `free -m`：查看内存使用情况；`-m` 表示以 MB 为单位显示。

答辩说明：

- 关闭 swap 是为了让物理内存压力更快、更明显地触发 OOM。
- `free -m` 中重点观察 `available`，它表示系统可用内存估计值。

### 阶段三：启动程序并自动观察到 OOM 结束

```bash
cd ~/labs/oom_experiment
./oom > oom.log 2>&1 &
OOM_PID=$!
clear
while kill -0 $OOM_PID 2>/dev/null; do
    free -m | awk '/Mem:/ {print "available_MB=" $7}'
    sleep 1
done
echo "oom process exited"
```

截图内容：截取本阶段输出即可，画面中只需要出现多行 `available_MB=数值`，并在最后出现 `oom process exited`。这张图用于证明内存可用量持续下降，直到测试进程被系统终止。

命令与参数解释：

- `cd ~/labs/oom_experiment`：进入 `oom` 程序所在目录。
- `./oom > oom.log 2>&1 &`：后台运行当前目录下的 `oom` 程序；`>` 把标准输出写入 `oom.log`；`2>&1` 把错误输出也合并到同一个日志文件；`&` 表示后台运行。
- `OOM_PID=$!`：把最近一个后台进程的 PID 保存到变量 `OOM_PID`。
- `clear`：清空终端中后台任务启动时产生的作业号等杂项输出，便于截图只保留内存数值。
- `while kill -0 $OOM_PID 2>/dev/null; do ... done`：只要 `oom` 进程还存在，就继续循环观察；`kill -0` 不会真正结束进程，只用于检测进程是否存在。
- `free -m | awk '/Mem:/ {print "available_MB=" $7}'`：只输出 `free -m` 中 Mem 行的 available 数值；`$7` 是 available 列；最终输出格式简化为 `available_MB=数值`。
- `sleep 1`：每隔 1 秒输出一次内存可用量。
- `echo "oom process exited"`：当 `oom` 进程被终止后输出结束标记。

答辩说明：

- 程序输出重定向到 `oom.log`，终端只显示可用内存大小，便于截图。
- `available_MB` 持续下降说明测试程序不断申请并写入内存。
- 循环自动结束说明 `oom` 进程已经退出，通常是被 OOM Killer 终止。

### 阶段四：查看 OOM 日志并恢复 swap

```bash
dmesg | tail -n 30
sudo swapon -a
free -m
```

截图内容：截取 `dmesg` 中出现 `Out of memory` 或 `Killed process` 的日志，以及恢复 swap 后的 `free -m` 输出。

命令与参数解释：

- `dmesg | tail -n 30`：查看内核日志末尾 30 行；`dmesg` 输出内核环形缓冲区日志；`|` 把输出传给 `tail`；`tail -n 30` 只显示最后 30 行。
- `sudo swapon -a`：重新启用所有 swap；`-a` 表示启用配置文件中的全部 swap 项。
- `free -m`：再次查看内存和 swap 状态，确认 swap 已恢复。

答辩说明：

- 日志中出现 `Out of memory` 或 `Killed process`，说明 OOM Killer 已经触发。
- OOM Killer 是内核在内存严重不足时保护系统继续运行的一种机制。

## 9.4.1 多用户与权限管理

本实验中，`groupadd`、`useradd`、`usermod`、`mkdir`、`chown`、`chmod`、`setfacl` 等配置命令成功时通常没有输出，不适合作为截图重点。截图应放在验证命令上，也就是能显示用户、用户组、目录权限、ACL 和删除失败结果的命令。

### 阶段一：创建用户和用户组

执行命令：

```bash
hostname; date; whoami
sudo groupadd school 2>/dev/null || true
sudo useradd -m yinhe 2>/dev/null || true
sudo useradd -m kylin 2>/dev/null || true
sudo usermod -aG school yinhe
sudo usermod -aG school kylin
```

验证/截图命令：

```bash
getent group school
id yinhe
id kylin
```

截图内容：`getent group school` 能看到 `school` 组，`id yinhe` 和 `id kylin` 能看到两个用户属于 `school` 组。

命令与参数解释：

- `hostname; date; whoami`：输出环境信息；`;` 表示顺序执行多个命令。
- `sudo groupadd school 2>/dev/null || true`：创建 `school` 用户组；`2>/dev/null` 隐藏组已存在等错误；`|| true` 让重复执行时不中断。
- `sudo useradd -m yinhe 2>/dev/null || true`：创建 `yinhe` 用户；`-m` 自动创建用户主目录。
- `sudo useradd -m kylin 2>/dev/null || true`：创建 `kylin` 用户；`-m` 同样表示创建主目录。
- `sudo usermod -aG school yinhe`：把 `yinhe` 加入 `school` 组；`-G school` 指定附加组；`-a` 表示追加，不覆盖原有附加组。
- `sudo usermod -aG school kylin`：把 `kylin` 加入 `school` 组，参数含义同上。
- `getent group school`：从系统数据库查询 `school` 组，能验证组是否存在以及组成员信息。
- `id yinhe`：查看 `yinhe` 的 UID、GID 和所属用户组。
- `id kylin`：查看 `kylin` 的 UID、GID 和所属用户组。

答辩说明：

- 用户组用于统一管理多个用户的访问权限。
- `usermod -aG` 必须带 `-a`，否则可能覆盖用户原来的附加组。

### 阶段二：配置共享目录和 ACL

执行命令：

```bash
sudo mkdir -p /root/network
sudo chown yinhe:school /root/network
sudo chmod 3770 /root/network
sudo setfacl -m g:school:x /root
sudo setfacl -m d:g:school:rwx /root/network
sudo touch /root/network/file1
sudo chown yinhe:school /root/network/file1
sudo setfacl -m u:kylin:rw /root/network/file1
```

验证/截图命令：

```bash
ls -ld /root /root/network
stat -c '%A %a %U %G %n' /root/network /root/network/file1
getfacl /root/network
getfacl /root/network/file1
```

截图内容：`ls -ld` 和 `stat` 能显示 `/root/network` 的权限、属主和属组；`getfacl` 能显示默认 ACL 和 `user:kylin:rw-`。

命令与参数解释：

- `sudo mkdir -p /root/network`：创建共享目录；`-p` 允许父目录存在时继续执行。
- `sudo chown yinhe:school /root/network`：修改目录属主和属组；`yinhe:school` 表示属主为 `yinhe`，属组为 `school`。
- `sudo chmod 3770 /root/network`：设置目录权限；第一位 `3` 表示特殊权限 `setgid(2)+sticky(1)`；第二位 `7` 表示属主 `rwx`；第三位 `7` 表示属组 `rwx`；第四位 `0` 表示其他用户无权限。
- `sudo setfacl -m g:school:x /root`：修改 `/root` 的 ACL；`-m` 表示 modify；`g:school:x` 表示给 `school` 组增加进入目录所需的执行权限。
- `sudo setfacl -m d:g:school:rwx /root/network`：设置默认 ACL；`d:` 表示 default，新建文件或目录会继承该默认权限；`g:school:rwx` 表示 `school` 组默认拥有读写执行权限。
- `sudo touch /root/network/file1`：创建测试文件 `file1`，如果文件已存在则更新其时间戳。
- `sudo chown yinhe:school /root/network/file1`：设置 `file1` 属主为 `yinhe`，属组为 `school`。
- `sudo setfacl -m u:kylin:rw /root/network/file1`：给用户 `kylin` 单独设置 ACL；`u:kylin:rw` 表示用户 `kylin` 对该文件有读写权限。
- `ls -ld /root /root/network`：查看目录本身权限；`-l` 长格式显示；`-d` 显示目录本身而不是目录内容。
- `stat -c '%A %a %U %G %n' ...`：按指定格式输出权限和属主信息；`-c` 指定输出格式；`%A` 是符号权限；`%a` 是八进制权限；`%U` 是属主；`%G` 是属组；`%n` 是文件名。
- `getfacl /root/network`：查看共享目录 ACL，重点看默认 ACL。
- `getfacl /root/network/file1`：查看文件 ACL，重点看 `user:kylin:rw-`。

答辩说明：

- `setgid` 让目录中新建文件继承目录属组，适合共享目录。
- `sticky` 限制普通用户删除他人文件，常见于 `/tmp` 目录。
- ACL 可以在传统属主、属组、其他用户三类权限之外，为指定用户或组单独授权。

### 阶段三：验证用户读写权限

执行并截图命令：

```bash
sudo -u kylin bash -c 'echo kylin-write-test >> /root/network/file1'
sudo -u kylin cat /root/network/file1
ls -l /root/network/file1
getfacl /root/network/file1
```

截图内容：`cat` 能看到 `kylin-write-test` 写入成功，`getfacl` 能看到 `kylin` 对 `file1` 有读写权限。

命令与参数解释：

- `sudo -u kylin bash -c 'echo kylin-write-test >> /root/network/file1'`：以 `kylin` 身份向文件追加内容；`-u kylin` 指定运行用户；`bash -c` 执行后面的字符串；`>>` 表示追加写入，不覆盖原内容。
- `sudo -u kylin cat /root/network/file1`：以 `kylin` 身份读取文件内容，验证读权限。
- `ls -l /root/network/file1`：查看文件属主、属组和传统权限。
- `getfacl /root/network/file1`：再次查看文件 ACL，验证 `kylin` 的读写权限来自 ACL。

### 阶段四：验证 sticky 位限制删除他人文件

执行并截图命令：

```bash
sudo -u yinhe bash -c 'echo yinhe-file > /root/network/yinhe.txt'
sudo -u kylin bash -c 'rm /root/network/yinhe.txt'
ls -l /root/network
```

截图内容：`kylin` 删除 `yinhe.txt` 时出现权限不足或不允许操作的提示，`ls -l /root/network` 能看到 `yinhe.txt` 仍然存在。

命令与参数解释：

- `sudo -u yinhe bash -c 'echo yinhe-file > /root/network/yinhe.txt'`：以 `yinhe` 身份创建文件；`>` 表示覆盖写入。
- `sudo -u kylin bash -c 'rm /root/network/yinhe.txt'`：以 `kylin` 身份尝试删除 `yinhe` 创建的文件；`rm` 用于删除文件。
- `ls -l /root/network`：查看共享目录中文件是否仍然存在；`-l` 显示详细信息。

答辩说明：

- 即使 `kylin` 属于同一用户组，也不能删除 `yinhe` 的文件，因为目录设置了 sticky 位。
- 本实验截图重点是“验证输出”，不是没有输出的配置命令。

## 9.4.2 文件快速定位与管理

### 阶段一：文件定位

```bash
hostname; date; whoami
find /usr -name "*pass*" | head -n 20
find /usr -name "kmod-protect.list" | head -n 5
find /dev \( -name "vd*" -o -name "sd*" \) -type b
sudo find /etc -type f -size 0 -exec ls -l {} \; | head -n 20
```

命令与参数解释：

- `hostname; date; whoami`：输出主机名、时间和用户信息。
- `find /usr -name "*pass*" | head -n 20`：在 `/usr` 下按文件名查找；`-name "*pass*"` 表示文件名包含 `pass`；`*` 是通配符；`|` 把结果交给 `head`；`head -n 20` 只显示前 20 行。
- `find /usr -name "kmod-protect.list" | head -n 5`：在 `/usr` 下查找教材指定文件；`-name` 精确匹配文件名；`head -n 5` 限制显示前 5 行。
- `find /dev \( -name "vd*" -o -name "sd*" \) -type b`：在 `/dev` 下查找块设备；`\(` 和 `\)` 用于分组条件；`-o` 表示 OR；`-name "vd*"` 匹配 virtio 磁盘设备；`-name "sd*"` 匹配 SCSI/SATA 磁盘设备；`-type b` 只匹配块设备文件。
- `sudo find /etc -type f -size 0 -exec ls -l {} \; | head -n 20`：查找 `/etc` 下大小为 0 的普通文件；`-type f` 表示普通文件；`-size 0` 表示大小为 0；`-exec ls -l {} \;` 对每个结果执行 `ls -l`；`{}` 代表当前找到的文件；`\;` 表示 `-exec` 命令结束；`head -n 20` 限制输出前 20 行。

### 阶段二：账号文本与日志查看

```bash
grep "nologin$" /etc/passwd
sudo tail -n 20 /var/log/messages || sudo journalctl -n 20
```

命令与参数解释：

- `grep "nologin$" /etc/passwd`：在 `/etc/passwd` 中筛选以 `nologin` 结尾的行；`grep` 按模式匹配文本；`$` 在正则表达式中表示行尾。
- `sudo tail -n 20 /var/log/messages || sudo journalctl -n 20`：优先查看传统日志文件最后 20 行；`tail -n 20` 表示末尾 20 行；如果 `/var/log/messages` 不存在，则通过 `||` 执行 `journalctl -n 20`；`journalctl` 查看 systemd 日志；`-n 20` 显示最近 20 条。

### 阶段三：文件类型与元数据

```bash
file /etc/passwd
stat /etc/passwd
```

命令与参数解释：

- `file /etc/passwd`：识别文件类型，判断它是文本、二进制、目录还是其他类型。
- `stat /etc/passwd`：查看文件元数据，包括大小、inode、权限、访问时间、修改时间、状态改变时间等。

## 9.4.3 数据检索与处理

### 阶段一：上下文检索

```bash
hostname; date; whoami
grep -A 2 root /etc/passwd
grep -B 1 daemon /etc/passwd
grep -C 1 daemon /etc/passwd
grep --color=always -n -A 2 root /etc/passwd
```

命令与参数解释：

- `hostname; date; whoami`：输出主机名、时间和当前用户。
- `grep -A 2 root /etc/passwd`：查找包含 `root` 的行；`-A 2` 表示 after，额外显示匹配行后 2 行。
- `grep -B 1 daemon /etc/passwd`：查找包含 `daemon` 的行；`-B 1` 表示 before，额外显示匹配行前 1 行。
- `grep -C 1 daemon /etc/passwd`：`-C 1` 表示 context，额外显示匹配行前后各 1 行。
- `grep --color=always -n -A 2 root /etc/passwd`：高亮显示匹配结果；`--color=always` 总是输出颜色标记；`-n` 显示行号；`-A 2` 显示匹配行后 2 行。

### 阶段二：计数结果对比

```bash
grep -c root /etc/passwd
grep root /etc/passwd | wc -l
```

命令与参数解释：

- `grep -c root /etc/passwd`：统计匹配 `root` 的行数；`-c` 表示 count，只输出匹配行数量。
- `grep root /etc/passwd | wc -l`：先输出匹配 `root` 的行，再通过管道交给 `wc`；`wc -l` 统计输入的行数。

答辩说明：

- 两种方法在本实验中通常结果一致。
- `grep -c` 是 grep 自带计数；`wc -l` 是通过管道对 grep 输出再统计。

### 阶段三：扩展正则表达式

```bash
mkdir -p /tmp/grep_lab
cd /tmp/grep_lab
touch file{1..10}
ls -l | grep -E 'file1{1,}'
```

命令与参数解释：

- `mkdir -p /tmp/grep_lab`：创建临时实验目录；`-p` 防止目录已存在时报错。
- `cd /tmp/grep_lab`：进入临时实验目录。
- `touch file{1..10}`：创建 `file1` 到 `file10`；`{1..10}` 是 shell 大括号展开。
- `ls -l | grep -E 'file1{1,}'`：列出文件并用扩展正则筛选；`ls -l` 长格式列出；`|` 管道；`grep -E` 启用扩展正则；`1{1,}` 表示字符 `1` 出现至少 1 次。

### 阶段四：普通字符串与忽略大小写

```bash
cd ~
printf 'a?b\na\\?b\n' > test
cat test
egrep --color=always '\?' test
fgrep --color=always '\?' test
echo 'AaBbCc' | grep --color=always -i -E 'A|b|c'
```

命令与参数解释：

- `cd ~`：回到当前用户主目录；`~` 表示主目录。
- `printf 'a?b\na\\?b\n' > test`：向 `test` 文件写入两行测试文本；`printf` 按格式输出；`\n` 表示换行；`\\` 表示输出一个反斜杠；`>` 表示写入文件。
- `cat test`：显示 `test` 文件内容。
- `egrep --color=always '\?' test`：使用扩展正则匹配；`egrep` 等价于 `grep -E`；`--color=always` 高亮匹配部分；`\?` 表示把 `?` 当普通字符匹配。
- `fgrep --color=always '\?' test`：使用固定字符串匹配；`fgrep` 等价于 `grep -F`；此时 `\?` 会按反斜杠加问号两个普通字符理解。
- `echo 'AaBbCc' | grep --color=always -i -E 'A|b|c'`：输出字符串并匹配；`echo` 输出文本；`|` 管道；`-i` 忽略大小写；`-E` 启用扩展正则；`A|b|c` 表示匹配 `A` 或 `b` 或 `c`。

## 9.6.1 课程设计：容器化负载均衡

本课程设计按完整 Web 项目进行验收。项目应用为“操作系统实验课程服务门户”，功能包括课程首页、实验资料索引、项目验收清单、健康检查接口和状态 API；再通过 Nginx 将请求负载均衡到两个 Tomcat 后端。报告中说明项目结构、部署流程、验证结果和截图证据即可，不需要粘贴应用源码。

### 阶段一：取得项目源码并查看结构

```bash
cd ~
git clone https://github.com/z-ph/os-labs.git 2>/dev/null || (cd os-labs && git pull)
cd ~/os-labs/course-9.6-lb-project
find . -maxdepth 3 -type f | sort
```

截图内容：截取项目目录结构，重点能看到 `nginx/`、`tomcat/`、`tomcat-app/ROOT/`、`scripts/`，证明课程设计不是临时端口验证，而是具有应用源码、镜像构建和部署脚本的完整项目。

命令与参数解释：

- `cd ~`：进入当前用户主目录，便于统一放置项目代码。
- `git clone https://github.com/z-ph/os-labs.git`：从 GitHub 下载项目仓库。
- `2>/dev/null`：隐藏仓库已存在等非关键错误提示。
- `||`：前一个命令失败时执行后一个命令，这里用于仓库已存在时改为更新仓库。
- `(cd os-labs && git pull)`：在子 shell 中进入已有仓库并执行更新；`&&` 表示进入目录成功后才执行 `git pull`。
- `cd ~/os-labs/course-9.6-lb-project`：进入 9.6 课程设计项目目录。
- `find . -maxdepth 3 -type f`：列出当前目录下最多 3 层深度的普通文件；`.` 表示当前目录；`-maxdepth 3` 限制深度；`-type f` 只显示文件。
- `| sort`：把文件列表通过管道交给 `sort` 排序，便于截图展示。

答辩说明：

- `tomcat-app/ROOT/` 是 Web 应用源码目录。
- `nginx/` 和 `tomcat/` 中保存镜像构建材料。
- `scripts/` 保存部署、验收和清理脚本，便于重复实验。

### 阶段二：启动 Docker 服务

```bash
sudo yum install -y docker || sudo dnf install -y docker
sudo systemctl enable --now docker
sudo systemctl status docker
sudo docker version
```

截图内容：截取 `systemctl status docker` 中的 `active (running)`，以及 `docker version` 能显示 Client/Server 信息。

命令与参数解释：

- `sudo`：以管理员权限执行命令。
- `yum install -y docker`：使用 yum 安装 Docker；`install` 表示安装软件包；`-y` 自动确认。
- `|| sudo dnf install -y docker`：如果 yum 安装失败，则尝试 dnf 安装，兼容不同 Kylin 环境。
- `systemctl enable --now docker`：设置 Docker 开机自启并立即启动；`enable` 表示加入开机启动；`--now` 表示同时立刻启动服务。
- `systemctl status docker`：查看 Docker 服务状态。
- `docker version`：查看 Docker 客户端与服务端版本，验证 Docker 能正常工作。

### 阶段三：部署完整项目

```bash
cd ~/os-labs/course-9.6-lb-project
bash scripts/deploy.sh
sudo docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'kylin-base|kylin-nginx|kylin-tomcat'
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
```

截图内容：截取部署完成后的镜像列表和容器列表。镜像列表中应包含 `kylin-base:v10sp1`、`kylin-nginx:861`、`kylin-tomcat:861`；容器列表中应包含 `nginx-lb`、`tomcat1`、`tomcat2`，并能看到端口映射。

命令与参数解释：

- `cd ~/os-labs/course-9.6-lb-project`：进入课程设计项目目录，确保脚本能找到 Dockerfile、Nginx 配置和 Web 应用源码。
- `bash scripts/deploy.sh`：使用 bash 执行部署脚本。该脚本会下载 Nginx/Tomcat 安装包、拉取 Kylin 基础镜像、构建 Tomcat 应用镜像、构建 Nginx 负载均衡镜像、创建 Docker 网络并启动三个容器。
- `docker images`：查看本地镜像。
- `--format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'`：指定镜像输出为表格格式；`.Repository` 是镜像名；`.Tag` 是标签；`.Size` 是镜像大小；`\t` 表示制表符。
- `grep -E 'kylin-base|kylin-nginx|kylin-tomcat'`：用扩展正则筛选项目相关镜像；`-E` 启用扩展正则；`|` 在正则中表示“或”。
- `docker ps`：查看正在运行的容器。
- `--format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'`：按容器名、镜像、运行状态和端口映射输出。

答辩说明：

- `kylin-tomcat:861` 镜像内置课程服务门户应用。
- `kylin-nginx:861` 镜像内置 Nginx 负载均衡配置。
- `tomcat1` 和 `tomcat2` 是两个业务后端，`nginx-lb` 是统一入口。

### 阶段四：验证应用页面与 API

```bash
curl -s http://127.0.0.1/ | grep '操作系统实验课程服务门户'
curl -s http://127.0.0.1/resources.jsp | grep '实验资料索引'
curl -s http://127.0.0.1/checklist.jsp | grep '项目验收清单'
curl -s http://127.0.0.1/api/status.jsp
```

截图内容：截取命令输出，证明首页、资料索引页、验收清单页和状态 API 均可通过 Nginx 入口访问。也可以在浏览器中分别打开 `http://127.0.0.1/`、`http://127.0.0.1/resources.jsp`、`http://127.0.0.1/checklist.jsp` 截图，报告中优先放浏览器页面截图。

命令与参数解释：

- `curl -s http://127.0.0.1/`：访问宿主机本地 80 端口，也就是 Nginx 负载均衡入口；`-s` 表示静默模式，不显示下载进度。
- `grep '操作系统实验课程服务门户'`：筛选首页标题，验证访问到的是课程门户应用。
- `resources.jsp`：实验资料索引页面，用于展示实验与课程设计材料分类。
- `checklist.jsp`：项目验收清单页面，用于展示部署与验证项。
- `api/status.jsp`：状态 API，返回应用版本、节点名称、服务角色和主机信息。

答辩说明：

- 本阶段证明系统运行的是一个具体 Web 应用，而不是空白容器或单行测试页面。
- 页面访问经过 Nginx，再由 Nginx 转发到 Tomcat 后端。

### 阶段五：验证负载均衡轮询

```bash
for i in {1..8}; do curl -s http://127.0.0.1/health.jsp; echo; done
```

截图内容：截取 8 次健康检查输出，重点观察 JSON 中的 `node` 字段在 `KYLIN-TOMCAT-1` 与 `KYLIN-TOMCAT-2` 之间变化。

命令与参数解释：

- `for i in {1..8}; do ... done`：shell 循环结构，连续执行 8 次访问。
- `{1..8}`：生成数字 1 到 8。
- `curl -s http://127.0.0.1/health.jsp`：通过 Nginx 入口访问健康检查接口。
- `echo`：每次请求后输出换行，便于观察多次结果。

答辩说明：

- Nginx upstream 默认使用轮询策略。
- 多次访问返回不同节点名称，说明请求被分发到两个 Tomcat 后端。

### 阶段六：验证单节点故障恢复

```bash
sudo docker stop tomcat1
for i in {1..5}; do curl -s http://127.0.0.1/health.jsp; echo; done
sudo docker start tomcat1
sleep 8
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
```

截图内容：截取停止 `tomcat1` 后仍能访问 `health.jsp` 的输出，以及恢复后 `docker ps` 显示三个容器重新运行的结果。

命令与参数解释：

- `docker stop tomcat1`：停止第一个 Tomcat 后端，用于模拟单节点故障。
- `for i in {1..5}; do curl -s http://127.0.0.1/health.jsp; echo; done`：连续访问负载均衡入口，观察服务是否仍能由另一个后端响应。
- `docker start tomcat1`：重新启动 `tomcat1` 容器。
- `sleep 8`：等待 8 秒，让 Tomcat 有时间完成启动。
- `docker ps --format ...`：查看容器恢复后的运行状态。

答辩说明：

- 停止一个后端后，系统仍能由另一个后端继续提供服务，说明具备基本容错能力。
- 恢复 `tomcat1` 后再次查看容器状态，证明系统能恢复到双后端运行。

### 阶段七：保存项目级验收证据

```bash
sudo docker network inspect kylin-lb-net --format '{{range $id,$c := .Containers}}{{$c.Name}} {{end}}'
sudo docker inspect nginx-lb --format 'Name={{.Name}} Image={{.Config.Image}} Ports={{json .NetworkSettings.Ports}}'
sudo docker exec nginx-lb /usr/local/nginx/sbin/nginx -T | grep -E 'upstream|server tomcat|proxy_pass'
sudo docker logs --tail 20 tomcat1
sudo docker logs --tail 20 tomcat2
bash scripts/verify.sh
```

截图内容：截取 Docker 网络包含 `nginx-lb`、`tomcat1`、`tomcat2` 的结果；截取 Nginx 配置中 `upstream web`、`server tomcat1:8080`、`server tomcat2:8080`、`proxy_pass http://web`；截取 Tomcat 日志和 `verify.sh` 的综合验收输出。

命令与参数解释：

- `docker network inspect kylin-lb-net`：查看 Docker 自定义网络详情。
- `--format '{{range $id,$c := .Containers}}{{$c.Name}} {{end}}'`：使用 Go 模板遍历网络内的容器并只输出容器名称；`range` 表示遍历。
- `docker inspect nginx-lb`：查看 Nginx 容器详细信息。
- `Ports={{json .NetworkSettings.Ports}}`：以 JSON 形式输出端口映射。
- `docker exec nginx-lb /usr/local/nginx/sbin/nginx -T`：在 Nginx 容器中输出完整配置；`exec` 表示在运行中的容器内执行命令；`-T` 表示测试并打印配置。
- `grep -E 'upstream|server tomcat|proxy_pass'`：筛选负载均衡关键配置。
- `docker logs --tail 20 tomcat1`：查看 `tomcat1` 最近 20 行日志；`--tail 20` 限制输出行数。
- `docker logs --tail 20 tomcat2`：查看 `tomcat2` 最近 20 行日志。
- `bash scripts/verify.sh`：执行项目综合验收脚本，集中输出镜像、容器、网络、配置、页面接口和日志证据。

答辩说明：

- `docker network inspect` 证明三个容器位于同一自定义网络。
- `nginx -T` 证明 Nginx 配置确实指向两个 Tomcat 后端。
- `docker logs` 证明后端服务具备运行日志和排查依据。
- `verify.sh` 用于复核项目整体状态，适合提交前自查。

### 阶段八：实验结束后的清理

```bash
cd ~/os-labs/course-9.6-lb-project
bash scripts/clean.sh
```

本阶段用于停止并删除课程设计容器和网络，不作为报告截图重点。

命令与参数解释：

- `cd ~/os-labs/course-9.6-lb-project`：进入项目目录。
- `bash scripts/clean.sh`：执行清理脚本，停止并删除 `nginx-lb`、`tomcat1`、`tomcat2`，并删除 `kylin-lb-net` 网络。

