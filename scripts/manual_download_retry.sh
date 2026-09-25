#!/usr/bin/env bash
#
# Legacy manual-download retry helper, migrated from the depmap-compliment
# workspace.
#
# NOTE: the signed Google Storage URLs embedded below carry `Expires=` values
# that have already passed, so most entries will return HTTP 400/403. Prefer
# `scripts/download_from_api.py`, which resolves fresh links from the DepMap
# index. This script is kept for provenance and for hosts where the legacy
# signatures are still valid.
set -u
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/depmap_data"
LOG_DIR="$ROOT_DIR/download_logs/manual_retry"
mkdir -p "$OUT_DIR" "$LOG_DIR"
FAILED=0

download_one() {
  local filename="$1"
  local url="$2"
  local logfile="$LOG_DIR/${filename}.log"
  echo "[RUN] $filename" | tee "$logfile"
  if command -v wget >/dev/null 2>&1; then
    timeout 180 wget -c --read-timeout=30 --tries=1 -O "$OUT_DIR/$filename" "$url" >>"$logfile" 2>&1
    return $?
  fi
  timeout 180 curl -L --max-time 180 --retry 1 --retry-delay 2 -o "$OUT_DIR/$filename" "$url" >>"$logfile" 2>&1
}

echo "==== CCLE_miRNA_MIMAT.csv (CCLE 2019) ===="
if download_one "CCLE_miRNA_MIMAT.csv" "https://storage.googleapis.com/depmap-external-downloads/ccle/mirna-573f.3/CCLE_miRNA_MIMAT.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=KF99i7naAYgyxsUnKdP8KH0OV38gPW4obLUiXYPisfTh%252FEuoYJzDSgeGQV3cPUQExcUNbtAdCvmq8Noie9IByCyLdFTsaZ%252FlIHLS9Ajrf%252F5wflBKZxWOjylYhVnCvTwU7fiPo1sovK42MdvxZ%252F8IrtFrCr7IFN1w36c7gH1CcCuXom0t%252FEJQb5UZCdWymfm%252FbHC3JVGKMlINWKkgBwpTrSDcJu4MsbHqjeB5mpVnKp3tpRJwQTEjv30nnny2NAMXgabB1HUqO2%252BY4RpUGq4zJ7My2XVOsSvCpy3xYHceO0Qcstp3qSjXCvY97HJF8zPusapClXDg%252F7ziBkUl2NZOKQ%3D%3D&userProject=broad-achilles"; then
  echo "[OK] CCLE_miRNA_MIMAT.csv"
else
  echo "[FAIL] CCLE_miRNA_MIMAT.csv"
  FAILED=$((FAILED+1))
fi

echo "==== OmicsExpressionGeneSetEnrichment.csv (DepMap Public 24Q2) ===="
if download_one "OmicsExpressionGeneSetEnrichment.csv" "https://ndownloader.figshare.com/files/51065381"; then
  echo "[OK] OmicsExpressionGeneSetEnrichment.csv"
else
  echo "[FAIL] OmicsExpressionGeneSetEnrichment.csv"
  FAILED=$((FAILED+1))
fi

echo "==== harmonized_MS_CCLE_Gygi.csv (Harmonized Public Proteomics 24Q4) ===="
if download_one "harmonized_MS_CCLE_Gygi.csv" "https://storage.googleapis.com/depmap-external-downloads/harmonized-public-proteomics-02cc.1/harmonized_MS_CCLE_Gygi.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=DdRBr2CEK5Z9xV0mKqyj3RMQPeDRwRlcLrXtLIg1iHlxNKPN2IMY%252Faeu5lMX1mHIaFzNrWp%252FX53BcC%252Bcn3LQk9Sn9D417b4s9cHpRdFC%252BPDcJi1GSxhUJVSLK8B2iFGhDVf6O0z%252BoN0t7HSzCvRzO5J5NQG5PaVs%252F%252Fi9tl1ATg8HOWb719uqyFb1pH6dVZHzCbXB0Ots02AyT6KutvqmZhA69thusLKPcjqP07dOi0cSxcIPWsWrTehj9Ik4ofvuMxxnn%252BKo3mUxVaES0TyxPhENJDu1IrACzdW2YyNxgLY%252FXD3gnehA6cGOIJ8gN%252FvOjpvsDKfW2UFBc1JoMaPwuQ%3D%3D&userProject=broad-achilles"; then
  echo "[OK] harmonized_MS_CCLE_Gygi.csv"
else
  echo "[FAIL] harmonized_MS_CCLE_Gygi.csv"
  FAILED=$((FAILED+1))
