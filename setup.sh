#!/usr/bin/env bash
# setup.sh — устанавливает все программы, нужные для воспроизведения лабораторной №5.
# Тестировано на Ubuntu 22.04 LTS. Запускать из корня репозитория:
#   ./setup.sh
#
# Что устанавливается:
#   * Prokka 1.14.6 (apt) + полная база Prokka (kingdom/Bacteria, HAMAP HMM, Rfam CM)
#   * barrnap, HMMER, Infernal, NCBI BLAST+, Aragorn, Prodigal, BioPerl
#   * MEME Suite 5.5.7 (собирается из исходников в $HOME/meme)
#   * Python-зависимости: biopython, openpyxl, pdfminer.six
set -euo pipefail

# ----- 1. Системные пакеты -------------------------------------------------
echo ">>> [1/4] Установка системных пакетов через apt..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    prokka barrnap hmmer infernal ncbi-blast+ aragorn prodigal \
    libdatetime-perl libxml-simple-perl libdigest-md5-perl bioperl \
    libopenmpi-dev openmpi-bin \
    python3 python3-pip git wget curl build-essential

# ----- 2. База Prokka ------------------------------------------------------
# В Ubuntu prokka ставится без kingdom-базы (UniProt SwissProt + HAMAP HMM),
# поэтому подтягиваем её из официального git tseemann/prokka.
echo ">>> [2/4] Установка базы Prokka..."
PROKKA_DB="$HOME/.local/lib/prokka/db"
if [ ! -f "$PROKKA_DB/kingdom/Bacteria/sprot.pin" ]; then
    if [ ! -d "$HOME/prokka-src" ]; then
        git clone --depth 1 https://github.com/tseemann/prokka.git "$HOME/prokka-src"
    fi
    mkdir -p "$HOME/.local/lib/prokka"
    rm -rf "$PROKKA_DB"
    cp -r "$HOME/prokka-src/db" "$PROKKA_DB"
    [ -f "$PROKKA_DB/hmm/HAMAP.hmm.gz" ] && gunzip -f "$PROKKA_DB/hmm/HAMAP.hmm.gz"
    prokka --setupdb
else
    echo "    база Prokka уже установлена"
fi

# ----- 3. MEME Suite -------------------------------------------------------
echo ">>> [3/4] Сборка и установка MEME Suite 5.5.7..."
if [ ! -x "$HOME/meme/bin/meme" ]; then
    cd "$HOME"
    if [ ! -f meme-5.5.7.tar.gz ]; then
        wget -q https://meme-suite.org/meme/meme-software/5.5.7/meme-5.5.7.tar.gz
    fi
    tar xzf meme-5.5.7.tar.gz
    cd meme-5.5.7
    ./configure --prefix="$HOME/meme" --enable-build-libxml2 --enable-build-libxslt
    make -j"$(nproc)"
    make install
    cd -
else
    echo "    MEME уже установлен в $HOME/meme"
fi
# Сделать meme/fimo видимыми в текущем шелле и в будущих сессиях
if ! grep -q 'meme/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH=$HOME/meme/bin:$HOME/meme/libexec/meme-5.5.7:$PATH' >> "$HOME/.bashrc"
fi
export PATH="$HOME/meme/bin:$HOME/meme/libexec/meme-5.5.7:$PATH"

# ----- 4. Python-зависимости -----------------------------------------------
echo ">>> [4/4] Установка Python-зависимостей..."
pip3 install --user --quiet biopython openpyxl pdfminer.six

# ----- Проверка ------------------------------------------------------------
echo
echo ">>> Установка завершена. Проверка инструментов:"
prokka --version
hmmscan -h | head -2
"$HOME/meme/bin/meme" -version
"$HOME/meme/bin/fimo" --version | head -1
python3 -c "import Bio; print('Biopython', Bio.__version__)"

cat <<'EOF'

Дальше для воспроизведения лабораторной достаточно:
    make all
или по шагам:
    make annotate      # Prokka-аннотация
    make tetr          # поиск TetR-белков и сайтов связывания
    make report        # пересборка финального GenBank с фичами protein_bind

Если PATH не обновился, выполните:
    export PATH=$HOME/meme/bin:$HOME/meme/libexec/meme-5.5.7:$PATH
EOF
