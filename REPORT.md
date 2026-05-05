# Лабораторная работа №5

**Студент:** Судиловский Л. (вариант 8)
**Соавтор по варианту:** Колешко В.
**Геном:** `NZ_CP017482.1` — *Pectobacterium polaris* strain NIBIO1392, complete chromosome (5 008 416 п.н.)
**Семейство ТФ:** TetR (Pfam **PF00440**, домен `TetR_N`)
**Префикс идентификаторов:** `Sudilovsky`

## 1. Скачивание генома

Геном получен с NCBI Nuccore через E-utilities в формате FASTA:

```
curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NZ_CP017482.1&rettype=fasta" -o NZ_CP017482.1.fasta
```

Файл — `data/NZ_CP017482.1.fasta` (1 контиг, 5 008 416 п.н.). Параллельно скачана оригинальная аннотация NCBI (`data/NZ_CP017482.1_NCBI.gbk`) для последующего сравнения.

## 2. Аннотация генома

Аннотация выполнена с помощью **Prokka 1.14.6** с базами данных Bacteria (UniProt SwissProt, HAMAP, барранк rRNA, Aragorn tRNA) и Rfam (`--rfam`). Все идентификаторы получили префикс `Sudilovsky`:

```
prokka --outdir annotation --prefix Sudilovsky --locustag Sudilovsky \
       --kingdom Bacteria --genus Pectobacterium --species polaris --strain NIBIO1392 \
       --rfam --cpus 4 \
       data/NZ_CP017482.1.fasta
```

Результат — каталог `annotation/`, основной файл — `annotation/Sudilovsky.gbk` (GenBank). Бирки во всех CDS/RNA-фичах имеют вид `Sudilovsky_00001`, `Sudilovsky_00002`, ….

## 3. Сравнение с аннотацией NCBI

| Тип фичи | Prokka (наша) | NCBI (RefSeq) | Δ |
|---|---:|---:|---|
| CDS | **4 390** | 4 356 | +34 |
| tRNA | **77** | 77 | 0 |
| rRNA (5S/16S/23S) | **15** | 22 | −7 |
| tmRNA | **1** | 1 | 0 |
| ncRNA / misc_RNA | **163** *(misc_RNA)* | 4 *(ncRNA)* | +159 |
| Псевдогены | 0 | 116 | — |
| **Итого фич с локус-тегом** | **4 646** | 4 460 (gene) | +186 |

**Комментарии к различиям**

- **CDS (+34)**: Prokka использует Prodigal в режиме `single` и более либеральные пороги; небольшие ORF-ы NCBI часто отбрасывает как пересекающиеся либо как псевдогены.
- **rRNA (−7)**: Prokka применяет barrnap, который сообщает по одной копии каждого из 5S/16S/23S на rrn-оперон (5 оперонов × 3 = 15). NCBI/RefSeq, напротив, разделяет 5S-rRNA в нескольких оперонах, поэтому набирается 22 фичи; биологически — те же 5–7 рибосомных оперонов.
- **misc_RNA (+159)**: Prokka с ключом `--rfam` пропускает геном через Infernal по всему Rfam-CM-набору (рибосвитчи, малые регуляторные РНК, шпильки терминаторов). NCBI хранит только 4 ncRNA, потому что использует более строгий куратируемый список.
- **Псевдогены**: Prokka не аннотирует псевдогены явно — соответствующие участки попадают либо в обычные CDS (в т.ч. усечённые), либо вовсе не аннотируются. Это ожидаемое поведение; для воспроизведения NCBI-набора псевдогенов требуется отдельный шаг (например, `pseudofinder`).

В целом наборы CDS и tRNA согласуются с NCBI на десятые доли процента, что подтверждает корректность аннотации.

## 4. Поиск сайтов связывания ТФ семейства TetR

Воспроизведён рекомендованный в инструкции SigmoID workflow «de novo TFBS inference» (этап с MEME/FIMO).

### 4.1. Поиск белков с TetR-доменом

С InterPro/Pfam скачан HMM-профиль `PF00440 TetR_N` (длина 47 а.к.) и применён к нашей трансляции `Sudilovsky.faa`:

```
hmmscan --cut_ga --domtblout TetR_hits.domtbl TetR_N.hmm Sudilovsky.faa
```