fi

echo "==== metmap500_metastatic_potential_matrix.csv (MetMap) ===="
if download_one "metmap500_metastatic_potential_matrix.csv" "https://storage.googleapis.com/depmap-external-downloads/metmap/metmap-data-f459.3/metmap500_metastatic_potential_matrix.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=SDjOkPMUzDivQBl13FAES7dhACszfoHIcG54oQEkeg0VXWcXFhB8JDZcn5kB20PF2JNg09a3e%252FXJ%252FnaYJSCaszC%252F6aAYmscO0xW3dCqUijGQrEf8I2ofapD5Cln%252FEWlm8YR%252FoJqXZU3E4XBeJ25XuyF%252BAuOmXjZ6KU4cY34kkPZU%252BLCYLKua6TwlDadsJgCf37CZO8anZa2wPK2JhMfim0RNuZ2jArl%252Bt9S%252FpjLHdWEwBqi12oP1j4WQV0iE1o6T%252F4Yr1lQn980lvbtoZ5hRMGbWw60fzcRKLUpu%252Fp0oPzdBh5Q1dmjtMzls1qPpCVHH%252BfDMEbF%252FswzU5gU1b9J2xw%3D%3D&userProject=broad-achilles"; then
  echo "[OK] metmap500_metastatic_potential_matrix.csv"
else
  echo "[FAIL] metmap500_metastatic_potential_matrix.csv"
  FAILED=$((FAILED+1))
fi

echo "==== metmap500_penetrance_matrix.csv (MetMap) ===="
if download_one "metmap500_penetrance_matrix.csv" "https://storage.googleapis.com/depmap-external-downloads/metmap/metmap-data-f459.3/metmap500_penetrance_matrix.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=aemq6WtkwyRgIf%252BN4tqNs7QvmZyubgMYOG0eTK%252FD3WpzEH%252BLHcPZYGnGhOFKF2%252B0oxSC56sUCkgshSkXKor0ADPVygOpNv6XHe3p85QgbjLiBQbikK5G7cFwSYHLa2%252F%252BtEOn8itq54CWYK6vk7wtj3SL8hWRZdvMeS6g1WXIjT5bqngPjr4J6NlSdnhLt25pDJLMxB1QDjQYESwpsJjx%252Fl%252FCElkzDxF71gVRi36UTMyHYK8CrQxgk%252FJxkl54qnpydBEZtmCNzn0LFc0LaIWY90zn3p%252Bgu64YKKugyGTO99EQ%252BkTJuEs%252F4FX7A%252Fd9GlOAq%252BDU6EHQRYwm%252BIoS9UCZJg%3D%3D&userProject=broad-achilles"; then
  echo "[OK] metmap500_penetrance_matrix.csv"
else
  echo "[FAIL] metmap500_penetrance_matrix.csv"
  FAILED=$((FAILED+1))
fi

echo "==== metmap125_metastatic_potential_matrix.csv (MetMap) ===="
if download_one "metmap125_metastatic_potential_matrix.csv" "https://storage.googleapis.com/depmap-external-downloads/metmap/metmap-data-f459.3/metmap125_metastatic_potential_matrix.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=TpkcdVtzhlouldDlAWw%252FEfk%252Fx1SqTh2kGqjQBq8izbYbKadYqp6%252FYW2V8Og8zECrPQYQ8UjJCzbPkJVmxtcO6eZ29XMZOIQgW06frrNSh4n3nVq9xNQBe4ppwzcixZohPh94b7eqMowxoHXusjdLLB2XrbEuzghmRUz10Pmygsj14DVaUEL7cj5ednWE7HZOGdx%252F99AzTqX9ZzB0FiySwnx%252Fw%252BVcYNyT9%252BjZ3ajpwQ7bKe28zWu5T33%252F1BeuFOyZJATuuFhVk2LXGYCHmhpceDnROuJzo3NlYjIn%252Bcc9dNJg27yC1MzE8fA1FwGCNYGNWdqS3RETmV%252F5S8jh0wwcaw%3D%3D&userProject=broad-achilles"; then
  echo "[OK] metmap125_metastatic_potential_matrix.csv"
else
  echo "[FAIL] metmap125_metastatic_potential_matrix.csv"
  FAILED=$((FAILED+1))
fi

