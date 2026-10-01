/// [AppStrings] holds all Arabic UI strings, headings, subtitles, and labels.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Centralizes all user-facing text strings for localization and consistency.
class AppStrings {
  // App Branding
  static const String appName = 'حِسبَتك';
  static const String appTagline = 'المحفظة الذكية وإدارة المصاريف بدون إنترنت';
  static const String appSubTagline = 'خصوصية تامة • مزامنة فورية عند الطلب';
  static const String appVersion = 'النسخة السريعة 2.4';
  static const String encryptedLocal = 'بياناتك مشفرة ومحفوظة محلياً 100% 🔒';
  static const String offlineReady = 'مستعد بدون اتصال';
  static const String offlineActive = 'وضع عدم الاتصال نشط';
  static const String syncedLocally = 'تمت المزامنة محلياً بنجاح (☁️✓)';
  static const String safeRecord = 'سجل آمن 100%';
  static const String offlineWorks = 'يعمل دون اتصال ☁️✓';

  // Profile Setup Screen
  static const String stepOne = 'الخطوة الأولى للتحكم بمصاريفك';
  static const String setupWorkspaceTitle = 'إعداد مساحة عملك';
  static const String setupWorkspaceSubtitle =
      'ابدأ بتنظيم مصاريفك وتقسيم الفواتير مع أصدقائك بخصوصية تامة ودون الحاجة لاتصال بالإنترنت.';
  static const String localAvatar = 'الصورة الرمزية المحلية';
  static const String fullNameLabel = 'الاسم الكريم';
  static const String phoneNumberLabel = 'رقم الهاتف';
  static const String defaultUserName = 'مستخدم حسبتك';
  static const String defaultUserEmail = 'tariq.mansour@offline.local';
  static const String defaultCurrencyLabel = 'العملة الافتراضية لمصروفاتك';
  static const String currencyYER = 'ريال يمني (YER)';
  static const String currencySAR = 'ريال سعودي (SAR)';
  static const String currencyAED = 'درهم إماراتي (AED)';
  static const String currencyKWD = 'دينار كويتي (KWD)';
  static const String currencyUSD = 'دولار أمريكي (USD)';
  static const String biometricProtection = 'حماية بالبصمة / Face ID';
  static const String biometricSubtitle = 'قفل التطبيق عند مغادرته';
  static const String startNow = 'إبدأ الآن';
  static const String noAccountNeeded =
      '🔒 لا يلزم إنشاء حساب، بياناتك ملكك وتُحفظ على جهازك فقط';

  // Home Screen
  static const String goodMorning = 'صباح الخير،';
  static const String homeAndBudget = 'الرئيسية والميزانية';
  static const String totalAvailableBudget = 'إجمالي الميزانية المتاحة';
  static const String thisMonthTrending = '+2,400 ر.س هذا الشهر';
  static const String spentLabel = 'المصروف:';
  static const String maxLimitLabel = 'الحد الأقصى:';
  static const String remainingPercentMonth = 'متبقي 74.2% للشهر';
  static const String liveUpdate = 'تحديث فوري';
  static const String monthlyExpenseDistribution = 'توزيع النفقات الشهرية';
  static const String june2024 = 'يونيو 2024';
  static const String walletAiTitle = 'ذكاء المحفظة';
  static const String walletAiDescription =
      'وفرت 15% مقارنة بنفس الفترة الشهر الماضي! استمر على هذا المعدل لتصل لهدف ادخار 3,000 ر.س.';
  static const String recentTransactions = 'آخر الحركات المالية';
  static const String viewAll = 'عرض الكل';
  static const String budgetUnderControl = 'ميزانيتك تحت السيطرة دائماً!';
  static const String budgetControlSub =
      'سجل العمليات المحلية يتقدم بسلاسة بدون الحاجة للإنترنت.';

  // Groups Screen
  static const String groupsAndSplits = 'المجموعات والتقسيم';
  static const String groupsSharedExpenses =
      'المجموعات والمصاريف المشتركة\nمتابعة دقيقة للذمم والحسابات الجماعية';
  static const String exportPdf = 'تصدير PDF';
  static const String totalBalanceSummary = 'ملخص الرصيد الإجمالي';
  static const String updatedLive = 'مُحدّث فورياً';
  static const String owesYou = 'لك في ذمة الآخرين';
  static const String youOwe = 'عليك للآخرين';
  static const String fromPersons = 'من شخصين';
  static const String toPersons = 'لشخص واحد';
  static const String netPosition = 'صافي الم موقف المالي:';
  static const String netPositive = '+270 ر.س (موجب)';
  static const String activeGroups = 'المجموعات النشطة';
  static const String threeActiveGroups = '3 مجموعات نشطة';
  static const String groupWork = 'زملاء العمل';
  static const String groupYouthHome = 'سكن الشباب';
  static const String groupAbhaTrip = 'رحلة أبها';
  static const String newGroup = '+ مجموعة جديدة';
  static const String groupMembersAndSettlements =
      'أعضاء المجموعة والتسويات';
  static const String settleAccount = 'تسوية الحساب';
  static const String youOweHer = 'أنتَ مَدين بمبلغ';
  static const String heOwesYou = 'يَدين لك بمبلغ';
  static const String balancedAccount = 'الحساب متوازن (0 ر.س)';
  static const String addSharedBill = 'إضافة فاتورة مشتركة';
  static const String automaticSyncNote =
      'يتم حفظ العمليات ومزامنتها تلقائياً مع المحفظة';

