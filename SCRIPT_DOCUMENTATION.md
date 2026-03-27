# cninfo-announcements-downloader.sh 脚本说明文档

## 脚本概述

**脚本名称**: cninfo-announcements-downloader.sh  
**版本**: v3.1  
**功能**: 从巨潮资讯网(cninfo.com.cn)批量下载上市公司公告  
**支持格式**: PDF, HTML, DOCX, DOC

---

## 一、功能清单

### 1.1 公告下载 (Phase 1)

| 功能 | 状态 | 说明 |
|------|------|------|
| 批量下载PDF | ✅ | 下载PDF格式公告 |
| 批量下载HTML | ✅ | 下载HTML格式公告 |
| 批量下载DOCX | ✅ | 下载DOCX格式研报 |
| 批量下载DOC | ✅ | 下载旧DOC格式 |
| 智能文件命名 | ✅ | `{日期}_{标题}.pdf` 格式 |
| 重试机制 | ✅ | 3次重试，间隔2秒 |
| 增量下载 | ✅ | 检测新公告，避免重复下载 |
| 时间记录 | ✅ | 保存最后下载时间戳 |

### 1.2 研报下载 (Phase 2)

| 功能 | 状态 | 说明 |
|------|------|------|
| 研报下载 | ✅ | 使用 tabName=relation |
| 研报时间记录 | ✅ | 独立研报时间跟踪 |

### 1.3 文件验证 (Phase 3)

| 功能 | 状态 | 说明 |
|------|------|------|
| 本地文件扫描 | ✅ | 扫描PDF/HTML/DOCX |
| 文件验证 | ✅ | 验证文件有效性 |
| 验证报告 | ✅ | 彩色输出统计 |
| 重新下载 | ✅ | 重新下载无效文件 |

### 1.4 辅助功能

| 功能 | 状态 | 说明 |
|------|------|------|
| 交互式菜单 | ✅ | 多模式选择 |
| 统计报告 | ✅ | 显示文件数量和大小 |
| 错误处理 | ✅ | 完善的异常处理 |
| 日志输出 | ✅ | 彩色日志显示 |

---

## 二、目录结构

```
[保存目录]/
├── pdf/                 # PDF文件
├── html/                # HTML文件
├── docx/                # DOCX文件
├── doc/                 # DOC文件
├── enhanced_pdf/        # 增强版PDF
├── relation/           # 研报目录
│   ├── pdf/
│   ├── html/
│   └── docx/
└── .last_download_time  # 时间记录(JSON)
```

---

## 三、核心函数

### 3.1 下载函数

| 函数名 | 功能 |
|--------|------|
| `download_pdf()` | 下载PDF文件 |
| `download_html()` | 下载HTML文件 |
| `download_docx()` | 下载DOCX文件 |
| `download_doc()` | 下载DOC文件 |
| `download_announcements()` | 主下载流程 |
| `download_research_reports()` | 研报下载 |

### 3.2 验证函数

| 函数名 | 功能 |
|--------|------|
| `verify_file()` | 验证单个文件 |
| `verify_local_files()` | 批量验证本地文件 |
| `redownload_invalid()` | 重新下载无效文件 |

### 3.3 工具函数

| 函数名 | 功能 |
|--------|------|
| `get_stock_org_id()` | 获取股票orgId |
| `get_column_plate()` | 获取交易所信息 |
| `get_total_pages()` | 获取总页数 |
| `save_last_download_time()` | 保存时间记录 |
| `load_last_download_time()` | 加载时间记录 |
| `is_incremental_download()` | 判断增量下载 |
| `show_statistics()` | 显示统计信息 |
| `show_menu()` | 显示菜单 |

---

## 四、命令用法

### 4.1 交互式菜单

```bash
./cninfo-announcements-downloader.sh
```

显示菜单选项:
1. 下载公告 - 从头下载所有公告
2. 下载研报 - 下载研究报告
3. 验证文件 - 验证本地文件
4. 显示统计 - 查看文件统计
5. 退出 - 退出程序

### 4.2 命令行模式

```bash
# 下载公告
./cninfo-announcements-downloader.sh download <股票代码> <保存目录>

# 下载研报
./cninfo-announcements-downloader.sh reports <股票代码> <保存目录>

# 验证文件
./cninfo-announcements-downloader.sh verify <股票代码> <保存目录>

# 显示统计
./cninfo-announcements-downloader.sh stats <股票代码> <保存目录>
```

---

## 五、技术细节

### 5.1 API端点

```
GET https://www.cninfo.com.cn/new/hisAnnouncement/query

参数:
- stock: 股票代码,orgId
- tabName: fulltext(公告) / relation(研报)
- pageSize: 每页数量(默认30)
- pageNum: 页码
- column: 交易所代码(szse/sse)
- plate: 板块(sz/sh)
- sortName: 排序字段
- sortType: 排序方式(asc/desc)
```

### 5.2 文件命名规则

```
PDF:  {日期}_{清理后的标题}.pdf
HTML: {日期}_{清理后的标题}.html
DOCX: {日期}_{清理后的标题}.docx
DOC:  {日期}_{清理后的标题}.doc
```

### 5.3 时间记录格式

```json
{
  "last_download_timestamp": 1757174400000,
  "last_download_date": "2025-09-07",
  "last_announcement_title": "公告标题",
  "last_announcement_id": "公告ID",
  "download_completed_at": "2025-09-19 19:01:15",
  "stock_code": "600900",
  "format_version": "1.0"
}
```

---

## 六、错误处理

### 6.1 重试机制

- 最大重试次数: 3次
- 重试间隔: 2秒
- 超时时间: 60秒

### 6.2 增量下载逻辑

1. 读取 `.last_download_time` 时间记录
2. 获取网站最新公告时间
3. 如果最新时间 <= 保存时间 → 无新文件
4. 否则 → 执行增量下载

---

## 七、依赖工具

| 工具 | 用途 |
|------|------|
| curl | HTTP请求 |
| jq | JSON解析 |
| bash | 脚本运行环境 |
| python3 | HTML转PDF(可选) |
| wkhtmltopdf | HTML转PDF(可选) |

---

## 八、版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v3.1 | 2026-03-16 | 完整功能版,支持PDF/HTML/DOCX/DOC |
| v3.0 | 2026-03-12 | 基础功能版 |

---

**文档版本**: 1.0  
**更新日期**: 2026-03-16
