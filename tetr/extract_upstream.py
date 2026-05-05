#!/usr/bin/env python3
"""Extract upstream regions of TetR-family TFs and their divergent neighbors
for MEME-based motif discovery (SigmoID-style de novo TFBS inference).
"""
import os
import sys
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq

GBK = "/home/ubuntu/lab5_bio/annotation/Sudilovsky.gbk"
DOMTBL = "/home/ubuntu/lab5_bio/tetr/TetR_hits.domtbl"
OUT_DIR = "/home/ubuntu/lab5_bio/tetr"

# Read TetR-family locus tags
tetr_tags = set()
with open(DOMTBL) as fh:
    for line in fh:
        if line.startswith("#"):
            continue
        parts = line.split()
        if not parts:
            continue
        tetr_tags.add(parts[3])  # column 4 = query name = locus_tag

print(f"TetR-family proteins: {len(tetr_tags)}")

# Load genome, build feature index
record = SeqIO.read(GBK, "genbank")
genome_len = len(record.seq)
print(f"Genome length: {genome_len}")

cds_features = [f for f in record.features if f.type == "CDS"]
# Sort by start position
cds_features.sort(key=lambda f: int(f.location.start))

# Build dict: locus_tag -> (idx, feature)
tag_to_idx = {}
for i, f in enumerate(cds_features):
    lt = f.qualifiers.get("locus_tag", [None])[0]
    if lt:
        tag_to_idx[lt] = i

UPSTREAM = 250
DOWNSTREAM = 50

upstream_records = []
upstream_seen = set()


def get_upstream_seq(feature, up=UPSTREAM, down=DOWNSTREAM):
    """Return sequence -up..+down relative to feature's start codon (coding strand)."""
    start = int(feature.location.start)
    end = int(feature.location.end)
    strand = feature.location.strand
    if strand == 1:
        s = max(0, start - up)
        e = min(genome_len, start + down)
        seq = record.seq[s:e]
    else:
        s = max(0, end - down)
        e = min(genome_len, end + up)
        seq = record.seq[s:e].reverse_complement()
    return seq, (s, e, strand)


for tag in sorted(tetr_tags):
    if tag not in tag_to_idx:
        print(f"WARN: {tag} not found", file=sys.stderr)
        continue
    idx = tag_to_idx[tag]
    feat = cds_features[idx]
    # The TetR gene itself
    seq, info = get_upstream_seq(feat)
    key = (feat.location.start, feat.location.strand)
    if key not in upstream_seen and len(seq) >= 100:
        upstream_seen.add(key)
        product = feat.qualifiers.get("product", ["?"])[0]
        upstream_records.append(
            SeqRecord(
                seq,
                id=f"{tag}_self",
                description=f"upstream of {tag} ({product[:60]})",
            )
        )
    # Look at divergent neighbor (gene on opposite strand whose start is near our gene's start)
    # Check neighboring CDS within 1000bp on opposite strand
    for j in (idx - 1, idx + 1):
        if 0 <= j < len(cds_features):
            n = cds_features[j]
            if n.location.strand != feat.location.strand:
                # divergent if n is upstream of feat (relative to feat)
                if feat.location.strand == 1:
                    gap = int(feat.location.start) - int(n.location.end)
                else:
                    gap = int(n.location.start) - int(feat.location.end)
                if 0 <= gap <= 600:
                    nseq, ninfo = get_upstream_seq(n)
                    nkey = (n.location.start, n.location.strand)
                    if nkey not in upstream_seen and len(nseq) >= 100:
                        upstream_seen.add(nkey)
                        nlt = n.qualifiers.get("locus_tag", ["?"])[0]
                        nprod = n.qualifiers.get("product", ["?"])[0]
                        upstream_records.append(
                            SeqRecord(
                                nseq,
                                id=f"{nlt}_div_{tag}",
                                description=f"divergent neighbor of {tag}: {nprod[:60]}",
                            )
                        )

# Write all upstream regions
out_fa = os.path.join(OUT_DIR, "tetr_upstream.fa")
SeqIO.write(upstream_records, out_fa, "fasta")
print(f"Wrote {len(upstream_records)} upstream regions to {out_fa}")
