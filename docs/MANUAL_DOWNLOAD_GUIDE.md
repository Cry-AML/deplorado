# DepMap 数据下载指南

本文档说明如何批量补全 DepMap 数据集文件：链接获取方式、校验方式，以及已知问题。
（迁移自 `depmap-compliment` 工作区，路径已改为相对工具仓库根目录。）

---

## 一、下载原理

DepMap 提供文件索引接口 `https://depmap.org/portal/api/download/files`，返回一份 CSV，包含：

- `release`：数据发布版本
- `release_date`：发布日期
- `filename`：文件名
- `url`：下载链接（带签名）
- `md5_hash`：文件哈希，用于校验

### 核心优势

1. **动态获取链接**：每次调用都拿到最新的签名 URL，避免使用会过期的硬编码链接
2. **批量下载**：一次拿到全部文件清单，按需筛选
3. **自动校验**：用索引里的 MD5 校验完整性

> 注意：DepMap 门户目前对部分自动化客户端返回浏览器验证挑战页（HTML 而非 CSV）。
> `scripts/download_from_api.py` 检测到这种情况会直接报错退出，而不是把 HTML 写进数据文件。

---

## 二、获取下载链接

### 方法 1：脚本（推荐）

```bash
python3 scripts/download_from_api.py --list-only
python3 scripts/download_from_api.py --out-dir ./depmap_data
```

脚本默认把文件写入 `<repo>/depmap_data`，可用 `--out-dir` / `--log-dir` / `--api-url` 覆盖。

### 方法 2：命令行

```bash
curl -s "https://depmap.org/portal/api/download/files" \
  | grep "目标文件名" | cut -d',' -f4
```

---

## 三、已知问题

### 1. 硬编码 URL 过期

旧脚本保存了带 `Expires=1767438631` 的签名 URL，过期后无法访问。解决方式是走索引接口动态取链接。
`scripts/manual_download_retry.sh` 是这类旧脚本的历史留存。

### 2. sanger-dose-response.csv

最初以为不在索引中，实际存在，需要用最新索引返回的链接。

### 3. metmap125 文件格式

索引里没有 `metmap125_metastatic_potential_matrix.csv`，只有 Excel 版本：

1. 从 Figshare 下载 Excel：`https://ndownloader.figshare.com/files/24009335`
2. 用 pandas 读取并转换为 CSV：

```python
import pandas as pd

excel_file = "metmap125.xlsx"
frames = []
for sheet in ["metp125.brain", "metp125.lung", "metp125.liver", "metp125.bone", "metp125.all4"]:
    frame = pd.read_excel(excel_file, sheet_name=sheet)
    frame.columns = ["cell_line", "CI.05", "CI.95", "mean"]
    frame["organ"] = sheet.replace("metp125.", "")
    frames.append(frame)

pd.concat(frames, ignore_index=True).to_csv(
    "metmap125_metastatic_potential_matrix.csv", index=False
)
```

原始 Excel 保留为 `metmap125.xlsx`，未随主数据镜像上传（见下）。

### 4. Figshare 返回 0 字节

可能由网络代理/防火墙导致，改用命令行 `curl`/`wget` 直接下载。

### 5. CTRPv2.0_2015_ctd2_ExpandedDataset.zip 损坏

- 原始来源 `ctd2-data.nci.nih.gov/.../CTRPv2.0_2015_ctd2_ExpandedDataset.zip` 已下线，
  现在重定向到 NCI Index of Studies 前端页面。
- 本地两份副本（主目录 25,338,290 B 与 compliment 6,016,217 B）**都缺少 ZIP 中央目录**
  （`unzip`/`zipfile` 均判定不是有效压缩包），即下载时被截断。
- 修复途径：从 Wayback 快照
  `http://web.archive.org/web/20241211195811id_/https://ctd2-data.nci.nih.gov/Public/Broad/CTRPv2.0_2015_ctd2_ExpandedDataset/CTRPv2.0_2015_ctd2_ExpandedDataset.zip`
  重新获取，或在 DepMap 门户手动下载后校验。

---

## 四、已补全文件清单

| 文件名 | 大小 | 数据来源 |
|--------|------|----------|
| CCLE_miRNA_MIMAT.csv | 9.3 MB | CCLE 2019 |
| CCLE_GlobalChromatinProfiling_20181130.csv | 477 KB | CCLE 2019 |
| CCLE_RRBS_TSS1kb_20181022.txt.gz | 39 MB | CCLE 2019 |
| CTRPv2.0_2015_ctd2_ExpandedDataset.zip | ~5.8 MB / 24 MB | CTRP CTD^2（损坏，待修） |
| OmicsExpressionGeneSetEnrichment.csv | 24 MB | DepMap Public 24Q2 |
| Repurposing_Public_24Q2_Extended_Primary_Data_Matrix.csv | 12 MB | PRISM Primary Repurposing 24Q2 |
| secondary-screen-dose-response-curve-parameters.csv | 277 MB | PRISM Repurposing 19Q4 |
| harmonized_MS_CCLE_Gygi.csv | 61 MB | Harmonized Public Proteomics 24Q4 |
| metmap500_metastatic_potential_matrix.csv | 51 KB | MetMap |
| metmap500_penetrance_matrix.csv | 35 KB | MetMap |
| metmap125_metastatic_potential_matrix.csv | 47 KB | MetMap（Excel 转换） |
| sanger-dose-response.csv | 92 MB | Sanger GDSC1/GDSC2 |
| sanger_combination_library_viability_breadbox_data.csv | 601 KB | Sanger Drug Combinations 2022 |
| sanger_combination_anchor_viability_breadbox_data.csv | 127 KB | Sanger Drug Combinations 2022 |
| sanger_combination_combo_viability_breadbox_data.csv | 31 MB | Sanger Drug Combinations 2022 |
| sanger_combination_library_fit_breadbox_data.csv | 78 KB | Sanger Drug Combinations 2022 |
| sanger_combination_combo_fit_breadbox_data.csv | 4.0 MB | Sanger Drug Combinations 2022 |

---

## 五、相关文件

- `scripts/download_from_api.py`：索引驱动下载脚本（推荐）
- `scripts/manual_download_retry.sh`：旧版下载脚本（硬编码签名 URL 已过期）
- `docs/manual_download_checklist.csv`：原始下载清单（含历史 `target_path` 与 `retry_url`）
