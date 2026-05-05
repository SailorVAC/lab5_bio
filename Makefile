# Makefile — воспроизводит весь пайплайн лабораторной №5 одной командой.
# Использование:
#   ./setup.sh   # один раз — установить программы
#   make all     # запустить всё: скачать геном, аннотировать, найти TetR-сайты

GENOME_ID  := NZ_CP017482.1
PREFIX     := Sudilovsky
DATA_DIR   := data
ANN_DIR    := annotation
TETR_DIR   := tetr
PFAM_TETR  := PF00440

FASTA      := $(DATA_DIR)/$(GENOME_ID).fasta
NCBI_GBK   := $(DATA_DIR)/$(GENOME_ID)_NCBI.gbk
PROKKA_GBK := $(ANN_DIR)/$(PREFIX).gbk
PROKKA_FAA := $(ANN_DIR)/$(PREFIX).faa
TETR_HMM   := $(TETR_DIR)/TetR_N.hmm
TETR_DOM   := $(TETR_DIR)/TetR_hits.domtbl
UPSTREAM   := $(TETR_DIR)/tetr_upstream.fa
MEME_OUT   := $(TETR_DIR)/meme_anr/meme.txt
FIMO_OUT   := $(TETR_DIR)/fimo_genome/fimo.tsv
FINAL_GBK  := $(ANN_DIR)/$(PREFIX)_TetR.gbk

# В пути добавляем MEME (на случай если bashrc ещё не подгружен).
export PATH := $(HOME)/meme/bin:$(HOME)/meme/libexec/meme-5.5.7:$(PATH)

.PHONY: all genome annotate tetr report clean help

help:
	@echo "Цели:"
	@echo "  make genome    - скачать FASTA и GenBank-аннотацию NCBI"
	@echo "  make annotate  - запустить Prokka (требует genome)"
	@echo "  make tetr      - найти TetR-белки + de novo мотив + сайты по геному"
	@echo "  make report    - финальный GenBank с фичами protein_bind"
	@echo "  make all       - все шаги по порядку"
	@echo "  make clean     - удалить промежуточные файлы (но не data/)"

all: $(FINAL_GBK)

# 1. Геном
genome: $(FASTA) $(NCBI_GBK)

$(FASTA):
	mkdir -p $(DATA_DIR)
	curl -sL "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$(GENOME_ID)&rettype=fasta&retmode=text" -o $@

$(NCBI_GBK):
	mkdir -p $(DATA_DIR)
	curl -sL "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$(GENOME_ID)&rettype=gbwithparts&retmode=text" -o $@

# 2. Аннотация Prokka с префиксом Sudilovsky
annotate: $(PROKKA_GBK)

$(PROKKA_GBK): $(FASTA)
	prokka --outdir $(ANN_DIR) --prefix $(PREFIX) --locustag $(PREFIX) \
	       --kingdom Bacteria --genus Pectobacterium --species polaris \
	       --strain NIBIO1392 --rfam --cpus $$(nproc) --force $(FASTA)

# 3. TetR-белки + мотив + сайты
tetr: $(FIMO_OUT)

$(TETR_HMM):
	mkdir -p $(TETR_DIR)
	curl -sL "https://www.ebi.ac.uk/interpro/wwwapi/entry/pfam/$(PFAM_TETR)?annotation=hmm" | gunzip > $@
	hmmpress -f $@

$(TETR_DOM): $(TETR_HMM) $(PROKKA_GBK)
	hmmscan --cut_ga --domtblout $@ $(TETR_HMM) $(PROKKA_FAA)

$(UPSTREAM): $(TETR_DOM)
	python3 $(TETR_DIR)/extract_upstream.py

$(MEME_OUT): $(UPSTREAM)
	meme $(UPSTREAM) -dna -revcomp -mod anr -nmotifs 5 -minw 14 -maxw 24 \
	     -evt 1e-5 -oc $(TETR_DIR)/meme_anr -p $$(nproc)

$(FIMO_OUT): $(MEME_OUT)
	fimo --motif WTSATGATDAYSGTAWTSA --thresh 1e-4 --max-stored-scores 1000000 \
	     -oc $(TETR_DIR)/fimo_genome $(MEME_OUT) $(FASTA)

# 4. Финальный GenBank
report: $(FINAL_GBK)

$(FINAL_GBK): $(FIMO_OUT)
	python3 $(TETR_DIR)/add_tetr_sites.py

clean:
	rm -rf $(ANN_DIR) $(TETR_DIR)/meme_anr $(TETR_DIR)/fimo_genome \
	       $(TETR_DIR)/TetR_N.hmm.h3? $(TETR_DIR)/tetr_upstream.fa \
	       $(TETR_DIR)/TetR_hits.domtbl $(TETR_DIR)/tetr_sites_summary.tsv \
	       $(TETR_DIR)/img