Найдено **19 белков семейства TetR** (порог Pfam GA, файл `tetr/TetR_hits.domtbl`):

| locus_tag | E-value | Bit-score |
|---|---|---|
| Sudilovsky_00125 | 9.5e-25 | 71.8 |
| Sudilovsky_00417 | 6.8e-18 | 49.8 |
| Sudilovsky_00510 | 4.4e-21 | 59.2 |
| Sudilovsky_01139 | 8.8e-14 | 36.4 |
| Sudilovsky_01625 | 4.2e-21 | 60.0 |
| Sudilovsky_01704 | 2.1e-16 | 45.0 |
| Sudilovsky_01794 | 2.6e-16 | 44.5 |
| Sudilovsky_01851 | 8.2e-18 | 49.4 |
| Sudilovsky_01854 | 3.9e-21 | 60.0 |
| Sudilovsky_02231 | 1.1e-15 | 42.6 |
| Sudilovsky_02242 | 1.3e-16 | 45.2 |
| Sudilovsky_03254 | 3.3e-13 | 34.4 |
| Sudilovsky_03460 | 3.3e-15 | 41.1 |
| Sudilovsky_03677 | 7.6e-13 | 33.8 |
| Sudilovsky_03912 | 6.2e-18 | 49.3 |
| Sudilovsky_04489 | 1e-18 | 52.0 |
| Sudilovsky_04495 | 4.2e-17 | 46.9 |
| Sudilovsky_04549 | 4e-10 | 24.7 |
| Sudilovsky_04599 | 2.2e-16 | 44.8 |

### 4.2. Извлечение upstream-областей и поиск мотива

Для каждого TetR-гена и его дивергентного соседа взяты участки −250 … +50 от стартового кодона (скрипт `tetr/extract_upstream.py`). Получено **32 уникальных upstream-региона** (`tetr/tetr_upstream.fa`), на которых запущен MEME в режиме `anr` (несколько сайтов на регион), палиндромный поиск (`-revcomp`):

```
meme tetr_upstream.fa -dna -revcomp -mod anr -nmotifs 5 -minw 14 -maxw 24 -evt 1e-5
```

Лучший мотив:

- **Консенсус**: `WTSATGATDAYSGTAWTSA` (упрощённый — `ATCATGATAATCGTATTCA`)
- **Длина**: 19 п.н., **сайтов в обучающей выборке**: 20
- **E-value**: **1.8 × 10⁻¹¹**
- **Структура**: квази-палиндромная, характерная для TetR-белков (две полусайта `TGATGAT…ATCATCA`).

Логотип мотива:

![TetR motif logo](tetr/img/tetr_motif_logo.png)

### 4.3. Сканирование генома (FIMO)

```
fimo --motif WTSATGATDAYSGTAWTSA --thresh 1e-4 meme_anr/meme.txt NZ_CP017482.1.fasta
```

При пороге **p < 10⁻⁶** выявлено **32 высоконадёжных сайта связывания** TetR-семейства (полный список — `tetr/tetr_sites_summary.tsv`). Все они добавлены в финальный GenBank-файл `annotation/Sudilovsky_TetR.gbk` как фичи `protein_bind` с метками `TetR_site_001 … TetR_site_032`.

**Подтверждение биологической релевантности.** 7 из 32 сайтов лежат в межгенном промежутке непосредственно перед самим TetR-геном (типичная авторегуляция TetR-семейства):

| Сайт | p-value | TetR-ген | Дивергентный сосед |
|---|---|---|---|
| TetR_site_002 | 1.9e-10 | Sudilovsky_00417 | _00418 (nemA, N-ethylmaleimide reductase) |
| TetR_site_003 | 4.0e-09 | Sudilovsky_00417 | _00418 |
| TetR_site_012 | 2.4e-07 | Sudilovsky_01854 | _01855 (trxB, тиоредоксин-редуктаза) |
| TetR_site_014 | 4.1e-07 | Sudilovsky_02231 | _02232 |
| TetR_site_025 | 9.5e-07 | Sudilovsky_03460 | _03461 (smvA, methyl-viologen resistance) |
| TetR_site_030 | 1.4e-07 | Sudilovsky_04489 | _04490 |
| TetR_site_031 | 2.3e-07 | Sudilovsky_04599 | _04600 (hipO, гиппурат-гидролаза) |