echo "==== CCLE_GlobalChromatinProfiling_20181130.csv (CCLE 2019) ===="
if download_one "CCLE_GlobalChromatinProfiling_20181130.csv" "https://storage.googleapis.com/depmap-external-downloads/ccle/ccle_2019/CCLE_GlobalChromatinProfiling_20181130.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=RnGzkYMX95JHboYpZLF6gaJICI56paCmUXXF%252FPvXTCyNNM3%252FXkSrzZJGJJQqWRTi0H3EcbOhRqWvDwun5Gq8jSUnZd6oPmk23D7J7qR76WXVgY5lJiI7CKi55VDUcMtzx92qQ61sU0Iinszw32vTl4YD7ROlJzQZNHfcBuFmPJ1y720oD%252FMeype4jVvGJaVgWvCHHhTQxXVwvwQjD%252Fa2p91wpWRcCHGBec26cmsKQr0EWvTlzFwJWYtFEtRlNJCIUjT9ABDZgOgFOo3tA33dOewNZhFpSXKwmSR5DqHHozk7fSPUhl6Sb6Uo42E0xzkbB%252BhCCB7CZQC3F1pVMy872A%3D%3D&userProject=broad-achilles"; then
  echo "[OK] CCLE_GlobalChromatinProfiling_20181130.csv"
else
  echo "[FAIL] CCLE_GlobalChromatinProfiling_20181130.csv"
  FAILED=$((FAILED+1))
fi

echo "==== CCLE_RRBS_TSS1kb_20181022.txt.gz (CCLE 2019) ===="
if download_one "CCLE_RRBS_TSS1kb_20181022.txt.gz" "https://storage.googleapis.com/depmap-external-downloads/ccle/ccle_2019/CCLE_RRBS_TSS1kb_20181022.txt.gz?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=XGzsyunlP8XthIk2P%252FKA4MGWLmd1D3p9fLTM6RWz2HwBkhhjDtflI8jJau8%252BJu1NKCPF7WdEtqYzYTfMgJCJ7duJbUulfV028wP1mU%252Buz5fEj0%252FM7jBhqf%252B%252BwzDjrFOJEuc696NuHwwLBi%252BibKcwGsoq%252BITui6hQzCcnTylUkaDmWBRYydglElfyHclG0WEOoKjgWBpzp8waRl8O9XRPNU9kXdi%252FIcrhNUqjsFygSg1yUx0ULY1mKIivGDbf%252FrREGfKqMgzYXP1euwmled1rYlZdIDATqOvTJOcG0f07rrLMm2TxF0SrGvc31RHZWts7dPPXT0tTBi55HCMg%252FkzYMg%3D%3D&userProject=broad-achilles"; then
  echo "[OK] CCLE_RRBS_TSS1kb_20181022.txt.gz"
else
  echo "[FAIL] CCLE_RRBS_TSS1kb_20181022.txt.gz"
  FAILED=$((FAILED+1))
fi

echo "==== CTRPv2.0_2015_ctd2_ExpandedDataset.zip (CTRP CTD^2) ===="
if download_one "CTRPv2.0_2015_ctd2_ExpandedDataset.zip" "https://ctd2-data.nci.nih.gov/Public/Broad/CTRPv2.0_2015_ctd2_ExpandedDataset/CTRPv2.0_2015_ctd2_ExpandedDataset.zip"; then
  echo "[OK] CTRPv2.0_2015_ctd2_ExpandedDataset.zip"
else
  echo "[FAIL] CTRPv2.0_2015_ctd2_ExpandedDataset.zip"
  FAILED=$((FAILED+1))
fi

echo "==== Repurposing_Public_24Q2_Extended_Primary_Data_Matrix.csv (PRISM Primary Repurposing DepMap Public 24Q2) ===="
if download_one "Repurposing_Public_24Q2_Extended_Primary_Data_Matrix.csv" "https://ndownloader.figshare.com/files/46630984"; then
  echo "[OK] Repurposing_Public_24Q2_Extended_Primary_Data_Matrix.csv"
else
  echo "[FAIL] Repurposing_Public_24Q2_Extended_Primary_Data_Matrix.csv"
  FAILED=$((FAILED+1))
fi

echo "==== secondary-screen-dose-response-curve-parameters.csv (PRISM Repurposing 19Q4) ===="
if download_one "secondary-screen-dose-response-curve-parameters.csv" "https://ndownloader.figshare.com/files/36794595"; then
  echo "[OK] secondary-screen-dose-response-curve-parameters.csv"
else
  echo "[FAIL] secondary-screen-dose-response-curve-parameters.csv"
  FAILED=$((FAILED+1))
fi

