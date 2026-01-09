# Backend Notification Architecture - Complaint Status Updates

## 📋 Overview

This document outlines the complete backend architecture for sending FCM push notifications to citizens when government employees update complaint statuses.

---

## 🏗️ Architecture Design

### Recommended Architecture: **Event-Driven + Queue System**

```
Employee API (PUT /api/employee/complaints/{id})
    ↓
ComplaintController::update()
    ↓
Complaint Model (updates status)
    ↓
ComplaintStatusUpdated Event (dispatched)
    ↓
SendComplaintNotificationListener (listens to event)
    ↓
SendComplaintNotificationJob (queued)
    ↓
FcmNotificationService::sendToUser()
    ↓
Firebase Cloud Messaging API
    ↓
Citizen's Mobile Device
```

---

## 📁 Laravel Backend Structure

### 1. **Database Schema**

```sql
-- Users table (citizens)
users
    - id
    - identifier (phone/email)
    - fcm_token (nullable)
    - fcm_token_updated_at (nullable)

-- Complaints table
complaints
    - id
    - identifier (CMP80471825)
    - user_id (foreign key to users)
    - status (NEW, IN_PROGRESS, RESOLVED, REJECTED)
    - description
    - lat, lng, address
    - created_at, updated_at
    - locked_at
```

### 2. **File Structure**

```
app/
├── Http/
│   └── Controllers/
│       └── Employee/
│           └── ComplaintController.php
├── Models/
│   ├── Complaint.php
│   └── User.php
├── Events/
│   └── ComplaintStatusUpdated.php
├── Listeners/
│   └── SendComplaintNotificationListener.php
├── Jobs/
│   └── SendComplaintNotificationJob.php
└── Services/
    └── FcmNotificationService.php
```

---

## 💻 Implementation Code

### 1. **Complaint Model** (`app/Models/Complaint.php`)

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Complaint extends Model
{
    protected $fillable = [
        'identifier',
        'user_id',
        'status',
        'description',
        'lat',
        'lng',
        'address',
        'locked_at',
    ];

    protected $casts = [
        'locked_at' => 'datetime',
    ];

    // Relationship to citizen (user)
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Status constants
    public const STATUS_NEW = 'NEW';
    public const STATUS_IN_PROGRESS = 'IN_PROGRESS';
    public const STATUS_RESOLVED = 'RESOLVED';
    public const STATUS_REJECTED = 'REJECTED';

    // Get status translations
    public function getStatusLabelAttribute(): string
    {
        return match($this->status) {
            self::STATUS_NEW => 'جديد',
            self::STATUS_IN_PROGRESS => 'قيد المعالجة',
            self::STATUS_RESOLVED => 'تم الحل',
            self::STATUS_REJECTED => 'مرفوض',
            default => $this->status,
        };
    }
}
```

### 2. **User Model** (`app/Models/User.php`)

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $fillable = [
        'identifier',
        'fcm_token',
        'fcm_token_updated_at',
    ];

    protected $casts = [
        'fcm_token_updated_at' => 'datetime',
    ];

    // Check if user has valid FCM token
    public function hasValidFcmToken(): bool
    {
        return !empty($this->fcm_token);
    }
}
```

### 3. **Event** (`app/Events/ComplaintStatusUpdated.php`)

```php
<?php

namespace App\Events;

use App\Models\Complaint;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ComplaintStatusUpdated
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Complaint $complaint;
    public string $oldStatus;
    public string $newStatus;

    public function __construct(Complaint $complaint, string $oldStatus, string $newStatus)
    {
        $this->complaint = $complaint;
        $this->oldStatus = $oldStatus;
        $this->newStatus = $newStatus;
    }
}
```

### 4. **Listener** (`app/Listeners/SendComplaintNotificationListener.php`)

```php
<?php

namespace App\Listeners;

use App\Events\ComplaintStatusUpdated;
use App\Jobs\SendComplaintNotificationJob;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;

class SendComplaintNotificationListener implements ShouldQueue
{
    use InteractsWithQueue;

    /**
     * Handle the event.
     */
    public function handle(ComplaintStatusUpdated $event): void
    {
        // Only send notification if status actually changed
        if ($event->oldStatus === $event->newStatus) {
            return;
        }

        // Dispatch job to queue for async processing
        SendComplaintNotificationJob::dispatch(
            $event->complaint,
            $event->oldStatus,
            $event->newStatus
        );
    }
}
```