То, что мотив рекуррентно встречается перед собственными генами семейства TetR, является классическим указанием на корректность открытого мотива (TetR обычно являются репрессорами и связываются с собственным промотором).

### 4.4. Биологический контекст некоторых регулонов

Среди потенциальных мишеней — гены, типичные для регулонов TetR-репрессоров: эффлюкс-помпы (`smvA` SmvA), ферменты детоксикации (`nemA`, `satP`, `tetA`), метаболизм (`fadD`, `glpD`, `metL`, `malQ`). Это согласуется с известной ролью TetR-факторов как регуляторов оттоковых систем и метаболических переключателей.

## 5. Итоговые файлы

| Файл | Описание |
|---|---|
| `data/NZ_CP017482.1.fasta` | исходный геном |
| `data/NZ_CP017482.1_NCBI.gbk` | оригинальная аннотация NCBI (для сверки) |
| `annotation/Sudilovsky.gbk` | **аннотация Prokka** (префикс `Sudilovsky`) |
| `annotation/Sudilovsky_TetR.gbk` | **финальный GenBank** = Prokka + 32 сайта TetR (`protein_bind`) |
| `annotation/Sudilovsky.{gff,faa,ffn,tbl,txt,tsv}` | дополнительные форматы |
| `tetr/TetR_N.hmm` | HMM-профиль Pfam PF00440 |
| `tetr/TetR_hits.domtbl` | hmmscan-хиты, 19 белков |
| `tetr/tetr_upstream.fa` | вытащенные upstream-области |
| `tetr/meme_anr/` | результаты MEME (motif logo + meme.html/.txt) |
| `tetr/fimo_genome/` | результаты сканирования FIMO по геному |
| `tetr/tetr_sites_summary.tsv` | сводка 32 сайтов с ближайшим геном |
| `tetr/extract_upstream.py`, `tetr/add_tetr_sites.py` | скрипты-обвязка |

## 6. Использованное ПО

- **Prokka** 1.14.6 (Prodigal 2.6.3, barrnap 0.9, Aragorn 1.2.41, BLAST+ 2.12, HMMER 3.3.2, Infernal 1.1.4)
- **HMMER** 3.3.2 (`hmmscan`)
- **MEME Suite** 5.5.7 (собран из исходников: `meme`, `fimo`)
- **Biopython** 1.x (парсинг GenBank, добавление фич)
- **Pfam** база — `PF00440 TetR_N` (InterPro)
- **Rfam** 14.1 (входит в комплект Prokka, для поиска ncRNA через Infernal)

## 7. Воспроизведение

Полная команда:

```bash
# 1. Геном
mkdir -p data && curl -sL "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NZ_CP017482.1&rettype=fasta" -o data/NZ_CP017482.1.fasta

# 2. Аннотация
prokka --outdir annotation --prefix Sudilovsky --locustag Sudilovsky \
       --kingdom Bacteria --genus Pectobacterium --species polaris --strain NIBIO1392 \
       --rfam --cpus 4 data/NZ_CP017482.1.fasta

# 3. Поиск TetR-белков
mkdir tetr && cd tetr
curl -sL "https://www.ebi.ac.uk/interpro/wwwapi/entry/pfam/PF00440?annotation=hmm" | gunzip > TetR_N.hmm
hmmpress TetR_N.hmm
hmmscan --cut_ga --domtblout TetR_hits.domtbl TetR_N.hmm ../annotation/Sudilovsky.faa

# 4. Поиск мотива
python3 extract_upstream.py
meme tetr_upstream.fa -dna -revcomp -mod anr -nmotifs 5 -minw 14 -maxw 24 -evt 1e-5 -oc meme_anr -p 4

# 5. Сканирование и аннотация сайтов
fimo --motif WTSATGATDAYSGTAWTSA --thresh 1e-4 -oc fimo_genome meme_anr/meme.txt ../data/NZ_CP017482.1.fasta
python3 add_tetr_sites.py
```

Финальный GenBank-файл для сдачи — **`annotation/Sudilovsky_TetR.gbk`**.
