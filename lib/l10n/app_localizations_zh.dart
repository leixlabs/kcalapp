// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '食刻';

  @override
  String get mealTypeBreakfast => '早餐';

  @override
  String get mealTypeLunch => '午餐';

  @override
  String get mealTypeDinner => '晚餐';

  @override
  String get mealTypeSnack => '加餐';

  @override
  String get foodCategoryGrains => '🌾 谷 薯';

  @override
  String get foodCategoryVegetablesFruits => '🥬 蔬菜 水果';

  @override
  String get foodCategoryMeatEggsSeafood => '🥩 肉 蛋 水产';

  @override
  String get foodCategoryDairyBeansNuts => '🥛 奶 豆 坚果';

  @override
  String get foodCategoryOther => '其他';

  @override
  String get macroCarbs => '碳水';

  @override
  String get macroProtein => '蛋白质';

  @override
  String get macroFat => '脂肪';

  @override
  String get macroCalories => '热量';

  @override
  String get nutrientCalories => '热量';

  @override
  String get settingGoals => '设置';

  @override
  String get appLanguageTitle => '应用语言';

  @override
  String get appLanguageSystem => '跟随系统';

  @override
  String get appLanguageChinese => '简体中文';

  @override
  String get appLanguageEnglish => 'English';

  @override
  String appLanguageSaveFailed(String error) {
    return '保存语言设置失败：$error';
  }

  @override
  String get retry => '重试';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '保存';

  @override
  String get actionDelete => '删除';

  @override
  String get actionConfirm => '确定';

  @override
  String get actionUpdate => '更新';

  @override
  String get actionApply => '应用';

  @override
  String get actionStop => '停止';

  @override
  String get actionStart => '启动';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionBack => '返回';

  @override
  String get mealPhotoLoadFailed => '无法加载食物照片';

  @override
  String secureStoreUnavailable(String message) {
    return '安全存储不可用: $message';
  }

  @override
  String homeErrorGeneric(String error) {
    return '加载失败: $error';
  }

  @override
  String get homeTodayRecords => '今日饮食记录';

  @override
  String homeDateRecords(String date) {
    return '$date饮食记录';
  }

  @override
  String get homeTakePhoto => '拍照识别热量';

  @override
  String get homeSelectDate => '选择日期';

  @override
  String get homeTodayCalories => '今日热量';

  @override
  String homeGoalValue(String value) {
    return '目标 $value';
  }

  @override
  String get homeSetGoal => '设置目标';

  @override
  String get homeMacroProgress => '今日营养素进度';

  @override
  String get homeFoodCategoriesThisWeek => '食物类别 · 本周';

  @override
  String homeWeeklyCategoryError(String error) {
    return '本周食物类别加载失败：$error';
  }

  @override
  String get homeWeeklySummary => '本周总结';

  @override
  String get homeNoRecordsToday => '今日暂无饮食记录';

  @override
  String get homeNoRecordsDay => '该日暂无饮食记录';

  @override
  String get homeEmptyHint => '点击右下角按钮拍照识别，添加一条饮食记录';

  @override
  String homeSaveMealFailed(String error) {
    return '保存饮食记录失败：$error';
  }

  @override
  String get homeRecognitionFailedHint => 'AI 识别失败，记录已保留，可点击图片重试';

  @override
  String homeGoalCalories(String value) {
    return '目标 $value';
  }

  @override
  String get homeNoGoal => '未设目标';

  @override
  String get weekdayMon => '周一';

  @override
  String get weekdayTue => '周二';

  @override
  String get weekdayWed => '周三';

  @override
  String get weekdayThu => '周四';

  @override
  String get weekdayFri => '周五';

  @override
  String get weekdaySat => '周六';

  @override
  String get weekdaySun => '周日';

  @override
  String calendarDayKcal(String day, String kcal) {
    return '$day日，$kcal千卡';
  }

  @override
  String calendarDayOnly(String day) {
    return '$day日';
  }

  @override
  String weekdayDayKcal(String weekday, String day, String kcal) {
    return '$weekday，$day日，$kcal千卡';
  }

  @override
  String weekdayDayNoRecord(String weekday, String day) {
    return '$weekday，$day日，未记录';
  }

  @override
  String calendarError(String error) {
    return '日历加载失败: $error';
  }

  @override
  String get calorieRingConsumed => '已摄入';

  @override
  String get foodCategoryNote =>
      '按食材名称和录入重量粗略归类；参考《中国居民膳食指南》成人日建议量折算为周目标，仅作饮食记录参考。';

  @override
  String get mealSectionApproxWeight => '  ·  约 ';

  @override
  String mealReviewSheetTitle(String mealType) {
    return '$mealType营养评价';
  }

  @override
  String mealReviewTotalLine(String kcal, int count) {
    return '共 $kcal kcal · $count 项食物';
  }

  @override
  String get mealReviewGeneratedByAi => 'AI 生成';

  @override
  String mealReviewUpdating(int count) {
    return '正在根据 $count 项食物更新评价…';
  }

  @override
  String get mealReviewFailed => '评价生成失败';

  @override
  String get mealReviewEmpty => '暂未生成评价';

  @override
  String get mealReviewComposingFoods => '组成食物';

  @override
  String get mealReviewRegenerate => '重新生成';

  @override
  String get mealSectionUpdating => '更新中';

  @override
  String mealSectionBasedOn(int count) {
    return '基于 $count 项';
  }

  @override
  String get mealSectionRecognizing => 'AI 正在识别食物…';

  @override
  String get mealSectionRecognitionFailed => '识别失败，点击图片重试';

  @override
  String get mealSectionReviewFailed => '评价生成失败，点击重新生成';

  @override
  String mealSectionMoreFoods(String names) {
    return '$names 等';
  }

  @override
  String mealSectionApproxGrams(String grams) {
    return '约${grams}g';
  }

  @override
  String get mealDbRecognizing => 'AI 识别中';

  @override
  String get mealDbRecognitionFailed => '识别失败的餐食';

  @override
  String get mealRecognizeNoPhoto => '找不到照片，无法识别';

  @override
  String get mealRecognizeConfigureLlm => '请先在设置中配置 LLM 服务';

  @override
  String get mealRecognizeConfigureKey => '请先在设置中配置 API Key';

  @override
  String get recognitionTitle => 'AI 识别结果';

  @override
  String get recognitionNoResult => '暂无识别结果';

  @override
  String get recognitionHint => '请先拍照识别餐食';

  @override
  String get recognitionBackHome => '返回首页';

  @override
  String get recognitionMealName => '餐名';

  @override
  String get recognitionFoodsKcal => '食材 (kcal)';

  @override
  String get recognitionFoodsHint => '点击食材修改名字和卡路里';

  @override
  String get recognitionMicronutrients => '微量营养素';

  @override
  String get recognitionMinerals => '矿物质';

  @override
  String get recognitionVitamins => '维生素';

  @override
  String get recognitionEditFood => '修改食材';

  @override
  String get recognitionFoodName => '食材名';

  @override
  String get recognitionKcalLabel => '热量 (kcal)';

  @override
  String get recognitionSaveRecord => '保存记录';

  @override
  String get recognitionKcalMustBePositive => '热量必须大于 0';

  @override
  String get recognitionEnterMealName => '请输入餐名';

  @override
  String recognitionSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String editValue(String label) {
    return '修改$label';
  }

  @override
  String get weeklySummaryTitleCurrent => '本周回顾';

  @override
  String get weeklySummaryTitle => '周回顾';

  @override
  String get weeklySummaryAdjustAdvice => '调整饮食建议';

  @override
  String weeklySummaryLoadError(String error) {
    return '周回顾加载失败：$error';
  }

  @override
  String get weeklySummaryGenerating => '正在生成…';

  @override
  String get weeklySummaryNextWeekQuestion => '下周想改进什么？';

  @override
  String get weeklySummaryNoCard => '分享卡片尚未准备好';

  @override
  String get weeklySummaryNoImage => '无法生成分享图片';

  @override
  String get weeklySummaryShareTitle => '本周饮食回顾';

  @override
  String get weeklySummaryFileName => '本周饮食回顾.png';

  @override
  String weeklySummaryShareFailed(String error) {
    return '生成分享卡片失败：$error';
  }

  @override
  String get weeklySummaryGenerateImage => '生成图片保存';

  @override
  String get shareCardTitle => '本周饮食回顾';

  @override
  String get shareCardDailyAchievement => '每日达成';

  @override
  String get shareCardFoodCategories => '食物类别 · 本周';

  @override
  String get shareCardHotTake => '本周锐评';

  @override
  String get shareCardAdvice => '饮食建议';

  @override
  String get shareCardEstimatedDailyAvg => '已估算日均';

  @override
  String get shareCardGeneratedBy => '生成自 kcalapp';

  @override
  String get shareCardWeekdayShort1 => '一';

  @override
  String get shareCardWeekdayShort2 => '二';

  @override
  String get shareCardWeekdayShort3 => '三';

  @override
  String get shareCardWeekdayShort4 => '四';

  @override
  String get shareCardWeekdayShort5 => '五';

  @override
  String get shareCardWeekdayShort6 => '六';

  @override
  String get shareCardWeekdayShort7 => '日';

  @override
  String get shareCardLegendEmpty => '未记录';

  @override
  String get shareCardLegendLow => '偏少';

  @override
  String get shareCardLegendNear => '接近';

  @override
  String get shareCardLegendOnTarget => '达标';

  @override
  String get shareCardLegendOver => '超出';

  @override
  String get mealViewDeleteTitle => '删除记录';

  @override
  String get mealViewDeleteConfirm => '确定要删除这条饮食记录吗？';

  @override
  String get mealViewTitle => '记录详情';

  @override
  String get mealViewNotFound => '记录不存在';

  @override
  String get mealViewTotalCalories => '总热量';

  @override
  String get mealViewFoodsKcal => '食材 (kcal)';

  @override
  String get mealViewFoodsHint => '点击食材修改名字和卡路里';

  @override
  String get mealViewNoFoods => '暂无食材信息';

  @override
  String mealViewReviewWillUseAll(String mealType) {
    return '$mealType营养评价会根据全部食物生成。';
  }

  @override
  String mealViewCountedIn(String mealType, String kcal) {
    return '已计入$mealType（共 $kcal kcal）';
  }

  @override
  String get mealViewViewFullReview => '查看完整评价';

  @override
  String get mealViewNutrients => '营养物质 (mg/μg)';

  @override
  String get mealViewEditMealName => '修改餐名';

  @override
  String get mealViewMealName => '餐名';

  @override
  String get mealViewEditFood => '修改食材';

  @override
  String get mealViewFoodName => '食材名称';

  @override
  String get mealViewInvalidFood => '请填写有效的食材名称和热量';

  @override
  String mealViewContentLabel(String unit) {
    return '含量 ($unit)';
  }

  @override
  String get mealViewInvalidNutrient => '请输入有效的营养素含量';

  @override
  String mealViewSaveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get mealViewDeleteFood => '删除食材';

  @override
  String get goalsTitle => '目标设置';

  @override
  String get goalsDailySection => '每日热量与营养素目标';

  @override
  String get goalsCalorieTarget => '热量目标 (kcal)';

  @override
  String get goalsCarbsTarget => '碳水 (g)';

  @override
  String get goalsProteinTarget => '蛋白质 (g)';

  @override
  String get goalsFatTarget => '脂肪 (g)';

  @override
  String get goalsResetDefaults => '恢复推荐默认值';

  @override
  String get goalsNote => '目标自设置日起生效，不会覆盖过去日期的历史统计。';

  @override
  String get goalsSave => '保存目标';

  @override
  String get goalsInvalidKcal => '请输入有效的热量值 (1-10000)';

  @override
  String get goalsNegativeNutrient => '营养素不能为负数';

  @override
  String get llmSettingsTitle => '设置';

  @override
  String get llmSettingsAddProfile => '添加新配置';

  @override
  String get llmSettingsHttpDebug => 'HTTP 调试面板';

  @override
  String get llmSettingsHttpDebugSubtitle => '查看 LLM 请求 / 响应（alice）';

  @override
  String get llmSettingsLanApi => '局域网只读 API';

  @override
  String get llmSettingsLanApiSubtitle => '在本地网络中读取餐食和目标数据';

  @override
  String get llmSettingsEmptyTitle => '暂无配置';

  @override
  String get llmSettingsEmptySubtitle => '添加 LLM 服务后即可使用拍照识别功能';

  @override
  String get llmSettingsFillAll => '请填写所有必填字段';

  @override
  String get llmSettingsDeleteTitle => '删除配置';

  @override
  String llmSettingsDeleteConfirm(String name) {
    return '确定删除配置「$name」？其 API Key 也会一并移除。';
  }

  @override
  String get llmSettingsFillNameUrlModel => '请先填写名称、Base URL 和模型名';

  @override
  String get llmSettingsFillApiKey => '请填写 API Key';

  @override
  String get llmSettingsConnectionOk => '连通正常';

  @override
  String llmSettingsValidateFailed(String message) {
    return '验证失败：$message';
  }

  @override
  String llmSettingsValidateFailedDetail(String message, String detail) {
    return '验证失败：$message（$detail）';
  }

  @override
  String get llmSettingsValidateFailedGeneric => '验证失败，请检查配置、网络或服务响应';

  @override
  String get llmSettingsEditProfile => '编辑配置';

  @override
  String get llmSettingsAddProfileTitle => '添加配置';

  @override
  String get llmSettingsServiceName => '服务名称';

  @override
  String get llmSettingsModelName => '模型名';

  @override
  String get llmSettingsLeaveBlank => '留空则不更新';

  @override
  String get llmSettingsKeyHint => 'sk-...';

  @override
  String get llmSettingsTimeout => '超时（秒）';

  @override
  String get llmSettingsResponseFormat => '结构化输出格式';

  @override
  String get llmSettingsFormatNone => '不发送 response_format，模型可能返回非 JSON 文本。';

  @override
  String get llmSettingsFormatJsonMode =>
      '使用 response_format: json_object。适用于支持 JSON Mode 但不支持 JSON Schema 的服务。';

  @override
  String get llmSettingsFormatJsonSchema =>
      '使用 response_format: json_schema，按餐食识别结构约束输出。';

  @override
  String get llmSettingsValidateConnection => '验证连通性';

  @override
  String get llmSettingsProfileAdded => '添加配置';

  @override
  String get llmErrorTimeout => '连接超时，请检查 Base URL 或网络';

  @override
  String get llmErrorUnauthorized => '鉴权失败：API Key 无效或权限不足';

  @override
  String get llmErrorRateLimited => '请求过于频繁，被限流';

  @override
  String get llmErrorServer => 'LLM 服务端错误（5xx）';

  @override
  String get llmErrorParse => '响应解析失败';

  @override
  String get llmErrorUnknown => '验证失败，请检查 Base URL、API Key 和服务状态';

  @override
  String get llmErrorInvalidResponse => '服务未返回有效内容，请检查模型和接口是否兼容';

  @override
  String get llmErrorFormatUnsupportedSchema =>
      '服务不支持 JSON Schema，请改用 JSON Mode 或关闭结构化输出';

  @override
  String get llmErrorFormatUnsupportedJsonMode =>
      '服务不支持 JSON Mode，请关闭结构化输出或更换模型';

  @override
  String get llmErrorFormatUnsupportedNone => '服务拒绝了请求，请检查模型配置';

  @override
  String get llmFormatNone => '关闭结构化输出';

  @override
  String get llmFormatJsonMode => 'JSON Mode';

  @override
  String get llmFormatJsonSchema => 'JSON Schema';

  @override
  String get lanApiTitle => '局域网只读 API';

  @override
  String get lanApiStatusRunning => '服务运行中';

  @override
  String get lanApiStatusStopped => '服务已停止';

  @override
  String get lanApiRunHint => '仅在此页面打开期间运行。使用同一局域网内的电脑或其他设备访问；离开本页时服务会自动停止。';

  @override
  String get lanApiSecurity =>
      '餐食和目标属于个人健康数据。访问接口必须携带上方令牌；停止服务或离开本页后，令牌立即失效。HTTP 未加密，令牌会在局域网中明文传输，请只在可信网络使用。';

  @override
  String get lanApiAddresses => '局域网地址';

  @override
  String get lanApiCopyAddress => '复制带令牌的地址';

  @override
  String get lanApiToken => '访问令牌';

  @override
  String get lanApiCopyToken => '复制令牌';

  @override
  String get lanApiAvailableEndpoints => '可用接口';

  @override
  String get lanApiEndpointMealsDesc => '读取指定时间范围内的餐食和食材明细';

  @override
  String get lanApiEndpointGoalsDesc => '读取每日营养目标';

  @override
  String get lanApiEndpointHealthDesc => '检查服务状态';

  @override
  String get lanApiAuthHint =>
      '认证：URL 参数 ?token=<令牌> 或请求头 Authorization: Bearer <令牌>。打开局域网地址可查看完整 API 文档。';

  @override
  String lanApiStartFailed(String error) {
    return '无法启动服务：$error';
  }

  @override
  String get lanApiCopied => '已复制';

  @override
  String get weeklyNoRecords => '这一周还没有饮食记录。';

  @override
  String weeklyRecordedDays(int days) {
    return '这一周记录了 $days 天';
  }

  @override
  String weeklyDailyAvg(String kcal) {
    return '日均约 $kcal kcal';
  }

  @override
  String weeklyCategoryRelativelyHigh(String category) {
    return '$category相对较多';
  }

  @override
  String get weeklyKeepLogging => '继续记录不同餐次，让下周回顾更贴近你的饮食。';

  @override
  String get weeklyFocusGrains => '下周可以留意谷薯类主食的安排。';

  @override
  String get weeklyFocusVegetables => '下周试着在午餐或晚餐加一份蔬菜。';

  @override
  String get weeklyFocusMeat => '下周可以留意肉、蛋或水产的搭配。';

  @override
  String get weeklyFocusDairy => '下周可以留意奶、豆或坚果的搭配。';

  @override
  String get weeklyClauseSeparator => '，';

  @override
  String get weeklySentenceEnd => '。';

  @override
  String get weeklyCategoryPlainGrains => '谷薯类';

  @override
  String get weeklyCategoryPlainVegetables => '蔬菜水果';

  @override
  String get weeklyCategoryPlainMeat => '肉蛋水产';

  @override
  String get weeklyCategoryPlainDairy => '奶豆坚果';

  @override
  String get errCannotDecodeImage => '无法解码图片';

  @override
  String get errSourceImageMissing => '源图片不存在';

  @override
  String llmSchemaParseFailed(String message) {
    return '识别结果解析失败: $message';
  }

  @override
  String get llmSchemaInvalidJson => '无法解析 JSON';

  @override
  String get llmSchemaNoMeal => '未识别餐食';

  @override
  String get llmSchemaZeroFoods => '识别到 0 个食材';

  @override
  String llmSchemaTooManyFoods(int count) {
    return '食材数量过多（$count），请确认';
  }

  @override
  String get llmSchemaUnknownFood => '未知食材';

  @override
  String llmSchemaNegativeValue(String name) {
    return '食材「$name」存在负数数值';
  }

  @override
  String llmSchemaInvalidNumber(String value) {
    return '数值无效: $value';
  }

  @override
  String llmSchemaInvalidNumberType(String value) {
    return '数值类型无效: $value';
  }

  @override
  String get llmSchemaMicronutrientNegative => '微量营养素存在负数数值';

  @override
  String get llmResponseTruncated => '模型输出达到长度上限，识别结果不完整，请重试或缩短输出内容';

  @override
  String get mineralIron => '铁';

  @override
  String get mineralZinc => '锌';

  @override
  String get mineralCopper => '铜';

  @override
  String get mineralSelenium => '硒';

  @override
  String get mineralIodine => '碘';

  @override
  String get mineralMolybdenum => '钼';

  @override
  String get mineralChromium => '铬';

  @override
  String get mineralCobalt => '钴';

  @override
  String get mineralCalcium => '钙';

  @override
  String get mineralSodium => '钠';

  @override
  String get mineralMagnesium => '镁';

  @override
  String get vitaminA => '维生素A';

  @override
  String get vitaminB1 => '维生素B1';

  @override
  String get vitaminB2 => '维生素B2';

  @override
  String get vitaminB3 => '维生素B3(烟酸)';

  @override
  String get vitaminB5 => '维生素B5';

  @override
  String get vitaminB6 => '维生素B6';

  @override
  String get vitaminB7 => '维生素B7(生物素)';

  @override
  String get vitaminB9 => '维生素B9(叶酸)';

  @override
  String get vitaminB12 => '维生素B12';

  @override
  String get vitaminC => '维生素C';

  @override
  String get vitaminD => '维生素D';

  @override
  String get vitaminE => '维生素E';

  @override
  String get vitaminK => '维生素K';
}
