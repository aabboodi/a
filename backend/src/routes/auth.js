// backend/src/routes/auth.js
router.post('/login', async (req, res) => {
  try {
    const { code } = req.body;
    
    // التحقق من صحة الكود
    if (!code || code.length < 4) {
      return res.status(400).json({
        success: false,
        message: 'كود غير صالح',
      });
    }
    
    // البحث عن المستخدم
    const user = await User.findOne({ code });
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'كود خاطئ',
      });
    }
    
    // إنشاء JWT Token
    const token = jwt.sign(
      { 
        userId: user._id,
        role: user.role,
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    // حفظ الجلسة في Redis
    await redis.setex(
      `session:${user._id}`,
      604800, // 7 days
      JSON.stringify({ userId: user._id, role: user.role })
    );
    
    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        code: user.code,
        fullName: user.fullName,
        role: user.role,
      },
    });
    
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في السيرفر',
    });
  }
});
