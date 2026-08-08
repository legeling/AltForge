# Process And Resource Rules

## 启动前

- 启动 Xcode build、test、simulator、AltServer、浏览器、listener 或后台脚本前检查等效进程、目标设备和端口占用。
- 优先运行可等待退出码的前台命令，并设置合理 timeout、输出上限、重试上限和并发上限。
- 需要隔离 build 时使用任务专属 DerivedData/临时目录，记录路径、PID/session 和端口。

## 运行中

- 不忙轮询；使用命令等待、事件或有界退避。
- 只操作当前任务创建的 process、simulator、connection、temporary directory 和 server。
- 不按模糊进程名批量终止，也不关闭用户 VPN、代理、AltServer、Xcode 或其他既有服务。
- 下载、构建和测试输出要有大小边界；失败重试必须保留最终错误并停止在有限次数内。

## 结束门禁

- 等待必要命令完成并记录退出码；不把仍运行的必要 session 留给最终回复。
- 停止当前任务创建且不再需要的 server、browser、simulator 和子进程，释放文件、锁、连接和 device session。
- 删除当前任务创建且不再需要的临时文件、DerivedData、测试数据和大型日志，不删除任务前已有内容。
- 只有用户需要立即试用时保留一个开发服务，并报告 URL、端口、PID/会话、保留原因和停止方式。
