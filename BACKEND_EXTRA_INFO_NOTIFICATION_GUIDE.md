# Backend Implementation Guide: Extra Info Request Notifications

## Problem
When an employee requests extra information via `POST /api/employee/complaints/{complaintId}/add-extra-info`, the Flutter app should receive a push notification, but currently no notification appears.

## Root Cause
The backend Laravel code is likely **not sending the FCM notification** after successfully saving the extra info request to the database.

## Solution: Backend Implementation

### Step 1: After Saving Extra Info, Send FCM Notification

In your Laravel controller or service that handles `POST /api/employee/complaints/{complaintId}/add-extra-info`, after successfully saving the extra info, you MUST send an FCM notification.

### Step 2: Required Notification Format

The notification **MUST** include the following structure:

```php
$payload = [
    'message' => [
        'token' => $citizenDeviceToken, // The FCM token stored for the citizen user
        'notification' => [
            'title' => 'Additional Information Required',
            'body' => 'Please provide the requested information to continue processing your complaint.',
        ],
        'data' => [
            'type' => 'extra_info_request',  // ⚠️ REQUIRED: Must be exactly this
            'complaint_id' => (string) $complaintId,  // ⚠️ REQUIRED
            'extra_info_id' => (string) $extraInfoId,  // ⚠️ REQUIRED: The ID of the extra_info record just created
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ],
        'android' => [
            'priority' => 'high',
            'notification' => [
                'channel_id' => 'high_importance_channel',
                'sound' => 'default',
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
        ],
        'apns' => [
            'payload' => [
                'aps' => [
                    'sound' => 'default',
                    'badge' => 1,
                ],
            ],
        ],
    ],
];
```

### Step 3: Example Laravel Implementation

```php
use Illuminate\Support\Facades\Http;

// After successfully saving extra_info to database
$extraInfo = ExtraInfo::create([
    'complaint_id' => $complaintId,
    'key' => $request->key,
    'value' => null, // Initially null until citizen responds
    // ... other fields
]);

// Get the citizen's FCM token from the database
$complaint = Complaint::with('user')->findOrFail($complaintId);
$citizen = $complaint->user;
$fcmToken = $citizen->device_token; // Assuming you store FCM token in users table

if ($fcmToken) {
    $payload = [
        'message' => [
            'token' => $fcmToken,
            'notification' => [
                'title' => 'Additional Information Required',
                'body' => 'Please provide the requested information to continue processing your complaint.',
            ],
            'data' => [
                'type' => 'extra_info_request',
                'complaint_id' => (string) $complaintId,
                'extra_info_id' => (string) $extraInfo->id, // ⚠️ IMPORTANT: Use the newly created extra_info ID
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'high_importance_channel',
                    'sound' => 'default',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1,
                    ],
                ],
            ],
        ],
    ];

    // Send to FCM
    $response = Http::withHeaders([
        'Authorization' => 'key=' . config('services.fcm.server_key'),
        'Content-Type' => 'application/json',
    ])->post('https://fcm.googleapis.com/fcm/send', $payload);

    if ($response->successful()) {
        \Log::info('Extra info request notification sent successfully', [
            'complaint_id' => $complaintId,
            'extra_info_id' => $extraInfo->id,
        ]);
    } else {
        \Log::error('Failed to send extra info request notification', [
            'response' => $response->body(),
        ]);
    }
} else {
    \Log::warning('Citizen has no FCM token registered', [
        'user_id' => $citizen->id,
    ]);
}
```

## Critical Requirements Checklist

- [ ] **Notification is sent AFTER extra_info is saved to database**
- [ ] **`type` field in data payload is exactly `'extra_info_request'`** (case-sensitive)
- [ ] **`complaint_id` is included in data payload** (as string)
- [ ] **`extra_info_id` is included in data payload** (as string) - This is the ID of the extra_info record just created
- [ ] **Citizen's FCM token is retrieved from database** (stored when they login/register)
- [ ] **Notification title and body are set correctly**
- [ ] **Android channel_id is set to `'high_importance_channel'`**

## Debugging

### Check Flutter Logs
When the backend sends the notification, you should see in Flutter logs:
```
📨 Foreground notification received
Title: Additional Information Required
Body: Please provide the requested information...
Data: {type: extra_info_request, complaint_id: 141, extra_info_id: 10, ...}
🔍 Notification type: extra_info_request
✅ Detected extra_info_request notification
```

If you see:
```
⚠️ WARNING: extra_info_request notification received but extra_info_id is missing!
```
This means the backend is sending the notification but missing the `extra_info_id` field.

### Check Backend Logs
Add logging in your Laravel code to verify:
1. The notification is being sent
2. The FCM token exists for the citizen
3. The FCM API response is successful

## Common Issues

1. **No notification appears**: Backend is not sending the notification at all
2. **Notification appears but doesn't navigate**: Missing `extra_info_id` in data payload
3. **Notification appears but wrong type**: `type` field is not exactly `'extra_info_request'`
4. **Citizen doesn't receive notification**: FCM token not stored or invalid

## Testing

1. Have an employee request extra info via the API
2. Check Flutter app logs for the notification
3. Verify the notification appears in the app
4. Tap the notification and verify it opens the bottom sheet with the question
