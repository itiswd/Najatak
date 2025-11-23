// android/app/src/main/kotlin/com/najatak/receivers/BootCompleteReceiver.kt

package com.najatak.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.najatak.workers.RescheduleAzkarWorker
import java.util.concurrent.TimeUnit

/**
 * BroadcastReceiver لمعالجة حدث إعادة تشغيل الجهاز
 * يضمن استمرار الأذكار الدورية والإشعارات بعد إعادة التشغيل
 */
class BootCompleteReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        // التحقق من الإجراء
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("BootReceiver", "🔄 تم اكتشاف إعادة تشغيل الجهاز - بدء إعادة جدولة الأذكار")
            
            try {
                // إنشء مهمة لإعادة جدولة الأذكار
                val rescheduleRequest = OneTimeWorkRequestBuilder<RescheduleAzkarWorker>()
                    .setInitialDelay(5, TimeUnit.SECONDS) // تأخير 5 ثوان قبل البدء
                    .setBackoffPolicy(
                        BackoffPolicy.EXPONENTIAL,
                        15, // الحد الأدنى للتأخير (ثواني)
                        TimeUnit.SECONDS
                    )
                    .addTag("reschedule_azkar")
                    .build()
                
                // جدولة المهمة
                WorkManager.getInstance(context).enqueueUniqueWork(
                    "reschedule_azkar_on_boot",
                    ExistingWorkPolicy.KEEP, // لا تستبدل إذا كانت هناك مهمة موجودة
                    rescheduleRequest
                )
                
                Log.d("BootReceiver", "✅ تم جدولة مهمة إعادة الجدولة بنجاح")
                
            } catch (e: Exception) {
                Log.e("BootReceiver", "❌ خطأ في جدولة إعادة الأذكار: ${e.message}", e)
            }
        }
    }
}