  // Add & Split Expense Screen
  static const String addNewTransaction = 'إضافة عملية جديدة';
  static const String sharedBill = 'فاتورة مشتركة';
  static const String personalExpense = 'مصروف شخصي';
  static const String requiredSplitAmount = 'المبلغ المطلوب تقسيمه';
  static const String splitMethod = 'طريقة التوزيع';
  static const String splitEqually = 'بالتساوي';
  static const String splitByPercentage = 'بالنسبة %';
  static const String splitCustom = 'مخصص';
  static const String saveOffline = 'حفظ محلياً دون اتصال 💾';
  static const String readyForSyncFooter =
      '● جاهز للمزامنة فور عودة الاتصال بشبكة الإنترنت';

  // Settings Screen
  static const String settingsAndPreferences = 'الإعدادات والتفضيلات';
  static const String generalSettings = 'الإعدادات العامة';
  static const String darkMode = 'الوضع الليلي';
  static const String darkModeSub = 'تخصيص الواجهة للأوقات المظلمة';
  static const String appLanguage = 'لغة التطبيق';
  static const String appLanguageSub = 'لغة النصوص والتقارير الرقمية';
  static const String languageArabic = 'العربية (Arabic)';
  static const String mainCurrency = 'العملة الرئيسية';
  static const String mainCurrencySub = 'تعتمد لجميع العمليات والتقسيمات';
  static const String budgetAlerts = 'تنبيهات تجاوز الميزانية';
  static const String budgetAlertsSub = 'إشعارات صوتية واهتزازية فور تخطي 80%';
  static const String dataPrivacyManagement = 'إدارة البيانات والخصوصية';
  static const String exportAllPdf = 'تصدير كافة البيانات كملف PDF';
  static const String exportAllPdfSub =
      'كشف شامل للمصروفات، الفواتير، والمجموعات';
  static const String createBackup = 'إنشاء نسخة احتياطية محلية';
  static const String lastBackupToday = 'آخر نسخة: اليوم 02:15 م';
  static const String restoreBackup = 'استعادة نسخة سابقة';
  static const String restoreBackupSub = 'ملف محلي (.json / .sqlite)';
  static const String wipeData = 'مسح البيانات المحلية نهائياً';
  static const String wipeDataSub = 'حذف كامل السجلات والمجموعات من ذاكرة الجهاز';
  static const String totalPrivacyNote =
      'تطبيق "حسبتك" يعمل بهندسة Offline-First، لا يتم إرسال بياناتك أو فواتيرك لأي خادم خارجي. مفاتيح التشفير تُخزن محلياً داخل مساح أمان جهازك.';

  // Categories
  static const String catRestaurantsName = 'مطاعم ومقاهي';
  static const String catGroceriesName = 'بقالة وتموين';
  static const String catBillsName = 'فواتير ومسكن';
  static const String catEntertainmentName = 'ترفيه وتسوق';
  static const String catTransportName = 'نقل ومواصلات';

  // Transaction Management & All Transactions Screen
  static const String allTransactionsTitle = 'سجل جميع العمليات';
  static const String transactionDetails = 'تفاصيل الحركة المالية';
  static const String editTransaction = 'تعديل العملية';
  static const String deleteTransaction = 'حذف العملية';
  static const String confirmDelete = 'تأكيد الحذف';
  static const String confirmDeleteMsg = 'هل أنت متأكد من رغبتك في حذف هذه الحركة المالية نهائياً؟ سيتم تعديل رصيدك وميزانيتك تلقائياً.';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String saveChanges = 'حفظ التعديلات';
  static const String transactionUpdated = 'تم تعديل العملية بنجاح ✓';
  static const String transactionDeleted = 'تم حذف العملية بنجاح ✓';
  static const String noTransactionsFound = 'لا توجد حركات مالية مطابقة';
  static const String all = 'الكل';
  static const String expenses = 'مصروفات';
  static const String income = 'دخل';
  static const String totalIncome = 'إجمالي الدخل';
  static const String totalExpenses = 'إجمالي المصروفات';
  static const String netBalance = 'صافي العمليات';
  static const String searchTransactionPlaceholder = 'بحث عن حركة، تصنيف، أو مبلغ...';
  static const String transactionDate = 'التاريخ والوقت';
  static const String transactionCategory = 'التصنيف';
  static const String paymentMethodLabel = 'طريقة الدفع';
  static const String transactionType = 'نوع العملية';
  static const String transactionTitleLabel = 'عنوان أو وصف العملية';
  static const String transactionAmountLabel = 'المبلغ';
}