echo "==== sanger_combination_library_viability_breadbox_data.csv (Sanger Drug Combinations 2022) ===="
if download_one "sanger_combination_library_viability_breadbox_data.csv" "https://storage.googleapis.com/depmap-external-downloads/sanger-drug-drug-interactions-9406.9/sanger_combination_library_viability_breadbox_data.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=EbLLHcAkSPmYUMYy%252BOa3dsR28%252FXeSFN%252FMj1PK5nAN2LbSIHbb6OWG4Ua5VBJlC%252FYZ4Cz%252FZTYYYmSQccnlXB4bvoT7x5YxfoLRxuxccK9DR%252FZGsu%252FpJ1X3WfVD0pWy7A9kReNQqoHgsX3wGj7TO9CtwHyST7nqmyespqPbJ6BNqQS0mwifwM3YqaiLsw57m7k0Kf8aqEYBywVzhLR6i3kiUcss%252FOnqUr71MTv2B65EmjRoSovif0ud9VvJdWlLzK29vgmqAdxEc9QmGBf1hkJLHSgZO3Cev7SlC7IyEbn1s3AY0DVHvqCqmmRvnrqOb22aBBcM3uL%252FHCp%252F%252BiwBqsefQ%3D%3D&userProject=broad-achilles"; then
  echo "[OK] sanger_combination_library_viability_breadbox_data.csv"
else
  echo "[FAIL] sanger_combination_library_viability_breadbox_data.csv"
  FAILED=$((FAILED+1))
fi

echo "==== sanger_combination_anchor_viability_breadbox_data.csv (Sanger Drug Combinations 2022) ===="
if download_one "sanger_combination_anchor_viability_breadbox_data.csv" "https://storage.googleapis.com/depmap-external-downloads/sanger-drug-drug-interactions-9406.9/sanger_combination_anchor_viability_breadbox_data.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=BT8zlDf%252FA%252BfjHq1R0BdTfGXy0mJ5grFT3gHyg8fSh0s119om76pUkJLDUMi9ubL7P8nEUF49ERMa8lDwYBw04ILGs%252BqwXy64x6rQ9k4jdBqB%252B6oVfvLlJFOXLqhVssPCBn1Pvc3OyFkakIuWDr7b6tlgrU3CP1ep%252FUhWkrUAzV1GVv8XAWJVQjzhO2gaxJcJKJaIJlnWSs9xp6UT8rv5hDX8rtHhyzrAiikIDzJRKG2rEULWPZzDmPYUfz0jvNdtyglWRi3sWUpdA%252Fd1X8SA083P81vazPhieenuSyIe%252B71Feij7JSRoBCwO%252BrmI2ds95lO2mpmD%252BNKAeueaIpnvoQ%3D%3D&userProject=broad-achilles"; then
  echo "[OK] sanger_combination_anchor_viability_breadbox_data.csv"
else
  echo "[FAIL] sanger_combination_anchor_viability_breadbox_data.csv"
  FAILED=$((FAILED+1))
fi

echo "==== sanger_combination_combo_viability_breadbox_data.csv (Sanger Drug Combinations 2022) ===="
if download_one "sanger_combination_combo_viability_breadbox_data.csv" "https://storage.googleapis.com/depmap-external-downloads/sanger-drug-drug-interactions-9406.9/sanger_combination_combo_viability_breadbox_data.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=n4xeg98OWcyPN5zsfAKNXMgjYkkqeerGsVteFrWtHBy2EFfu1lW6o28A%252B4lOBIVsx2lUMbNYchlWAYbeZ9K18O%252BKLFDO2LhA2tEa1WopPDBJ4L4KEEq5NBSysCNbXXLILqI38oy%252Bee2YLlOVPmzvMYAkdIuDg30J%252FhnEw45aUOZ2vdoce6umC19S9OTGbK423IuBGdjJ93AyFMC3JuHcEYtkb173AWbdidVX%252FifVKbh8imfA%252FjKCH2zR3ghou5n0jWOqrNyoK32vdWKHBJd%252Bdj2b3UWBsCyPJvka5jS7ri7g%252FDSQn%252Bqxzw8F%252FPp6Vk%252BiJlLSdRKxNqB9Ihw0x8ULzw%3D%3D&userProject=broad-achilles"; then
  echo "[OK] sanger_combination_combo_viability_breadbox_data.csv"
else
  echo "[FAIL] sanger_combination_combo_viability_breadbox_data.csv"
  FAILED=$((FAILED+1))
fi

