# 9.1.1 进程调度与优先级实验分步操作

这个版本严格按教材的 pthread 多线程测试程序来做。分步执行，每一步确认现象后再继续。

注意：教材中 `renice -n -5` 是把 nice 值调小，也就是提高优先级，通常需要 `sudo` 权限。

## 第 1 步：创建并编译 pthread 程序

在 Kylin 终端执行：

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

截图：能看到 `nice-exp` 文件生成。

## 第 2 步：启动两个 nice-exp 进程并绑定到同一 CPU

教材建议重新开终端启动进程。为了保留 PID，下面在同一个终端里完成：

```bash
cd ~/labs/cfs_experiment
pkill nice-exp 2>/dev/null

taskset -c 0 ./nice-exp >/dev/null &
PID_A=$!

taskset -c 0 ./nice-exp >/dev/null &
PID_B=$!

echo "PID_A=$PID_A PID_B=$PID_B"
```

注意：后面的命令都要在同一个终端里执行，因为 `$PID_A` 和 `$PID_B` 只在当前终端有效。

## 第 3 步：确认两个进程在同一个 CPU 核心竞争

执行：

```bash
taskset -cp $PID_A
taskset -cp $PID_B
ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B
```

你要看两点：

- `taskset -cp` 输出里两个进程的 CPU affinity 都是 `0`。
- `ps` 输出里两个进程的 `PSR` 都是 `0`，说明两个进程在同一个 CPU 核心竞争。

截图：这一张证明两个进程绑定到了同一个 CPU 核心。

## 第 4 步：把其中一个进程 nice 值调为 -5

执行：

```bash
sudo renice -n -5 -p $PID_A
sleep 8
ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B
```

看 `NI` 列：

- `PID_A` 应该变成 `-5`。
- `PID_B` 应该还是 `0`。

如果 `NI` 没有变成 `-5`，说明 `renice` 没成功，先不要截图。

## 第 5 步：用 top 观察 CPU 占用变化

执行：

```bash
top -p $PID_A,$PID_B
```

进入 `top` 后等 5 到 10 秒再截图。

预期现象：

- `NI=-5` 的进程优先级更高，CPU 占用更高。
- `NI=0` 的进程优先级较低，CPU 占用相对更低。

如果刚进入 `top` 还是差不多，就再等几秒；也可以按 `f` 打开字段选择，显示 `P = Last Used Cpu (SMP)`，确认两个进程在同一个 CPU 核心。

截图：这一张证明 nice 值改变后 CPU 分配发生变化。

## 第 6 步：结束实验进程

截图完成后执行：

```bash
kill $PID_A $PID_B
pkill nice-exp 2>/dev/null
```

## 报告里怎么写结果

结果分析可以写：

> 两个 nice-exp 进程绑定到同一 CPU 核心后会竞争同一处理器时间。调整前两个进程 nice 值相同，CPU 占比接近；对其中一个进程执行 sudo renice -n -5 后，该进程 nice 值变小、优先级提高，获得的 CPU 时间增多，另一个 nice 值为 0 的进程获得的 CPU 时间相对减少，说明 Linux CFS 调度器会根据 nice 值对应的权重分配运行时间。
