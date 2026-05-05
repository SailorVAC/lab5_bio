#!/usr/bin/env python3
"""Add TetR binding sites from FIMO output as protein_bind features to the
annotated GenBank file. Also produce a summary TSV listing each site's nearest
downstream gene."""
import csv
import sys
from Bio import SeqIO
from Bio.SeqFeature import SeqFeature, FeatureLocation

GBK_IN = "/home/ubuntu/lab5_bio/annotation/Sudilovsky.gbk"
GBK_OUT = "/home/ubuntu/lab5_bio/annotation/Sudilovsky_TetR.gbk"
FIMO_TSV = "/home/ubuntu/lab5_bio/tetr/fimo_genome/fimo.tsv"
TARGETS_TSV = "/home/ubuntu/lab5_bio/tetr/tetr_sites_summary.tsv"
P_CUTOFF = 1e-6  # high-confidence

record = SeqIO.read(GBK_IN, "genbank")
genome_len = len(record.seq)

# All CDS sorted by start
cds_features = sorted(
    [f for f in record.features if f.type == "CDS"],
    key=lambda f: int(f.location.start),
)


def nearest_gene(start, end):
    """Return (locus_tag, product, distance, direction) for the closest CDS."""
    best = None
    best_dist = float("inf")
    midpoint = (start + end) // 2
    for f in cds_features:
        s = int(f.location.start)
        e = int(f.location.end)
        if s <= midpoint <= e:
            d = 0
            direction = "inside"
        elif midpoint < s:
            d = s - midpoint
            direction = "upstream of" if f.location.strand == 1 else "downstream of"
        else:
            d = midpoint - e
            direction = "downstream of" if f.location.strand == 1 else "upstream of"
        if d < best_dist:
            best_dist = d
            lt = f.qualifiers.get("locus_tag", ["?"])[0]
            prod = f.qualifiers.get("product", ["?"])[0]
            gene = f.qualifiers.get("gene", [""])[0]
            strand = "+" if f.location.strand == 1 else "-"
            best = (lt, gene, prod, d, direction, strand)
    return best


sites = []
with open(FIMO_TSV) as fh:
    reader = csv.DictReader(fh, delimiter="\t")
    for row in reader:
        if not row.get("p-value"):
            continue
        try:
            p = float(row["p-value"])
        except (TypeError, ValueError):
            continue
        if p > P_CUTOFF:
            continue
        try:
            s = int(row["start"]) - 1  # FIMO is 1-based, we need 0-based start
            e = int(row["stop"])
        except (TypeError, ValueError):
            continue
        strand_sign = row["strand"]
        strand = 1 if strand_sign == "+" else -1
        sites.append(
            {
                "start": s,
                "end": e,
                "strand": strand,
                "score": row["score"],
                "pvalue": p,
                "qvalue": row.get("q-value", ""),
                "matched": row["matched_sequence"],
            }
        )

sites.sort(key=lambda x: x["start"])
print(f"High-confidence TetR sites (p < {P_CUTOFF}): {len(sites)}")

# Add features and build summary
summary_rows = []
for i, s in enumerate(sites, start=1):
    loc = FeatureLocation(s["start"], s["end"], strand=s["strand"])
    feat = SeqFeature(
        loc,
        type="protein_bind",
        qualifiers={
            "bound_moiety": ["TetR-family transcription factor (de novo motif)"],
            "note": [
                f"Putative TetR-family operator predicted by MEME/FIMO; "
                f"motif WTSATGATDAYSGTAWTSA; score={s['score']}; "
                f"p-value={s['pvalue']:.2e}"
            ],
            "label": [f"TetR_site_{i:03d}"],
        },
    )
    record.features.append(feat)

    g = nearest_gene(s["start"], s["end"])
    summary_rows.append(
        {
            "site_id": f"TetR_site_{i:03d}",
            "start": s["start"] + 1,
            "end": s["end"],
            "strand": "+" if s["strand"] == 1 else "-",
            "matched_seq": s["matched"],
            "score": s["score"],
            "p_value": f"{s['pvalue']:.2e}",
            "q_value": s["qvalue"],
            "nearest_gene": g[0] if g else "",
            "gene_name": g[1] if g else "",
            "product": g[2] if g else "",
            "distance_bp": g[3] if g else "",
            "relation": g[4] if g else "",
            "gene_strand": g[5] if g else "",
        }
    )

# Re-sort features by start position so the GenBank stays tidy
record.features.sort(key=lambda f: int(f.location.start))

SeqIO.write([record], GBK_OUT, "genbank")
print(f"Wrote enhanced GenBank to {GBK_OUT}")

with open(TARGETS_TSV, "w") as fh:
    fields = list(summary_rows[0].keys())
    w = csv.DictWriter(fh, fieldnames=fields, delimiter="\t")
    w.writeheader()
    for r in summary_rows:
        w.writerow(r)
print(f"Wrote summary to {TARGETS_TSV}")
