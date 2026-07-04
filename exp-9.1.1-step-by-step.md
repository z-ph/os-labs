# 9.1.1 进程调度与优先级实验分步操作

这个实验按步骤做，不要把所有命令一次性粘贴进去。每一步看清现象后再继续。

这里使用单线程 CPU 密集型程序，然后启动两个独立进程。这样更符合“进程调度”实验，也能避免主进程等待线程导致 `top` 里现象不清楚。

## 第 1 步：创建并编译程序

在 Kylin 终端执行：

```bash
mkdir -p ~/labs/cfs_experiment
cd ~/labs/cfs_experiment
cat > nice-exp.c <<'EOF'
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

int main(void)
{
    printf("pid:%d\n", getpid());
    while (1) {
    }
    return 0;
}
EOF
gcc nice-exp.c -o nice-exp
ls -l nice-exp
```

截图：能看到 `nice-exp` 文件生成。

## 第 2 步：启动两个独立进程并绑定到同一个 CPU

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

注意：后面的命令都要在同一个终端里执行，因为 `$PID_A` 和 `$PID_B` 只在当前终端有效。

## 第 3 步：确认两个进程真的在同一个 CPU 核心

执行：

```bash
taskset -cp $PID_A
taskset -cp $PID_B
ps -o pid,stat,ni,psr,pcpu,comm -p $PID_A,$PID_B
```

你要看两点：

- `taskset -cp` 输出里两个进程的 CPU affinity 都是 `0`。
- `ps` 输出里两个进程的 `PSR` 都是 `0`，说明两个进程在同一个 CPU 核心竞争。

截图：这一张证明两个进程在同一个 CPU 核心竞争。

如果 `PSR` 不一样，先执行：

```bash
pkill nice-exp
```

然后回到第 2 步重新启动。

## 第 4 步：降低其中一个进程优先级

为了让现象更明显，把 `PID_B` 的 nice 值调大到 `19`：

```bash
renice -n 19 -p $PID_B
sleep 8
ps -o pid,stat,ni,psr,pcpu,comm -p $PID_A,$PID_B
```

看 `NI` 列：

- `PID_A` 应该还是 `0`。
- `PID_B` 应该变成 `19`。

如果 `NI` 没有变成 `19`，说明 `renice` 没成功，先不要截图。

## 第 5 步：观察 CPU 占用变化

用 `top` 看实时占比：

```bash
top -p $PID_A,$PID_B
```

进入 `top` 后等 5 到 10 秒再截图。

预期现象：

- `NI=0` 的进程 CPU 占用更高。
- `NI=19` 的进程 CPU 占用更低。

如果刚进入 `top` 还是差不多，就再等几秒。`ps` 的 `%CPU` 会受平均值影响，刚调整完不一定马上明显。

截图：这一张证明 nice 值改变后 CPU 分配发生变化。

## 第 6 步：结束实验进程

截图完成后执行：

```bash
kill $PID_A $PID_B
pkill nice-exp 2>/dev/null
```

## 报告里怎么写结果

结果分析可以写：

> 两个单线程 CPU 密集型进程绑定到同一 CPU 核心后会竞争同一处理器时间。调整前两个进程的 nice 值相同，CPU 占比接近；将 PID_B 的 nice 值调整为 19 后，该进程优先级降低，获得的 CPU 时间减少，而 nice 值仍为 0 的 PID_A 获得更多 CPU 时间，说明 Linux CFS 调度器会根据 nice 值对应的权重分配运行时间。