### 5. **Job** (`app/Jobs/SendComplaintNotificationJob.php`)

```php
<?php

namespace App\Jobs;

use App\Models\Complaint;
use App\Services\FcmNotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendComplaintNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public Complaint $complaint;
    public string $oldStatus;
    public string $newStatus;

    /**
     * The number of times the job may be attempted.
     */
    public int $tries = 3;

    /**
     * The number of seconds to wait before retrying the job.
     */
    public int $backoff = 60;

    public function __construct(Complaint $complaint, string $oldStatus, string $newStatus)
    {
        $this->complaint = $complaint;
        $this->oldStatus = $oldStatus;
        $this->newStatus = $newStatus;
    }

    public function handle(FcmNotificationService $fcmService): void
    {
        try {
            $user = $this->complaint->user;

            // Check if user has FCM token
            if (!$user || !$user->hasValidFcmToken()) {
                Log::warning("User {$user->id} has no FCM token for complaint {$this->complaint->id}");
                return;
            }

            // Send notification
            $fcmService->sendComplaintStatusUpdate(
                fcmToken: $user->fcm_token,
                complaint: $this->complaint,
                oldStatus: $this->oldStatus,
                newStatus: $this->newStatus
            );

            Log::info("Notification sent for complaint {$this->complaint->id} to user {$user->id}");
        } catch (\Exception $e) {
            Log::error("Failed to send notification for complaint {$this->complaint->id}: " . $e->getMessage());
            throw $e; // Re-throw to trigger retry
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error("Job failed after {$this->tries} attempts for complaint {$this->complaint->id}: " . $exception->getMessage());
    }
}
```

### 6. **FCM Service** (`app/Services/FcmNotificationService.php`)

```php
<?php

namespace App\Services;

use App\Models\Complaint;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmNotificationService
{
    private string $fcmServerKey;
    private string $fcmUrl = 'https://fcm.googleapis.com/v1/projects/{project_id}/messages:send';

    public function __construct()
    {
        $this->fcmServerKey = config('services.fcm.server_key');
        
        // For FCM v1 API, you need to use OAuth2 token instead of server key
        // This is a simplified version - adjust based on your Firebase setup
    }

    /**
     * Send complaint status update notification
     */
    public function sendComplaintStatusUpdate(
        string $fcmToken,
        Complaint $complaint,
        string $oldStatus,
        string $newStatus
    ): bool {
        $title = $this->getNotificationTitle($newStatus);
        $body = $this->getNotificationBody($complaint, $newStatus);

        $payload = [
            'message' => [
                'token' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => [
                    'type' => 'complaint_status_update',
                    'complaint_id' => (string) $complaint->id,
                    'complaint_identifier' => $complaint->identifier,
                    'old_status' => $oldStatus,
                    'new_status' => $newStatus,
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

        return $this->sendToFcm($payload);
    }

    /**
     * Send notification using FCM HTTP v1 API
     */
    private function sendToFcm(array $payload): bool
    {
        try {
            // Option 1: Using FCM HTTP v1 API (Recommended)
            // Requires OAuth2 token - see: https://firebase.google.com/docs/cloud-messaging/migrate-v1
            
            // Option 2: Using Legacy HTTP API (Simpler, but deprecated)
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $this->fcmServerKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', $payload);

            if ($response->successful()) {
                Log::info('FCM notification sent successfully', [
                    'response' => $response->json(),
                ]);
                return true;
            }

            Log::error('FCM notification failed', [
                'status' => $response->status(),
                'response' => $response->body(),
            ]);
            return false;
        } catch (\Exception $e) {
            Log::error('FCM notification exception: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Get notification title based on status
     */
    private function getNotificationTitle(string $status): string
    {
        return match($status) {
            Complaint::STATUS_IN_PROGRESS => 'تم تحديث حالة الشكوى',
            Complaint::STATUS_RESOLVED => 'تم حل الشكوى',
            Complaint::STATUS_REJECTED => 'تم رفض الشكوى',
            default => 'تحديث على الشكوى',
        };
    }

    /**
     * Get notification body
     */
    private function getNotificationBody(Complaint $complaint, string $status): string
    {
        $statusLabel = $complaint->status_label;
        return "شكواك رقم {$complaint->identifier} - الحالة: {$statusLabel}";
    }
}
```

