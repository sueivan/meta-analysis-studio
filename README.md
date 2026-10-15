# Meta Analysis Studio V0.2.1 修复包

将本文件夹作为完整应用使用，双击 `START_META.bat`。若 R 安装路径不常见，启动器会弹出文件选择框，请选 `Rscript.exe`。

也可以在 RStudio Console 中运行：

```r
shiny::runApp("F:/meta_studio_v021_fix", launch.browser=TRUE)
```

首次安装依赖：`install.packages(c("shiny", "metafor", "readxl", "zip"))`。

修复：森林图 slab 变量求值问题；导出脚本同步修复；ZIP 导出优先使用 R zip 包。

**验证状态**：完成源代码修改和文件打包；当前环境没有 R，因此尚未实际执行 R Shiny 和数值一致性测试。正式投稿前需以已知数据验证效应量、模型与图表。
