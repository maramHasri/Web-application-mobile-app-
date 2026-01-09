# Complete Notification Flow Summary

## 🎯 Overview

This document summarizes the complete notification flow from employee status update to citizen notification.

---

## 🔄 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. EMPLOYEE ACTION (Web Platform)                                │
│    Employee updates complaint status via API                    │
│    PUT /api/employee/complaints/109                             │
│    Body: { "status": "IN_PROGRESS" }                            │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. BACKEND CONTROLLER (Laravel)                                 │
│    ComplaintController::update()                                │
│    - Validates request                                           │
│    - Updates complaint status                                    │
│    - Dispatches ComplaintStatusUpdated event                     │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. EVENT SYSTEM (Laravel)                                        │
│    ComplaintStatusUpdated Event                                  │
│    └─> SendComplaintNotificationListener                        │
│        └─> Queues SendComplaintNotificationJob                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. QUEUE WORKER (Laravel)                                       │
│    SendComplaintNotificationJob                                 │
│    - Retrieves complaint with user relationship                 │
│    - Checks if user has FCM token                                │
│    - Calls FcmNotificationService                               │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. FCM SERVICE (Laravel)                                        │
│    FcmNotificationService::sendComplaintStatusUpdate()           │
│    - Builds FCM payload                                          │
│    - Sends to Firebase Cloud Messaging API                      │
│    - Returns success/failure                                    │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. FIREBASE CLOUD MESSAGING                                     │
│    Receives notification request                                 │
│    - Validates FCM token                                         │
│    - Routes to correct device                                    │
│    - Delivers notification                                       │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. FLUTTER APP - THREE STATES                                    │
│                                                                  │
│  A. FOREGROUND (App is open)                                    │
│     └─> FirebaseMessaging.onMessage                             │
│         └─> NotificationService.handleForegroundMessage()       │
│             └─> Shows local notification                        │
│                                                                  │
│  B. BACKGROUND (App minimized)                                   │
│     └─> System shows notification automatically                 │
│     └─> User taps notification                                  │
│         └─> FirebaseMessaging.onMessageOpenedApp                │
│             └─> Navigates to ComplaintsPage                    │
│                                                                  │
│  C. TERMINATED (App closed)                                     │
│     └─> System shows notification automatically                 │
│     └─> User taps notification                                  │
│         └─> FirebaseMessaging.instance.getInitialMessage()     │
│             └─> Navigates to ComplaintsPage                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 Flutter App Notification Handling

### Current Implementation Status:

✅ **Foreground**: Handled via `FirebaseMessaging.onMessage` → `handleForegroundMessage()`  
✅ **Background**: Handled via `FirebaseMessaging.onMessageOpenedApp`  
✅ **Terminated**: Handled via `FirebaseMessaging.instance.getInitialMessage()`  
✅ **Navigation**: Automatically navigates to `ComplaintsPage` on tap  
✅ **Local Notifications**: Uses `flutter_local_notifications` for foreground display  

### Notification Data Structure:

The Flutter app expects the following data in the notification payload:

```dart
{
  'type': 'complaint_status_update',
  'complaint_id': '109',
  'complaint_identifier': 'CMP80471825',
  'old_status': 'NEW',
  'new_status': 'IN_PROGRESS',
  'click_action': 'FLUTTER_NOTIFICATION_CLICK'
}
```

---

## 🔧 Backend Implementation Checklist

### Step 1: Database Setup
- [ ] Ensure `users` table has `fcm_token` column
- [ ] Ensure `complaints` table has proper structure
- [ ] Set up foreign key relationship: `complaints.user_id → users.id`

### Step 2: Laravel Setup
- [ ] Create `ComplaintStatusUpdated` event
- [ ] Create `SendComplaintNotificationListener`
- [ ] Create `SendComplaintNotificationJob`
- [ ] Create `FcmNotificationService`
- [ ] Update `ComplaintController::update()` to dispatch event
- [ ] Register event listener in `EventServiceProvider`