### 7. **Controller** (`app/Http/Controllers/Employee/ComplaintController.php`)

```php
<?php

namespace App\Http\Controllers\Employee;

use App\Events\ComplaintStatusUpdated;
use App\Http\Controllers\Controller;
use App\Models\Complaint;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ComplaintController extends Controller
{
    /**
     * Update complaint status
     * PUT /api/employee/complaints/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|in:NEW,IN_PROGRESS,RESOLVED,REJECTED',
        ]);

        $complaint = Complaint::with('user')->findOrFail($id);
        $oldStatus = $complaint->status;
        $newStatus = $request->input('status');

        // Update complaint
        $complaint->status = $newStatus;
        $complaint->save();

        // Dispatch event (triggers notification)
        event(new ComplaintStatusUpdated($complaint, $oldStatus, $newStatus));

        return response()->json([
            'success' => true,
            'message' => 'messages.generic.success',
            'data' => $complaint->fresh(),
            'status_code' => 200,
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
```

### 8. **Event Service Provider** (`app/Providers/EventServiceProvider.php`)

```php
<?php

namespace App\Providers;

use App\Events\ComplaintStatusUpdated;
use App\Listeners\SendComplaintNotificationListener;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        ComplaintStatusUpdated::class => [
            SendComplaintNotificationListener::class,
        ],
    ];
}
```

### 9. **Configuration** (`config/services.php`)

```php
'fcm' => [
    'server_key' => env('FCM_SERVER_KEY'),
    'project_id' => env('FCM_PROJECT_ID'),
],
```

### 10. **Environment Variables** (`.env`)

```env
FCM_SERVER_KEY=your_firebase_server_key_here
FCM_PROJECT_ID=your_firebase_project_id_here
QUEUE_CONNECTION=database  # or 'redis' for better performance
```

---

## 📦 Sample FCM Notification Payload

### For HTTP v1 API (Recommended):

```json
{
  "message": {
    "token": "citizen_fcm_token_here",
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
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "high_importance_channel",
        "sound": "default"
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
}
```

### For Legacy HTTP API:

```json
{
  "to": "citizen_fcm_token_here",
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
  }
}
```

---

## 🔄 Queue Setup

### 1. **Create Migration**

```bash
php artisan queue:table
php artisan migrate
```

### 2. **Run Queue Worker**

```bash
# Development
php artisan queue:work

# Production (with supervisor)
php artisan queue:work --daemon --tries=3 --timeout=60
```

### 3. **Supervisor Configuration** (Production)

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/path/to/worker.log
stopwaitsecs=3600
```

---

## 📱 Flutter App Notification Handling

Your Flutter app already handles notifications well! Here are the improvements needed:

### Current Implementation Status:
✅ Foreground handling
✅ Background handling  
✅ Terminated state handling
✅ Navigation on tap

### Recommended Improvements:

See the updated `notification_service.dart` in the next section.

---

## 🎯 Best Practices

1. **Always use queues** for notification sending (non-blocking)
2. **Retry failed notifications** (3 attempts with backoff)
3. **Log all notification attempts** for debugging
4. **Validate FCM tokens** before sending
5. **Handle token expiration** gracefully
6. **Use event-driven architecture** for decoupling
7. **Monitor queue performance** in production
8. **Rate limit** if sending to many users

---

## 🚀 Deployment Checklist

- [ ] Set `QUEUE_CONNECTION` in `.env`
- [ ] Configure FCM server key
- [ ] Run queue migrations
- [ ] Set up supervisor for queue workers
- [ ] Test notification flow end-to-end
- [ ] Monitor queue logs
- [ ] Set up error alerting

---

## 📊 Monitoring & Debugging

### Check Queue Status:
```bash
php artisan queue:failed  # View failed jobs
php artisan queue:retry all  # Retry failed jobs
```

### View Logs:
```bash
tail -f storage/logs/laravel.log | grep "FCM\|Notification"
```

---

## 🔐 Security Considerations

1. **Never expose FCM server key** in frontend code
2. **Validate employee permissions** before status updates
3. **Sanitize notification content** to prevent XSS
4. **Rate limit** notification endpoints
5. **Use HTTPS** for all API calls
6. **Validate FCM tokens** are associated with correct users
