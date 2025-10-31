package ua.dmtsol.qrredirector

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class ForegroundDeepLinkService : Service() {
    companion object {
        private const val CHANNEL_ID = "qr_redirector_fg_channel"
        private const val CHANNEL_NAME = "QR Redirector Background"
        private const val NOTIFICATION_ID = 1001
        
        private var methodChannel: MethodChannel? = null
        
        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        android.util.Log.d("ForegroundDeepLinkService", "onCreate")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        android.util.Log.d("ForegroundDeepLinkService", "onStartCommand: intent=$intent flags=$flags startId=$startId")
        
        // Обробляємо deep link якщо він переданий через putExtra
        intent?.getStringExtra("deep_link")?.let { deepLink ->
            android.util.Log.d("ForegroundDeepLinkService", "Processing deep link in background: $deepLink")
            android.util.Log.d("ForegroundDeepLinkService", "MethodChannel available: ${methodChannel != null}")
            processDeepLinkInBackground(deepLink)
        }
        
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }

    private fun buildNotification(): Notification {
        android.util.Log.d("ForegroundDeepLinkService", "buildNotification")
        val launchIntent = Intent(this, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("QR Redirector")
            .setContentText("Працює у фоні та обробляє QR діплінки")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun processDeepLinkInBackground(deepLink: String) {
        try {
            android.util.Log.d("ForegroundDeepLinkService", "Starting deep link processing: $deepLink")

            // Дедуплікація: не обробляти дубль протягом TTL
            if (isDuplicateWithinTtl(deepLink)) {
                android.util.Log.d("ForegroundDeepLinkService", "Deep link skipped by dedup TTL: $deepLink")
                return
            }

            val rules = loadProjectRules()
            android.util.Log.d("ForegroundDeepLinkService", "Loaded ${rules.size} rules from SharedPreferences")

            val finalUrl = resolveFinalUrl(deepLink, rules)
            if (finalUrl == null) {
                android.util.Log.w("ForegroundDeepLinkService", "No matching rule for deep link: $deepLink")
                return
            }

            android.util.Log.d("ForegroundDeepLinkService", "Opening URL: $finalUrl")
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(finalUrl)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)

            // Зберігаємо як останній оброблений
            saveLastProcessed(deepLink)
        } catch (e: Exception) {
            android.util.Log.e("ForegroundDeepLinkService", "Error processing deep link: $deepLink", e)
        }
    }

    private data class ProjectRule(
        val regex: String,
        val urlTemplate: String
    )

    private fun loadProjectRules(): List<ProjectRule> {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val json = prefs.getString("flutter.native_projects_json", null)
            val rules = mutableListOf<ProjectRule>()
            if (!json.isNullOrEmpty()) {
                val arr = JSONArray(json)
                for (i in 0 until arr.length()) {
                    val obj: JSONObject = arr.getJSONObject(i)
                    val regex = obj.optString("regex", "")
                    val urlTemplate = obj.optString("urlTemplate", "")
                    if (regex.isNotEmpty() && urlTemplate.isNotEmpty()) {
                        rules.add(ProjectRule(regex, urlTemplate))
                    }
                }
            } else {
                // Fallback: пробуємо розпарсити flutter.projects (список JSON-рядків у Base64 або вбудованим форматом)
                val legacy = prefs.getString("flutter.projects", null)
                if (!legacy.isNullOrEmpty()) {
                    try {
                        // Очікуємо шаблон з ["{...}", "{...}"] у тексті
                        val start = legacy.indexOf('!')
                        val jsonList = if (start >= 0) legacy.substring(start + 1) else legacy
                        val arr = JSONArray(jsonList)
                        for (i in 0 until arr.length()) {
                            val item = arr.getString(i)
                            val obj = JSONObject(item)
                            val regex = obj.optString("regex", "")
                            val urlTemplate = obj.optString("urlTemplate", "")
                            if (regex.isNotEmpty() && urlTemplate.isNotEmpty()) {
                                rules.add(ProjectRule(regex, urlTemplate))
                            }
                        }
                    } catch (e: Exception) {
                        android.util.Log.w("ForegroundDeepLinkService", "Failed to parse legacy flutter.projects: ${e.message}")
                    }
                } else {
                    android.util.Log.w("ForegroundDeepLinkService", "No project rules found in SharedPreferences")
                }
            }
            rules
        } catch (e: Exception) {
            android.util.Log.e("ForegroundDeepLinkService", "Failed to load project rules", e)
            emptyList()
        }
    }

    private fun resolveFinalUrl(deepLink: String, rules: List<ProjectRule>): String? {
        for (rule in rules) {
            try {
                val pattern = Regex(rule.regex)
                val match = pattern.find(deepLink)
                if (match != null) {
                    val groups = match.groupValues
                    if (groups.isNotEmpty()) {
                        val key = groups.last()
                        val finalUrl = rule.urlTemplate.replace("{key}", key)
                        android.util.Log.d("ForegroundDeepLinkService", "Match with regex='${rule.regex}', key='$key', finalUrl='$finalUrl'")
                        return finalUrl
                    }
                }
            } catch (e: Exception) {
                android.util.Log.w("ForegroundDeepLinkService", "Regex error for pattern='${rule.regex}': ${e.message}")
                continue
            }
        }
        return null
    }

    private fun isDuplicateWithinTtl(deepLink: String, ttlMs: Long = 5000L): Boolean {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val lastLink = prefs.getString("foreground.last_processed_link", null)
            val lastAt = prefs.getLong("foreground.last_processed_at_ms", 0L)
            val now = System.currentTimeMillis()
            val isDup = (deepLink == lastLink) && (now - lastAt in 0..ttlMs)
            android.util.Log.d("ForegroundDeepLinkService", "Dedup check: isDup=$isDup, delta=${now - lastAt}ms")
            isDup
        } catch (_: Exception) { false }
    }

    private fun saveLastProcessed(deepLink: String) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("foreground.last_processed_link", deepLink)
                .putLong("foreground.last_processed_at_ms", System.currentTimeMillis())
                .apply()
        } catch (e: Exception) {
            android.util.Log.w("ForegroundDeepLinkService", "Failed to save last processed link: ${e.message}")
        }
    }
    

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}


