# Notification Testing Guide

## 🧪 How to Test Notifications

There are **three ways** to test notifications. Choose the method that fits your needs:

---

## Method 1: Test via Backend API (Recommended - Real Scenario)

This is the **best way** to test because it simulates the real flow when an employee updates a complaint status.

### Steps:

1. **Get your FCM Token from Flutter App:**
   - Open the Flutter app
   - Go to ComplaintsPage
   - Tap menu (⋮) → "Debug Notifications"
   - Copy the FCM Token shown in the dialog

2. **Send FCM Token to Backend:**
   - Make sure you're logged in to the Flutter app
   - The app automatically sends FCM token to backend after login
   - Verify in your backend database that the token is saved in `users.fcm_token`

3. **Update Complaint Status via API (Postman):**

   ```http
   PUT http://192.168.1.104:8000/api/employee/complaints/109
   Authorization: Bearer {employee_token}
   Content-Type: application/json

   {
     "status": "IN_PROGRESS"
   }
   ```

4. **Expected Result:**
   - Backend processes the status update
   - Backend sends FCM notification automatically
   - Flutter app receives notification
   - Notification appears on device

### ✅ Advantages:
- Tests the complete real-world flow
- Verifies backend notification logic works
- Tests end-to-end integration

---

## Method 2: Test via Postman (Direct FCM API)

This method sends notifications **directly** to Firebase, bypassing your backend. Useful for testing Flutter app notification handling.

### Prerequisites:

1. **Get Firebase Server Key:**
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Copy the **Server Key** (Legacy) or set up OAuth2 for v1 API

2. **Get FCM Token from Flutter App:**
   - Open Flutter app → ComplaintsPage → Menu → "Debug Notifications"
   - Copy the FCM Token

### Postman Request:

**For Legacy HTTP API (Easier):**

