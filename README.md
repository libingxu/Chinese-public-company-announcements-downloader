README.md
cninfo-downloader
Download announcements (公告) from Chinese stock exchange using cninfo.com.cn API.

Features
Download PDF, HTML, DOCX announcements
Support for both SZSE and SSE stocks
Incremental download (skip already downloaded)
Re-download invalid/corrupt files
Clean filenames
Progress tracking
Requirements
bash
curl
jq
pandoc (for HTML → PDF conversion, optional)
Usage
# Download announcements for a stock
./cninfo-announcements-downloader.sh download 600900 ./output

# Download with custom directory
./cninfo-announcements-downloader.sh download 000001 ./my_announcements

# Re-download invalid files
./cninfo-announcements-downloader.sh redownload 600900 ./output

# Verify downloaded files
./cninfo-announcements-downloader.sh verify 600900 ./output
Arguments
Argument	Description
download	Download mode
redownload	Re-download failed files
verify	Verify file integrity
<stock_code>	6-digit stock code (e.g., 600900)
<save_dir>	Output directory
Examples
# Download 长江电力 announcements
./cninfo-announcements-downloader.sh download 600900 ./600900_announcements

# Download 平安银行 announcements  
./cninfo-announcements-downloader.sh download 000001 ./bank_announcements

# Check for new announcements (incremental)
./cninfo-announcements-downloader.sh download 600900 ./600900_announcements
Stock Code Format
SSE (上海): 6-digit codes starting with 5, 6, 8, 9 (e.g., 600900, 688001)
SZSE (深圳): 6-digit codes starting with 0, 1, 2, 3 (e.g., 000001, 300750)
Output Structure
600900_announcements/
├── 2024/
│   ├── Q1/
│   │   ├── 600900_2024-01-15_年度报告.pdf
│   │   ├── 600900_2024-01-15_年度报告.html
│   │   └── 600900_2024-03-20_一季度报告.pdf
│   └── Q2/
│   └── ...
├── 2025/
│   └── ...
└── .last_download_time
Notes
Incremental download is enabled by default (uses .last_download_time)
To force full re-download, delete .last_download_time file
Files are organized by year and quarter
License
MIT License

Contributing
Pull requests welcome! Issues, feature requests, and improvements appreciated.
