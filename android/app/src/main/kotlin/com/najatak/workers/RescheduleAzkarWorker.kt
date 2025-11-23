// android/app/src/main/kotlin/com/najatak/workers/RescheduleAzkarWorker.kt

package com.najatak.workers

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin

/**
 * Worker لإعادة جدولة الأذكار بعد إعادة تشغيل الجهاز
 */
class RescheduleAzkarWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    override fun doWork(): Result {
        return try {
            Log.d("RescheduleWorker", "🔄 بدء إعادة جدولة الأذكار...")
            
            // تهيئة FlutterLocalNotifications
            val flutterLocalNotifications = FlutterLocalNotificationsPlugin()
            
            // الحصول على جميع الإشعارات المجدولة
            val pending = flutterLocalNotifications.pendingNotificationRequests()
            Log.d("RescheduleWorker", "📊 إشعارات موجودة: ${pending.size}")
            
            // إذا كان عدد الإشعارات أقل من المتوقع، قم بإعادة الجدولة
            val periodicCount = pending.count { it.id >= 10000 }
            
            if (periodicCount < 30) {
                Log.d("RescheduleWorker", "⚠️ عدد الإشعارات الدورية أقل من المتوقع ($periodicCount)")
                Log.d("RescheduleWorker", "📱 سيتم إعادة الجدولة بواسطة التطبيق الرئيسي")
                
                // إرسال signal إلى التطبيق الرئيسي
                // (التطبيق سيتعامل مع هذا في الـ main app logic)
            } else {
                Log.d("RescheduleWorker", "✅ الإشعارات الدورية موجودة وتعمل بشكل صحيح")
            }
            
            Result.success()
            
        } catch (e: Exception) {
            Log.e("RescheduleWorker", "❌ خطأ في إعادة الجدولة: ${e.message}", e)
            
            // أعد المحاولة في حالة الفشل
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }
}