// backend/src/routes/messaging.js
router.post('/whatsapp/configure', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const { apiKey, phoneNumberId } = req.body;
    
    if (!apiKey || !phoneNumberId) {
      return res.status(400).json({
        success: false,
        message: 'API Key and Phone Number ID are required',
      });
    }
    
    // حفظ في متغيرات البيئة أو قاعدة البيانات
    whatsappService.setCredentials(apiKey, phoneNumberId);
    
    res.json({
      success: true,
      message: 'WhatsApp API configured successfully',
    });
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

router.post('/whatsapp/send', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const { message, recipients } = req.body;
    
    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Message is required',
      });
    }
    
    let results;
    
    if (recipients === 'all') {
      // إرسال للجميع
      results = await whatsappService.sendToAll(message);
    } else if (Array.isArray(recipients)) {
      // إرسال لأرقام محددة
      results = await whatsappService.sendBulkMessages(recipients, message);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid recipients',
      });
    }
    
    res.json({
      success: true,
      results,
    });
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// إدارة المتابعين
router.get('/contacts', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const contacts = await Contact.find().sort({ createdAt: -1 });
    res.json({ success: true, contacts });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/contacts', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const contact = await Contact.create(req.body);
    res.json({ success: true, contact });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.delete('/contacts/:id', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    await Contact.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});
