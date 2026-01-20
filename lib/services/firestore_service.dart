// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

extension _DateKey on DateTime {
  String get ymd => DateFormat('yyyyMMdd').format(this);
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => startOfDay.add(const Duration(days: 1));
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // -----------------------------
  // Collections
  // -----------------------------
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  // user subcollections
  CollectionReference<Map<String, dynamic>> _schedules(String uid) =>
      _users.doc(uid).collection('schedules');

  CollectionReference<Map<String, dynamic>> _activities(String uid) =>
      _users.doc(uid).collection('activities');

  DocumentReference<Map<String, dynamic>> _dailyTargetsDoc(String uid) =>
      _users.doc(uid).collection('targets').doc('daily');

  // meal schedules
  CollectionReference<Map<String, dynamic>> _mealSchedules(String uid) =>
      _users.doc(uid).collection('mealSchedules');

  // progress photos
  CollectionReference<Map<String, dynamic>> _progressPhotos(String uid) =>
      _users.doc(uid).collection('progress_photos');

  // daily summary
  CollectionReference<Map<String, dynamic>> _daily(String uid) =>
      _users.doc(uid).collection('daily');

  DocumentReference<Map<String, dynamic>> dailyDoc(String uid, DateTime day) =>
      _daily(uid).doc(day.ymd);

  // logs
  CollectionReference<Map<String, dynamic>> _waterLogs(String uid) =>
      _users.doc(uid).collection('water_logs');

  CollectionReference<Map<String, dynamic>> _mealLogs(String uid) =>
      _users.doc(uid).collection('meal_logs');

  CollectionReference<Map<String, dynamic>> _sleepLogs(String uid) =>
      _users.doc(uid).collection('sleep_logs');

  CollectionReference<Map<String, dynamic>> _workoutLogs(String uid) =>
      _users.doc(uid).collection('workout_logs');