echo "==== sanger_combination_library_fit_breadbox_data.csv (Sanger Drug Combinations 2022) ===="
if download_one "sanger_combination_library_fit_breadbox_data.csv" "https://storage.googleapis.com/depmap-external-downloads/sanger-drug-drug-interactions-9406.9/sanger_combination_library_fit_breadbox_data.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=e9G%252FZK5pN2R9hsob3eqNQNpkkssR%252B2TRx0LITLPpbDutQ3VaAnBO%252BX6HbI%252FUqoMETZPLZu1vA8gEKPM9A9Rb9N1fT0b9xSAW0ZDmmNfdKHZ7t4ZHMM8IKXqmACihTHAbMOjENfsIy22cpPEV0o4yG5bTrOsCy1xQN%252B02zdy1%252FGgM28S0Nk3okcrdyKDCAOBTc2Dzqw9wdavV7EdYjfW2uO0SJ8VCGB865ixlvAcslSJ2QrQxeq8SB%252FePmBvcTTSO5dj%252BkW9YrYmxF9ou2RMtjQmVIQYFf4YM9IdgzuFiVXyY1BmjPyISoy8X8isHkzIj5%252F6EWKbuFQMwEKZDQO5NVA%3D%3D&userProject=broad-achilles"; then
  echo "[OK] sanger_combination_library_fit_breadbox_data.csv"
else
  echo "[FAIL] sanger_combination_library_fit_breadbox_data.csv"
  FAILED=$((FAILED+1))
fi

echo "==== sanger_combination_combo_fit_breadbox_data.csv (Sanger Drug Combinations 2022) ===="
if download_one "sanger_combination_combo_fit_breadbox_data.csv" "https://storage.googleapis.com/depmap-external-downloads/sanger-drug-drug-interactions-9406.9/sanger_combination_combo_fit_breadbox_data.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=E%252FyRBUGWFS77hGPrCxBR9Pn3sk%252BalnSyj8lH4wI0DxicWgzse5J6uI13GESqaXamZjx9lkCzHn7%252B%252FB5jqho5PeV9iFIGpXxDZJ1Vrb5VdzSfbMKJsFMuDsH%252B6K%252FkiSMNuf9WeA9vjomkX6jTL68p6vexd3nfga2QwPGx8eW3jcqniLpIeX72lw5BV5um8UZa5P14dchjTNv6hfvN0I18Zr9PNOOxh6AlCn1FbKjB9jXDhBxzF7qZ3ruI3fL4pncmuz3hiWf55OIz6ve5igfd7ousz1JUb2P0UxDYB%252BpWuPrVlPLt2QJnufrRnBkBmF9Fq%252BLAelZUB945CsooWs2MFQ%3D%3D&userProject=broad-achilles"; then
  echo "[OK] sanger_combination_combo_fit_breadbox_data.csv"
else
  echo "[FAIL] sanger_combination_combo_fit_breadbox_data.csv"
  FAILED=$((FAILED+1))
fi

echo "==== sanger-dose-response.csv (Sanger GDSC1 and GDSC2) ===="
if download_one "sanger-dose-response.csv" "https://storage.googleapis.com/depmap-external-downloads/processed_portal_downloads/gdsc-drug-set-export-658c.5/sanger-dose-response.csv?GoogleAccessId=depmap-external-downloads%40broad-achilles.iam.gserviceaccount.com&Expires=1767438631&Signature=aDk6OsHvrix7N3hDZeMSS7iTSLZYlYm24CxJoeasF9%252FIvvUYW1gzlOdyYEJHNas5XDFOsOQY7z6KtNdae87R%252FvwBW44%252FSXqXpsZEzH6J%252B7UA7U2vtHG4FRW2cL7atVmjlssuHv%252FxerFNlILi0830dpjPZiK70K2ut1hH1nu%252BQ1jxN1KUsZBYzrg%252Bc4KAVPr1LUdmQHoNyPd04IoyrFTUzXyhxatNONvgR7QANG0h2jtElEY6f8hc77mQzIA3DjJLtlGF%252BUK%252B6TUh3STMBRua0zrBtPOpiT%252FpSIngZWUnBf62D7Vf4wZtVuNLEsvJ60j52VEUJd6XerLtzvFBa4GC1w%3D%3D&userProject=broad-achilles"; then
  echo "[OK] sanger-dose-response.csv"
else
  echo "[FAIL] sanger-dose-response.csv"
  FAILED=$((FAILED+1))
fi

echo "Retry script failures: $FAILED"
echo "If failures remain, download manually via Portal and run import script:"
echo "  $ROOT_DIR/scripts/import_manual_downloads.sh <your_download_dir>"
exit 0
