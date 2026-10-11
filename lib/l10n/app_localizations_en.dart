// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calory';

  @override
  String get mealTypeBreakfast => 'Breakfast';

  @override
  String get mealTypeLunch => 'Lunch';

  @override
  String get mealTypeDinner => 'Dinner';

  @override
  String get mealTypeSnack => 'Snack';

  @override
  String get foodCategoryGrains => '🌾 Grains & Tubers';

  @override
  String get foodCategoryVegetablesFruits => '🥬 Vegetables & Fruits';

  @override
  String get foodCategoryMeatEggsSeafood => '🥩 Meat, Eggs & Seafood';

  @override
  String get foodCategoryDairyBeansNuts => '🥛 Dairy, Beans & Nuts';

  @override
  String get foodCategoryOther => 'Other';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroCalories => 'Calories';

  @override
  String get nutrientCalories => 'Energy';

  @override
  String get settingGoals => 'Goals';

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get appLanguageSystem => 'Follow system';

  @override
  String get appLanguageChinese => '简体中文';

  @override
  String get appLanguageEnglish => 'English';

  @override
  String appLanguageSaveFailed(String error) {
    return 'Failed to save language preference: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionUpdate => 'Update';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionStart => 'Start';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionBack => 'Back';

  @override
  String get mealPhotoLoadFailed => 'Unable to load the food photo';

  @override
  String secureStoreUnavailable(String message) {
    return 'Secure storage unavailable: $message';
  }

  @override
  String homeErrorGeneric(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get homeTodayRecords => 'Today\'s Meals';

  @override
  String homeDateRecords(String date) {
    return '$date Meals';
  }

  @override
  String get homeTakePhoto => 'Snap to log calories';

  @override
  String get homeSelectDate => 'Select date';

  @override
  String get homeTodayCalories => 'Today\'s Calories';

  @override
  String homeGoalValue(String value) {
    return 'Goal $value';
  }

  @override
  String get homeSetGoal => 'Set goal';

  @override
  String get homeMacroProgress => 'Today\'s Nutrient Progress';

  @override
  String get homeFoodCategoriesThisWeek => 'Food Categories · This Week';

  @override
  String homeWeeklyCategoryError(String error) {
    return 'Failed to load this week\'s food categories: $error';
  }

  @override
  String get homeWeeklySummary => 'Weekly Summary';

  @override
  String get homeNoRecordsToday => 'No meals logged today';

  @override
  String get homeNoRecordsDay => 'No meals logged on this day';

  @override
  String get homeEmptyHint =>
      'Tap the button at the bottom right to snap a photo and add a meal';

  @override
  String homeSaveMealFailed(String error) {
    return 'Failed to save the meal: $error';
  }

  @override
  String get homeRecognitionFailedHint =>
      'AI recognition failed. The record is kept — tap the photo to retry';

  @override
  String homeGoalCalories(String value) {
    return 'Goal $value';
  }

  @override
  String get homeNoGoal => 'No goal';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String calendarDayKcal(String day, String kcal) {
    return '$day, $kcal kcal';
  }

  @override
  String calendarDayOnly(String day) {
    return '$day';
  }

  @override
  String weekdayDayKcal(String weekday, String day, String kcal) {
    return '$weekday, $day, $kcal kcal';
  }

  @override
  String weekdayDayNoRecord(String weekday, String day) {
    return '$weekday, $day, no record';
  }

  @override
  String calendarError(String error) {
    return 'Failed to load the calendar: $error';
  }

  @override
  String get calorieRingConsumed => 'Consumed';

  @override
  String get foodCategoryNote =>
      'Roughly grouped by ingredient name and logged weight; weekly targets are derived from the adult daily recommendations in the Chinese Dietary Guidelines, for reference only.';

  @override
  String get mealSectionApproxWeight => '  ·  ~ ';

  @override
  String mealReviewSheetTitle(String mealType) {
    return '$mealType Nutrition Review';
  }

  @override
  String mealReviewTotalLine(String kcal, int count) {
    return '$kcal kcal · $count foods';
  }

  @override
  String get mealReviewGeneratedByAi => 'AI';

  @override
  String mealReviewUpdating(int count) {
    return 'Updating the review based on $count foods…';
  }

  @override
  String get mealReviewFailed => 'Failed to generate the review';

  @override
  String get mealReviewEmpty => 'No review yet';

  @override
  String get mealReviewComposingFoods => 'Foods';

  @override
  String get mealReviewRegenerate => 'Regenerate';

  @override
  String get mealSectionUpdating => 'Updating';

  @override
  String mealSectionBasedOn(int count) {
    return '$count foods';
  }

  @override
  String get mealSectionRecognizing => 'AI is recognizing the food…';

  @override
  String get mealSectionRecognitionFailed =>
      'Recognition failed. Tap the photo to retry';

  @override
  String get mealSectionReviewFailed =>
      'Failed to generate the review. Tap to retry';

  @override
  String mealSectionMoreFoods(String names) {
    return '$names …';
  }

  @override
  String mealSectionApproxGrams(String grams) {
    return '~${grams}g';
  }

  @override
  String get mealDbRecognizing => 'AI recognizing';

  @override
  String get mealDbRecognitionFailed => 'Failed recognition';

  @override
  String get mealRecognizeNoPhoto => 'Photo not found, cannot recognize';

  @override
  String get mealRecognizeConfigureLlm =>
      'Set up an LLM service in Settings first';

  @override
  String get mealRecognizeConfigureKey => 'Add an API Key in Settings first';

  @override
  String get recognitionTitle => 'AI Result';

  @override
  String get recognitionNoResult => 'No result yet';

  @override
  String get recognitionHint => 'Take a photo to recognize a meal first';

  @override
  String get recognitionBackHome => 'Back to Home';

  @override
  String get recognitionMealName => 'Meal name';

  @override
  String get recognitionFoodsKcal => 'Foods (kcal)';

  @override
  String get recognitionFoodsHint => 'Tap a food to edit its name and calories';

  @override
  String get recognitionMicronutrients => 'Micronutrients';

  @override
  String get recognitionMinerals => 'Minerals';

  @override
  String get recognitionVitamins => 'Vitamins';

  @override
  String get recognitionEditFood => 'Edit food';

  @override
  String get recognitionFoodName => 'Food name';

  @override
  String get recognitionKcalLabel => 'Calories (kcal)';

  @override
  String get recognitionSaveRecord => 'Save';

  @override
  String get recognitionKcalMustBePositive => 'Calories must be greater than 0';

  @override
  String get recognitionEnterMealName => 'Please enter a meal name';

  @override
  String recognitionSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String editValue(String label) {
    return 'Edit $label';
  }

  @override
  String get weeklySummaryTitleCurrent => 'This Week\'s Recap';

  @override
  String get weeklySummaryTitle => 'Weekly Recap';

  @override
  String get weeklySummaryAdjustAdvice => 'Adjust dietary advice';

  @override
  String weeklySummaryLoadError(String error) {
    return 'Failed to load the weekly recap: $error';
  }

  @override
  String get weeklySummaryGenerating => 'Generating…';

  @override
  String get weeklySummaryNextWeekQuestion =>
      'What would you like to improve next week?';

  @override
  String get weeklySummaryNoCard => 'The share card is not ready yet';

  @override
  String get weeklySummaryNoImage => 'Unable to generate the share image';

  @override
  String get weeklySummaryShareTitle => 'Weekly Food Recap';

  @override
  String get weeklySummaryFileName => 'weekly-food-recap.png';

  @override
  String weeklySummaryShareFailed(String error) {
    return 'Failed to generate the share card: $error';
  }

  @override
  String get weeklySummaryGenerateImage => 'Generate image';

  @override
  String get shareCardTitle => 'Weekly Food Recap';

  @override
  String get shareCardDailyAchievement => 'Daily Achievement';

  @override
  String get shareCardFoodCategories => 'Food Categories · This Week';

  @override
  String get shareCardHotTake => 'The Week\'s Hot Take';

  @override
  String get shareCardAdvice => 'Dietary Advice';

  @override
  String get shareCardEstimatedDailyAvg => 'Estimated daily average';

  @override
  String get shareCardGeneratedBy => 'Made with kcalapp';

  @override
  String get shareCardWeekdayShort1 => 'M';

  @override
  String get shareCardWeekdayShort2 => 'T';

  @override
  String get shareCardWeekdayShort3 => 'W';

  @override
  String get shareCardWeekdayShort4 => 'T';

  @override
  String get shareCardWeekdayShort5 => 'F';

  @override
  String get shareCardWeekdayShort6 => 'S';

  @override
  String get shareCardWeekdayShort7 => 'S';

  @override
  String get shareCardLegendEmpty => 'None';

  @override
  String get shareCardLegendLow => 'Low';

  @override
  String get shareCardLegendNear => 'Near';

  @override
  String get shareCardLegendOnTarget => 'On target';

  @override
  String get shareCardLegendOver => 'Over';

  @override
  String get mealViewDeleteTitle => 'Delete Record';

  @override
  String get mealViewDeleteConfirm => 'Delete this meal record?';

  @override
  String get mealViewTitle => 'Record Details';

  @override
  String get mealViewNotFound => 'Record not found';

  @override
  String get mealViewTotalCalories => 'Total Calories';

  @override
  String get mealViewFoodsKcal => 'Foods (kcal)';

  @override
  String get mealViewFoodsHint => 'Tap a food to edit its name and calories';

  @override
  String get mealViewNoFoods => 'No ingredient information';

  @override
  String mealViewReviewWillUseAll(String mealType) {
    return 'The $mealType review is generated from all foods.';
  }

  @override
  String mealViewCountedIn(String mealType, String kcal) {
    return 'Counted in $mealType ($kcal kcal)';
  }

  @override
  String get mealViewViewFullReview => 'View full review';

  @override
  String get mealViewNutrients => 'Nutrients (mg/μg)';

  @override
  String get mealViewEditMealName => 'Edit meal name';

  @override
  String get mealViewMealName => 'Meal name';

  @override
  String get mealViewEditFood => 'Edit food';

  @override
  String get mealViewFoodName => 'Food name';

  @override
  String get mealViewInvalidFood =>
      'Please enter a valid food name and calories';

  @override
  String mealViewContentLabel(String unit) {
    return 'Content ($unit)';
  }

  @override
  String get mealViewInvalidNutrient => 'Please enter a valid nutrient amount';

  @override
  String mealViewSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get mealViewDeleteFood => 'Delete food';

  @override
  String get goalsTitle => 'Goal Settings';

  @override
  String get goalsDailySection => 'Daily Calories & Nutrients';

  @override
  String get goalsCalorieTarget => 'Calorie target (kcal)';

  @override
  String get goalsCarbsTarget => 'Carbs (g)';

  @override
  String get goalsProteinTarget => 'Protein (g)';

  @override
  String get goalsFatTarget => 'Fat (g)';

  @override
  String get goalsResetDefaults => 'Reset to recommended defaults';

  @override
  String get goalsNote =>
      'Goals take effect from the day they are set and will not overwrite past daily stats.';

  @override
  String get goalsSave => 'Save goals';

  @override
  String get goalsInvalidKcal => 'Please enter a valid calorie value (1-10000)';

  @override
  String get goalsNegativeNutrient => 'Nutrients cannot be negative';

  @override
  String get llmSettingsTitle => 'Settings';

  @override
  String get llmSettingsAddProfile => 'Add profile';

  @override
  String get llmSettingsHttpDebug => 'HTTP Debug Panel';

  @override
  String get llmSettingsHttpDebugSubtitle =>
      'Inspect LLM requests / responses (alice)';

  @override
  String get llmSettingsLanApi => 'LAN Read-only API';

  @override
  String get llmSettingsLanApiSubtitle =>
      'Read meal and goal data on your local network';

  @override
  String get llmSettingsEmptyTitle => 'No profiles';

  @override
  String get llmSettingsEmptySubtitle =>
      'Add an LLM service to use photo recognition';

  @override
  String get llmSettingsFillAll => 'Please fill in all required fields';

  @override
  String get llmSettingsDeleteTitle => 'Delete Profile';

  @override
  String llmSettingsDeleteConfirm(String name) {
    return 'Delete profile \"$name\"? Its API Key will also be removed.';
  }

  @override
  String get llmSettingsFillNameUrlModel =>
      'Please fill in the name, Base URL and model first';

  @override
  String get llmSettingsFillApiKey => 'Please fill in the API Key';

  @override
  String get llmSettingsConnectionOk => 'Connection OK';

  @override
  String llmSettingsValidateFailed(String message) {
    return 'Validation failed: $message';
  }

  @override
  String llmSettingsValidateFailedDetail(String message, String detail) {
    return 'Validation failed: $message ($detail)';
  }

  @override
  String get llmSettingsValidateFailedGeneric =>
      'Validation failed. Check the configuration, network, or service response';

  @override
  String get llmSettingsEditProfile => 'Edit profile';

  @override
  String get llmSettingsAddProfileTitle => 'Add profile';

  @override
  String get llmSettingsServiceName => 'Service name';

  @override
  String get llmSettingsModelName => 'Model';

  @override
  String get llmSettingsLeaveBlank => 'Leave blank to keep unchanged';

  @override
  String get llmSettingsKeyHint => 'sk-...';

  @override
  String get llmSettingsTimeout => 'Timeout (seconds)';

  @override
  String get llmSettingsResponseFormat => 'Structured output format';

  @override
  String get llmSettingsFormatNone =>
      'Does not send response_format; the model may return non-JSON text.';

  @override
  String get llmSettingsFormatJsonMode =>
      'Uses response_format: json_object. For services that support JSON Mode but not JSON Schema.';

  @override
  String get llmSettingsFormatJsonSchema =>
      'Uses response_format: json_schema to constrain the meal-recognition output.';

  @override
  String get llmSettingsValidateConnection => 'Test connection';

  @override
  String get llmSettingsProfileAdded => 'Add profile';

  @override
  String get llmErrorTimeout =>
      'Connection timed out. Check the Base URL or network';

  @override
  String get llmErrorUnauthorized =>
      'Authentication failed: invalid API Key or insufficient permission';

  @override
  String get llmErrorRateLimited => 'Too many requests, rate limited';

  @override
  String get llmErrorServer => 'LLM server error (5xx)';

  @override
  String get llmErrorParse => 'Failed to parse the response';

  @override
  String get llmErrorUnknown =>
      'Validation failed. Check the Base URL, API Key and service status';

  @override
  String get llmErrorInvalidResponse =>
      'The service returned no valid content. Check whether the model and endpoint are compatible';

  @override
  String get llmErrorFormatUnsupportedSchema =>
      'The service does not support JSON Schema. Switch to JSON Mode or turn off structured output';

  @override
  String get llmErrorFormatUnsupportedJsonMode =>
      'The service does not support JSON Mode. Turn off structured output or switch models';

  @override
  String get llmErrorFormatUnsupportedNone =>
      'The service rejected the request. Check the model configuration';

  @override
  String get llmFormatNone => 'Structured output off';

  @override
  String get llmFormatJsonMode => 'JSON Mode';

  @override
  String get llmFormatJsonSchema => 'JSON Schema';

  @override
  String get lanApiTitle => 'LAN Read-only API';

  @override
  String get lanApiStatusRunning => 'Service running';

  @override
  String get lanApiStatusStopped => 'Service stopped';

  @override
  String get lanApiRunHint =>
      'Runs only while this page is open. Access it from a computer or other device on the same LAN; the service stops automatically when you leave this page.';

  @override
  String get lanApiSecurity =>
      'Meals and goals are personal health data. Requests must carry the token above; stopping the service or leaving this page invalidates the token immediately. HTTP is unencrypted, so the token travels in plain text over the LAN — use it only on trusted networks.';

  @override
  String get lanApiAddresses => 'LAN addresses';

  @override
  String get lanApiCopyAddress => 'Copy address with token';

  @override
  String get lanApiToken => 'Access token';

  @override
  String get lanApiCopyToken => 'Copy token';

  @override
  String get lanApiAvailableEndpoints => 'Available endpoints';

  @override
  String get lanApiEndpointMealsDesc =>
      'Read meals and food-item details within a time range';

  @override
  String get lanApiEndpointGoalsDesc => 'Read daily nutrition goals';

  @override
  String get lanApiEndpointHealthDesc => 'Check service status';

  @override
  String get lanApiAuthHint =>
      'Auth: URL parameter ?token=<token> or header Authorization: Bearer <. See the API docs.';

  @override
  String lanApiStartFailed(String error) {
    return 'Failed to start the service: $error';
  }

  @override
  String get lanApiCopied => 'Copied';

  @override
  String get weeklyNoRecords => 'No meals were logged this week.';

  @override
  String weeklyRecordedDays(int days) {
    return '$days days logged this week';
  }

  @override
  String weeklyDailyAvg(String kcal) {
    return 'Daily average about $kcal kcal';
  }

  @override
  String weeklyCategoryRelativelyHigh(String category) {
    return '$category featured relatively heavily';
  }

  @override
  String get weeklyKeepLogging =>
      'Keep logging different meals to make next week\'s recap fit your diet better.';

  @override
  String get weeklyFocusGrains =>
      'Next week, watch how you schedule staple grains and tubers.';

  @override
  String get weeklyFocusVegetables =>
      'Next week, try adding a serving of vegetables to lunch or dinner.';

  @override
  String get weeklyFocusMeat =>
      'Next week, watch how you pair meat, eggs or seafood.';

  @override
  String get weeklyFocusDairy =>
      'Next week, watch how you pair dairy, beans or nuts.';

  @override
  String get weeklyClauseSeparator => ', ';

  @override
  String get weeklySentenceEnd => '.';

  @override
  String get weeklyCategoryPlainGrains => 'Grains & tubers';

  @override
  String get weeklyCategoryPlainVegetables => 'Vegetables & fruits';

  @override
  String get weeklyCategoryPlainMeat => 'Meat, eggs & seafood';

  @override
  String get weeklyCategoryPlainDairy => 'Dairy, beans & nuts';

  @override
  String get errCannotDecodeImage => 'Unable to decode the image';

  @override
  String get errSourceImageMissing => 'Source image does not exist';

  @override
  String llmSchemaParseFailed(String message) {
    return 'Failed to parse the recognition result: $message';
  }

  @override
  String get llmSchemaInvalidJson => 'Unable to parse JSON';

  @override
  String get llmSchemaNoMeal => 'No meal recognized';

  @override
  String get llmSchemaZeroFoods => '0 foods recognized';

  @override
  String llmSchemaTooManyFoods(int count) {
    return 'Too many foods ($count); please confirm';
  }

  @override
  String get llmSchemaUnknownFood => 'Unknown food';

  @override
  String llmSchemaNegativeValue(String name) {
    return 'Food \"$name\" has a negative value';
  }

  @override
  String llmSchemaInvalidNumber(String value) {
    return 'Invalid number: $value';
  }

  @override
  String llmSchemaInvalidNumberType(String value) {
    return 'Invalid number type: $value';
  }

  @override
  String get llmSchemaMicronutrientNegative =>
      'Micronutrients contain a negative value';

  @override
  String get llmResponseTruncated =>
      'Model output hit the length limit; the recognition result is incomplete. Retry or shorten the output';

  @override
  String get mineralIron => 'Iron';

  @override
  String get mineralZinc => 'Zinc';

  @override
  String get mineralCopper => 'Copper';

  @override
  String get mineralSelenium => 'Selenium';

  @override
  String get mineralIodine => 'Iodine';

  @override
  String get mineralMolybdenum => 'Molybdenum';

  @override
  String get mineralChromium => 'Chromium';

  @override
  String get mineralCobalt => 'Cobalt';

  @override
  String get mineralCalcium => 'Calcium';

  @override
  String get mineralSodium => 'Sodium';

  @override
  String get mineralMagnesium => 'Magnesium';

  @override
  String get vitaminA => 'Vitamin A';

  @override
  String get vitaminB1 => 'Vitamin B1';

  @override
  String get vitaminB2 => 'Vitamin B2';

  @override
  String get vitaminB3 => 'Vitamin B3 (Niacin)';

  @override
  String get vitaminB5 => 'Vitamin B5';

  @override
  String get vitaminB6 => 'Vitamin B6';

  @override
  String get vitaminB7 => 'Vitamin B7 (Biotin)';

  @override
  String get vitaminB9 => 'Vitamin B9 (Folate)';

  @override
  String get vitaminB12 => 'Vitamin B12';

  @override
  String get vitaminC => 'Vitamin C';

  @override
  String get vitaminD => 'Vitamin D';

  @override
  String get vitaminE => 'Vitamin E';

  @override
  String get vitaminK => 'Vitamin K';
}
