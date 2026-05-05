# lab5_bio — Лабораторная работа №5

Аннотация генома *Pectobacterium polaris* `NZ_CP017482.1` и поиск сайтов связывания транскрипционных факторов семейства **TetR**.

- Вариант **8**: Судиловский Л., Колешко В.
- Префикс идентификаторов: `Sudilovsky`
- Семейство ТФ: TetR (Pfam **PF00440**)

Полное описание работы см. в [`REPORT.md`](REPORT.md).

## Быстрый старт (Ubuntu 22.04)

```bash
git clone https://github.com/SailorVAC/lab5_bio.git
cd lab5_bio
./setup.sh        # установит prokka + БД, MEME, HMMER, biopython и пр.
source ~/.bashrc  # чтобы подцепить PATH к meme/fimo
make all          # скачает геном, прогонит prokka, найдёт TetR-сайты
```

После `make all` финальный GenBank-файл лежит в
`annotation/Sudilovsky_TetR.gbk`.

Запустить шаги по отдельности:

```bash
make genome     # скачать FASTA и оригинальный NCBI GenBank
make annotate   # Prokka-аннотация
make tetr       # hmmscan PF00440 + MEME + FIMO
make report     # пересборка финального GenBank с фичами protein_bind
make clean      # удалить всё кроме data/
```

## Структура

```
data/
  NZ_CP017482.1.fasta            # исходный геном (NCBI)
  NZ_CP017482.1_NCBI.gbk         # оригинальная аннотация NCBI (для сверки)
annotation/
  Sudilovsky.gbk                 # аннотация Prokka, префикс Sudilovsky
  Sudilovsky_TetR.gbk            # финальный GenBank = Prokka + 32 TetR-сайта
  Sudilovsky.{gff,faa,ffn,tbl,txt,tsv}
tetr/
  TetR_N.hmm                     # Pfam PF00440 HMM
  TetR_hits.domtbl               # hmmscan: 19 TetR-белков
  tetr_upstream.fa               # upstream-области для MEME
  meme_anr/                      # MEME-открытый мотив
  fimo_genome/                   # сканирование FIMO
  tetr_sites_summary.tsv         # 32 финальных сайта
  extract_upstream.py
  add_tetr_sites.py
REPORT.md                        # отчёт по лабораторной
setup.sh                         # установка всех зависимостей (Prokka, MEME, ...)
Makefile                         # пайплайн воспроизведения
```

## Главное

| Тип фичи | Prokka | NCBI | Δ |
|---|---:|---:|---|
| CDS | 4 390 | 4 356 | +34 |
| tRNA | 77 | 77 | 0 |
| rRNA | 15 | 22 | −7 |
| ncRNA / misc_RNA | 163 | 4 | +159 |
| tmRNA | 1 | 1 | 0 |

**Открытый de novo мотив TetR**: `WTSATGATDAYSGTAWTSA` (19 п.н., E-value 1.8e-11), 32 высоконадёжных сайта в геноме (p < 1e-6), 7 из них — перед самими TetR-генами (авторегуляция).
