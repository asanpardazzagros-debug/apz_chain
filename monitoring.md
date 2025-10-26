
---

✅ ابزار پیشنهادی: [PM2 + pm2-monitor + Uptime Kuma]

1. 📦 مانیتورینگ داخلی با PM2

اگر از PM2 برای اجرای API و Web استفاده می‌کنی، می‌توانی از داشبورد داخلی آن بهره ببری:

نصب داشبورد مانیتورینگ:

`bash
pm2 install pm2-server-monit
`

مشاهده وضعیت:

`bash
pm2 monit
`

✅ نمایش لحظه‌ای:
- مصرف CPU و RAM  
- تعداد درخواست‌ها  
- وضعیت سرویس‌ها  
- خطاهای اخیر

---

2. 🌐 مانیتورینگ خارجی با Uptime Kuma

Uptime Kuma یک ابزار مانیتورینگ وب‌محور است که می‌تونه وضعیت API و Web را از بیرون بررسی کنه.

نصب با Docker:

`bash
docker run -d --restart=always -p 3002:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma
`

دسترسی:

`
http://your-server-ip:3002
`

✅ امکانات:
- بررسی لحظه‌ای API و Web  
- ارسال هشدار به تلگرام، Discord، ایمیل  
- نمودارهای وضعیت و تاریخچه  
- رابط کاربری فارسی و چندزبانه

---

3. 📁 فایل monitoring.md برای مستندات پروژه

📁 مسیر: docs/monitoring.md

`markdown

مانیتورینگ سرور | APZ Dashboard

✅ مانیتورینگ داخلی با PM2

`bash
pm2 install pm2-server-monit
pm2 monit
`

✅ مانیتورینگ خارجی با Uptime Kuma

`bash
docker run -d --restart=always -p 3002:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma
`

📍 دسترسی: http://your-server-ip:3002

🔔 هشدارها

- می‌توانید اعلان‌ها را به تلگرام، Discord، یا ایمیل متصل کنید
- در صورت قطع شدن API یا Web، هشدار فوری ارسال می‌شود
`
