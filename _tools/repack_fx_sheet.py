#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
repack_fx_sheet.py — จัดชีทเอฟเฟกต์ที่ "อัดชิดกันแบบความกว้างไม่เท่ากัน" ให้เป็นตารางเท่ากันทุกช่อง

ปัญหาที่แก้: ภาพเอฟเฟกต์บางชีท (magnum_break / slime_burst รอบ 82) ถูกอัดมาแบบ
เฟรมเล็กแคบ เฟรมใหญ่กว้าง ชิดกันไปเรื่อย ๆ  ตัดด้วยตารางเท่ากันแล้วเฟรมเบี้ยว
สคริปต์นี้จะ
  1) หารอยต่อระหว่างเฟรม N-1 รอย (เลือกคอลัมน์ที่ "เนื้อภาพบางที่สุด")
  2) วัดกรอบเนื้อภาพของแต่ละเฟรม + จุดกึ่งกลางของ "วงพื้น" (แถบล่างสุด)
  3) วางทุกเฟรมลงช่องขนาดเท่ากัน จัดกึ่งกลางที่วงพื้น และให้ระดับพื้นตรงกันทุกเฟรม
  4) ตัดขอบว่างบน-ล่างออก แล้วเซฟทับ (สำรองไฟล์เดิมไว้)

