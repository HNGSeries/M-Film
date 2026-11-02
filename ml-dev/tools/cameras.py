"""ml-dev/cameras.txt -> the camera tables in README.md, README.th.md and TESTING.md, and the
cameras CI builds (.github/workflows/camera.yml, and which of them without the darkroom or with the
film OS as a module). Run after changing cameras.txt:

    python3 ml-dev/tools/cameras.py
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STATUS = {
    "working": "✅ **Works**",
    "issues": "⚠️ Tried, known problem",
    "testing": "🧪 Builds, needs a tester",
    "nodark": "⚠️ Without the in-camera darkroom (develop with Darkrooms)",
    "planned": "⏳ Planned",
    "memory": "🔧 Too big for its boot memory: being fixed",
    "no": "— Not yet",
}
WHY_NO = "Magic Lantern itself is still experimental on these"
# README.th.md
STATUS_TH = {
    "working": "✅ **ใช้ได้**",
    "issues": "⚠️ ลองแล้ว ยังมีปัญหา",
    "testing": "🧪 build ได้แล้ว รอคนทดสอบ",
    "nodark": "⚠️ ไม่มีห้องมืดในกล้อง (ล้างด้วย Darkrooms)",
    "planned": "⏳ วางแผนไว้",
    "memory": "🔧 ใหญ่เกินหน่วยความจำตอนบูต: กำลังแก้",
}
WHY_TH = {
    WHY_NO: "Magic Lantern เองยังเป็นรุ่นทดลองบนกล้องเหล่านี้",
    "Magic Lantern's current source doesn't build it": "source ปัจจุบันของ Magic Lantern build รุ่นนี้ไม่ได้",
}


def cameras():
    out = []
    for line in (ROOT / "ml-dev" / "cameras.txt").read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        plat, status, limit, rest = line.split(None, 3)
        # "testing:module": the film OS is built as a module for it (build_fork.sh --module)
        status, _, build = status.partition(":")
        name, note, note_th = (rest.split(" | ") + ["", ""])[:3]
        fw = plat.split(".")[1]
        out.append({"plat": plat, "status": status, "module": build == "module", "limit": limit, "name": name.strip(),
                    "note": note.strip(), "note_th": note_th.strip() or note.strip(),
                    "fw": ".".join(fw) if fw.isdigit() else fw})
    return out


def issue_links(text):
    """'#31' -> a link to the issue (a README on GitHub doesn't link them by itself)"""
    return re.sub(r"#(\d+)", r"[#\1](../../issues/\1)", text)


def short(name):
    """'Canon EOS 200D / Rebel SL2' -> '200D', 'Canon PowerShot SX70 HS' -> 'SX70 HS'"""
    name = name.split(" / ", 1)[0]
    return re.sub(r"^Canon (EOS |PowerShot )?", "", name)


def replace(path, start, end, body):
    text = path.read_text(encoding="utf-8")
    a, b = text.index(start) + len(start), text.index(end)
    path.write_text(text[:a] + "\n" + body.rstrip("\n") + "\n" + text[b:], encoding="utf-8")


def main():
    cams = cameras()
    def table(head, status, not_yet, why_text, end=".", th=False):
        rows = [head, "|---|---|---|---|---|"]
        for c in cams:
            if c["status"] in ("working", "issues", "testing", "nodark", "memory", "planned"):
                dl = f"`M-Film-camera-{c['plat']}.zip`" if c["status"] in ("working", "issues", "testing", "nodark") else ""
                rows.append(f"| {c['name']} | {c['fw']} | {status[c['status']]} | {issue_links(c['note_th' if th else 'note'])} | {dl} |")
        # the ones Magic Lantern isn't ready on: one line, grouped by why
        why = {}
        for c in cams:
            if c["status"] == "no":
                name, _, reason = c["name"].partition(" (")
                why.setdefault(reason.rstrip(")") or WHY_NO, []).append(short(name))
        if why:
            rows += ["", f"**{not_yet}:** " + " · ".join(f"{', '.join(n)} ({why_text(r)})" for r, n in why.items()) + end]
        return "\n".join(rows)

    rows = table("| Camera | Canon firmware | Status | Notes | Card files |", STATUS, "Not yet", lambda r: r)
    th = table("| กล้อง | เฟิร์มแวร์ Canon | สถานะ | หมายเหตุ | ไฟล์ลงการ์ด |", STATUS_TH, "ยังไม่รองรับ",
               lambda r: WHY_TH.get(r, r), end="", th=True)
    # the badge at the top: how many work, start with a problem, wait for a tester
    n = {s: sum(c["status"] == s for c in cams) for s in STATUS}
    rough = n["issues"] + n["nodark"]
    badge = (f"cameras-{n['working']}%20work" + (f"%20%C2%B7%20{rough}%20with%20a%20problem" if rough else "")
             + (f"%20%C2%B7%20{n['testing']}%20in%20testing" if n["testing"] else "") + "-3b352f")
    for p in (ROOT / "README.md", ROOT / "README.th.md"):
        p.write_text(re.sub(r"img\.shields\.io/badge/cameras-[^)]*-3b352f", "img.shields.io/badge/" + badge,
                            p.read_text(encoding="utf-8"), count=1), encoding="utf-8")
    replace(ROOT / "README.th.md", "<!-- cameras:start -->", "<!-- cameras:end -->", th)
    replace(ROOT / "README.md", "<!-- cameras:start -->", "<!-- cameras:end -->", rows)

    built = [c for c in cams if c["status"] in ("working", "issues", "testing", "nodark")]
    rows = ["| Camera | Canon firmware it needs | File |", "|---|---|---|"]
    rows += [f"| {c['name']} | {c['fw']} | `M-Film-camera-{c['plat']}.zip` |" for c in built]
    replace(ROOT / "TESTING.md", "<!-- cameras:start -->", "<!-- cameras:end -->", "\n".join(rows))

    wf = ROOT / ".github" / "workflows" / "camera.yml"
    text = wf.read_text(encoding="utf-8")
    text = re.sub(r"(        platform: )\[[^\]]*\]( *# from ml-dev/cameras.txt)?",
                  lambda m: m.group(1) + "[" + ", ".join(c["plat"] for c in built) + "]  # from ml-dev/cameras.txt", text, count=1)
    text = re.sub(r"(      NODARK: \")[^\"]*(\")",
                  lambda m: m.group(1) + " ".join(c["plat"] for c in cams if c["status"] == "nodark") + m.group(2), text, count=1)
    text = re.sub(r"(      MODULE: \")[^\"]*(\")",
                  lambda m: m.group(1) + " ".join(c["plat"] for c in built if c["module"]) + m.group(2), text, count=1)
    wf.write_text(text, encoding="utf-8")
    print(f"{len(cams)} cameras: {sum(c['status'] == 'working' for c in cams)} working, {sum(c['status'] == 'issues' for c in cams)} with a problem, "
          f"{sum(c['status'] == 'testing' for c in cams)} testing, {sum(c['status'] == 'nodark' for c in cams)} without the darkroom, {sum(c['status'] == 'memory' for c in cams)} too big at boot")


if __name__ == "__main__":
    main()
