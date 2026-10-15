# Meta Analysis Studio V0.2.1

本地 Windows R/Shiny 元分析工作室。**这不是 GitHub Pages 静态网页**：需要在安装 R 的 Windows 电脑上运行。

## 启动

解压 ZIP，双击 `START_META.bat`。自动查找 `Rscript.exe`；如未找到，粘贴 Rscript.exe 完整路径。首次安装 R 包需要联网。或在 RStudio 执行 `shiny::runApp('F:/meta_studio_v021',launch.browser=TRUE)`（请修改为实际目录）。

## 数据格式

连续型：`study_id,n_t,mean_t,sd_t,n_c,mean_c,sd_c`。
二分类：`study_id,event_t,n_t,event_c,n_c`。
通用：`study_id,yi,vi`。二分类效应量内部在 log 尺度拟合，展示及导出时转换为比值尺度。

提供 CSV 模板下载，支持 CSV 和 Excel .xlsx（使用 readxl）。统计引擎使用 metafor 的 REML 随机效应模型，可选 Hartung–Knapp。森林图支持 PNG 300 DPI 和矢量 PDF。

## 投稿注意

- 自动检查不能识别所有重复试验、多臂设计、变化值与终点值的混淆、结局方向及依赖效应量。
- 仅对零单元格使用 0.5 连续性校正。需评估稀疏事件分析的替代方法。
- 预测区间在研究数很少时可能不稳定；发表偏倚与网状 Meta 尚未实现。
- 使用真实数据时应核验效应量、方差、图表及结果表，与独立参考计算交叉核对。
- 分析包包含输入数据、完整 R 脚本、统计结果、版本信息；ZIP 导出依赖系统可用 zip 程序。
- 此版本尚未在用户 Windows 环境进行实机统计验证，不应声称已通过投稿级验证。

软件开发：苏裕盛 教授／医学博士
