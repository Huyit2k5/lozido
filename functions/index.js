const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

/**
 * Trigger: Tự động chạy khi có hóa đơn mới trong collection "invoices"
 */
exports.sendZaloInvoiceBot = functions.firestore
    .document('houses/{houseid}/invoices/{invoiceId}')
    .onCreate(async (snap, context) => {
        // 1. Lấy dữ liệu cơ bản từ hóa đơn
        const invoiceData = snap.data();
        let zaloUid = invoiceData.zaloUid;
        const roomId = invoiceData.roomId;
        const houseId = context.params.houseid;

        // 2. CỐ GẮNG QUÉT LẠI ID ZALO MỚI NHẤT TỪ PHÒNG (Tránh lỗi ID cũ của hóa đơn)
        if (houseId && roomId) {
            try {
                const roomSnap = await admin.firestore().doc(`houses/${houseId}/rooms/${roomId}`).get();
                if (roomSnap.exists && roomSnap.data().zaloUid) {
                    zaloUid = roomSnap.data().zaloUid;
                    console.log(`🔄 Đã cập nhật Zalo ID mới nhất từ Phòng [${roomId}]: ${zaloUid}`);
                }
            } catch (e) {
                console.log("Không thể truy cập document Phòng, sử dụng ID mặc định từ hóa đơn.");
            }
        }

        // KIỂM TRA: Chỉ gửi nếu sendZaloApp là true
        if (invoiceData.sendZaloApp === false) {
            console.log("Bỏ qua: Chủ nhà không chọn gửi nội dung Zalo.");
            return null;
        }

        if (!zaloUid) {
            console.log("Bỏ qua: Hóa đơn này chưa có Zalo ID (Khách chưa kết nối).");
            return null;
        }

        // ĐỊNH NGHĨA LẠI CÁC BIẾN DỮ LIỆU HÓA ĐƠN
        const roomName = invoiceData.roomName || "N/A";
        const tenantName = invoiceData.tenantName || "Khách hàng";
        const totalAmount = invoiceData.grandTotal || 0;
        const month = invoiceData.billingMonth || "này";

        try {
            const configDoc = await admin.firestore().doc('config/zalo_api').get();
            if (!configDoc.exists) {
                console.error("Lỗi: Chưa có cấu hình Zalo Bot tại config/zalo_api");
                return null;
            }
            const botToken = configDoc.data().bot_token;

            const messageText = `CHÀO ${tenantName.toUpperCase()}!\n` +
                `Hóa đơn tiền nhà [${roomName}] tháng ${month} của bạn đã có.\n` +
                `Tổng tiền: ${totalAmount.toLocaleString('vi-VN')} đ\n` +
                `Vui lòng kiểm tra chi tiết trên ứng dụng và thanh toán đúng hạn. Trân trọng!`;

            const sendUrl = `https://bot-api.zaloplatforms.com/bot${botToken}/sendMessage`;
            console.log('Đang gửi thông báo tới:', zaloUid);

            const response = await axios.post(sendUrl, {
                chat_id: zaloUid,
                text: messageText
            }, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 15000
            });

            if (response.data && (response.data.ok || response.data.success)) {
                console.log(`✅ SUCCESS: Đã gửi Zalo cho khách ${tenantName} thành công!`);
                return snap.ref.update({
                    zaloStatus: 'sent',
                    sentAt: admin.firestore.FieldValue.serverTimestamp()
                });
            } else {
                console.error("❌ Zalo Bot trả về lỗi:", response.data);
            }

        } catch (error) {
            console.error("❌ Lỗi hệ thống khi gửi Zalo:", error.message);
        }
    });

/**
 * Webhook: Nhận tin nhắn từ khách để tự động kết nối ID Zalo
 */
