# Flutter Notification Handling Guide

## 📱 Overview

This guide explains how the Flutter app handles push notifications when employees update complaint statuses. The backend already sends notifications - this document focuses on the Flutter side.

---

## ✅ Current Implementation Status

### All Three States Handled:

1. **✅ Foreground** (App is open)
   - Shows local notification overlay
   - User can tap to navigate

2. **✅ Background** (App minimized)
   - System shows notification automatically
   - User taps → App opens → Navigates to complaints

3. **✅ Terminated** (App closed)
   - System shows notification automatically
   - User taps → App launches → Navigates to complaints

---

## 🔄 Notification Flow in Flutter

```
Backend Sends FCM Notification
    ↓
Firebase Cloud Messaging
    ↓
┌─────────────────────────────────────────┐
│ Flutter App Receives Notification       │
└─────────────────────────────────────────┘
    ↓
    ├─> App Foreground?
    │   └─> FirebaseMessaging.onMessage
    │       └─> NotificationService.handleForegroundMessage()
    │           └─> Shows local notification
    │
    ├─> App Background?
    │   └─> System shows notification
    │       └─> User taps
    │           └─> FirebaseMessaging.onMessageOpenedApp
    │               └─> Navigates to ComplaintsPage
    │
    └─> App Terminated?
        └─> System shows notification
            └─> User taps
                └─> FirebaseMessaging.instance.getInitialMessage()
                    └─> Navigates to ComplaintsPage
```

---

## 📦 Expected Notification Payload

Your backend should send notifications with this structure:

```json
{
  "notification": {
    "title": "تم تحديث حالة الشكوى",
    "body": "شكواك رقم CMP80471825 - الحالة: قيد المعالجة"
  },
  "data": {
    "type": "complaint_status_update",
    "complaint_id": "109",
    "complaint_identifier": "CMP80471825",
    "old_status": "NEW",
    "new_status": "IN_PROGRESS",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

### Key Data Fields:

- `complaint_id` - Used for navigation and notification ID
- `type` - Notification type (optional, for filtering)
- `old_status` / `new_status` - Status change info (optional)

---

## 🔧 How It Works

### 1. **Foreground Handling** (`lib/service/notification_service.dart`)

When app is open and notification arrives:

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  await handleForegroundMessage(message);
});
```

**What happens:**
- Extracts `complaint_id` from `message.data['complaint_id']`
- Shows local notification using `flutter_local_notifications`
- User can tap notification to navigate

### 2. **Background Handling**

When app is minimized and notification arrives:

```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Extract complaint_id
  final String? complaintId = message.data['complaint_id']?.toString();
  
  // Navigate to complaints page
  handleNotificationNavigation(complaintId ?? '');
});
```

**What happens:**
- System automatically shows notification
- User taps notification
- App opens and navigates to `ComplaintsPage`
- Complaints list automatically refreshes

### 3. **Terminated State Handling**

When app is closed and notification arrives:

```dart
final RemoteMessage? initialMessage = 
    await FirebaseMessaging.instance.getInitialMessage();
    
if (initialMessage != null) {
  final String? complaintId = 
      initialMessage.data['complaint_id']?.toString();
  
  // Navigate to complaints page
  handleNotificationNavigation(complaintId ?? '');
}
```

**What happens:**
- System automatically shows notification
- User taps notification
- App launches and navigates to `ComplaintsPage`
- Complaints list automatically refreshes

---

## 📂 Key Files

### 1. `lib/service/notification_service.dart`
- Handles all notification logic
- Manages foreground/background/terminated states
- Handles navigation

### 2. `lib/main.dart`
- Initializes Firebase
- Sets up background message handler
- Registers notification handlers

### 3. `lib/view/allComplains.dart`
- `ComplaintsPage` - Displays complaints list
- Automatically refreshes when opened from notification

---

## 🎯 Navigation Behavior

When a notification is tapped:

