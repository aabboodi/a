// lib/presentation/screens/student/student_class_screen.dart
class StudentClassScreen extends StatefulWidget {
  final ClassModel classData;
  
  const StudentClassScreen({required this.classData});
  
  @override
  _StudentClassScreenState createState() => _StudentClassScreenState();
}

class _StudentClassScreenState extends State<StudentClassScreen> {
  late RtcEngine _agoraEngine;
  late SocketService _socketService;
  
  bool _isMicOn = false;
  bool _canSpeak = false;
  bool _hasPendingRequest = false;
  
  List<ChatMessage> _messages = [];
  List<RecordingModel> _recordings = [];
  
  int? _teacherUid;
  Set<int> _speakingStudents = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _initializeSocket();
    _loadRecordings();
  }
  
  Future<void> _initializeAgora() async {
    await [Permission.microphone].request();
    
    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine.initialize(RtcEngineContext(
      appId: AppConfig.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    
    _agoraEngine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        print('Student joined: ${connection.localUid}');
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() {
          if (_teacherUid == null) {
            _teacherUid = remoteUid;
          } else {
            _speakingStudents.add(remoteUid);
          }
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() {
          _speakingStudents.remove(remoteUid);
        });
      },
    ));
    
    await _agoraEngine.enableVideo();
    
    // الطالب كـ Audience بشكل افتراضي
    await _agoraEngine.setClientRole(
      role: ClientRoleType.clientRoleAudience,
    );
    
    final token = await _getAgoraToken();
    
    await _agoraEngine.joinChannel(
      token: token,
      channelId: widget.classData.id,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }
  
  Future<String> _getAgoraToken() async {
    final response = await ApiService().post('/agora/token', {
      'channelName': widget.classData.id,
      'role': 'subscriber',
    });
    return response['token'];
  }
  
  void _initializeSocket() {
    _socketService = context.read<SocketService>();
    _socketService.joinClass(widget.classData.id, 'student');
    
    // استقبال الرسائل
    _socketService.on('new-message', (data) {
      setState(() {
        _messages.add(ChatMessage.fromJson(data));
      });
    });
    
    // استقبال السماح بالمداخلة
    _socketService.on('speak-granted', (data) {
      final userId = context.read<AuthProvider>().user!.id;
      if (data['studentId'] == userId) {
        _enableSpeaking();
      }
    });
    
    // استقبال التسجيل الجاهز
    _socketService.on('recording-ready', (data) {
      _loadRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تسجيل المحاضرة جاهز للتنزيل')),
      );
    });
  }
  
  Future<void> _loadRecordings() async {
    try {
      final response = await ApiService().get(
        '/classes/${widget.classData.id}/recordings'
      );
      setState(() {
        _recordings = (response['recordings'] as List)
            .map((r) => RecordingModel.fromJson(r))
            .toList();
      });
    } catch (e) {
      print('Error loading recordings: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classData.name),
      ),
      body: Column(
        children: [
          // شاشة العرض الكبيرة
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // فيديو المدرس
                  if (_teacherUid != null)
                    AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: _agoraEngine,
                        canvas: VideoCanvas(uid: _teacherUid),
                        connection: RtcConnection(
                          channelId: widget.classData.id,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'في انتظار المدرس...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  
                  // الطلاب المتحدثين
                  if (_speakingStudents.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _buildSpeakingStudents(),
                    ),
                  
                  // حالة الميكروفون
                  if (_canSpeak)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isMicOn ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isMicOn ? Icons.mic : Icons.mic_off,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _isMicOn ? 'الميكروفون مفعل' : 'الميكروفون مغلق',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // أزرار التحكم
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
                // زر طلب الإذن
                ElevatedButton.icon(
                  onPressed: _hasPendingRequest ? null : _requestSpeak,
                  icon: Icon(_hasPendingRequest 
                    ? Icons.schedule 
                    : Icons.pan_tool,
                  ),
                  label: Text(_hasPendingRequest 
                    ? 'تم الإرسال'
                    : 'طلب المداخلة',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasPendingRequest 
                      ? Colors.orange 
                      : Colors.blue,
                  ),
                ),
                
                // زر الميكروفون (فقط إذا سمح له)
                if (_canSpeak)
                  IconButton(
                    icon: Icon(
                      _isMicOn ? Icons.mic : Icons.mic_off,
                      size: 32,
                    ),
                    onPressed: _toggleMicrophone,
                    color: _isMicOn ? Colors.green : Colors.red,
                  ),
                
                // زر التسجيلات
                Badge(
                  label: Text('${_recordings.length}'),
                  child: IconButton(
                    icon: Icon(Icons.video_library),
                    onPressed: _showRecordings,
                  ),
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
    );
  }
  
  Widget _buildSpeakingStudents() {
    return Container(
      height: 80,
      width: 80,
      child: ListView.builder(
        itemCount: _speakingStudents.length,
        itemBuilder: (context, index) {
          final uid = _speakingStudents.elementAt(index);
          return Container(
            margin: EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _agoraEngine,
                  canvas: VideoCanvas(uid: uid),
                  connection: RtcConnection(channelId: widget.classData.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildChatSection() {
    // مشابه لنافذة المدرس
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
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
  
  void _requestSpeak() {
    final user = context.read<AuthProvider>().user!;
    
    _socketService.emit('request-speak', {
      'classId': widget.classData.id,
      'studentId': user.id,
      'studentName': user.fullName,
    });
    
    setState(() => _hasPendingRequest = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال طلب المداخلة')),
    );
  }
  
  Future<void> _enableSpeaking() async {
    // تغيير الدور إلى Broadcaster
    await _agoraEngine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );
    
    await _agoraEngine.enableLocalAudio(true);
    
    setState(() {
      _canSpeak = true;
      _isMicOn = true;
      _hasPendingRequest = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم السماح لك بالمداخلة'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _toggleMicrophone() async {
    await _agoraEngine.enableLocalAudio(!_isMicOn);
    setState(() => _isMicOn = !_isMicOn);
  }
  
  void _showRecordings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => RecordingsSheet(
        recordings: _recordings,
        onDownload: (recording) async {
          // تنزيل التسجيل
          await _downloadRecording(recording);
        },
        onPlay: (recording) {
          // تشغيل التسجيل
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                recording: recording,
              ),
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _downloadRecording(RecordingModel recording) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('جاري التنزيل...')),
      );
      
      // تنزيل الفيديو
      final dio = Dio();
      final savePath = await _getSavePath(recording.filename);
      
      await dio.download(
        '${ApiService.baseUrl}/recordings/${recording.id}/download',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم التنزيل بنجاح')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التنزيل')),
      );
    }
  }
  
  @override
  void dispose() {
    _agoraEngine.leaveChannel();
    _agoraEngine.release();
    _socketService.leaveClass(widget.classData.id);
    super.dispose();
  }
}
