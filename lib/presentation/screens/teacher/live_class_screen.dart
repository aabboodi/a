// lib/presentation/screens/teacher/live_class_screen.dart
class LiveClassScreen extends StatefulWidget {
  final ClassModel classData;
  
  const LiveClassScreen({required this.classData});
  
  @override
  _LiveClassScreenState createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  late RtcEngine _agoraEngine;
  late SocketService _socketService;
  
  bool _isCameraOn = false;
  bool _isMicOn = false;
  bool _isScreenSharing = false;
  bool _isRecording = false;
  bool _isClassActive = false;
  bool _isFreeSpeakMode = false;
  
  Duration _classDuration = Duration.zero;
  Timer? _durationTimer;
  
  List<StudentPresence> _students = [];
  List<ChatMessage> _messages = [];
  List<SpeakRequest> _speakRequests = [];
  
  int? _localUid;
  Set<int> _remoteUids = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _initializeSocket();
  }
  
  Future<void> _initializeAgora() async {
    // طلب الصلاحيات
    await [Permission.camera, Permission.microphone].request();
    
    // إنشاء محرك Agora
    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine.initialize(RtcEngineContext(
      appId: AppConfig.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    
    // تسجيل Event Handlers
    _agoraEngine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() => _localUid = connection.localUid);
        print('Local user joined: ${connection.localUid}');
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        setState(() => _remoteUids.add(remoteUid));
        print('Remote user joined: $remoteUid');
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        setState(() => _remoteUids.remove(remoteUid));
        print('Remote user offline: $remoteUid');
      },
      onError: (ErrorCodeType err, String msg) {
        print('Agora error: $err - $msg');
      },
    ));
    
    // تفعيل الفيديو
    await _agoraEngine.enableVideo();
    
    // إعدادات للشبكات الضعيفة
    await _agoraEngine.setVideoEncoderConfiguration(
      VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 480),
        frameRate: 15,
        bitrate: 800,
        minBitrate: 400,
        orientationMode: OrientationMode.orientationModeAdaptive,
        degradationPreference: DegradationPreference.maintainFramerate,
      ),
    );
    
    // تفعيل Dual Stream للتكيف مع الشبكات الضعيفة
    await _agoraEngine.enableDualStreamMode(enabled: true);
    
    // الانضمام للقناة كـ Broadcaster
    await _agoraEngine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );
    
    // الحصول على Token من Backend
    final token = await _getAgoraToken();
    
    await _agoraEngine.joinChannel(
      token: token,
      channelId: widget.classData.id,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }
  
  Future<String> _getAgoraToken() async {
    final response = await ApiService().post('/agora/token', {
      'channelName': widget.classData.id,
      'role': 'publisher',
    });
    return response['token'];
  }
  
  void _initializeSocket() {
    _socketService = context.read<SocketService>();
    _socketService.joinClass(widget.classData.id, 'teacher');
    
    // الاستماع للطلاب المنضمين
    _socketService.on('user-joined', (data) {
      setState(() {
        _students.add(StudentPresence.fromJson(data));
      });
    });
    
    // الاستماع للطلاب المغادرين
    _socketService.on('user-left', (data) {
      setState(() {
        _students.removeWhere((s) => s.userId == data['userId']);
      });
    });
    
    // استقبال الرسائل
    _socketService.on('new-message', (data) {
      setState(() {
        _messages.add(ChatMessage.fromJson(data));
      });
    });
    
    // استقبال طلبات المداخلة
    _socketService.on('speak-request', (data) {
      setState(() {
        _speakRequests.add(SpeakRequest.fromJson(data));
      });
      
      // إظهار إشعار
      _showSpeakRequestNotification(data['studentName']);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData.name),
        actions: [
          // مؤقت المحاضرة
          if (_isClassActive)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        _formatDuration(_classDuration),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // منطقة الفيديو الرئيسية
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // الفيديو الرئيسي
                Container(
                  color: Colors.black,
                  child: _isScreenSharing
                    ? _buildScreenShareView()
                    : _buildVideoView(),
                ),
                
                // أزرار التحكم العلوية
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildControlButtons(),
                ),
                
                // قائمة الطلاب المتحدثين
                if (_remoteUids.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _buildRemoteUsersView(),
                  ),
              ],
            ),
          ),
          
          // منطقة الأدوات السفلية
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                  label: 'الكاميرا',
                  isActive: _isCameraOn,
                  onPressed: _toggleCamera,
                ),
                _buildToolButton(
                  icon: _isMicOn ? Icons.mic : Icons.mic_off,
                  label: 'الميكروفون',
                  isActive: _isMicOn,
                  onPressed: _toggleMicrophone,
                ),
                _buildToolButton(
                  icon: Icons.screen_share,
                  label: 'مشاركة الشاشة',
                  isActive: _isScreenSharing,
                  onPressed: _toggleScreenShare,
                ),
                _buildToolButton(
                  icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
                  label: 'التسجيل',
                  isActive: _isRecording,
                  color: Colors.red,
                  onPressed: _toggleRecording,
                ),
                _buildToolButton(
                  icon: Icons.people,
                  label: 'الطلاب',
                  badge: _students.length,
                  onPressed: _showStudentsList,
                ),
                _buildToolButton(
                  icon: _speakRequests.isNotEmpty 
                    ? Icons.notifications_active 
                    : Icons.notifications,
                  label: 'الطلبات',
                  badge: _speakRequests.length,
                  onPressed: _showSpeakRequests,
                ),
                _buildToolButton(
                  icon: Icons.settings_voice,
                  label: _isFreeSpeakMode ? 'حر' : 'مقيد',
                  isActive: _isFreeSpeakMode,
                  onPressed: _toggleSpeakMode,
                ),
              ],
            ),
          ),
          
          // منطقة المحادثة
          Expanded(
            flex: 2,
            child: _buildChatSection(),
          ),
        ],
      ),
      
      // زر البدء/الإيقاف المركزي
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleClass,
        backgroundColor: _isClassActive ? Colors.orange : Colors.green,
        icon: Icon(_isClassActive ? Icons.pause : Icons.play_arrow),
        label: Text(_isClassActive ? 'إيقاف مؤقت' : 'بدء المحاضرة'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  
  Widget _buildControlButtons() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _isScreenSharing ? _showDrawingTools : null,
              tooltip: 'أدوات الرسم',
            ),
            IconButton(
              icon: Icon(Icons.grade),
              onPressed: _showGradesDialog,
              tooltip: 'إدخال العلامات',
            ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: _isClassActive ? _endClass : null,
              icon: Icon(Icons.stop),
              label: Text('إنهاء المحاضرة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoView() {
    if (_localUid == null) {
      return Center(child: CircularProgressIndicator());
    }
    
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _agoraEngine,
        canvas: VideoCanvas(uid: 0),
      ),
    );
  }
  
  Widget _buildScreenShareView() {
    // عرض مشاركة الشاشة مع إمكانية الرسم عليها
    return Stack(
      children: [
        // الشاشة المشاركة
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _agoraEngine,
            canvas: VideoCanvas(uid: 0),
            connection: RtcConnection(channelId: widget.classData.id),
          ),
        ),
        
        // طبقة الرسم
        if (_isDrawingMode)
          DrawingCanvas(
            onDrawingChanged: (drawing) {
              // بث الرسم للطلاب
              _socketService.emit('drawing-update', drawing);
            },
          ),
      ],
    );
  }
  
  Widget _buildRemoteUsersView() {
    return Container(
      height: 120,
      width: 100,
      child: ListView.builder(
        itemCount: _remoteUids.length,
        itemBuilder: (context, index) {
          final uid = _remoteUids.elementAt(index);
          final student = _students.firstWhere(
            (s) => s.agoraUid == uid,
            orElse: () => StudentPresence(userId: '', name: 'طالب'),
          );
          
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _agoraEngine,
                      canvas: VideoCanvas(uid: uid),
                      connection: RtcConnection(channelId: widget.classData.id),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      student.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildChatSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // عنوان المحادثة
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.chat, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'المحادثة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // الرسائل
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // حقل إدخال الرسالة
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // الدوال الرئيسية
  
  Future<void> _toggleCamera() async {
    await _agoraEngine.enableLocalVideo(!_isCameraOn);
    setState(() => _isCameraOn = !_isCameraOn);
  }
  
  Future<void> _toggleMicrophone() async {
    await _agoraEngine.enableLocalAudio(!_isMicOn);
    setState(() => _isMicOn = !_isMicOn);
  }
  
  Future<void> _toggleScreenShare() async {
    if (_isScreenSharing) {
      await _agoraEngine.stopScreenCapture();
    } else {
      await _agoraEngine.startScreenCapture(
        ScreenCaptureParameters2(
          captureVideo: true,
          captureAudio: true,
        ),
      );
    }
    setState(() => _isScreenSharing = !_isScreenSharing);
  }
  
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // إيقاف التسجيل
      final response = await ApiService().post('/recordings/stop', {
        'classId': widget.classData.id,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إيقاف التسجيل')),
      );
    } else {
      // بدء التسجيل
      await ApiService().post('/recordings/start', {
        'classId': widget.classData.id,
        'channelName': widget.classData.id,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم بدء التسجيل')),
      );
    }
    
    setState(() => _isRecording = !_isRecording);
  }
  
  void _toggleClass() {
    if (_isClassActive) {
      // إيقاف مؤقت
      _durationTimer?.cancel();
      _socketService.emit('class-paused', {'classId': widget.classData.id});
    } else {
      // بدء/استئناف
      _durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _classDuration = _classDuration + Duration(seconds: 1);
        });
      });
      _socketService.emit('class-resumed', {'classId': widget.classData.id});
    }
    
    setState(() => _isClassActive = !_isClassActive);
  }
  
  Future<void> _endClass() async {
    // تأكيد الإنهاء
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إنهاء المحاضرة'),
        content: Text('هل أنت متأكد من إنهاء المحاضرة؟ سيتم إنشاء تقرير الحضور وحفظ التسجيل.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('إنهاء'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      // إيقاف المؤقت
      _durationTimer?.cancel();
      
      // إيقاف التسجيل إذا كان نشطاً
      if (_isRecording) {
        await _toggleRecording();
      }
      
      // إنشاء تقرير الحضور
      final report = await ApiService().post('/classes/end', {
        'classId': widget.classData.id,
        'duration': _classDuration.inSeconds,
        'students': _students.map((s) => {
          'userId': s.userId,
          'duration': s.totalDuration,
        }).toList(),
      });
      
      // مغادرة القناة
      await _agoraEngine.leaveChannel();
      
      // إعلام الطلاب
      _socketService.emit('class-ended', {'classId': widget.classData.id});
      
      // عرض التقرير
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClassReportScreen(report: report),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إنهاء المحاضرة: $e')),
      );
    }
  }
  
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final message = {
      'classId': widget.classData.id,
      'userId': context.read<AuthProvider>().user!.id,
      'userName': context.read<AuthProvider>().user!.fullName,
      'content': text,
      'role': 'teacher',
    };
    
    _socketService.emit('send-message', message);
    _messageController.clear();
  }
  
  void _showStudentsList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StudentsListSheet(
        students: _students,
        totalStudents: widget.classData.students.length,
      ),
    );
  }
  
  void _showSpeakRequests() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SpeakRequestsSheet(
        requests: _speakRequests,
        onGrant: (studentId) {
          _socketService.emit('grant-speak', {
            'classId': widget.classData.id,
            'studentId': studentId,
          });
          setState(() {
            _speakRequests.removeWhere((r) => r.studentId == studentId);
          });
        },
        onDeny: (studentId) {
          setState(() {
            _speakRequests.removeWhere((r) => r.studentId == studentId);
          });
        },
      ),
    );
  }
  
  void _showGradesDialog() {
    showDialog(
      context: context,
      builder: (context) => GradesDialog(
        classData: widget.classData,
        students: widget.classData.students,
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
  
  @override
  void dispose() {
    _durationTimer?.cancel();
    _agoraEngine.leaveChannel();
    _agoraEngine.release();
    _socketService.leaveClass(widget.classData.id);
    super.dispose();
  }
}