1. **Extracts complaint ID** from notification payload
2. **Navigates to ComplaintsPage** using `pushAndRemoveUntil`
3. **Clears navigation stack** (user can't go back)
4. **Automatically refreshes** complaints list in `initState`

---

## 🔍 Debugging

### Check Notification Reception:

1. **Enable debug logging:**
   - Look for logs starting with: `📨`, `📱`, `🔔`, `🧭`

2. **Test notification button:**
   - Go to ComplaintsPage
   - Tap menu (⋮) → "Debug Notifications"
   - Tap "Test Notification"

3. **Check console logs:**
   ```
   📨 Foreground notification received
   Title: تم تحديث حالة الشكوى
   Body: شكواك رقم CMP80471825 - الحالة: قيد المعالجة
   Data: {complaint_id: 109, type: complaint_status_update, ...}
   ```

### Common Issues:

**Issue: Notification not showing**
- ✅ Check notification permissions are granted
- ✅ Verify FCM token is sent to backend
- ✅ Check backend is sending notifications correctly

**Issue: Navigation not working**
- ✅ Check `navigatorKey` is set in `main.dart`
- ✅ Verify user is logged in (has `userToken`)
- ✅ Check console logs for navigation errors

**Issue: Complaints not refreshing**
- ✅ `ComplaintsPage` automatically loads in `initState`
- ✅ Check API is returning updated data
- ✅ Verify network connection

---

## ✅ Testing Checklist

### Test Foreground:
- [ ] Open app
- [ ] Backend sends notification
- [ ] Local notification appears
- [ ] Tap notification → Navigates to ComplaintsPage
- [ ] Complaints list shows updated status

### Test Background:
- [ ] Minimize app (press home button)
- [ ] Backend sends notification
- [ ] System notification appears
- [ ] Tap notification → App opens → Navigates to ComplaintsPage
- [ ] Complaints list shows updated status

### Test Terminated:
- [ ] Close app completely
- [ ] Backend sends notification
- [ ] System notification appears
- [ ] Tap notification → App launches → Navigates to ComplaintsPage
- [ ] Complaints list shows updated status

---

## 🚀 What Happens When Employee Updates Status

1. **Employee** updates complaint status via API:
   ```
   PUT /api/employee/complaints/109
   { "status": "IN_PROGRESS" }
   ```

2. **Backend** sends FCM notification to citizen's device

3. **Flutter App** receives notification:
   - **If foreground**: Shows local notification
   - **If background**: System shows notification
   - **If terminated**: System shows notification

4. **User taps notification**:
   - App navigates to `ComplaintsPage`
   - Complaints list refreshes automatically
   - Updated status is visible

---

## 📝 Code Structure

### Notification Service Methods:

- `initialize()` - Sets up notification channels and permissions
- `requestPermissions()` - Requests notification permissions
- `handleForegroundMessage()` - Handles foreground notifications
- `handleBackgroundMessage()` - Handles background notifications (logging)
- `handleNotificationNavigation()` - Navigates to complaints page
- `setupMessageHandlers()` - Registers all FCM listeners

### ComplaintsPage:

- `_loadComplaints()` - Loads complaints from API
- Automatically called in `initState` when page opens
- Ensures fresh data when opened from notification

---

## 🎨 User Experience

### Notification Display:

- **Title**: "تم تحديث حالة الشكوى" (Complaint Status Updated)
- **Body**: "شكواك رقم CMP80471825 - الحالة: قيد المعالجة" (Your complaint #CMP80471825 - Status: In Progress)

### Navigation:

- Tapping notification always navigates to ComplaintsPage
- Navigation stack is cleared (can't go back)
- Complaints list automatically refreshes
- Updated complaint status is immediately visible

---

## 🔐 Security Notes

- FCM tokens are stored securely in backend
- Only authenticated users receive notifications
- Notification payload doesn't contain sensitive data
- Navigation requires valid `userToken`

---

## ✅ Summary

The Flutter app is **fully configured** to handle notifications:

1. ✅ Receives notifications in all three states
2. ✅ Shows notifications appropriately
3. ✅ Navigates correctly on tap
4. ✅ Refreshes complaints list automatically
5. ✅ Handles errors gracefully

**No additional Flutter code needed** - just ensure your backend sends notifications with the correct payload structure!