  void _requireUid(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError('uid is empty. User must be logged in.');
    }
  }

  // -----------------------------
  // GENERIC FIRESTORE METHODS (from your friend)
  // -----------------------------
  
  /// Create/Update user data (generic version)
  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Get user data (generic version - returns DocumentSnapshot)
  /// Note: Use getUserData(uid) for the typed version
  Future<DocumentSnapshot> getUserDataGeneric(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  /// Stream user data (generic version - returns DocumentSnapshot)
  /// Note: Use streamUserData(uid) for the typed version
  Stream<DocumentSnapshot> streamUserDataGeneric(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Add document to any collection
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    return await _db.collection(collection).add(data);
  }

  /// Get entire collection
  Future<QuerySnapshot> getCollection(String collection) async {
    return await _db.collection(collection).get();
  }

  /// Stream entire collection
  Stream<QuerySnapshot> streamCollection(String collection) {
    return _db.collection(collection).snapshots();
  }

  /// Update document in any collection
  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  /// Delete document from any collection
  Future<void> deleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  // -----------------------------
  // User Profile (Your original methods - kept intact)
  // -----------------------------
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) {
    _requireUid(uid);
    return _users.doc(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserData(String uid) {
    _requireUid(uid);
    return _users.doc(uid).snapshots();
  }

  Future<void> ensureUserDocument({
    required String uid,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    _requireUid(uid);

    final ref = _users.doc(uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'email': email.trim().toLowerCase(),
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'profileSetupComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.set({
      'email': email.trim().toLowerCase(),
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    _requireUid(uid);
    await _users.doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  // -----------------------------
  // Daily Targets (FIXED to match HomeScreen fields)
  // -----------------------------
  Future<void> setDailyTargets({
    required String uid,
    double? waterLitersTarget,
    int? caloriesTarget,
    int? sleepMinutesTarget,
    int? stepsTarget,
  }) async {
    _requireUid(uid);

    await _dailyTargetsDoc(uid).set({
      if (waterLitersTarget != null) 'waterLitersTarget': waterLitersTarget,
      if (caloriesTarget != null) 'caloriesTarget': caloriesTarget,
      if (sleepMinutesTarget != null) 'sleepMinutesTarget': sleepMinutesTarget,
      if (stepsTarget != null) 'stepsTarget': stepsTarget,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDailyTargets(String uid) {
    _requireUid(uid);
    return _dailyTargetsDoc(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDailyTargets(String uid) {
    _requireUid(uid);
    return _dailyTargetsDoc(uid).snapshots();
  }

  // -----------------------------
  // Activities
  // -----------------------------
  Future<void> addActivity({
    required String uid,
    required String title,
    required String type, // water/snack/workout/meal/schedule/progress_photo
    Map<String, dynamic>? meta,
    DateTime? when,
  }) async {
    _requireUid(uid);

    await _activities(uid).add({
      'title': title,
      'type': type,
      'meta': meta ?? <String, dynamic>{},
      'timestamp':
          when != null ? Timestamp.fromDate(when) : FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLatestActivities(
    String uid, {
    int limit = 10,
  }) {
    _requireUid(uid);

    return _activities(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // -----------------------------
  // Workout Schedules
  // -----------------------------
  Future<String> addWorkoutSchedule({
    required String uid,
    required String workoutTitle,
    required DateTime scheduledAt,
    String difficulty = 'Beginner',
    int durationMinutes = 30,
    bool notificationEnabled = true,
  }) async {
    _requireUid(uid);

    final doc = await _schedules(uid).add({
      'workoutTitle': workoutTitle,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'difficulty': difficulty,
      'durationMinutes': durationMinutes,
      'notificationEnabled': notificationEnabled,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await addActivity(
      uid: uid,
      title: 'Scheduled: $workoutTitle',
      type: 'schedule',
      meta: {'difficulty': difficulty, 'durationMinutes': durationMinutes},
      when: scheduledAt,
    );

    return doc.id;
  }

  Future<void> updateSchedule(
    String uid,
    String scheduleId,
    Map<String, dynamic> data,
  ) async {
    _requireUid(uid);

    await _schedules(uid).doc(scheduleId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteWorkoutSchedule(String uid, String scheduleId) async {
    _requireUid(uid);
    await _schedules(uid).doc(scheduleId).delete();
  }

  Future<void> markScheduleDone({
    required String uid,
    required String scheduleId,
    required bool isDone,
  }) async {
    _requireUid(uid);

    await _schedules(uid).doc(scheduleId).set({
      'isDone': isDone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addActivity(
      uid: uid,
      title: isDone ? 'Workout marked as done' : 'Workout marked as not done',
      type: 'workout',
      meta: {'scheduleId': scheduleId, 'isDone': isDone},
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSchedulesForDay(
    String uid, {
    required DateTime day,
  }) {
    _requireUid(uid);

    final start = day.startOfDay;
    final end = day.endOfDay;

    return _schedules(uid)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSchedulesInRange(
    String uid, {
    required DateTime start,
    required DateTime end,
  }) {
    _requireUid(uid);

    return _schedules(uid)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('scheduledAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSchedulesForMonth(
    String uid, {
    required DateTime month,
  }) {
    _requireUid(uid);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return streamSchedulesInRange(uid, start: start, end: end);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUpcomingSchedules(
    String uid,
    DateTime from, {
    int limit = 20,
  }) {
    _requireUid(uid);

    return _schedules(uid)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('scheduledAt', descending: false)
        .limit(limit)
        .snapshots();
  }
  
  // -----------------------------
  // Meal Schedule
  // -----------------------------
  DocumentReference<Map<String, dynamic>> getMealScheduleDoc(
    String uid,
    String mealId,
  ) {
    _requireUid(uid);
    return _mealSchedules(uid).doc(mealId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamMealScheduleDoc(
    String uid,
    String mealId,
  ) {
    _requireUid(uid);
    return getMealScheduleDoc(uid, mealId).snapshots();
  }

  Future<String> addMealSchedule({
    required String uid,
    required String mealName,
    required String mealType, // Breakfast/Lunch/Snacks/Dinner
    required DateTime scheduledAt,
    int? calories,
    bool notificationEnabled = true,
    bool isDone = false,
  }) async {
    _requireUid(uid);

    final doc = await _mealSchedules(uid).add({
      'mealName': mealName,
      'mealType': mealType,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      if (calories != null) 'calories': calories,
      'notificationEnabled': notificationEnabled,
      'isDone': isDone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await addActivity(
      uid: uid,
      title: 'Meal scheduled: $mealName',
      type: 'meal',
      meta: {'mealType': mealType, 'mealId': doc.id},
      when: scheduledAt,
    );

    return doc.id;
  }

  Future<void> updateMealSchedule(
    String uid,
    String mealId,
    Map<String, dynamic> data,
  ) async {
    _requireUid(uid);

    await _mealSchedules(uid).doc(mealId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteMealSchedule(String uid, String mealId) async {
    _requireUid(uid);
    await _mealSchedules(uid).doc(mealId).delete();
  }

  Future<void> markMealDone({
    required String uid,
    required String mealId,
    required bool isDone,
  }) async {
    _requireUid(uid);

    await _mealSchedules(uid).doc(mealId).set({
      'isDone': isDone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addActivity(
      uid: uid,
      title: isDone ? 'Meal marked as done' : 'Meal marked as not done',
      type: 'meal',
      meta: {'mealId': mealId, 'isDone': isDone},
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMealsForDay(
    String uid, {
    required DateTime day,
    String? mealType,
  }) {
    _requireUid(uid);

    final start = day.startOfDay;
    final end = day.endOfDay;

    Query<Map<String, dynamic>> q = _mealSchedules(uid)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end));

    if (mealType != null && mealType.trim().isNotEmpty) {
      q = q.where('mealType', isEqualTo: mealType.trim());
    }

    q = q.orderBy('scheduledAt', descending: false);

    return q.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUpcomingMeals(
    String uid,
    DateTime from, {
    int limit = 20,
  }) {
    _requireUid(uid);

    return _mealSchedules(uid)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('scheduledAt', descending: false)
        .limit(limit)
        .snapshots();
  }

  // -----------------------------
  // Progress Photos (UPDATED WITH POSE DETECTION)
  // -----------------------------
  
  /// Get all progress photos
  Future<QuerySnapshot<Map<String, dynamic>>> getProgressPhotos(String uid) {
    _requireUid(uid);
    return _progressPhotos(uid).orderBy('timestamp', descending: true).get();
  }

  /// Stream all progress photos
  Stream<QuerySnapshot<Map<String, dynamic>>> streamProgressPhotos(String uid) {
    _requireUid(uid);
    return _progressPhotos(uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Add progress photo with automatic pose detection
  /// The pose should be detected by PoseDetectorService before calling this
  Future<String> addProgressPhoto(
    String uid, 
    String base64Photo, {
    String? view, // Optional: 'front', 'right', 'back', 'left'
  }) async {
    _requireUid(uid);

    final doc = await _progressPhotos(uid).add({
      'photoBase64': base64Photo,
      'timestamp': FieldValue.serverTimestamp(),
      'view': view ?? 'front', // Default to 'front' for backward compatibility
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addActivity(
      uid: uid,
      title: view != null 
          ? 'Added progress photo (${view} view)' 
          : 'Added progress photo',
      type: 'progress_photo',
      meta: {
        'photoId': doc.id,
        if (view != null) 'view': view,
      },
    );

    return doc.id;
  }

  /// Add progress photo with pose/view (enforced)
  /// This is the recommended method when using pose detection
  Future<String> addProgressPhotoWithPose(
    String uid,
    String base64Photo,
    String pose, // Required: 'front', 'right', 'back', 'left'
  ) async {
    _requireUid(uid);

    final validPoses = ['front', 'right', 'back', 'left'];
    if (!validPoses.contains(pose)) {
      throw ArgumentError(
        'Invalid pose: $pose. Must be one of: ${validPoses.join(", ")}'
      );
    }

    return await addProgressPhoto(uid, base64Photo, view: pose);
  }

  /// Deprecated: Use addProgressPhotoWithPose instead
  @Deprecated('Use addProgressPhotoWithPose for better clarity')
  Future<String> addProgressPhotoWithView(
    String uid,
    String base64Photo,
    String view,
  ) async {
    return await addProgressPhotoWithPose(uid, base64Photo, view);
  }

  /// Get photos filtered by pose/view
  Future<QuerySnapshot<Map<String, dynamic>>> getProgressPhotosByView(
    String uid, 
    String view,
  ) {
    _requireUid(uid);
    
    return _progressPhotos(uid)
        .where('view', isEqualTo: view)
        .orderBy('timestamp', descending: true)
        .get();
  }

  /// Stream photos filtered by pose/view
  Stream<QuerySnapshot<Map<String, dynamic>>> streamProgressPhotosByView(
    String uid,
    String view,
  ) {
    _requireUid(uid);

    return _progressPhotos(uid)
        .where('view', isEqualTo: view)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get photos grouped by view (useful for comparison screens)
  Future<Map<String, List<Map<String, dynamic>>>> getProgressPhotosGroupedByView(
    String uid,
  ) async {
    _requireUid(uid);

    final snapshot = await getProgressPhotos(uid);
    
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'front': [],
      'right': [],
      'back': [],
      'left': [],
    };

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final view = data['view'] as String? ?? 'front';
      
      if (grouped.containsKey(view)) {
        grouped[view]!.add({
          'id': doc.id,
          ...data,
        });
      }
    }

    return grouped;
  }

  /// Update the pose/view of an existing photo
  /// Useful if you want to manually correct pose detection
  Future<void> updateProgressPhotoView(
    String uid,
    String photoId,
    String view,
  ) async {
    _requireUid(uid);

    final validViews = ['front', 'right', 'back', 'left'];
    if (!validViews.contains(view)) {
      throw ArgumentError(
        'Invalid view: $view. Must be one of: ${validViews.join(", ")}'
      );
    }

    await _progressPhotos(uid).doc(photoId).update({
      'view': view,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await addActivity(
      uid: uid,
      title: 'Updated photo view to $view',
      type: 'progress_photo',
      meta: {'photoId': photoId, 'newView': view},
    );
  }

  /// Delete progress photo
  Future<void> deleteProgressPhoto(String uid, String photoId) async {
    _requireUid(uid);

    await _progressPhotos(uid).doc(photoId).delete();

    await addActivity(
      uid: uid,
      title: 'Deleted progress photo',
      type: 'progress_photo',
      meta: {'photoId': photoId},
    );
  }

  // -----------------------------
  // Daily Summary + Logs
  // -----------------------------
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDailyDoc(
    String uid,
    DateTime day,
  ) {
    _requireUid(uid);
    return dailyDoc(uid, day).snapshots();
  }

  Future<void> ensureTodayDailyDoc(String uid) async {
    _requireUid(uid);

    final today = DateTime.now();
    final ref = dailyDoc(uid, today);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'dateKey': today.ymd,
      'waterMl': 0,
      'sleepMinutes': 0,
      'caloriesConsumed': 0,
      'workoutMinutes': 0,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addWater({
    required String uid,
    required int ml,
    DateTime? when,
  }) async {
    _requireUid(uid);

    final t = when ?? DateTime.now();

    await _waterLogs(uid).add({
      'ml': ml,
      'timestamp': Timestamp.fromDate(t),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await dailyDoc(uid, t).set({
      'waterMl': FieldValue.increment(ml),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addActivity(
      uid: uid,
      title: 'Drink water',
      type: 'water',
      meta: {'ml': ml},
      when: t,
    );
  }

  Future<void> addMeal({
    required String uid,
    required String mealName,
    required int calories,
    DateTime? when,
  }) async {
    _requireUid(uid);

    final t = when ?? DateTime.now();

    await _mealLogs(uid).add({
      'mealName': mealName,
      'calories': calories,
      'timestamp': Timestamp.fromDate(t),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await dailyDoc(uid, t).set({
      'caloriesConsumed': FieldValue.increment(calories),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addActivity(
      uid: uid,
      title: 'Meal: $mealName',
      type: 'meal',
      meta: {'calories': calories},
      when: t,
    );
  }

  Future<void> addSleep({
    required String uid,
    required int minutes,
    DateTime? when,
  }) async {
    _requireUid(uid);

    final t = when ?? DateTime.now();

    await _sleepLogs(uid).add({
      'minutes': minutes,
      'timestamp': Timestamp.fromDate(t),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await dailyDoc(uid, t).set({
      'sleepMinutes': FieldValue.increment(minutes),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addActivity(
      uid: uid,
      title: 'Sleep logged',
      type: 'sleep',
      meta: {'minutes': minutes},
      when: t,
    );
  }

  Future<void> addWorkoutDone({
    required String uid,
    required String category,
    required int minutes,
    required int caloriesBurn,
    DateTime? when,
  }) async {
    _requireUid(uid);

    final t = when ?? DateTime.now();

    await _workoutLogs(uid).add({
      'category': category,
      'minutes': minutes,
      'caloriesBurn': caloriesBurn,
      'timestamp': Timestamp.fromDate(t),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await dailyDoc(uid, t).set({
      'workoutMinutes': FieldValue.increment(minutes),
      'lastWorkoutAt': Timestamp.fromDate(t),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addActivity(
      uid: uid,
      title: 'Workout done',
      type: 'workout',
      meta: {
        'category': category,
        'minutes': minutes,
        'caloriesBurn': caloriesBurn,
      },
      when: t,
    );
  }

    // Body metrics subcollection
  CollectionReference<Map<String, dynamic>> _bodyMetrics(String uid) =>
      _users.doc(uid).collection('body_metrics');

  /// Save body metrics analysis
  Future<String> saveBodyMetrics({
    required String uid,
    required String photoId,
    required Map<String, dynamic> metricsData,
    String? view,
  }) async {
    _requireUid(uid);

    final doc = await _bodyMetrics(uid).add({
      'photoId': photoId,
      if (view != null) 'view': view,
      ...metricsData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addActivity(
      uid: uid,
      title: 'Body metrics recorded',
      type: 'body_metrics',
      meta: {'photoId': photoId, if (view != null) 'view': view},
    );

    return doc.id;
  }

  /// Get body metrics for a specific photo
  Future<QuerySnapshot<Map<String, dynamic>>> getBodyMetricsForPhoto(
    String uid,
    String photoId,
  ) {
    _requireUid(uid);
    
    return _bodyMetrics(uid)
        .where('photoId', isEqualTo: photoId)
        .get();
  }

  /// Get all body metrics
  Future<QuerySnapshot<Map<String, dynamic>>> getAllBodyMetrics(String uid) {
    _requireUid(uid);
    
    return _bodyMetrics(uid)
        .orderBy('createdAt', descending: true)
        .get();
  }

  /// Stream body metrics
  Stream<QuerySnapshot<Map<String, dynamic>>> streamBodyMetrics(String uid) {
    _requireUid(uid);
    
    return _bodyMetrics(uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get body metrics grouped by view
  Future<Map<String, List<Map<String, dynamic>>>> getBodyMetricsGroupedByView(
    String uid,
  ) async {
    _requireUid(uid);

    final snapshot = await getAllBodyMetrics(uid);
    
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'front': [],
      'right': [],
      'back': [],
      'left': [],
    };

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final view = data['view'] as String? ?? 'front';
      
      if (grouped.containsKey(view)) {
        grouped[view]!.add({
          'id': doc.id,
          ...data,
        });
      }
    }

    return grouped;
  }

  /// Compare body metrics between two dates
  Future<Map<String, dynamic>> compareBodyMetrics({
    required String uid,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _requireUid(uid);

    final snapshot = await _bodyMetrics(uid)
        .where('createdAt', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'start': null,
        'end': null,
        'change': {},
      };
    }

    final first = snapshot.docs.first.data();
    final last = snapshot.docs.last.data();

    return {
      'start': first,
      'end': last,
      'change': _calculateMetricsChange(first, last),
      'count': snapshot.docs.length,
    };
  }

  Map<String, dynamic> _calculateMetricsChange(
    Map<String, dynamic> start,
    Map<String, dynamic> end,
  ) {
    final change = <String, dynamic>{};
    
    // Calculate differences for numeric metrics
    for (final key in start.keys) {
      if (start[key] is num && end[key] is num) {
        final startVal = (start[key] as num).toDouble();
        final endVal = (end[key] as num).toDouble();
        change['${key}_diff'] = endVal - startVal;
        change['${key}_percent'] = startVal != 0 
            ? ((endVal - startVal) / startVal * 100) 
            : 0;
      }
    }

    return change;
  }
} 