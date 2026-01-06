# Flutter FCM Push Notification System - Complete Setup Guide

## 📋 Overview

This Flutter application implements a complete Firebase Cloud Messaging (FCM) push notification system that receives notifications from a Laravel backend whenever order/complaint status is updated.

## 🔄 Notification Flow

```
Laravel Web Dashboard 
    ↓ (Status Update)
Laravel Backend API 
    ↓ (Sends FCM Notification)
Firebase Cloud Messaging (FCM) 
    ↓ (Delivers to Device)
Flutter Mobile App 
    ↓ (Displays Notification)
User Sees Notification
```

## 📁 File Structure

```
lib/
├── service/
│   ├── fcm_token_service.dart      # Handles FCM token retrieval, refresh, and backend sync
│   ├── notification_service.dart    # Handles all notification display and navigation
│   └── login.dart                   # Updated to use FCM token service
├── main.dart                        # Initializes Firebase and notification services
└── view/
    └── login.dart                   # Sends FCM token to backend after login
```

## 🚀 Key Features

### 1. **FCM Token Management** (`fcm_token_service.dart`)
- ✅ Retrieves FCM token on app start
- ✅ Sends token to Laravel backend after login
- ✅ Handles token refresh automatically
- ✅ Updates backend when token changes
- ✅ Prevents duplicate token submissions

### 2. **Notification Handling** (`notification_service.dart`)
- ✅ **Foreground**: Shows local notification using `flutter_local_notifications`
- ✅ **Background**: Handles notifications when app is in background
- ✅ **Terminated**: Handles notifications when app is closed
- ✅ **Navigation**: Navigates to complaints page when notification is tapped
- ✅ **Permissions**: Requests notification permissions for Android 13+ and iOS

### 3. **App States Coverage**
- ✅ **App Foreground**: Local notification displayed
- ✅ **App Background**: System notification displayed
- ✅ **App Terminated**: System notification displayed, app opens on tap

## 📱 Notification Format

### Expected Notification Structure

```json
{
  "notification": {
    "title": "Order Status Updated",
    "body": "Your order status has changed from 'pending' to 'in_progress'"
  },
  "data": {
    "complaint_id": "123",
    "order_id": "456",
    "old_status": "pending",
    "new_status": "in_progress"
  }
}
```

## 🔧 Setup Instructions

### 1. **Install Dependencies**

Run:
```bash
flutter pub get
```

### 2. **Android Configuration**

#### Update `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for FCM
    }
}
```

#### Update `AndroidManifest.xml`:
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- Add this inside <application> tag -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
    </application>
</manifest>
```

### 3. **iOS Configuration** (if needed)

Add to `ios/Runner/Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### 4. **Backend API Endpoint**

The app expects the following Laravel endpoint:

**POST** `/api/user/fcm-token`
- **Headers**: `Authorization: Bearer {user_token}`
- **Body**: 
```json
{
  "device_token": "fcm_token_here"
}
```

## 📝 Usage

### After User Login

1. User logs in successfully
2. FCM token is automatically retrieved
3. Token is sent to Laravel backend via `/api/user/fcm-token`
4. Token refresh listener is set up
5. User receives notifications when order/complaint status changes

### Notification Handling

#### Foreground (App Open)
- Shows local notification using `flutter_local_notifications`
- User can tap to navigate to complaints page

#### Background (App Minimized)
- Shows system notification
- User taps notification → App opens → Navigates to complaints page

#### Terminated (App Closed)
- Shows system notification
- User taps notification → App launches → Navigates to complaints page

## 🐛 Debugging

### Check FCM Token
Look for this in console logs:
```
✅ FCM Token Retrieved: [token_here]
```

### Check Token Submission
Look for:
```
✅ FCM token sent to backend successfully
```

### Check Notification Reception
Look for:
```
📨 Foreground notification received
📱 App opened from background notification
📱 App opened from terminated notification
```

## 🔐 Security Notes

1. ✅ FCM server keys are **NOT** stored in the mobile app
2. ✅ All backend API calls use Bearer token authentication
3. ✅ FCM tokens are stored securely using `FlutterSecureStorage`
4. ✅ Token refresh is handled automatically

## 📊 Notification States

| App State | Notification Display | User Action | Result |
|-----------|---------------------|-------------|--------|
| Foreground | Local notification | Tap notification | Navigate to complaints |
| Background | System notification | Tap notification | Open app → Navigate |
| Terminated | System notification | Tap notification | Launch app → Navigate |

## 🎯 Laravel Backend Requirements

Your Laravel backend should:

1. **Store FCM Tokens**: Save tokens when received from `/api/user/fcm-token`
2. **Send Notifications**: When order/complaint status changes, send FCM notification with:
   - Title: "Order Status Updated"
   - Body: "Your order status has changed from '{old_status}' to '{new_status}'"
   - Data: `{"complaint_id": "123"}` or `{"order_id": "456"}`

### Example Laravel Code (for reference):

```php
use Illuminate\Support\Facades\Http;

// When status changes
$fcmToken = $user->fcm_token; // Retrieved from database

Http::withHeaders([
    'Authorization' => 'key=' . config('services.fcm.server_key'),
])->post('https://fcm.googleapis.com/fcm/send', [
    'to' => $fcmToken,
    'notification' => [
        'title' => 'Order Status Updated',
        'body' => "Your order status has changed from '{$oldStatus}' to '{$newStatus}'",
    ],
    'data' => [
        'complaint_id' => $complaintId,
        'old_status' => $oldStatus,
        'new_status' => $newStatus,
    ],
]);
```

## ✅ Testing Checklist

- [ ] App receives FCM token on startup
- [ ] Token is sent to backend after login
- [ ] Foreground notifications display correctly
- [ ] Background notifications display correctly
- [ ] Terminated app notifications work
- [ ] Tapping notification navigates to complaints page
- [ ] Token refresh updates backend automatically
- [ ] Permissions are requested on Android 13+ and iOS

## 🆘 Troubleshooting

### Notifications not showing?
1. Check FCM token is retrieved: Look for `✅ FCM Token Retrieved`
2. Check token is sent to backend: Look for `✅ FCM token sent to backend`
3. Verify Firebase configuration files are correct
4. Check notification permissions are granted

### Navigation not working?
1. Ensure user is logged in (token exists)
2. Check console logs for navigation errors
3. Verify `navigatorKey` is properly set in `main.dart`

### Token not refreshing?
1. Check `setupTokenRefreshListener` is called after login
2. Verify backend endpoint `/api/user/fcm-token` is working
3. Check network connectivity

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Flutter Package](https://pub.dev/packages/firebase_messaging)

