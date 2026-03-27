#!/bin/bash

# 长江电力公告下载系统 - 完整版 v3.1
# Author: Development Team
# Date: 2026-03-16

set -uo pipefail  # Removed -e to allow script to continue on errors

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${BLUE}[SUCCESS]${NC} $1"; }

# 配置
DEFAULT_DIR="./financial_data"
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

# 变量
STOCK_CODE=""
SAVE_DIR=""
CACHED_ORG_ID=""
TOTAL_PDF_COUNT=0
TOTAL_HTML_COUNT=0
TOTAL_DOCX_COUNT=0

# ============================================
# 工具函数
# ============================================

clean_filename() {
    echo "$1" | sed 's/[\/\:*?"<>|]/_/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

fix_url_format() {
    local url="$1"
    if [[ "$url" == /* ]]; then
        echo "https://static.cninfo.com.cn$url"
    else
        echo "https://static.cninfo.com.cn/$url"
    fi
}

get_column_plate() {
    local stock_code="$1"
    if [[ "$stock_code" =~ ^(000|001|002|003|300|301|200) ]]; then
        echo "szse sz"
    else
        echo "sse sh"
    fi
}

# ============================================
# Phase 1: 基础下载功能
# ============================================

get_stock_org_id() {
    local stock_code="$1"
    local response=$(curl -s "https://www.cninfo.com.cn/new/information/topSearch/query" \
        -H "Accept: application/json" \
        -H "User-Agent: $USER_AGENT" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-raw "keyWord=${stock_code}&maxNum=10")
    
    local org_id=$(echo "$response" | jq -r ".[] | select(.code == \"$stock_code\") | .orgId" 2>/dev/null)
    
    if [[ -n "$org_id" && "$org_id" != "null" ]]; then
        echo "$org_id"
    else
        echo "gssz0000898"
    fi
}

get_total_pages() {
    local stock_code="$1"
    local org_id="$2"
    local tab_name="${3:-fulltext}"
    
    read -r column plate <<< "$(get_column_plate "$stock_code")"
    
    local url="https://www.cninfo.com.cn/new/hisAnnouncement/query"
    local data="stock=${stock_code}%2C${org_id}&tabName=${tab_name}&pageSize=30&pageNum=1&column=${column}&category=&plate=${plate}&seDate=&searchkey=&secid=&sortName=announcementTime&sortType=asc&isHLtitle=true"
    
    local response=$(curl -s -L "$url" -H "User-Agent: $USER_AGENT" -H "Content-Type: application/x-www-form-urlencoded" --data-raw "$data")
    
    local total=$(echo "$response" | jq -r '.totalRecordNum // .totalAnnouncement // 0')
    echo $(((total + 29) / 30))
}

download_pdf() {
    local url="$1"
    local title="$2"
    local date="$3"
    local save_dir="${4:-$SAVE_DIR}"
    
    local clean_title=$(clean_filename "$title")
    local filename="${save_dir}/pdf/${date}_${clean_title}.pdf"
    local full_url=$(fix_url_format "$url" "$date")
    
    mkdir -p "$(dirname "$filename")"
    
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -sL "$full_url" -H "User-Agent: $USER_AGENT" -o "$filename" --max-time 60; then
            local size=$(stat -c%s "$filename" 2>/dev/null || echo 0)
            if [[ $size -gt 1000 ]]; then
                TOTAL_PDF_COUNT=$((TOTAL_PDF_COUNT + 1))
                return 0
            fi
        fi
        retry_count=$((retry_count + 1))
        sleep 2
    done
    return 1
}

# P1: HTML下载功能
download_html() {
    local announcement_id="$1"
    local title="$2"
    local date="$3"
    local save_dir="${4:-$SAVE_DIR}"
    
    local clean_title=$(clean_filename "$title")
    local filename="${save_dir}/html/${date}_${clean_title}.html"
    local full_url="https://static.cninfo.com.cn/finalpage/${date}/${announcement_id}.html"
    
    mkdir -p "$(dirname "$filename")"
    
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -sL "$full_url" \
            -H "User-Agent: $USER_AGENT" \
            -H "Accept: text/html" \
            -o "$filename" \
            --max-time 30; then
            
            local size=$(stat -c%s "$filename" 2>/dev/null || echo 0)
            local header=$(head -c 20 "$filename" 2>/dev/null || echo "")
            
            if [[ $size -gt 500 && "$header" == *"<html"* || "$header" == *"<!DOCTYPE"* ]]; then
                TOTAL_HTML_COUNT=$((TOTAL_HTML_COUNT + 1))
                echo "$filename"
                return 0
            fi
        fi
        retry_count=$((retry_count + 1))
        sleep 2
    done
    return 1
}

# DOCX下载
download_docx() {
    local url="$1"
    local title="$2"
    local date="$3"
    local save_dir="${4:-$SAVE_DIR}"
    
    local clean_title=$(clean_filename "$title")
    local filename="${save_dir}/docx/${date}_${clean_title}.docx"
    local full_url=$(fix_url_format "$url" "$date")
    
    mkdir -p "$(dirname "$filename")"
    
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -sL "$full_url" -H "User-Agent: $USER_AGENT" -o "$filename" --max-time 60; then
            local size=$(stat -c%s "$filename" 2>/dev/null || echo 0)
            if [[ $size -gt 1000 ]]; then
                TOTAL_DOCX_COUNT=$((TOTAL_DOCX_COUNT + 1))
                return 0
            fi
        fi
        retry_count=$((retry_count + 1))
        sleep 2
    done
    return 1
}

# 新增: DOC旧格式下载
download_doc() {
    local url="$1"
    local title="$2"
    local date="$3"
    local save_dir="${4:-$SAVE_DIR}"
    
    local clean_title=$(clean_filename "$title")
    local filename="${save_dir}/doc/${date}_${clean_title}.doc"
    local full_url=$(fix_url_format "$url" "$date")
    
    mkdir -p "$(dirname "$filename")"
    
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -sL "$full_url" -H "User-Agent: $USER_AGENT" -o "$filename" --max-time 60; then
            local size=$(stat -c%s "$filename" 2>/dev/null || echo 0)
            if [[ $size -gt 500 ]]; then
                log_success "✅ DOC下载成功: $(basename "$filename")"
                return 0
            fi
        fi
        retry_count=$((retry_count + 1))
        sleep 2
    done
    return 1
}

# ============================================
# P4: HTML转PDF转换
# ============================================

convert_html_to_pdf() {
    local html_file="$1"
    local pdf_file="$2"
    
    # 检查是否有wkhtmltopdf
    if command -v wkhtmltopdf &> /dev/null; then
        wkhtmltopdf --enable-local-file-access --encoding UTF-8 "$html_file" "$pdf_file" 2>/dev/null
        return $?
    fi
    
    # 检查是否有chromium
    if command -v chromium &> /dev/null; then
        chromium --headless --print-to-pdf="$pdf_file" "$html_file" 2>/dev/null
        return $?
    fi
    
    log_warn "未安装wkhtmltopdf或chromium,跳过HTML转PDF"
    return 1
}

# ============================================
# 时间跟踪功能 (P2)
# ============================================

save_last_download_time() {
    local save_dir="$1"
    local stock_code="$2"
    local timestamp="$3"
    local title="$4"
    local announcement_id="$5"
    
    local date_str=$(date -d "@$((timestamp/1000))" '+%Y-%m-%d' 2>/dev/null || echo "1970-01-01")
    local json_file="${save_dir}/.last_download_time"
    
    cat > "$json_file" << EOF
{
  "last_download_timestamp": $timestamp,
  "last_download_date": "$date_str",
  "last_announcement_title": "$title",
  "last_announcement_id": "$announcement_id",
  "download_completed_at": "$(date '+%Y-%m-%d %H:%M:%S')",
  "stock_code": "$stock_code",
  "format_version": "1.0"
}
EOF
    log_info "时间记录已保存: $json_file"
}

load_last_download_time() {
    local save_dir="$1"
    local json_file="${save_dir}/.last_download_time"
    
    if [[ -f "$json_file" ]]; then
        jq -r '.last_download_timestamp // 0' "$json_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# ============================================
# P7: 增量下载判断
# ============================================

is_incremental_download() {
    local save_dir="$1"
    local last_timestamp="$2"
    local saved_timestamp
    
    saved_timestamp=$(load_last_download_time "$save_dir")
    
    if [[ "$saved_timestamp" -gt 0 && "$last_timestamp" -le "$saved_timestamp" ]]; then
        return 0  # 增量下载
    else
        return 1  # 完整下载
    fi
}

# ============================================
# Phase 2: 研报下载功能
# ============================================

download_research_reports() {
    local stock_code="$1"
    local org_id="$2"
    local save_dir="$3"
    
    mkdir -p "$save_dir/relation"
    
    read -r column plate <<< "$(get_column_plate "$stock_code")"
    
    # 使用tabName=relation获取研报
    local total_pages=$(get_total_pages "$stock_code" "$org_id" "relation")
    log_info "研报总页数: $total_pages"
    
    local url="https://www.cninfo.com.cn/new/hisAnnouncement/query"
    
    for page in $(seq 1 $total_pages); do
        log_info "下载研报第 $page/$total_pages 页..."
        
        local data="stock=${stock_code}%2C${org_id}&tabName=relation&pageSize=30&pageNum=${page}&column=${column}&category=&plate=${plate}&seDate=&searchkey=&secid=&sortName=announcementTime&sortType=asc&isHLtitle=true"
        
        local response=$(curl -s -L "$url" -H "User-Agent: $USER_AGENT" -H "Content-Type: application/x-www-form-urlencoded" --data-raw "$data")
        
        local announcements=$(echo "$response" | jq -r '.announcements[] | @base64' 2>/dev/null)
        
        for ann in $announcements; do
            local announcement_id=$(echo "$ann" | base64 --decode | jq -r '.announcementId')
            local announcement_time=$(echo "$ann" | base64 --decode | jq -r '.announcementTime')
            local announcement_title=$(echo "$ann" | base64 --decode | jq -r '.announcementTitle')
            local adjunct_url=$(echo "$ann" | base64 --decode | jq -r '.adjunctUrl')
            local date_str=$(date -d "@$((announcement_time/1000))" '+%Y-%m-%d' 2>/dev/null || echo "1970-01-01")
            
            if [[ -n "$adjunct_url" && "$adjunct_url" != "null" ]]; then
                if [[ "$adjunct_url" == *.pdf || "$adjunct_url" == *.PDF ]]; then
                    download_pdf "$adjunct_url" "$announcement_title" "$date_str" "$save_dir/relation"
                elif [[ "$adjunct_url" == *.docx || "$adjunct_url" == *.DOCX ]]; then
                    download_docx "$adjunct_url" "$announcement_title" "$date_str" "$save_dir/relation"
                elif [[ "$adjunct_url" == *.doc || "$adjunct_url" == *.DOC ]]; then
                    download_doc "$adjunct_url" "$announcement_title" "$date_str" "$save_dir/relation"
                fi
            fi
        done
        
        sleep 1
    done
    
    # 保存研报时间记录
    save_last_download_time "$save_dir" "$stock_code" "$(date +%s)000" "research_reports" "latest"
    log_success "研报下载完成"
}

# ============================================
# Phase 1: 主下载流程
# ============================================

download_announcements() {
    local stock_code="$1"
    local org_id="$2"
    local save_dir="$3"
    
    mkdir -p "$save_dir/pdf" "$save_dir/html" "$save_dir/docx" "$save_dir/doc" "$save_dir/enhanced_pdf"
    
    read -r column plate <<< "$(get_column_plate "$stock_code")"
    
    local total_pages=$(get_total_pages "$stock_code" "$org_id")
    log_info "总页数: $total_pages"
    
    # ===== 强制全量下载 - 移除增量检查以确保下载所有历史公告 =====
    # 如需增量下载功能，可手动删除 .last_download_time 文件
    log_info "执行全量下载..."
    # ===== 增量下载检查结束 =====
    
    local url="https://www.cninfo.com.cn/new/hisAnnouncement/query"
    local last_id=""
    local last_time=0
    
    for page in $(seq 1 $total_pages); do
        log_info "处理第 $page/$total_pages 页..."
        
        local data="stock=${stock_code}%2C${org_id}&tabName=fulltext&pageSize=30&pageNum=${page}&column=${column}&category=&plate=${plate}&seDate=&searchkey=&secid=&sortName=announcementTime&sortType=asc&isHLtitle=true"
        
        local response=$(curl -s -L "$url" -H "User-Agent: $USER_AGENT" -H "Content-Type: application/x-www-form-urlencoded" --data-raw "$data")
        
        local announcements=$(echo "$response" | jq -r '.announcements[] | @base64' 2>/dev/null)
        
        for ann in $announcements; do
            local announcement_id=$(echo "$ann" | base64 --decode | jq -r '.announcementId')
            local announcement_time=$(echo "$ann" | base64 --decode | jq -r '.announcementTime')
            local announcement_title=$(echo "$ann" | base64 --decode | jq -r '.announcementTitle')
            local adjunct_url=$(echo "$ann" | base64 --decode | jq -r '.adjunctUrl')
            local date_str=$(date -d "@$((announcement_time/1000))" '+%Y-%m-%d' 2>/dev/null || echo "1970-01-01")
            
            # 记录最新的公告信息
            if [[ "$announcement_time" -gt "$last_time" ]]; then
                last_time=$announcement_time
                last_id=$announcement_id
            fi
            
            if [[ -n "$adjunct_url" && "$adjunct_url" != "null" ]]; then
                if [[ "$adjunct_url" == *.pdf || "$adjunct_url" == *.PDF ]]; then
                    download_pdf "$adjunct_url" "$announcement_title" "$date_str" "$save_dir"
                elif [[ "$adjunct_url" == *.html || "$adjunct_url" == *.HTML ]]; then
                    download_html "$announcement_id" "$announcement_title" "$date_str" "$save_dir"
                elif [[ "$adjunct_url" == *.docx || "$adjunct_url" == *.DOCX ]]; then
                    download_docx "$adjunct_url" "$announcement_title" "$date_str" "$save_dir"
                elif [[ "$adjunct_url" == *.doc || "$adjunct_url" == *.DOC ]]; then
                    download_doc "$adjunct_url" "$announcement_title" "$date_str" "$save_dir"
                fi
            fi
        done
        
        sleep 1
    done
    
    # 保存时间记录
    save_last_download_time "$save_dir" "$stock_code" "$last_time" "$last_id" "$last_id"
    
    # 打印统计
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "              📊 下载统计报告"
    echo "════════════════════════════════════════════════════"
    echo "📊 PDF文件: $TOTAL_PDF_COUNT"
    echo "📊 HTML文件: $TOTAL_HTML_COUNT"
    echo "📊 DOCX文件: $TOTAL_DOCX_COUNT"
    echo "════════════════════════════════════════════════════"
}

# ============================================
# Phase 3: 文件验证功能
# ============================================

verify_file() {
    local file_path="$1"
    local file_type="$2"
    
    if [[ ! -f "$file_path" ]]; then
        return 2  # missing
    fi
    
    local size=$(stat -c%s "$file_path" 2>/dev/null || echo 0)
    
    if [[ $size -lt 1000 ]]; then
        return 3  # invalid
    fi
    
    if [[ "$file_type" == "pdf" ]]; then
        local header=$(head -c 5 "$file_path")
        if [[ "$header" != "%PDF-" ]]; then
            return 3
        fi
    elif [[ "$file_type" == "docx" ]]; then
        local header=$(head -c 4 "$file_path")
        if [[ "$header" != "PK\x03\x04" ]]; then
            return 3
        fi
    elif [[ "$file_type" == "html" ]]; then
        local header=$(head -c 20 "$file_path")
        if [[ "$header" != *"<html"* && "$header" != *"<!DOCTYPE"* ]]; then
            return 3
        fi
    fi
    
    return 0  # valid
}

# P6: 重新下载无效文件
redownload_invalid() {
    local save_dir="$1"
    local stock_code="$2"
    local org_id="$3"
    
    log_info "开始重新下载无效文件..."
    
    local invalid_files=()
    while IFS= read -r -d '' file; do
        if ! verify_file "$file" "pdf"; then
            invalid_files+=("$file")
        fi
    done < <(find "$save_dir" -iname "*.pdf" -type f -print0 2>/dev/null)
    
    log_info "发现 ${#invalid_files[@]} 个无效文件"
    
    for file in "${invalid_files[@]}"; do
        log_warn "删除无效文件: $(basename "$file")"
        rm -f "$file"
    done
    
    # 重新下载
    log_info "重新下载所有公告..."
    download_announcements "$stock_code" "$org_id" "$save_dir"
}

verify_local_files() {
    local save_dir="$1"
    local stock_code="$2"
    local org_id="$3"
    
    log_info "开始验证文件..."
    
    local total=0
    local valid=0
    local invalid=0
    local missing=0
    
    # 扫描PDF
    local pdf_files=()
    while IFS= read -r -d '' file; do
        pdf_files+=("$file")
    done < <(find "$save_dir" -iname "*.pdf" -type f -print0 2>/dev/null)
    
    # 扫描HTML
    local html_files=()
    while IFS= read -r -d '' file; do
        html_files+=("$file")
    done < <(find "$save_dir" -iname "*.html" -type f -print0 2>/dev/null)
    
    # 扫描DOCX
    local docx_files=()
    while IFS= read -r -d '' file; do
        docx_files+=("$file")
    done < <(find "$save_dir" -iname "*.docx" -type f -print0 2>/dev/null)
    
    total=$(( ${#pdf_files[@]} + ${#html_files[@]} + ${#docx_files[@]} ))
    log_info "本地文件数: PDF=${#pdf_files[@]}, HTML=${#html_files[@]}, DOCX=${#docx_files[@]}"
    
    for file in "${pdf_files[@]}"; do
        if verify_file "$file" "pdf"; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
            log_warn "无效PDF: $(basename "$file")"
        fi
    done
    
    for file in "${html_files[@]}"; do
        if verify_file "$file" "html"; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
        fi
    done
    
    for file in "${docx_files[@]}"; do
        if verify_file "$file" "docx"; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
        fi
    done
    
    # 打印报告
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "              📊 验证结果报告"
    echo "════════════════════════════════════════════════════"
    echo "📁 目录: $save_dir"
    echo "📊 总文件数: $total"
    echo "   - PDF: ${#pdf_files[@]}"
    echo "   - HTML: ${#html_files[@]}"
    echo "   - DOCX: ${#docx_files[@]}"
    echo "✅ 验证通过: $valid"
    echo "⚠️  无效文件: $invalid"
    echo "❌ 缺失文件: $missing"
    echo "════════════════════════════════════════════════════"
    
    # 询问是否重新下载
    if [[ $invalid -gt 0 ]]; then
        read -p "是否重新下载无效文件？[Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            redownload_invalid "$save_dir" "$stock_code" "$org_id"
        fi
    fi
}

# ============================================
# 统计报告
# ============================================

show_statistics() {
    local save_dir="$1"
    
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "              📊 文件统计"
    echo "════════════════════════════════════════════════════"
    
    local pdf_count=$(find "$save_dir" -iname "*.pdf" -type f 2>/dev/null | wc -l)
    local html_count=$(find "$save_dir" -iname "*.html" -type f 2>/dev/null | wc -l)
    local docx_count=$(find "$save_dir" -iname "*.docx" -type f 2>/dev/null | wc -l)
    local total_size=$(du -sh "$save_dir" 2>/dev/null | cut -f1)
    
    echo "📄 PDF: $pdf_count"
    echo "📄 HTML: $html_count"
    echo "📄 DOCX: $docx_count"
    echo "💾 总大小: $total_size"
    
    if [[ -f "${save_dir}/.last_download_time" ]]; then
        echo ""
        echo "上次下载:"
        cat "${save_dir}/.last_download_time" | jq -r '.download_completed_at // "unknown"'
    fi
    
    echo "════════════════════════════════════════════════════"
}

# ============================================
# 主程序
# ============================================

show_menu() {
    echo ""
    echo "════════════════════════════════════════════════════"
    echo "       长江电力公告下载系统 v3.1"
    echo "════════════════════════════════════════════════════"
    echo "1. 下载公告 (PDF+HTML+DOCX)"
    echo "2. 下载研报"
    echo "3. 验证本地文件"
    echo "4. 显示统计"
    echo "5. 退出"
    echo "════════════════════════════════════════════════════"
    read -p "请选择 [1-5]: " choice
}

main() {
    local mode="${1:-menu}"
    local stock_code="${2:-600900}"
    local save_dir="${3:-./financial_data}"
    
    echo "股票代码: $stock_code"
    echo "保存目录: $save_dir"
    
    # 获取orgId
    log_info "获取股票信息..."
    CACHED_ORG_ID=$(get_stock_org_id "$stock_code")
    log_info "OrgId: $CACHED_ORG_ID"
    
    # 创建目录
    mkdir -p "$save_dir/pdf" "$save_dir/html" "$save_dir/docx" "$save_dir/doc" "$save_dir/enhanced_pdf"
    
    # 根据模式执行
    case "$mode" in
        download)
            download_announcements "$stock_code" "$CACHED_ORG_ID" "$save_dir"
            ;;
        download-reports|reports)
            download_research_reports "$stock_code" "$CACHED_ORG_ID" "$save_dir"
            ;;
        verify)
            verify_local_files "$save_dir" "$stock_code" "$CACHED_ORG_ID"
            ;;
        stats)
            show_statistics "$save_dir"
            ;;
        menu)
            show_menu
            ;;
        *)
            echo "用法: $0 {download|download-reports|verify|stats|menu} [股票代码] [保存目录]"
            ;;
    esac
}

main "$@"
