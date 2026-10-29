# LUTs

วางไฟล์ `.cube` ไว้ที่นี่ แล้วตั้งชื่อตามฟิล์มใน `films.py` ตามด้วยสิ่งที่ LUT ต้องการเป็นอินพุต:

    portra400.logc3.cube      ใช้กับทุกม้วนที่เป็น Portra 400 อัตโนมัติ, อินพุต ARRI LogC3
    cinestill800t.cineon.cube อินพุต Cineon log
    hp5.srgb.cube             อินพุตภาพปกติ (LUT ที่ทำจาก Lightroom / Photoshop)

อินพุตที่รองรับ: `logc3`, `cineon`, `rec709`, `srgb`, `linear` (รายละเอียดใน `../lut.py`)
ถ้าไม่ระบุในชื่อไฟล์ จะถือว่าเป็น `srgb`

ไฟล์ `.cube` ไม่ถูกเก็บใน git (LUT ส่วนใหญ่มีลิขสิทธิ์)
