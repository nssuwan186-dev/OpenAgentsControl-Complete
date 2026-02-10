# 🛡️ OAC Security Hardening Guide

## นำแนวทางจาก OpenClaw Security Guide มาใช้กับ OAC

บทความต้นฉบับ: [How to Self-Host OpenClaw Securely on a VPS](https://www.dsebastien.net/how-to-self-host-openclaw-securely-on-a-vps-a-security-first-guide)

---

## 🎯 หลักการสำคัญจาก OpenClaw ที่นำมาใช้

### 1. **Isolation (การแยกส่วน)**
**จาก OpenClaw:**
- ใช้ Dedicated VPS (ไม่ใช่เครื่องหลัก)
- สร้าง user แยกสำหรับ OpenClaw (`openclaw`)

**ใช้กับ OAC:**
- ✅ สร้าง user `oac` แยกจาก root
- ✅ ติดตั้ง OAC ใน `/home/oac/OpenAgentsControl/`
- ✅ ไม่รันด้วย root

---

### 2. **Zero Trust Networking**
**จาก OpenClaw:**
- ใช้ Tailscale สร้าง private mesh network
- ไม่ expose services สู่ public internet
- ใช้ shields-up บน client

**ใช้กับ OAC:**
- ✅ แนะนำติดตั้ง Tailscale
- ✅ SSH ผ่าน Tailscale IP แทน public IP
- ✅ ปิด port 22 จาก public (หลังจากมี Tailscale)

---

### 3. **Defense in Depth**
**จาก OpenClaw:**
- SSH hardening
- Fail2Ban
- UFW Firewall
- Auto-updates
- Protection skills

**ใช้กับ OAC:**
- ✅ **SSH Hardening:**
  - ปิด root login
  - ปิด password authentication
  - ใช้ key-based auth เท่านั้น
  
- ✅ **Fail2Ban:**
  - Ban IP ที่พยายาม brute force SSH
  - ตั้งค่า maxretry = 3
  
- ✅ **UFW Firewall:**
  - Default deny incoming
  - Allow only necessary ports
  
- ✅ **Auto-updates:**
  - ติดตั้ง unattended-upgrades
  - อัพเดท security patches อัตโนมัติ

---

### 4. **Least Privilege (สิทธิ์ขั้นต่ำ)**
**จาก OpenClaw:**
- Agent ทำงานด้วยสิทธิ์จำกัด
- ไม่ให้ API keys ทั้งหมด
- ระวัง skills จาก third-party

**ใช้กับ OAC:**
- ✅ User `oac` อยู่ในกลุ่ม sudo แต่ใช้งานแยกจาก root
- ✅ OAC Agents มี permission controls ในตัว
- ✅ Approval gates บังคับขออนุมัติก่อนทำงาน

---

### 5. **Monitoring & Auditing**
**จาก OpenClaw:**
- journalctl ดู logs
- security audit สม่ำเสมอ
- ตรวจสอบเมื่อมีบางอย่างผิดปกติ

**ใช้กับ OAC:**
- ✅ สร้าง script ตรวจสอบความปลอดภัยรายวัน
- ✅ Registry validation ตรวจสอบ paths และ dependencies
- ✅ Test suite ตรวจสอบการทำงานของ agents

---

## 🚀 วิธีใช้ Security Hardening Script

### ขั้นตอนที่ 1: รันสคริปต์บน VPS
```bash
# รันด้วย root
sudo bash oac-security-hardening.sh
```

สคริปต์จะทำ:
1. อัพเดทระบบ
2. สร้าง user `oac`
3. Harden SSH (ปิด root + password)
4. ติดตั้ง Fail2Ban
5. สร้าง swap file
6. ตั้งค่า UFW firewall
7. เปิด auto-updates
8. ตั้งค่า time sync
9. ตั้งค่า OAC permissions
10. ตรวจสอบความปลอดภัย

---

### ขั้นตอนที่ 2: ติดตั้ง Tailscale (แนะนำมาก)
```bash
# บน VPS
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# ดู Tailscale IP
tailscale ip -4
```

**บนเครื่อง client ของคุณ:**
```bash
# ติดตั้ง Tailscale
# เปิด shields-up (สำคัญ!)
sudo tailscale set --shields-up=true

# SSH ผ่าน Tailscale
ssh oac@<vps-tailscale-ip>
```

---

### ขั้นตอนที่ 3: ปิด SSH จาก Public (หลังจากมี Tailscale)
```bash
# ลบ allow ssh จาก public
sudo ufw delete allow ssh

# อนุญาตเฉพาะผ่าน Tailscale
sudo ufw allow in on tailscale0
sudo ufw reload
```

---

### ขั้นตอนที่ 4: ใช้งาน OAC
```bash
# เปลี่ยนเป็น user oac
su - oac

# เริ่มใช้งาน OAC
cd OpenAgentsControl
./start-agent.sh
```

---

## 📋 Security Checklist

ก่อนใช้งานจริง ตรวจสอบรายการนี้:

- [ ] รัน `oac-security-hardening.sh` จนจบ
- [ ] ตั้งรหัสผ่านให้ user `oac`
- [ ] ทดสอบ SSH ด้วย key (ก่อนปิดเซสชัน)
- [ ] ติดตั้ง Tailscale
- [ ] ตั้งค่า shields-up บน client
- [ ] ปิด SSH จาก public (ถ้าใช้ Tailscale)
- [ ] รัน security check: `/usr/local/bin/oac-security-check`
- [ ] ทดสอบ OAC ทำงานได้

---

## ⚠️ ข้อควรระวัง (จาก OpenClaw)

### ห้ามทำ:
1. ❌ อย่าติดตั้ง OAC บนเครื่องหลัก (ใช้ VPS เท่านั้น)
2. ❌ อย่า expose OAC สู่ public internet โดยตรง
3. ❌ อย่าให้ API keys ทั้งหมดแก่ agent
4. ❌ อย่าละเลยการ monitor logs

### ควรทำ:
1. ✅ ใช้ dedicated user (ไม่ใช่ root)
2. ✅ ใช้ Tailscale หรือ VPN สำหรับการเชื่อมต่อ
3. ✅ ตรวจสอบ security เป็นประจำ
4. ✅ Backup การตั้งค่าสม่ำเสมอ

---

## 🔍 การตรวจสอบความปลอดภัย

### ตรวจสอบรายวัน:
```bash
# รันสคริปต์ตรวจสอบ
/usr/local/bin/oac-security-check

# ดู logs
tail -f /var/log/auth.log

# ดูสถานะ services
systemctl status sshd
systemctl status fail2ban
```

### ตรวจสอบ OAC:
```bash
cd /home/oac/OpenAgentsControl
npm run validate:registry
./run-test.sh smoke
```

---

## 📊 สรุปการปรับใช้จาก OpenClaw

| OpenClaw Feature | OAC Implementation | Status |
|-----------------|-------------------|--------|
| Dedicated User | user `oac` | ✅ |
| SSH Hardening | PermitRootLogin no, PasswordAuthentication no | ✅ |
| Fail2Ban | ติดตั้งและตั้งค่า | ✅ |
| UFW Firewall | Default deny, allow selective | ✅ |
| Auto-updates | unattended-upgrades | ✅ |
| Time Sync | chrony | ✅ |
| Tailscale | แนะนำและมีคำแนะนำ | ✅ |
| Protection Skills | Approval gates + permissions | ✅ |
| Monitoring | Daily security check script | ✅ |
| Isolation | VPS only, not main machine | ✅ |

---

## 📚 References

- [OpenClaw Security Guide](https://www.dsebastien.net/how-to-self-host-openclaw-securely-on-a-vps-a-security-first-guide)
- [OAC README](./README.md)
- [Tailscale Documentation](https://tailscale.com/kb)

---

**🛡️ ระบบพร้อมใช้งานอย่างปลอดภัยแล้ว!**