```http
POST https://fcm.googleapis.com/fcm/send
Authorization: key=YOUR_FIREBASE_SERVER_KEY
Content-Type: application/json

{
  "to": "YOUR_FCM_TOKEN_FROM_FLUTTER_APP",
  "notification": {
    "title": "تم تحديث حالة الشكوى",
    "body": "شكواك رقم CMP80471825 - الحالة: قيد المعالجة",
    "sound": "default"
  },
  "data": {
    "type": "complaint_status_update",
    "complaint_id": "109",
    "complaint_identifier": "CMP80471825",
    "old_status": "NEW",
    "new_status": "IN_PROGRESS",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "priority": "high",
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "high_importance_channel"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

**Expected Response:**
```json
{
  "multicast_id": 123456789,
  "success": 1,
  "failure": 0,
  "canonical_ids": 0,
  "results": [
    {
      "message_id": "0:1234567890"
    }
  ]
}
```

### ✅ Advantages:
- Quick testing without backend
- Tests Flutter app notification handling
- Good for debugging notification display

### ❌ Disadvantages:
- Doesn't test backend integration
- Requires Firebase Server Key

---

## Method 3: Test via Flutter Debug Feature (Easiest)

The Flutter app has a built-in test notification feature.

### Steps:

1. **Open Flutter App**
2. **Navigate to ComplaintsPage**
3. **Tap Menu (⋮) in top right**
4. **Select "Debug Notifications"**
5. **Tap "Test Notification" button**

### ✅ Advantages:
- No setup required
- Tests local notification display
- Verifies notification permissions
- Shows FCM token and permission status

### ❌ Disadvantages:
- Only tests local notifications (not FCM)
- Doesn't test backend integration
- Doesn't test navigation from notification

---

## 📊 Comparison Table

| Method | Tests Backend | Tests FCM | Tests Navigation | Difficulty |
|--------|--------------|-----------|------------------|------------|
| **Backend API** | ✅ | ✅ | ✅ | Medium |
| **Postman (FCM)** | ❌ | ✅ | ✅ | Easy |
| **Flutter Debug** | ❌ | ❌ | ❌ | Very Easy |

---

## 🎯 Recommended Testing Flow

### Step 1: Test Flutter App Setup
1. Use **Method 3** (Flutter Debug) to verify:
   - Notification permissions are granted
   - FCM token is generated
   - Local notifications work

### Step 2: Test FCM Integration
1. Use **Method 2** (Postman FCM) to verify:
   - Flutter app receives FCM notifications
   - Notifications display correctly
   - Navigation works when tapping notification

### Step 3: Test Complete Flow
1. Use **Method 1** (Backend API) to verify:
   - Employee updates complaint status
   - Backend sends notification automatically
   - Citizen receives notification
   - Complete end-to-end flow works

---

## 🔍 Testing Different App States

### Test Foreground (App Open):

1. **Open Flutter app** (keep it open)
2. **Send notification** via Postman or Backend API
3. **Expected:** Local notification appears in app
4. **Tap notification:** Should navigate to ComplaintsPage

### Test Background (App Minimized):

1. **Open Flutter app**
2. **Press Home button** (minimize app)
3. **Send notification** via Postman or Backend API
4. **Expected:** System notification appears in notification tray
5. **Tap notification:** App opens and navigates to ComplaintsPage

### Test Terminated (App Closed):

1. **Close Flutter app completely** (swipe away from recent apps)
2. **Send notification** via Postman or Backend API
3. **Expected:** System notification appears in notification tray
4. **Tap notification:** App launches and navigates to ComplaintsPage

---

## 🐛 Troubleshooting

### Notification Not Received?

1. **Check FCM Token:**
   - Verify token is correct (use Debug menu)
   - Check token is sent to backend
   - Verify token in database matches device

2. **Check Firebase Server Key:**
   - Verify key is correct in Postman
   - Check key has proper permissions

3. **Check Notification Permissions:**
   - Android: Settings → Apps → Your App → Notifications
   - iOS: Settings → Notifications → Your App

4. **Check Console Logs:**
   - Look for: `📨 Foreground notification received`
   - Look for: `🔔 Background notification received`
   - Look for errors

### Notification Received But Not Displaying?

1. **Check notification channel** (Android):
   - Verify `high_importance_channel` exists
   - Check channel is not disabled

2. **Check app state:**
   - Foreground: Should show local notification
   - Background: Should show system notification
   - Terminated: Should show system notification

### Navigation Not Working?

1. **Check navigatorKey:**
   - Verify `navigatorKey` is set in `main.dart`
   - Check it's passed to `MaterialApp`

2. **Check user token:**
   - Verify user is logged in
   - Check `userToken` exists in secure storage

3. **Check console logs:**
   - Look for: `🧭 Navigating to complaints page`
   - Look for errors

---

## 📝 Postman Collection Example

Create a Postman collection with these requests:

### Request 1: Update Complaint Status (Backend API)
```
PUT {{baseURL}}/api/employee/complaints/109
Authorization: Bearer {{employee_token}}
Body: { "status": "IN_PROGRESS" }
```

### Request 2: Send FCM Notification (Direct)
```
POST https://fcm.googleapis.com/fcm/send
Authorization: key={{firebase_server_key}}
Body: {
  "to": "{{fcm_token}}",
  "notification": { ... },
  "data": { ... }
}
```

### Environment Variables:
- `baseURL`: `http://192.168.1.5:8000/api`
- `employee_token`: Your employee auth token
- `firebase_server_key`: Your Firebase server key
- `fcm_token`: FCM token from Flutter app

---

## ✅ Testing Checklist

### Flutter App Setup:
- [ ] FCM token generated
- [ ] Notification permissions granted
- [ ] Local notifications work (test button)
- [ ] FCM token sent to backend

### FCM Integration:
- [ ] Postman FCM request succeeds
- [ ] Notification received in foreground
- [ ] Notification received in background
- [ ] Notification received when terminated
- [ ] Navigation works on tap

### Backend Integration:
- [ ] Complaint status update API works
- [ ] Backend sends notification automatically
- [ ] Notification received after status update
- [ ] Complete flow works end-to-end

---

## 🚀 Quick Start Testing

**Fastest way to test right now:**

1. **Get FCM Token:**
   - Open app → ComplaintsPage → Menu → Debug → Copy token

2. **Test with Postman:**
   - Use Method 2 (Postman FCM) with the token
   - Send notification
   - Check if it appears on device

3. **If that works, test with Backend:**
   - Use Method 1 (Backend API)
   - Update complaint status
   - Verify notification is sent automatically

---

## 💡 Pro Tips

1. **Use Postman for quick testing** - No need to update complaint status every time
2. **Use Backend API for real testing** - Verifies complete integration
3. **Test all three app states** - Foreground, background, terminated
4. **Check console logs** - Very helpful for debugging
5. **Use Flutter debug button** - Quick way to verify setup

---

## 📚 Related Files

- `lib/service/notification_service.dart` - Notification handling
- `lib/view/allComplains.dart` - ComplaintsPage with debug menu
- `FLUTTER_NOTIFICATION_HANDLING.md` - Flutter notification guide