### Step 3: Configuration
- [ ] Add `FCM_SERVER_KEY` to `.env`
- [ ] Add `FCM_PROJECT_ID` to `.env`
- [ ] Set `QUEUE_CONNECTION=database` (or `redis`)
- [ ] Run `php artisan queue:table` and migrate

### Step 4: Queue Worker
- [ ] Start queue worker: `php artisan queue:work`
- [ ] (Production) Set up supervisor for queue workers

### Step 5: Testing
- [ ] Test status update via API
- [ ] Verify event is dispatched
- [ ] Verify job is queued
- [ ] Verify notification is sent
- [ ] Test on Flutter app (foreground, background, terminated)

---

## 📊 Sample API Request/Response

### Employee Updates Complaint Status:

**Request:**
```http
PUT /api/employee/complaints/109
Authorization: Bearer {employee_token}
Content-Type: application/json

{
  "status": "IN_PROGRESS"
}
```

**Response:**
```json
{
  "success": true,
  "message": "messages.generic.success",
  "data": {
    "id": 109,
    "identifier": "CMP80471825",
    "description": "الفواتييير",
    "status": "IN_PROGRESS",
    "lat": 33.4977381,
    "lng": 36.2358394,
    "address": "خي",
    "locked_at": "07/01/2026",
    "created_at": "1 day ago"
  },
  "status_code": 200,
  "timestamp": "2026-01-08T12:08:13+00:00"
}
```

**What Happens Behind the Scenes:**
1. Complaint status updated in database
2. `ComplaintStatusUpdated` event dispatched
3. `SendComplaintNotificationJob` queued
4. Queue worker processes job
5. FCM notification sent to citizen's device
6. Citizen receives notification

---

## 🎨 Notification Display Examples

### Foreground (App Open):
- Shows as local notification overlay
- User can tap to navigate to complaints page
- Notification appears in notification tray

### Background (App Minimized):
- System notification appears in notification tray
- User taps notification → App opens → Navigates to complaints page

### Terminated (App Closed):
- System notification appears in notification tray
- User taps notification → App launches → Navigates to complaints page

---

## 🐛 Troubleshooting

### Notification Not Received?

1. **Check FCM Token:**
   - Verify user has valid FCM token in database
   - Check token was sent from Flutter app after login

2. **Check Queue:**
   ```bash
   php artisan queue:failed
   php artisan queue:work --verbose
   ```

3. **Check Logs:**
   ```bash
   tail -f storage/logs/laravel.log | grep "FCM\|Notification"
   ```

4. **Check Firebase Console:**
   - Verify FCM server key is correct
   - Check Firebase project settings

5. **Check Flutter App:**
   - Verify notification permissions granted
   - Check console logs for notification handlers
   - Test with debug notification button

---

## 📚 Related Files

### Backend:
- `BACKEND_NOTIFICATION_ARCHITECTURE.md` - Complete backend implementation guide
- Laravel event-driven architecture
- Queue system setup

### Flutter:
- `lib/service/notification_service.dart` - Notification handling
- `lib/main.dart` - Firebase initialization
- `lib/service/fcm_token_service.dart` - FCM token management

---

## ✅ Success Criteria

The system is working correctly when:

1. ✅ Employee updates complaint status via API
2. ✅ Notification job is queued within 1 second
3. ✅ Queue worker processes job successfully
4. ✅ FCM notification is sent to Firebase
5. ✅ Citizen receives notification on device
6. ✅ Tapping notification navigates to complaints page
7. ✅ Updated complaint status is visible in app

---

## 🚀 Next Steps

1. Implement backend code from `BACKEND_NOTIFICATION_ARCHITECTURE.md`
2. Test end-to-end flow
3. Set up production queue workers
4. Monitor notification delivery rates
5. Add analytics for notification engagement
