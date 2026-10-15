options(shiny.maxRequestSize=40*1024^2)
if (!requireNamespace('shiny',quietly=TRUE)) stop('请安装 shiny')
library(shiny)
PASS <- '检查通过。仍须人工核对研究独立性、结局方向及多臂试验。'
required_cols <- function(type) switch(type,continuous=c('study_id','n_t','mean_t','sd_t','n_c','mean_c','sd_c'),binary=c('study_id','event_t','n_t','event_c','n_c'),generic=c('study_id','yi','vi'))
read_study <- function(path,name){if(grepl('\\.xlsx$',name,ignore.case=TRUE)){if(!requireNamespace('readxl',quietly=TRUE))stop('请安装 readxl 后导入 Excel');as.data.frame(readxl::read_excel(path))}else{read.csv(path,check.names=FALSE,fileEncoding='UTF-8-BOM',stringsAsFactors=FALSE)}}
validate_study <- function(d,type){
 missing<-setdiff(required_cols(type),names(d));if(length(missing))return(paste('缺少字段：',paste(missing,collapse=', ')))
 if(nrow(d)<2)return('至少需要两行研究数据。')
 ids<-trimws(as.character(d$study_id));if(anyNA(ids)||any(!nzchar(ids)))return('study_id 不可为空。')
 if(anyDuplicated(ids))return('研究编号重复：请先核对多臂试验、重复报告或相关效应量。')
 num<-setdiff(required_cols(type),'study_id');for(nm in num){v<-suppressWarnings(as.numeric(d[[nm]]));if(anyNA(v)||any(!is.finite(v)))return(paste('字段',nm,'含缺失或非数字值。'));d[[nm]]<-v}
 if(type=='continuous' && (any(d$n_t<2|d$n_c<2|d$sd_t<=0|d$sd_c<=0)))return('连续型数据要求两组样本量≥2，SD>0。')
 if(type=='binary' && (any(d$n_t<=0|d$n_c<=0|d$event_t<0|d$event_c<0|d$event_t>d$n_t|d$event_c>d$n_c)||any(abs(d$n_t-round(d$n_t))>1e-8|abs(d$n_c-round(d$n_c))>1e-8|abs(d$event_t-round(d$event_t))>1e-8|abs(d$event_c-round(d$event_c))>1e-8)))return('二分类事件数/样本量必须为非负整数，事件数不得超过总人数。')
 if(type=='generic' && any(d$vi<=0))return('vi 必须大于零。')
 PASS
}
calc_fit<-function(d,type,measure,knha){
 if(!requireNamespace('metafor',quietly=TRUE))stop('请先安装 metafor')
 if(type=='continuous'){
  e<-metafor::escalc(measure=measure,m1i=d$mean_t,sd1i=d$sd_t,n1i=d$n_t,m2i=d$mean_c,sd2i=d$sd_c,n2i=d$n_c,data=d)
 }else if(type=='binary'){
  e<-metafor::escalc(measure=measure,ai=d$event_t,bi=d$n_t-d$event_t,ci=d$event_c,di=d$n_c-d$event_c,data=d,add=0.5,to='only0')
 }else e<-d
 f<-metafor::rma.uni(yi=e$yi,vi=e$vi,method='REML',test=if(knha)'knha' else 'z')
 list(f=f,e=e,d=d,type=type,measure=measure,knha=knha)
}
fmt<-function(v,digits=3)ifelse(is.finite(v),formatC(v,format='f',digits=digits),'—')
make_script<-function(d,type,measure,knha){
 lines<-c('# Meta Analysis Studio V0.2.1 — reproducible R analysis',paste0('# Created: ',format(Sys.time(),'%Y-%m-%d %H:%M:%S %Z')),'# Place this script and analysis_data.csv in the same directory.','library(metafor)','d <- read.csv("analysis_data.csv", check.names=FALSE, fileEncoding="UTF-8-BOM")',paste0('type <- ',sprintf("\"%s\"",type)),paste0('measure <- ',sprintf("\"%s\"",measure)),paste0('knha <- ',if(knha)'TRUE' else 'FALSE'),'if (anyDuplicated(d$study_id)) stop("Duplicate study_id")', 'if (type == "continuous") {',' e <- metafor::escalc(measure=measure, m1i=d$mean_t,sd1i=d$sd_t,n1i=d$n_t,m2i=d$mean_c,sd2i=d$sd_c,n2i=d$n_c,data=d)','} else if (type == "binary") {',' e <- metafor::escalc(measure=measure,ai=d$event_t,bi=d$n_t-d$event_t,ci=d$event_c,di=d$n_c-d$event_c,data=d,add=0.5,to="only0")','} else { e <- d }','fit <- metafor::rma.uni(yi=e$yi,vi=e$vi,method="REML",test=if(knha)"knha" else "z")','print(summary(fit))','print(predict(fit,transf=if(type=="binary")exp else NULL))','png("forest.png",width=3200,height=2400,res=300)','metafor::forest(fit,slab=as.character(d$study_id), atransf=if(type=="binary")exp else NULL, xlab=if(type=="binary")"Ratio (RR / OR)" else "Effect size")','dev.off()','writeLines(capture.output(sessionInfo()),"sessionInfo.txt")')
 paste(lines,collapse='\n')
}
ui<-fluidPage(
 tags$head(tags$meta(name='viewport',content='width=device-width, initial-scale=1'),tags$style(HTML('body{background:#f4f7fb;font-family:"Microsoft YaHei",Arial,sans-serif;color:#18304a}.container-fluid{max-width:1550px}.mast{padding:17px 22px;background:#102f52;color:white;border-radius:14px;margin:15px 0 18px}.mast h2{color:white;margin:0 0 6px;font-weight:700}.mast small{color:#d3e6fa}.well{background:white;border:1px solid #e0e8f0;border-radius:14px;box-shadow:0 4px 20px #183c5a0b}.nav-tabs>li>a{color:#26527b}.nav-tabs>li.active>a{font-weight:700}.btn-primary{background:#1262aa;border:0}.step{font-size:13px;color:#4a708e;font-weight:700;margin-bottom:9px}.summary{display:flex;flex-wrap:wrap;gap:12px;margin:15px 0}.metric{background:#fff;border:1px solid #dce7f1;padding:14px 18px;border-radius:12px;min-width:135px;flex:1}.metric strong{display:block;font-size:22px;color:#123e69}.helptext{font-size:12px;color:#60758a}.shiny-output-error{color:#ba2531!important}.table{background:white}@media(max-width:768px){.mast h2{font-size:22px}.metric{min-width:115px}}'))),
 div(class='mast',h2('Meta Analysis Studio V0.2.1'),tags$small('本地 R 统计引擎 · 中文研究工作流 · 可复现输出')),
 sidebarLayout(sidebarPanel(width=4,
 div(class='step','步骤 1 / 3 · 导入研究数据'),fileInput('file','Excel (.xlsx) 或 CSV',accept=c('.csv','.xlsx')),selectInput('type','结局数据类型',c('连续型（两组均值/SD）'='continuous','二分类（事件数/样本量）'='binary','通用效应量（yi/vi）'='generic')),
 downloadButton('template','下载当前类型数据模板',class='btn-default'),hr(),
 div(class='step','步骤 2 / 3 · 设置统计方法'),uiOutput('measure'),checkboxInput('knha','Hartung–Knapp 调整（需结合研究数量解释）',TRUE),tags$p(class='helptext','随机效应模型：REML；二分类结局默认仅对零单元格采用 0.5 连续性校正。'),
 div(class='step','步骤 3 / 3 · 运行与导出'),actionButton('run','运行 R 分析',class='btn-primary btn-lg'),hr(),
 downloadButton('bundle','下载可复现分析包 ZIP'),tags$p(class='helptext','包含原始导入数据、完整 R 脚本、统计结果与版本记录。'),hr(),
 strong('本机 R 环境'),verbatimTextOutput('versions'),tags$p(class='helptext','研究数据仅在本机 Shiny 会话处理；不自动上传互联网。')),
 mainPanel(width=8,tabsetPanel(id='tabs',
 tabPanel('① 数据核查',h4('数据质量检查'),textOutput('validation'),hr(),tableOutput('preview'),tags$p(class='helptext','自动检查不能代替人工判断：需核对多报告同试验、组内/组间效应及量表方向。')),
 tabPanel('② 统计结果',uiOutput('metrics'),h4('模型摘要'),tableOutput('result_table'),h4('研究层面效应量'),tableOutput('study_table'),h4('完整统计输出'),verbatimTextOutput('results')),
 tabPanel('③ 森林图',plotOutput('forest',height='600px'),downloadButton('png','导出高清森林图 PNG（300 DPI）'),downloadButton('pdf','导出矢量 PDF')),
 tabPanel('④ 分析记录',h4('软件与分析参数'),verbatimTextOutput('session'),tags$p('论文方法学报告应基于实际运行记录，不得把示例数据当作真实研究结果。'))
 ))))
)
server<-function(input,output,session){
 output$measure<-renderUI({selectInput('measure','效应量',switch(input$type,continuous=c('均值差 MD'='MD','标准化均值差 SMD (Hedges g)'='SMD'),binary=c('风险比 RR'='RR','比值比 OR'='OR'),generic=c('通用效应量'='GEN')))})
 output$versions<-renderText({paste0('R ',getRversion(),'\nshiny ',as.character(packageVersion('shiny')),'\nmetafor ',if(requireNamespace('metafor',quietly=TRUE))as.character(packageVersion('metafor')) else '未安装','\nreadxl ',if(requireNamespace('readxl',quietly=TRUE))as.character(packageVersion('readxl')) else '未安装')})
 dat<-reactive({req(input$file);tryCatch(read_study(input$file$datapath,input$file$name),error=function(e)validate(need(FALSE,conditionMessage(e))))})
 check<-reactive({req(dat());validate_study(dat(),input$type)})
 output$validation<-renderText({req(input$file);check()})
 output$preview<-renderTable({req(dat());head(dat(),25)},striped=TRUE,bordered=TRUE)
 output$template<-downloadHandler(filename=function()paste0('meta_template_',input$type,'.csv'),content=function(file){d<-switch(input$type,continuous=data.frame(study_id='Study_01',n_t=30,mean_t=25,sd_t=4,n_c=30,mean_c=23,sd_c=4),binary=data.frame(study_id='Study_01',event_t=8,n_t=30,event_c=12,n_c=30),generic=data.frame(study_id='Study_01',yi=0.25,vi=0.04));write.csv(d,file,row.names=FALSE,fileEncoding='UTF-8')})
 analysis<-eventReactive(input$run,{req(input$file,input$measure);validate(need(check()==PASS,check()));tryCatch(calc_fit(dat(),input$type,input$measure,input$knha),error=function(e)validate(need(FALSE,paste('R 计算失败：',conditionMessage(e)))) )})
 output$metrics<-renderUI({x<-analysis();f<-x$f;div(class='summary',div(class='metric','研究数量',strong(f$k)),div(class='metric','合并效应',strong(fmt(if(x$type=='binary')exp(as.numeric(coef(f))) else as.numeric(coef(f))))),div(class='metric','I²',strong(paste0(fmt(f$I2,1),'%'))),div(class='metric','τ²',strong(fmt(f$tau2))))})
 output$result_table<-renderTable({x<-analysis();f<-x$f;pr<-predict(f,transf=if(x$type=='binary')exp else NULL);data.frame(指标=c('效应量','模型','合并效应','95% CI 下限','95% CI 上限','p 值','I² (%)','τ²','95% 预测区间下限','95% 预测区间上限'),结果=c(x$measure,'随机效应 REML',fmt(pr$pred),fmt(pr$ci.lb),fmt(pr$ci.ub),format.pval(f$pval,digits=3,eps=0.001),fmt(f$I2,1),fmt(f$tau2),fmt(pr$pi.lb),fmt(pr$pi.ub)))},striped=TRUE,bordered=TRUE)
 output$study_table<-renderTable({x<-analysis();e<-x$e;v<-if(x$type=='binary')exp(as.numeric(e$yi)) else as.numeric(e$yi);data.frame(研究=x$d$study_id,效应量=fmt(v),标准误=fmt(sqrt(as.numeric(e$vi))))},striped=TRUE,bordered=TRUE)
 output$results<-renderPrint({x<-analysis();print(summary(x$f));cat('\nPrediction interval (reporting scale):\n');print(predict(x$f,transf=if(x$type=='binary')exp else NULL))})
 draw<-function(){x<-analysis();metafor::forest(x$f,slab=as.character(x$d$study_id),atransf=if(x$type=='binary')exp else NULL,header=c('研究','效应量 [95% CI]'),xlab=if(x$type=='binary')paste0(x$measure,'（比值尺度）') else paste0(x$measure,'（治疗组 − 对照组）'),cex=0.85);title('Meta Analysis Studio · Random-effects REML',cex.main=0.9)}
 output$forest<-renderPlot({draw()},res=110)
 output$png<-downloadHandler(filename=function()paste0('forest_',Sys.Date(),'.png'),content=function(file){req(analysis());grDevices::png(file,width=3200,height=2400,res=300);on.exit(grDevices::dev.off(),add=TRUE);draw()},contentType='image/png')
 output$pdf<-downloadHandler(filename=function()paste0('forest_',Sys.Date(),'.pdf'),content=function(file){req(analysis());grDevices::pdf(file,width=11,height=8.5);on.exit(grDevices::dev.off(),add=TRUE);draw()},contentType='application/pdf')
 output$session<-renderPrint({x<-analysis();cat('数据文件：',input$file$name,'\n数据类型：',x$type,'\n效应量：',x$measure,'\n模型：REML\n推断检验：',if(x$knha)'Hartung-Knapp' else 'z','\n运行时间：',format(Sys.time()),'\n\n');print(sessionInfo())})
 output$bundle<-downloadHandler(filename=function()paste0('meta_reproducible_',Sys.Date(),'.zip'),content=function(file){x<-analysis();td<-tempfile('meta_export_');dir.create(td);write.csv(x$d,file.path(td,'analysis_data.csv'),row.names=FALSE,fileEncoding='UTF-8');writeLines(make_script(x$d,x$type,x$measure,x$knha),file.path(td,'analysis_script.R'),useBytes=TRUE);capture.output(summary(x$f),file=file.path(td,'model_summary.txt'));capture.output(sessionInfo(),file=file.path(td,'sessionInfo.txt'));grDevices::png(file.path(td,'forest.png'),width=3200,height=2400,res=300);tryCatch(draw(),finally=grDevices::dev.off());files<-list.files(td,full.names=FALSE);old<-getwd();on.exit(setwd(old),add=TRUE);setwd(td);utils::zip(zipfile=normalizePath(file,mustWork=FALSE),files=files,flags='-q');if(!file.exists(file))stop('ZIP 创建失败：请检查 Windows 是否有 zip 命令')},contentType='application/zip')
}
shinyApp(ui,server)