exports.zaloWebhook = functions.https.onRequest(async (req, res) => {
    // 1. GET Request: Trả về trang Web/Xác thực
    if (req.method === 'GET') {
        try {
            const configDoc = await admin.firestore().doc('config/zalo_api').get();
            const verificationCode = configDoc.exists ? (configDoc.data().zalo_verification || "") : "";

            const html = `
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <title>Lozido Zalo Webhook</title>
                    ${verificationCode ? `<meta name="zalo-platform-site-verification" content="${verificationCode}" />` : ""}
                </head>
                <body style="font-family: sans-serif; text-align: center; padding: 50px; background-color: #f0f2f5;">
                    <div style="background: white; display: inline-block; padding: 40px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
                        <h1 style="color: #00A651; margin-bottom: 10px;">Lozido Zalo Webhook</h1>
                        <p style="color: #666;">Status: <span style="color: #0068FF; font-weight: bold;">ACTIVE</span></p>
                        <p style="font-size: 14px; color: #888;">Hệ thống đã sẵn sàng nhận tin nhắn từ khách hàng.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                        <p style="font-size: 12px; color: #aaa;">Challenge: ${req.query.challenge || "OK"}</p>
                    </div>
                </body>
                </html>
            `;
            return res.status(200).set('Content-Type', 'text/html').send(html);
        } catch (e) {
            return res.status(200).send(req.query.challenge || "OK");
        }
    }

    if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
    }

    try {
        const body = req.body;
        const headers = req.headers;

        // LOG CỰC KỲ CHI TIẾT ĐỂ BẮT BỆNH
        console.log('--- 📨 NHẬN WEBHOOK MỚI ---');
        console.log('📑 HEADERS:', JSON.stringify(headers, null, 2));
        console.log('📦 BODY:', JSON.stringify(body, null, 2));

        // 2. Kiểm tra Secret Token (Bảo mật)
        const configDoc = await admin.firestore().doc('config/zalo_api').get();
        const secretToken = configDoc.exists ? configDoc.data().secret_token : null;
        const incomingSecret = headers['x-zalo-secret'] || body.secret_token;

        if (secretToken && incomingSecret !== secretToken) {
            console.warn('⚠️ Cảnh báo: Secret Token không khớp. Bỏ qua yêu cầu.');
            // (Tùy chọn: Uncomment dòng dưới nếu muốn bắt buộc bảo mật)
            // return res.status(403).send('Forbidden');
        }

        const message = body.message || {};
        const text = (message.text || "").trim();

        let chatId = null;
        if (body.from && body.from.id) chatId = body.from.id;
        else if (message.from && message.from.id) chatId = message.from.id;
        else if (message.chat && message.chat.id) chatId = message.chat.id;
        else if (body.chat_id) chatId = body.chat_id;

        if (chatId) chatId = chatId.toString();

        console.log(`💬 Xử lý nội dung: "${text}" | Từ ChatId: ${chatId}`);

        if (chatId && text.toLowerCase().includes('ketnoi')) {
            const phoneMatch = text.match(/\d{9,11}/);
            const phoneNumber = phoneMatch ? phoneMatch[0] : null;

            if (phoneNumber) {
                const contractQuery = await admin.firestore()
                    .collectionGroup('contracts')
                    .where('phoneNumber', '==', phoneNumber)
                    .where('status', '==', 'Active')
                    .get();

                if (!contractQuery.empty) {
                    const batch = admin.firestore().batch();
                    let linkedRooms = [];

                    for (const doc of contractQuery.docs) {
                        const contractData = doc.data();
                        const houseId = contractData.houseId;
                        const roomId = contractData.roomId;
                        batch.update(doc.ref, { zaloUid: chatId });
                        if (houseId && roomId) {
                            const roomRef = admin.firestore().doc(`houses/${houseId}/rooms/${roomId}`);
                            batch.update(roomRef, { zaloUid: chatId });
                            linkedRooms.push(contractData.roomName || "N/A");
                        }
                    }
                    await batch.commit();
                    console.log(`✅ Đã kết nối Zalo cho các phòng: ${linkedRooms.join(', ')}`);

                    // Phản hồi cho khách kèm theo tên nhà trọ
                    try {
                        let houseName = "nhà trọ";
                        // Lấy houseId từ hợp đồng đầu tiên để tìm tên nhà
                        const firstContract = contractQuery.docs[0].data();
                        if (firstContract.houseId) {
                            const houseSnap = await admin.firestore().doc(`houses/${firstContract.houseId}`).get();
                            if (houseSnap.exists) {
                                houseName = houseSnap.data().name || houseName;
                            }
                        }

                        const botToken = configDoc.data().bot_token;
                        const replyUrl = `https://bot-api.zaloplatforms.com/bot${botToken}/sendMessage`;
                        await axios.post(replyUrl, {
                            chat_id: chatId,
                            text: `✅ [Lozido] Kết nối thành công!\nBạn đã được liên kết với phòng: ${linkedRooms.join(', ')} tại ${houseName}. Từ nay bạn sẽ nhận được thông báo hóa đơn tự động qua Zalo.`
                        });
                    } catch (e) {
                        console.error('Lỗi khi gửi tin nhắn phản hồi:', e.message);
                    }
                }
            }
        }

        return res.status(200).json({ status: "success" });
    } catch (error) {
        console.error('❌ Webhook Error:', error.message);
        return res.status(500).json({ status: "error", message: error.message });
    }
});

/**
 * Setup Tool: Chạy hàm này để kích hoạt Webhook với Zalo Bot
 */
exports.setupZaloBot = functions.https.onRequest(async (req, res) => {
    try {
        const configDoc = await admin.firestore().doc('config/zalo_api').get();
        if (!configDoc.exists) return res.send("Lỗi: Chưa có cấu hình config/zalo_api trong Firestore.");

        const botToken = configDoc.data().bot_token;
        const secretToken = configDoc.data().secret_token;
        const webhookUrl = "https://us-central1-lozido-d7efc.cloudfunctions.net/zaloWebhook";

        console.log(`📡 Đang đăng ký Webhook: ${webhookUrl}`);

        const entrypoint = `https://bot-api.zaloplatforms.com/bot${botToken}/setWebhook`;
        const response = await axios.post(entrypoint, {
            url: webhookUrl,
            secret_token: secretToken
        });

        return res.status(200).json({
            message: "Kết quả đăng ký Webhook với Zalo",
            status: response.status,
            data: response.data,
            registered_url: webhookUrl
        });

    } catch (error) {
        console.error('❌ Setup Error:', error.message);
        return res.status(500).json({
            error: error.message,
            detail: error.response ? error.response.data : "No detail"
        });
    }
});