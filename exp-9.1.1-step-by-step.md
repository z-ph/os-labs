# 9.1.1 进程调度与优先级实验分步操作

这个实验不要一次性粘贴所有命令。分 5 步做，每一步确认现象后再继续。

如果 `renice -5` 后 CPU 占比看起来还是差不多，通常有三个原因：

1. 两个进程没有真的绑定到同一个 CPU 核心。
2. `renice` 没有成功，`NI` 值没有变化。
3. `ps` 显示的是平均 CPU 占用，刚调整完不一定马上明显变化。

下面用更稳的做法：把一个进程的 nice 值改成 `+10`，也就是降低它的优先级。这样另一个进程会明显占用更多 CPU，不需要 root 权限，截图也更容易看清楚。

## 第 1 步：创建并编译程序

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

## 第 2 步：启动两个进程并绑定到同一个 CPU

继续在同一个终端执行：

```bash
cd ~/labs/cfs_experiment
pkill nice-exp 2>/dev/null

taskset -c 0 ./nice-exp >/dev/null &
PID_A=$!

taskset -c 0 ./nice-exp >/dev/null &
PID_B=$!

echo "PID_A=$PID_A PID_B=$PID_B"
```

注意：这一步结束后，终端会显示两个 PID。后面的命令都要在同一个终端里执行，因为 `$PID_A` 和 `$PID_B` 只在当前终端有效。

## 第 3 步：确认两个进程真的在同一个 CPU 核心

执行：

```bash
taskset -cp $PID_A
taskset -cp $PID_B
ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B
```

你要看两点：

- `taskset -cp` 输出里两个进程的 CPU affinity 都是 `0`。
- `ps` 输出里两个进程的 `PSR` 都是 `0`，或者至少都在同一个数字上。

截图：这一张证明两个进程在同一个 CPU 核心竞争。

如果 `PSR` 不一样，不要继续做 `renice`，先执行：

```bash
pkill nice-exp
```

然后回到第 2 步重新启动。

## 第 4 步：调整其中一个进程优先级

为了让现象明显，降低 `PID_B` 的优先级：

```bash
renice -n 10 -p $PID_B
ps -o pid,ni,psr,pcpu,comm -p $PID_A,$PID_B
```

看 `NI` 列：

- `PID_A` 应该还是 `0`。
- `PID_B` 应该变成 `10`。

如果 `NI` 没有变成 `10`，说明 `renice` 没成功，先不要截图。

## 第 5 步：观察 CPU 占用变化

用 `top` 看实时占比：

```bash
top -p $PID_A,$PID_B
```

进入 `top` 后等 5 到 10 秒再截图。

预期现象：

- `NI=0` 的进程 CPU 占用更高。
- `NI=10` 的进程 CPU 占用更低。

如果你看到 `ps` 里 CPU 还是差不多，不要慌，优先看 `top`。`ps` 的 `%CPU` 有平均值影响，刚调整后不一定马上变明显。

截图：这一张证明 nice 值改变后 CPU 分配发生变化。

## 第 6 步：结束实验进程

截图完成后执行：

```bash
kill $PID_A $PID_B
pkill nice-exp 2>/dev/null
```

## 报告里怎么写结果

结果分析可以写：

> 两个 CPU 密集型进程绑定到同一 CPU 核心后会竞争同一处理器时间。调整其中一个进程的 nice 值后，nice 值较大的进程优先级降低，获得的 CPU 时间减少；nice 值较小的进程相对获得更多 CPU 时间，说明 Linux CFS 调度器会根据进程权重分配运行时间。

