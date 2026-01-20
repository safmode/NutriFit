import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color kPrimary = Color(0xFF92A3FD);

  final AuthService _authService = AuthService();
  late final AnimationController _controller;

  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = _authService.currentUser?.uid;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _notiCol(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  Future<void> _seedDemoIfEmpty(String uid) async {
    // Optional: seed only if empty (useful for demo)
    final snap = await _notiCol(uid).limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final now = DateTime.now();
    final demo = <Map<String, dynamic>>[
      {
        'type': 'meal',
        'title': "Hey, it's time for lunch",
        'createdAt': now.subtract(const Duration(minutes: 1)),
        'read': false,
      },
      {
        'type': 'workout',
        'title': "Don't miss your lowerbody workout",
        'createdAt': now.subtract(const Duration(hours: 3)),
        'read': false,
      },
      {
        'type': 'meal',
        'title': "Hey, let's add some meals for your b...",
        'createdAt': now.subtract(const Duration(hours: 3)),
        'read': true,
      },
      {
        'type': 'achievement',
        'title': "Congratulations, You have finished A...",
        'createdAt': now.subtract(const Duration(days: 2)),
        'read': true,
      },
      {
        'type': 'meal',
        'title': "Hey, it's time for lunch",
        'createdAt': now.subtract(const Duration(days: 20)),
        'read': true,
      },
      {
        'type': 'workout',
        'title': "Ups, You have missed your Lowerbo...",
        'createdAt': now.subtract(const Duration(days: 25)),
        'read': true,
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (final d in demo) {
      final ref = _notiCol(uid).doc();
      batch.set(ref, {
        ...d,
        'createdAt': Timestamp.fromDate((d['createdAt'] as DateTime)),
      });
    }
    await batch.commit();
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'About ${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return 'About ${diff.inHours} hours ago';

    // date label similar to mockup: "29 May"
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  _NotiUI _uiForType(String type, bool read) {
    // Keep your “circle icon + bg” style
    switch (type) {
      case 'meal':
        return _NotiUI(
          icon: Icons.lunch_dining,
          iconBg: const Color(0xFFFFE8D6),
          iconColor: Colors.orange,
        );
      case 'workout':
        return _NotiUI(
          icon: Icons.fitness_center,
          iconBg: const Color(0xFFE8EEFF),
          iconColor: const Color(0xFF92A3FD),
        );
      case 'achievement':
        return _NotiUI(
          icon: Icons.emoji_events,
          iconBg: const Color(0xFFE8EEFF),
          iconColor: const Color(0xFF92A3FD),
        );
      default:
        return _NotiUI(
          icon: Icons.notifications,
          iconBg: const Color(0xFFF0F0F5),
          iconColor: read ? Colors.grey : const Color(0xFF92A3FD),
        );
    }
  }

  Future<void> _markAsRead(String uid, String docId) async {
    await _notiCol(uid).doc(docId).update({'read': true});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as read')),
    );
  }

  Future<void> _deleteOne(String uid, String docId) async {
    await _notiCol(uid).doc(docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted')),
    );
  }

  Future<void> _clearAll(String uid) async {
    final snap = await _notiCol(uid).get();
    if (snap.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared all notifications')),
    );
  }

  void _showItemMenu({
    required String uid,
    required String docId,
    required bool isRead,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.done_all, color: kPrimary),
                title: Text(isRead ? 'Already read' : 'Mark as read'),
                onTap: isRead
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _markAsRead(uid, docId);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteOne(uid, docId);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Notification',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Please login first.'),
        ),
      );
    }

    // Optional demo seed: comment out if not needed
    _seedDemoIfEmpty(uid);

    final query = _notiCol(uid).orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snap) {
              final hasItems = (snap.data?.docs.isNotEmpty ?? false);
              return TextButton(
                onPressed: hasItems ? () => _clearAll(uid) : null,
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: hasItems ? kPrimary : Colors.grey.shade400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return _EmptyState(onBackHome: () => Navigator.pop(context));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: docs.length,
            separatorBuilder: (_, _) => Divider(
              color: Colors.grey.shade200,
              thickness: 1,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final title = (data['title'] ?? '').toString();
              final type = (data['type'] ?? 'general').toString();
              final read = (data['read'] is bool) ? data['read'] as bool : false;

              DateTime createdAt = DateTime.now();
              final ts = data['createdAt'];
              if (ts is Timestamp) createdAt = ts.toDate();

              final ui = _uiForType(type, read);
              final time = _timeLabel(createdAt);

              // Staggered entrance animation
              final start = (index * 0.08).clamp(0.0, 0.6);
              final anim = CurvedAnimation(
                parent: _controller,
                curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
              );

              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(anim),
                  child: _TapScale(
                    onTap: () async {
                      // Mark as read when opened
                      if (!read) {
                        await _markAsRead(uid, doc.id);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opened: $title')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: ui.iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(ui.icon, color: ui.iconColor, size: 24),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert,
                                color: Colors.grey.shade400, size: 20),
                            onPressed: () => _showItemMenu(
                              uid: uid,
                              docId: doc.id,
                              isRead: read,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotiUI {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _NotiUI({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBackHome;
  const _EmptyState({required this.onBackHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 38,
                color: Color(0xFF92A3FD),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'You’re all caught up for now.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onBackHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF92A3FD),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small “top-level” tap animation (scale down then up)
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