ใช้:  python3 repack_fx_sheet.py <ไฟล์.png> <จำนวนเฟรม> [--out ไฟล์ออก] [--pad 8] [--dry]
"""
import sys, os, shutil, argparse
import numpy as np
from PIL import Image

ALPHA_MIN = 20          # ถือว่า "มีเนื้อภาพ" เมื่อ alpha เกินนี้
SMOOTH = 15             # ความกว้างหน้าต่างเกลี่ยเส้นกราฟ
MIN_GAP_FRAC = 0.35     # รอยต่อสองรอยต้องห่างกันอย่างน้อยกี่ % ของความกว้างเฉลี่ยต่อเฟรม (ปรับด้วย --min-gap)
GROUND_BAND = 70        # นับ "วงพื้น" จากแถวล่างสุดของเนื้อภาพขึ้นมากี่แถว


def content_columns(alpha):
    return (alpha > ALPHA_MIN).sum(axis=0).astype(float)


def smooth(v, k):
    return np.convolve(v, np.ones(k) / k, mode="same")


def find_cuts(alpha, n_frames, min_gap_frac=MIN_GAP_FRAC):
    """หา n_frames-1 รอยต่อ ที่ผลรวม 'ความหนาของเนื้อภาพ' ตรงรอยน้อยที่สุด"""
    cov = smooth(content_columns(alpha), SMOOTH)
    nz = np.nonzero(cov > 0)[0]
    if len(nz) == 0:
        raise SystemExit("ภาพว่าง")
    x0, x1 = int(nz[0]), int(nz[-1]) + 1
    span = x1 - x0
    avg = span / n_frames
    min_gap = max(8, int(avg * min_gap_frac))

    # DP: เลือก n_frames-1 จุดในช่วง (x0, x1) ห่างกัน >= min_gap ให้ผลรวม cov น้อยสุด
    cand = list(range(x0 + min_gap, x1 - min_gap + 1))
    if len(cand) < n_frames - 1:
        # ภาพแคบมาก — แบ่งเท่ากันไปเลย
        return [x0 + int(round(i * span / n_frames)) for i in range(1, n_frames)], x0, x1

    INF = float("inf")
    K = n_frames - 1
    # best[k][i] = ค่าน้อยสุดเมื่อวางรอยที่ k ไว้ที่ cand[i]
    best = [[INF] * len(cand) for _ in range(K)]
    prev = [[-1] * len(cand) for _ in range(K)]
    for i, x in enumerate(cand):
        best[0][i] = cov[x]
    for k in range(1, K):
        run_min = INF
        run_idx = -1
        j = 0
        for i, x in enumerate(cand):
            while j < len(cand) and cand[j] <= x - min_gap:
                if best[k - 1][j] < run_min:
                    run_min = best[k - 1][j]
                    run_idx = j
                j += 1
            if run_idx >= 0:
                best[k][i] = run_min + cov[x]
                prev[k][i] = run_idx
    end = min(range(len(cand)), key=lambda i: best[K - 1][i])
    cuts = []
    k = K - 1
    i = end
    while k >= 0 and i >= 0:
        cuts.append(cand[i])
        i = prev[k][i]
        k -= 1
    cuts.reverse()
    return cuts, x0, x1


def frame_boxes(alpha, cuts, x0, x1):
    """คืนกรอบเนื้อภาพ (l, t, r, b) และจุดกึ่งกลางวงพื้นของแต่ละเฟรม"""
    edges = [x0] + list(cuts) + [x1]
    out = []
    for i in range(len(edges) - 1):
        a, b = edges[i], edges[i + 1]
        sub = alpha[:, a:b]
        mask = sub > ALPHA_MIN
        cols = np.nonzero(mask.any(axis=0))[0]
        rows = np.nonzero(mask.any(axis=1))[0]
        if len(cols) == 0 or len(rows) == 0:
            out.append(None)
            continue
        l, r = a + int(cols[0]), a + int(cols[-1]) + 1
        t, bo = int(rows[0]), int(rows[-1]) + 1
        # กึ่งกลางแนวนอน = จุดกึ่งกลางน้ำหนักของแถบล่างสุด (วงพื้น)
        band_top = max(t, bo - GROUND_BAND)
        band = sub[band_top:bo, :].astype(float)
        w = band.sum(axis=0)
        cx = a + (float((np.arange(len(w)) * w).sum() / w.sum()) if w.sum() > 0 else (l + r) / 2 - a)
        out.append({"l": l, "t": t, "r": r, "b": bo, "cx": cx})
    return out


def repack(path, n_frames, out_path, pad, dry, min_gap_frac=MIN_GAP_FRAC):
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    alpha = np.array(im)[:, :, 3]

    cuts, x0, x1 = find_cuts(alpha, n_frames, min_gap_frac)
    boxes = frame_boxes(alpha, cuts, x0, x1)
    if any(b is None for b in boxes):
        raise SystemExit("มีเฟรมว่าง — จำนวนเฟรมน่าจะไม่ถูก")

    print("ภาพเดิม %dx%d · รอยต่อ: %s" % (W, H, cuts))
    for i, b in enumerate(boxes):
        print("  เฟรม %2d  x %4d..%4d (กว้าง %3d)  y %3d..%3d (สูง %3d)  กึ่งกลางพื้น %.0f"
              % (i, b["l"], b["r"], b["r"] - b["l"], b["t"], b["b"], b["b"] - b["t"], b["cx"]))

    # ขนาดช่อง: กว้างพอสำหรับเฟรมที่กว้างที่สุด (วัดจากกึ่งกลางวงพื้นออกไปสองข้าง)
    half = max(max(b["cx"] - b["l"], b["r"] - b["cx"]) for b in boxes)
    cell_w = int(np.ceil(half * 2)) + pad * 2
    top = min(b["t"] for b in boxes)
    bottom = max(b["b"] for b in boxes)
    cell_h = (bottom - top) + pad * 2
    print("ช่องใหม่ %dx%d  ·  ชีทใหม่ %dx%d" % (cell_w, cell_h, cell_w * n_frames, cell_h))

    if dry:
        return

    out = Image.new("RGBA", (cell_w * n_frames, cell_h), (0, 0, 0, 0))
    for i, b in enumerate(boxes):
        piece = im.crop((b["l"], top, b["r"], bottom))
        # วางให้ "กึ่งกลางวงพื้น" ตรงกลางช่องพอดี และระดับพื้นตรงกันทุกเฟรม
        dx = int(round(i * cell_w + cell_w / 2 - (b["cx"] - b["l"])))
        out.alpha_composite(piece, (dx, pad))

    if os.path.abspath(out_path) == os.path.abspath(path):
        bak_dir = os.path.join(os.path.dirname(path) or ".", "..", "..", "_to_delete", "originals_fx_r82")
        bak_dir = os.path.normpath(bak_dir)
        os.makedirs(bak_dir, exist_ok=True)
        bak = os.path.join(bak_dir, os.path.basename(path))
        if not os.path.exists(bak):
            shutil.copy2(path, bak)
            print("สำรองไฟล์เดิมไว้ที่ %s" % bak)
    out.save(out_path)
    print("เขียน %s (%dx%d · %d เฟรม ช่องละ %dx%d)"
          % (out_path, out.width, out.height, n_frames, cell_w, cell_h))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("png")
    ap.add_argument("frames", type=int)
    ap.add_argument("--out", default=None)
    ap.add_argument("--pad", type=int, default=8)
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--min-gap", type=float, default=MIN_GAP_FRAC, dest="min_gap")
    a = ap.parse_args()
    repack(a.png, a.frames, a.out or a.png, a.pad, a.dry, a.min_gap)


if __name__ == "__main__":
    main()
