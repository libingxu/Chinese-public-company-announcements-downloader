# 巨潮资讯公告下载器 - 使用手册

## 一、前置要求

### 1.1 系统要求

- **操作系统**: Linux / macOS
- **Shell**: Bash 4.0+
- **网络**: 能访问 internet (cninfo.com.cn)

### 1.2 依赖工具

| 工具 | 安装命令 (Ubuntu/Debian) | 安装命令 (macOS) |
|------|--------------------------|------------------|
| curl | `sudo apt install curl` | 系统自带 |
| jq | `sudo apt install jq` | `brew install jq` |

```bash
# 一键安装依赖 (Ubuntu)
sudo apt update && sudo apt install curl jq

# 一键安装依赖 (macOS)
brew install jq
```

---

## 二、快速开始

### 2.1 下载脚本

```bash
# 方式1: 克隆仓库
git clone <仓库地址>
cd <仓库目录>

# 方式2: 直接下载
curl -O https://raw.githubusercontent.com/xxx/cninfo-announcements-downloader.sh
```

### 2.2 添加执行权限

```bash
chmod +x cninfo-announcements-downloader.sh
```

### 2.3 运行脚本

```bash
# 方式1: 交互式菜单
./cninfo-announcements-downloader.sh

# 方式2: 命令行模式
./cninfo-announcements-downloader.sh download 600900 ./data
```

---

## 三、使用场景

### 3.1 场景一: 首次下载

**目标**: 下载某股票的全部历史公告

```bash
# 命令
./cninfo-announcements-downloader.sh download 600900 /home/user/cninfo/600900
```

**输出示例**:
```
股票代码: 600900
保存目录: /home/user/cninfo/600900
[INFO] 获取股票信息...
[INFO] OrgId: gssh0600900
[INFO] 总页数: 71
[INFO] 处理第 1/71 页...
[INFO] 处理第 2/71 页...
...
[INFO] PDF文件: 1503
[INFO] HTML文件: 0
[INFO] DOCX文件: 0
```

**文件保存位置**:
```
/home/user/cninfo/600900/
├── pdf/
│   ├── 2025-01-01_年度报告.pdf
│   ├── 2024-12-15_季度报告.pdf
│   └── ...
├── html/
├── docx/
├── doc/
└── .last_download_time
```

---

### 3.2 场景二: 增量更新

**目标**: 下载最新发布的公告(不重复下载已有的)

```bash
# 之前已下载过,现在再次运行
./cninfo-announcements-downloader.sh download 600900 /home/user/cninfo/600900
```

**输出示例** (如果没有新公告):
```
股票代码: 600900
保存目录: /home/user/cninfo/600900
[INFO] 获取股票信息...
[INFO] 总页数: 71
[SUCCESS] ✅ 没有新文件需要下载 (最后下载: 2026-03-16)
[INFO] 如需重新下载,请删除 .last_download_time 文件
```

**输出示例** (如果有新公告):
```
[INFO] 检测到新公告,将执行增量下载...
[INFO] 处理第 1/71 页...
...
[INFO] 新增文件: 3
```

---

### 3.3 场景三: 下载研报

**目标**: 下载公司的研究报告

```bash
./cninfo-announcements-downloader.sh reports 600900 /home/user/cninfo/600900
```

**输出**:
```
[INFO] 研报总页数: 15
[INFO] 处理研报第 1/15 页...
...
[SUCCESS] 研报下载完成
```

---

### 3.4 场景四: 验证本地文件

**目标**: 检查已下载的文件是否完整有效

```bash
./cninfo-announcements-downloader.sh verify 600900 /home/user/cninfo/600900
```

**输出示例**:
```
════════════════════════════════════════════════════
              📊 文件验证报告
════════════════════════════════════════════════════
📁 目录: /home/user/cninfo/600900/
📊 总文件数: 1503
   - PDF: 1503
   - HTML: 0
   - DOCX: 0
✅ 验证通过: 1503
⚠️  无效文件: 0
❌ 缺失文件: 0
════════════════════════════════════════════════════
```

---

### 3.5 场景五: 查看统计

**目标**: 查看已下载文件的统计信息

```bash
./cninfo-announcements-downloader.sh stats 600900 /home/user/cninfo/600900
```

**输出示例**:
```
════════════════════════════════════════════════════
              📊 文件统计
════════════════════════════════════════════════════
📄 PDF: 1503
📄 HTML: 0
📄 DOCX: 0
💾 总大小: 883M
════════════════════════════════════════════════════
```

---

## 四、命令行参数

### 4.1 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `download` | 下载公告模式 | `./cninfo-announcements-downloader.sh download 600900 ./data` |
| `reports` | 下载研报模式 | `./cninfo-announcements-downloader.sh reports 600900 ./data` |
| `verify` | 验证文件模式 | `./cninfo-announcements-downloader.sh verify 600900 ./data` |
| `stats` | 统计模式 | `./cninfo-announcements-downloader.sh stats 600900 ./data` |

### 4.2 完整命令示例

```bash
# 交互式菜单
./cninfo-announcements-downloader.sh

# 命令行下载
./cninfo-announcements-downloader.sh download 600900 /path/to/save

# 命令行下载研报
./cninfo-announcements-downloader.sh reports 600900 /path/to/save

# 命令行验证
./cninfo-announcements-downloader.sh verify 600900 /path/to/save

# 命令行统计
./cninfo-announcements-downloader.sh stats 600900 /path/to/save
```

---

## 五、常见问题

### 5.1 权限问题

**问题**: `Permission denied`

**解决**:
```bash
chmod +x cninfo-announcements-downloader.sh
```

### 5.2 jq未安装

**问题**: `jq: command not found`

**解决**:
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq
```

### 5.3 重新下载全部文件

**问题**: 想删除时间记录,重新下载全部

**解决**:
```bash
rm /path/to/save/.last_download_time
./cninfo-announcements-downloader.sh download 600900 /path/to/save
```

### 5.4 下载中断

**问题**: 下载中途网络断开

**解决**:
```bash
# 重新运行会继续下载(增量模式)
./cninfo-announcements-downloader.sh download 600900 /path/to/save
```

---

## 六、注意事项

1. **网络要求**: 需要能访问 `cninfo.com.cn`
2. **频率限制**: 脚本内置1秒间隔,避免被封
3. **磁盘空间**: 预估每股票约 500MB-2GB
4. **时间记录**: 首次下载后会自动记录,不要删除 `.last_download_time`

---

## 七、故障排查

### 7.1 下载失败

检查网络连接:
```bash
curl -I https://www.cninfo.com.cn
```

### 7.2 API返回空

检查股票代码是否正确:
```bash
# 600900 是长江电力
# 000333 是美的集团
```

### 7.3 文件损坏

使用验证功能检查:
```bash
./cninfo-announcements-downloader.sh verify 600900 /path/to/save
```

---

**手册版本**: 1.0  
**更新日期**: 2026-03-16
