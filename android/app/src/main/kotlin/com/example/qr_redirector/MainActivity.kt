package com.example.qr_redirector

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "qr_redirector/deep_link"
    private var initialLink: String? = null
    private var methodChannel: MethodChannel? = null

    private data class ProjectRule(
        val regex: String,
        val urlTemplate: String
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        android.util.Log.d("MainActivity", "configureFlutterEngine called")
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            android.util.Log.d("MainActivity", "Method call received: ${call.method}")
            when (call.method) {
                "getInitialLink" -> {
                    android.util.Log.d("MainActivity", "getInitialLink called, returning: $initialLink")
                    result.success(initialLink)
                    initialLink = null
                }
                "getLinkStream" -> {
                    // Stream реалізований через onDeepLink метод
                    result.success(null)
                }
                "clearLastProcessedLink" -> {
                    android.util.Log.d("MainActivity", "Clearing last processed link")
                    // Очищаємо поточний intent щоб не обробляти його повторно
                    setIntent(Intent())
                    result.success(null)
                }
                "startForegroundService" -> {
                    android.util.Log.d("MainActivity", "Starting ForegroundDeepLinkService via channel")
                    val serviceIntent = Intent(this, ForegroundDeepLinkService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(null)
                }
                
                "moveTaskToBack" -> {
                    android.util.Log.d("MainActivity", "Moving task to back (hide UI)")
                    moveTaskToBack(true)
                    result.success(null)
                }
                
                "exitApp" -> {
                    android.util.Log.d("MainActivity", "exitApp invoked -> stopping service and finishing task")
                    try {
                        val serviceIntent = Intent(this, ForegroundDeepLinkService::class.java)
                        stopService(serviceIntent)
                    } catch (_: Exception) {}
                    finishAndRemoveTask()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        android.util.Log.d("MainActivity", "onNewIntent called")
        setIntent(intent) // Важливо! Оновлюємо поточний intent
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        android.util.Log.d("MainActivity", "onResume called")
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Якщо це deeplink, обробляємо і приховуємо UI одразу
        if (intent?.action == Intent.ACTION_VIEW && intent?.data != null) {
            android.util.Log.d("MainActivity", "Deep link in onCreate, processing immediately")
            handleIntent(intent)
            return
        }
        
        // Якщо це звичайний запуск, показуємо Flutter UI
        android.util.Log.d("MainActivity", "Normal app launch, showing Flutter UI")
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data: Uri? = intent?.data

        android.util.Log.d("MainActivity", "handleIntent called - action: $action, data: $data")

        if (Intent.ACTION_VIEW == action && data != null) {
            val link = data.toString()
            android.util.Log.d("MainActivity", "Deep link received: $link")
            // Локальна нативна обробка: парсимо правила і відкриваємо браузер
            val rules = loadProjectRules()
            android.util.Log.d("MainActivity", "Loaded ${rules.size} rules from SharedPreferences (Activity)")
            val finalUrl = resolveFinalUrl(link, rules)
            if (finalUrl != null) {
                android.util.Log.d("MainActivity", "Opening URL from Activity: $finalUrl")
                try {
                    val viewIntent = Intent(Intent.ACTION_VIEW, Uri.parse(finalUrl))
                    viewIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(viewIntent)
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Failed to open URL from Activity: $finalUrl", e)
                }
            } else {
                android.util.Log.w("MainActivity", "No matching rule for deep link in Activity: $link")
            }
            // Після відкриття URL ховаємо UI і очищаємо intent
            moveTaskToBack(true)
            setIntent(Intent())
            // З noHistory="true" активність автоматично не з'являється в треї
        }
    }

    private fun loadProjectRules(): List<ProjectRule> {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
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
                val legacy = prefs.getString("flutter.projects", null)
                if (!legacy.isNullOrEmpty()) {
                    try {
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
                        android.util.Log.w("MainActivity", "Failed to parse legacy flutter.projects: ${e.message}")
                    }
                }
            }
            rules
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to load project rules in Activity", e)
            emptyList()
        }
    }

    private fun resolveFinalUrl(deepLink: String, rules: List<ProjectRule>): String? {
        android.util.Log.d("MainActivity", "Пошук найкращого співпадіння для: $deepLink")
        android.util.Log.d("MainActivity", "Кількість правил: ${rules.size}")
        
        val validMatches = mutableListOf<MatchInfo>()
        
        for (rule in rules) {
            try {
                val pattern = Regex(rule.regex)
                val allMatches = pattern.findAll(deepLink).toList()
                
                android.util.Log.d("MainActivity", "Regex '${rule.regex}': знайдено ${allMatches.size} співпадінь")
                
                // Критерій 1: має бути рівно одне співпадіння
                if (allMatches.size != 1) {
                    android.util.Log.d("MainActivity", "Regex '${rule.regex}' пропущено: ${allMatches.size} співпадінь (має бути 1)")
                    continue
                }
                
                val match = allMatches.first()
                val groups = match.groupValues
                
                // Критерій 2: має бути хоча б одна група захоплення
                if (groups.size < 2) {
                    android.util.Log.d("MainActivity", "Regex '${rule.regex}' пропущено: немає груп захоплення")
                    continue
                }
                
                val key = groups.last()
                val finalUrl = rule.urlTemplate.replace("{key}", key)
                val matchLength = match.range.last - match.range.first + 1
                val groupCount = groups.size - 1 // Виключаємо повне співпадіння
                
                val matchInfo = MatchInfo(
                    rule = rule,
                    key = key,
                    finalUrl = finalUrl,
                    matchLength = matchLength,
                    groupCount = groupCount
                )
                
                validMatches.add(matchInfo)
                android.util.Log.d("MainActivity", "Regex '${rule.regex}' додано: key='$key', length=$matchLength, groups=$groupCount")
                
            } catch (e: Exception) {
                android.util.Log.w("MainActivity", "Regex error in Activity for pattern='${rule.regex}': ${e.message}")
                continue
            }
        }
        
        if (validMatches.isEmpty()) {
            android.util.Log.w("MainActivity", "Не знайдено жодного валідного співпадіння")
            return null
        }
        
        // Сортування за критеріями пріоритету:
        // 1. Більше груп захоплення (більш специфічний regex)
        // 2. Довше співпадіння (більш точний match)
        // 3. Порядок в списку правил (перший має пріоритет)
        validMatches.sortWith { a, b ->
            val groupComparison = b.groupCount.compareTo(a.groupCount)
            if (groupComparison != 0) return@sortWith groupComparison
            
            val lengthComparison = b.matchLength.compareTo(a.matchLength)
            if (lengthComparison != 0) return@sortWith lengthComparison
            
            // Порядок в списку правил
            rules.indexOf(a.rule).compareTo(rules.indexOf(b.rule))
        }
        
        val bestMatch = validMatches.first()
        android.util.Log.d("MainActivity", "Найкраще співпадіння: regex='${bestMatch.rule.regex}', key='${bestMatch.key}', url='${bestMatch.finalUrl}'")
        
        return bestMatch.finalUrl
    }
    
    // Допоміжний клас для зберігання інформації про співпадіння
    private data class MatchInfo(
        val rule: ProjectRule,
        val key: String,
        val finalUrl: String,
        val matchLength: Int,
        val groupCount: Int
    )
}
