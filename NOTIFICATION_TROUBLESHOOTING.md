# 🔍 Notification Troubleshooting Guide

## Why Notifications Aren't Appearing

If notifications aren't showing when you change the status, follow these steps:

## ✅ Step 1: Check Console Logs

When you run the app, look for these logs in your console:

### On App Start:
```
✅ NotificationService initialized
✅ FCM Token Retrieved: [your_token_here]
📱 Android Notification Permission: true
```

### After Login:
```
✅ FCM token sent to backend successfully
```

### When Status Changes (if notification is received):
```
📨 Foreground notification received
Title: Order Status Updated
Body: Your order status has changed...
📬 Local notification shown: ...
```

## ✅ Step 2: Use Debug Menu

1. Open the app and go to the **Complaints Page**
2. Tap the **three dots menu** (⋮) in the top right
3. Select **"Debug Notifications"**
4. This will show:
   - Your FCM token
   - Permission status
   - Full debug info in console
5. Tap **"Test Notification"** to verify notifications work locally

## ✅ Step 3: Verify FCM Token is Sent to Backend

### Check Console Logs:
Look for:
```
✅ FCM token sent to backend successfully
```

If you see:
```
❌ Failed to send FCM token: [status_code] - [error]
```

**Problem**: The backend endpoint `/api/user/fcm-token` might not exist or is failing.

**Solution**: 
1. Check your Laravel backend has this endpoint
2. Verify the endpoint accepts POST requests
3. Check it requires Bearer token authentication
4. Verify the endpoint saves the token to database

## ✅ Step 4: Verify Backend is Sending Notifications

### Check Your Laravel Backend:

1. **Is the FCM token stored?**
   - Check your database to see if the token was saved after login
   - Table: `users` or `fcm_tokens` (depends on your schema)
   - Column: `fcm_token` or `device_token`

2. **Is the notification being sent?**
   - Check Laravel logs when you change status
   - Look for FCM API calls
   - Verify the notification payload format

### Expected Laravel Notification Format:

```php
// When status changes, send notification like this:
$notification = [
    'title' => 'Order Status Updated',
    'body' => "Your order status has changed from '{$oldStatus}' to '{$newStatus}'",
];

$data = [
    'complaint_id' => $complaintId,
    'old_status' => $oldStatus,
    'new_status' => $newStatus,
];

// Send via FCM
```

### FCM API Call Should Include:
```json
{
  "to": "FCM_TOKEN_FROM_DATABASE",
  "notification": {
    "title": "Order Status Updated",
    "body": "Your order status has changed from 'pending' to 'in_progress'"
  },
  "data": {
    "complaint_id": "123"
  }
}
```

## ✅ Step 5: Check Common Issues

### Issue 1: Token Not Saved in Backend
**Symptoms**: No token in database after login
**Solution**: 
- Check backend endpoint `/api/user/fcm-token` exists
- Verify endpoint accepts POST with Bearer token
- Check backend logs for errors

### Issue 2: Backend Not Sending Notifications
**Symptoms**: Token exists but no notifications received
**Solution**:
- Verify Laravel is calling FCM API when status changes
- Check FCM server key is configured in Laravel
- Verify FCM token in database matches the one in app
- Check Laravel logs for FCM API errors

### Issue 3: Notification Format Wrong
**Symptoms**: Notifications sent but not displayed
**Solution**:
- Ensure notification has both `notification` and `data` fields
- Check `notification.title` and `notification.body` are set
- Verify `data.complaint_id` or `data.order_id` is included

### Issue 4: Permissions Not Granted
**Symptoms**: No notifications at all
**Solution**:
- Check app notification permissions in device settings
- For Android 13+: Ensure POST_NOTIFICATIONS permission is granted
- Reinstall app if permissions were denied initially

### Issue 5: App in Background/Terminated
**Symptoms**: Notifications work in foreground but not in background
**Solution**:
- Background notifications should work automatically
- Check if device has battery optimization enabled (might block notifications)
- Verify `google-services.json` is properly configured

## ✅ Step 6: Test Notification Flow

### Test 1: Local Notification
1. Go to Complaints Page
2. Tap menu → Debug Notifications
3. Tap "Test Notification"
4. **Expected**: Notification appears immediately
5. **If not**: Notification system has issues

### Test 2: FCM Token
1. Check console for: `✅ FCM Token Retrieved: [token]`
2. Copy the token
3. Check if this token exists in your Laravel database
4. **If not**: Token wasn't sent to backend

### Test 3: Backend Notification
1. Manually send a test notification from Laravel using the stored FCM token
2. Use a tool like Postman or curl:
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_FROM_DATABASE",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test"
    },
    "data": {
      "complaint_id": "123"
    }
  }'
```

## 🔧 Quick Fixes

### Fix 1: Re-send FCM Token
If token wasn't sent, you can manually trigger it:
1. Logout and login again
2. Check console for token send confirmation

### Fix 2: Check Backend Endpoint
Verify your Laravel route exists:
```php
Route::post('/user/fcm-token', [UserController::class, 'storeFcmToken'])
    ->middleware('auth:sanctum'); // or your auth middleware
```

### Fix 3: Verify Notification Payload
Ensure Laravel sends notifications with this structure:
```php
$fcmToken = $user->fcm_token; // Get from database

Http::withHeaders([
    'Authorization' => 'key=' . config('services.fcm.server_key'),
])->post('https://fcm.googleapis.com/fcm/send', [
    'to' => $fcmToken,
    'notification' => [
        'title' => 'Order Status Updated',
        'body' => "Status changed from '{$oldStatus}' to '{$newStatus}'",
    ],
    'data' => [
        'complaint_id' => (string) $complaintId,
    ],
]);
```

## 📊 Debug Checklist

- [ ] App shows "✅ NotificationService initialized" on start
- [ ] FCM token is retrieved (check console)
- [ ] FCM token is sent to backend after login
- [ ] Backend endpoint `/api/user/fcm-token` exists and works
- [ ] FCM token is saved in Laravel database
- [ ] Laravel sends notification when status changes
- [ ] Notification has both `notification` and `data` fields
- [ ] App has notification permissions granted
- [ ] Test notification works (from debug menu)
- [ ] Console shows notification received logs

## 🆘 Still Not Working?

1. **Check all console logs** - Look for any error messages
2. **Verify Firebase setup** - Ensure `google-services.json` is correct
3. **Test with Postman** - Send notification directly to FCM API
4. **Check Laravel logs** - Look for FCM API errors
5. **Verify network** - Ensure device can reach FCM servers

## 📝 Expected Console Output

### Successful Flow:
```
✅ NotificationService initialized
✅ FCM Token Retrieved: cAp9A5vyQ7qrDQGcX6qgsy:APA91b...
📱 Android Notification Permission: true
✅ FCM token sent to backend successfully
📨 Foreground notification received
Title: Order Status Updated
Body: Your order status has changed from 'pending' to 'in_progress'
📬 Local notification shown: Order Status Updated - Your order status...
```

If you see different output, compare it with the expected flow above.

