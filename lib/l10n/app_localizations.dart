import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application name shown in the OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Calory'**
  String get appTitle;

  /// No description provided for @mealTypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealTypeBreakfast;

  /// No description provided for @mealTypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealTypeLunch;

  /// No description provided for @mealTypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealTypeDinner;

  /// No description provided for @mealTypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealTypeSnack;

  /// No description provided for @foodCategoryGrains.
  ///
  /// In en, this message translates to:
  /// **'🌾 Grains & Tubers'**
  String get foodCategoryGrains;

  /// No description provided for @foodCategoryVegetablesFruits.
  ///
  /// In en, this message translates to:
  /// **'🥬 Vegetables & Fruits'**
  String get foodCategoryVegetablesFruits;

  /// No description provided for @foodCategoryMeatEggsSeafood.
  ///
  /// In en, this message translates to:
  /// **'🥩 Meat, Eggs & Seafood'**
  String get foodCategoryMeatEggsSeafood;

  /// No description provided for @foodCategoryDairyBeansNuts.
  ///
  /// In en, this message translates to:
  /// **'🥛 Dairy, Beans & Nuts'**
  String get foodCategoryDairyBeansNuts;

  /// No description provided for @foodCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get foodCategoryOther;

  /// No description provided for @macroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get macroCarbs;

  /// No description provided for @macroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get macroProtein;

  /// No description provided for @macroFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get macroFat;

  /// No description provided for @macroCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get macroCalories;

  /// No description provided for @nutrientCalories.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get nutrientCalories;

  /// No description provided for @settingGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get settingGoals;

  /// No description provided for @appLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get appLanguageSystem;

  /// No description provided for @appLanguageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get appLanguageChinese;

  /// No description provided for @appLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get appLanguageEnglish;

  /// No description provided for @appLanguageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save language preference: {error}'**
  String appLanguageSaveFailed(String error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @mealPhotoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the food photo'**
  String get mealPhotoLoadFailed;

  /// No description provided for @secureStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Secure storage unavailable: {message}'**
  String secureStoreUnavailable(String message);

  /// No description provided for @homeErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String homeErrorGeneric(String error);

  /// No description provided for @homeTodayRecords.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meals'**
  String get homeTodayRecords;

  /// No description provided for @homeDateRecords.
  ///
  /// In en, this message translates to:
  /// **'{date} Meals'**
  String homeDateRecords(String date);

  /// No description provided for @homeTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Snap to log calories'**
  String get homeTakePhoto;

  /// No description provided for @homeSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get homeSelectDate;

  /// No description provided for @homeTodayCalories.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Calories'**
  String get homeTodayCalories;

  /// No description provided for @homeGoalValue.
  ///
  /// In en, this message translates to:
  /// **'Goal {value}'**
  String homeGoalValue(String value);

  /// No description provided for @homeSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get homeSetGoal;

  /// No description provided for @homeMacroProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Nutrient Progress'**
  String get homeMacroProgress;

  /// No description provided for @homeFoodCategoriesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Food Categories · This Week'**
  String get homeFoodCategoriesThisWeek;

  /// No description provided for @homeWeeklyCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load this week\'s food categories: {error}'**
  String homeWeeklyCategoryError(String error);

  /// No description provided for @homeWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get homeWeeklySummary;

  /// No description provided for @homeNoRecordsToday.
  ///
  /// In en, this message translates to:
  /// **'No meals logged today'**
  String get homeNoRecordsToday;

  /// No description provided for @homeNoRecordsDay.
  ///
  /// In en, this message translates to:
  /// **'No meals logged on this day'**
  String get homeNoRecordsDay;

  /// No description provided for @homeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button at the bottom right to snap a photo and add a meal'**
  String get homeEmptyHint;

  /// No description provided for @homeSaveMealFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the meal: {error}'**
  String homeSaveMealFailed(String error);

  /// No description provided for @homeRecognitionFailedHint.
  ///
  /// In en, this message translates to:
  /// **'AI recognition failed. The record is kept — tap the photo to retry'**
  String get homeRecognitionFailedHint;

  /// No description provided for @homeGoalCalories.
  ///
  /// In en, this message translates to:
  /// **'Goal {value}'**
  String homeGoalCalories(String value);

  /// No description provided for @homeNoGoal.
  ///
  /// In en, this message translates to:
  /// **'No goal'**
  String get homeNoGoal;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @calendarDayKcal.
  ///
  /// In en, this message translates to:
  /// **'{day}, {kcal} kcal'**
  String calendarDayKcal(String day, String kcal);

  /// No description provided for @calendarDayOnly.
  ///
  /// In en, this message translates to:
  /// **'{day}'**
  String calendarDayOnly(String day);

  /// No description provided for @weekdayDayKcal.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {day}, {kcal} kcal'**
  String weekdayDayKcal(String weekday, String day, String kcal);

  /// No description provided for @weekdayDayNoRecord.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {day}, no record'**
  String weekdayDayNoRecord(String weekday, String day);

  /// No description provided for @calendarError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the calendar: {error}'**
  String calendarError(String error);

  /// No description provided for @calorieRingConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get calorieRingConsumed;

  /// No description provided for @foodCategoryNote.
  ///
  /// In en, this message translates to:
  /// **'Roughly grouped by ingredient name and logged weight; weekly targets are derived from the adult daily recommendations in the Chinese Dietary Guidelines, for reference only.'**
  String get foodCategoryNote;

  /// No description provided for @mealSectionApproxWeight.
  ///
  /// In en, this message translates to:
  /// **'  ·  ~ '**
  String get mealSectionApproxWeight;

  /// No description provided for @mealReviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{mealType} Nutrition Review'**
  String mealReviewSheetTitle(String mealType);

  /// No description provided for @mealReviewTotalLine.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {count} foods'**
  String mealReviewTotalLine(String kcal, int count);

  /// No description provided for @mealReviewGeneratedByAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get mealReviewGeneratedByAi;

  /// No description provided for @mealReviewUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating the review based on {count} foods…'**
  String mealReviewUpdating(int count);

  /// No description provided for @mealReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate the review'**
  String get mealReviewFailed;

  /// No description provided for @mealReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No review yet'**
  String get mealReviewEmpty;

  /// No description provided for @mealReviewComposingFoods.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get mealReviewComposingFoods;

  /// No description provided for @mealReviewRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get mealReviewRegenerate;

  /// No description provided for @mealSectionUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating'**
  String get mealSectionUpdating;

  /// No description provided for @mealSectionBasedOn.
  ///
  /// In en, this message translates to:
  /// **'{count} foods'**
  String mealSectionBasedOn(int count);

  /// No description provided for @mealSectionRecognizing.
  ///
  /// In en, this message translates to:
  /// **'AI is recognizing the food…'**
  String get mealSectionRecognizing;

  /// No description provided for @mealSectionRecognitionFailed.
  ///
  /// In en, this message translates to:
  /// **'Recognition failed. Tap the photo to retry'**
  String get mealSectionRecognitionFailed;

  /// No description provided for @mealSectionReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate the review. Tap to retry'**
  String get mealSectionReviewFailed;

  /// No description provided for @mealSectionMoreFoods.
  ///
  /// In en, this message translates to:
  /// **'{names} …'**
  String mealSectionMoreFoods(String names);

  /// No description provided for @mealSectionApproxGrams.
  ///
  /// In en, this message translates to:
  /// **'~{grams}g'**
  String mealSectionApproxGrams(String grams);

  /// No description provided for @mealDbRecognizing.
  ///
  /// In en, this message translates to:
  /// **'AI recognizing'**
  String get mealDbRecognizing;

  /// No description provided for @mealDbRecognitionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed recognition'**
  String get mealDbRecognitionFailed;

  /// No description provided for @mealRecognizeNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo not found, cannot recognize'**
  String get mealRecognizeNoPhoto;

  /// No description provided for @mealRecognizeConfigureLlm.
  ///
  /// In en, this message translates to:
  /// **'Set up an LLM service in Settings first'**
  String get mealRecognizeConfigureLlm;

  /// No description provided for @mealRecognizeConfigureKey.
  ///
  /// In en, this message translates to:
  /// **'Add an API Key in Settings first'**
  String get mealRecognizeConfigureKey;

  /// No description provided for @recognitionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Result'**
  String get recognitionTitle;

  /// No description provided for @recognitionNoResult.
  ///
  /// In en, this message translates to:
  /// **'No result yet'**
  String get recognitionNoResult;

  /// No description provided for @recognitionHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo to recognize a meal first'**
  String get recognitionHint;

  /// No description provided for @recognitionBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get recognitionBackHome;

  /// No description provided for @recognitionMealName.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get recognitionMealName;

  /// No description provided for @recognitionFoodsKcal.
  ///
  /// In en, this message translates to:
  /// **'Foods (kcal)'**
  String get recognitionFoodsKcal;

  /// No description provided for @recognitionFoodsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a food to edit its name and calories'**
  String get recognitionFoodsHint;

  /// No description provided for @recognitionMicronutrients.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients'**
  String get recognitionMicronutrients;

  /// No description provided for @recognitionMinerals.
  ///
  /// In en, this message translates to:
  /// **'Minerals'**
  String get recognitionMinerals;

  /// No description provided for @recognitionVitamins.
  ///
  /// In en, this message translates to:
  /// **'Vitamins'**
  String get recognitionVitamins;

  /// No description provided for @recognitionEditFood.
  ///
  /// In en, this message translates to:
  /// **'Edit food'**
  String get recognitionEditFood;

  /// No description provided for @recognitionFoodName.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get recognitionFoodName;

  /// No description provided for @recognitionKcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get recognitionKcalLabel;

  /// No description provided for @recognitionSaveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get recognitionSaveRecord;

  /// No description provided for @recognitionKcalMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Calories must be greater than 0'**
  String get recognitionKcalMustBePositive;

  /// No description provided for @recognitionEnterMealName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a meal name'**
  String get recognitionEnterMealName;

  /// No description provided for @recognitionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String recognitionSaveFailed(String error);

  /// No description provided for @editValue.
  ///
  /// In en, this message translates to:
  /// **'Edit {label}'**
  String editValue(String label);

  /// No description provided for @weeklySummaryTitleCurrent.
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Recap'**
  String get weeklySummaryTitleCurrent;

  /// No description provided for @weeklySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Recap'**
  String get weeklySummaryTitle;

  /// No description provided for @weeklySummaryAdjustAdvice.
  ///
  /// In en, this message translates to:
  /// **'Adjust dietary advice'**
  String get weeklySummaryAdjustAdvice;

  /// No description provided for @weeklySummaryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the weekly recap: {error}'**
  String weeklySummaryLoadError(String error);

  /// No description provided for @weeklySummaryGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get weeklySummaryGenerating;

  /// No description provided for @weeklySummaryNextWeekQuestion.
  ///
  /// In en, this message translates to:
  /// **'What would you like to improve next week?'**
  String get weeklySummaryNextWeekQuestion;

  /// No description provided for @weeklySummaryNoCard.
  ///
  /// In en, this message translates to:
  /// **'The share card is not ready yet'**
  String get weeklySummaryNoCard;

  /// No description provided for @weeklySummaryNoImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to generate the share image'**
  String get weeklySummaryNoImage;

  /// No description provided for @weeklySummaryShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Food Recap'**
  String get weeklySummaryShareTitle;

  /// No description provided for @weeklySummaryFileName.
  ///
  /// In en, this message translates to:
  /// **'weekly-food-recap.png'**
  String get weeklySummaryFileName;

  /// No description provided for @weeklySummaryShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate the share card: {error}'**
  String weeklySummaryShareFailed(String error);

  /// No description provided for @weeklySummaryGenerateImage.
  ///
  /// In en, this message translates to:
  /// **'Generate image'**
  String get weeklySummaryGenerateImage;

  /// No description provided for @shareCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Food Recap'**
  String get shareCardTitle;

  /// No description provided for @shareCardDailyAchievement.
  ///
  /// In en, this message translates to:
  /// **'Daily Achievement'**
  String get shareCardDailyAchievement;

  /// No description provided for @shareCardFoodCategories.
  ///
  /// In en, this message translates to:
  /// **'Food Categories · This Week'**
  String get shareCardFoodCategories;

  /// No description provided for @shareCardHotTake.
  ///
  /// In en, this message translates to:
  /// **'The Week\'s Hot Take'**
  String get shareCardHotTake;

  /// No description provided for @shareCardAdvice.
  ///
  /// In en, this message translates to:
  /// **'Dietary Advice'**
  String get shareCardAdvice;

  /// No description provided for @shareCardEstimatedDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Estimated daily average'**
  String get shareCardEstimatedDailyAvg;

  /// No description provided for @shareCardGeneratedBy.
  ///
  /// In en, this message translates to:
  /// **'Made with kcalapp'**
  String get shareCardGeneratedBy;

  /// No description provided for @shareCardWeekdayShort1.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get shareCardWeekdayShort1;

  /// No description provided for @shareCardWeekdayShort2.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get shareCardWeekdayShort2;

  /// No description provided for @shareCardWeekdayShort3.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get shareCardWeekdayShort3;

  /// No description provided for @shareCardWeekdayShort4.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get shareCardWeekdayShort4;

  /// No description provided for @shareCardWeekdayShort5.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get shareCardWeekdayShort5;

  /// No description provided for @shareCardWeekdayShort6.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get shareCardWeekdayShort6;

  /// No description provided for @shareCardWeekdayShort7.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get shareCardWeekdayShort7;

  /// No description provided for @shareCardLegendEmpty.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get shareCardLegendEmpty;

  /// No description provided for @shareCardLegendLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get shareCardLegendLow;

  /// No description provided for @shareCardLegendNear.
  ///
  /// In en, this message translates to:
  /// **'Near'**
  String get shareCardLegendNear;

  /// No description provided for @shareCardLegendOnTarget.
  ///
  /// In en, this message translates to:
  /// **'On target'**
  String get shareCardLegendOnTarget;

  /// No description provided for @shareCardLegendOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get shareCardLegendOver;

  /// No description provided for @mealViewDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get mealViewDeleteTitle;

  /// No description provided for @mealViewDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this meal record?'**
  String get mealViewDeleteConfirm;

  /// No description provided for @mealViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Details'**
  String get mealViewTitle;

  /// No description provided for @mealViewNotFound.
  ///
  /// In en, this message translates to:
  /// **'Record not found'**
  String get mealViewNotFound;

  /// No description provided for @mealViewTotalCalories.
  ///
  /// In en, this message translates to:
  /// **'Total Calories'**
  String get mealViewTotalCalories;

  /// No description provided for @mealViewFoodsKcal.
  ///
  /// In en, this message translates to:
  /// **'Foods (kcal)'**
  String get mealViewFoodsKcal;

  /// No description provided for @mealViewFoodsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a food to edit its name and calories'**
  String get mealViewFoodsHint;

  /// No description provided for @mealViewNoFoods.
  ///
  /// In en, this message translates to:
  /// **'No ingredient information'**
  String get mealViewNoFoods;

  /// No description provided for @mealViewReviewWillUseAll.
  ///
  /// In en, this message translates to:
  /// **'The {mealType} review is generated from all foods.'**
  String mealViewReviewWillUseAll(String mealType);

  /// No description provided for @mealViewCountedIn.
  ///
  /// In en, this message translates to:
  /// **'Counted in {mealType} ({kcal} kcal)'**
  String mealViewCountedIn(String mealType, String kcal);

  /// No description provided for @mealViewViewFullReview.
  ///
  /// In en, this message translates to:
  /// **'View full review'**
  String get mealViewViewFullReview;

  /// No description provided for @mealViewNutrients.
  ///
  /// In en, this message translates to:
  /// **'Nutrients (mg/μg)'**
  String get mealViewNutrients;

  /// No description provided for @mealViewEditMealName.
  ///
  /// In en, this message translates to:
  /// **'Edit meal name'**
  String get mealViewEditMealName;

  /// No description provided for @mealViewMealName.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get mealViewMealName;

  /// No description provided for @mealViewEditFood.
  ///
  /// In en, this message translates to:
  /// **'Edit food'**
  String get mealViewEditFood;

  /// No description provided for @mealViewFoodName.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get mealViewFoodName;

  /// No description provided for @mealViewInvalidFood.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid food name and calories'**
  String get mealViewInvalidFood;

  /// No description provided for @mealViewContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content ({unit})'**
  String mealViewContentLabel(String unit);

  /// No description provided for @mealViewInvalidNutrient.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid nutrient amount'**
  String get mealViewInvalidNutrient;

  /// No description provided for @mealViewSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String mealViewSaveFailed(String error);

  /// No description provided for @mealViewDeleteFood.
  ///
  /// In en, this message translates to:
  /// **'Delete food'**
  String get mealViewDeleteFood;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Settings'**
  String get goalsTitle;

  /// No description provided for @goalsDailySection.
  ///
  /// In en, this message translates to:
  /// **'Daily Calories & Nutrients'**
  String get goalsDailySection;

  /// No description provided for @goalsCalorieTarget.
  ///
  /// In en, this message translates to:
  /// **'Calorie target (kcal)'**
  String get goalsCalorieTarget;

  /// No description provided for @goalsCarbsTarget.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get goalsCarbsTarget;

  /// No description provided for @goalsProteinTarget.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get goalsProteinTarget;

  /// No description provided for @goalsFatTarget.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get goalsFatTarget;

  /// No description provided for @goalsResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to recommended defaults'**
  String get goalsResetDefaults;

  /// No description provided for @goalsNote.
  ///
  /// In en, this message translates to:
  /// **'Goals take effect from the day they are set and will not overwrite past daily stats.'**
  String get goalsNote;

  /// No description provided for @goalsSave.
  ///
  /// In en, this message translates to:
  /// **'Save goals'**
  String get goalsSave;

  /// No description provided for @goalsInvalidKcal.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid calorie value (1-10000)'**
  String get goalsInvalidKcal;

  /// No description provided for @goalsNegativeNutrient.
  ///
  /// In en, this message translates to:
  /// **'Nutrients cannot be negative'**
  String get goalsNegativeNutrient;

  /// No description provided for @llmSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get llmSettingsTitle;

  /// No description provided for @llmSettingsAddProfile.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get llmSettingsAddProfile;

  /// No description provided for @llmSettingsHttpDebug.
  ///
  /// In en, this message translates to:
  /// **'HTTP Debug Panel'**
  String get llmSettingsHttpDebug;

  /// No description provided for @llmSettingsHttpDebugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect LLM requests / responses (alice)'**
  String get llmSettingsHttpDebugSubtitle;

  /// No description provided for @llmSettingsLanApi.
  ///
  /// In en, this message translates to:
  /// **'LAN Read-only API'**
  String get llmSettingsLanApi;

  /// No description provided for @llmSettingsLanApiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read meal and goal data on your local network'**
  String get llmSettingsLanApiSubtitle;

  /// No description provided for @llmSettingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No profiles'**
  String get llmSettingsEmptyTitle;

  /// No description provided for @llmSettingsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an LLM service to use photo recognition'**
  String get llmSettingsEmptySubtitle;

  /// No description provided for @llmSettingsFillAll.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get llmSettingsFillAll;

  /// No description provided for @llmSettingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get llmSettingsDeleteTitle;

  /// No description provided for @llmSettingsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete profile \"{name}\"? Its API Key will also be removed.'**
  String llmSettingsDeleteConfirm(String name);

  /// No description provided for @llmSettingsFillNameUrlModel.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the name, Base URL and model first'**
  String get llmSettingsFillNameUrlModel;

  /// No description provided for @llmSettingsFillApiKey.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the API Key'**
  String get llmSettingsFillApiKey;

  /// No description provided for @llmSettingsConnectionOk.
  ///
  /// In en, this message translates to:
  /// **'Connection OK'**
  String get llmSettingsConnectionOk;

  /// No description provided for @llmSettingsValidateFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {message}'**
  String llmSettingsValidateFailed(String message);

  /// No description provided for @llmSettingsValidateFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {message} ({detail})'**
  String llmSettingsValidateFailedDetail(String message, String detail);

  /// No description provided for @llmSettingsValidateFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Validation failed. Check the configuration, network, or service response'**
  String get llmSettingsValidateFailedGeneric;

  /// No description provided for @llmSettingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get llmSettingsEditProfile;

  /// No description provided for @llmSettingsAddProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get llmSettingsAddProfileTitle;

  /// No description provided for @llmSettingsServiceName.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get llmSettingsServiceName;

  /// No description provided for @llmSettingsModelName.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get llmSettingsModelName;

  /// No description provided for @llmSettingsLeaveBlank.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep unchanged'**
  String get llmSettingsLeaveBlank;

  /// No description provided for @llmSettingsKeyHint.
  ///
  /// In en, this message translates to:
  /// **'sk-...'**
  String get llmSettingsKeyHint;

  /// No description provided for @llmSettingsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout (seconds)'**
  String get llmSettingsTimeout;

  /// No description provided for @llmSettingsResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'Structured output format'**
  String get llmSettingsResponseFormat;

  /// No description provided for @llmSettingsFormatNone.
  ///
  /// In en, this message translates to:
  /// **'Does not send response_format; the model may return non-JSON text.'**
  String get llmSettingsFormatNone;

  /// No description provided for @llmSettingsFormatJsonMode.
  ///
  /// In en, this message translates to:
  /// **'Uses response_format: json_object. For services that support JSON Mode but not JSON Schema.'**
  String get llmSettingsFormatJsonMode;

  /// No description provided for @llmSettingsFormatJsonSchema.
  ///
  /// In en, this message translates to:
  /// **'Uses response_format: json_schema to constrain the meal-recognition output.'**
  String get llmSettingsFormatJsonSchema;

  /// No description provided for @llmSettingsValidateConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get llmSettingsValidateConnection;

  /// No description provided for @llmSettingsProfileAdded.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get llmSettingsProfileAdded;

  /// No description provided for @llmErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check the Base URL or network'**
  String get llmErrorTimeout;

  /// No description provided for @llmErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed: invalid API Key or insufficient permission'**
  String get llmErrorUnauthorized;

  /// No description provided for @llmErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests, rate limited'**
  String get llmErrorRateLimited;

  /// No description provided for @llmErrorServer.
  ///
  /// In en, this message translates to:
  /// **'LLM server error (5xx)'**
  String get llmErrorServer;

  /// No description provided for @llmErrorParse.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse the response'**
  String get llmErrorParse;

  /// No description provided for @llmErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Validation failed. Check the Base URL, API Key and service status'**
  String get llmErrorUnknown;

  /// No description provided for @llmErrorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The service returned no valid content. Check whether the model and endpoint are compatible'**
  String get llmErrorInvalidResponse;

  /// No description provided for @llmErrorFormatUnsupportedSchema.
  ///
  /// In en, this message translates to:
  /// **'The service does not support JSON Schema. Switch to JSON Mode or turn off structured output'**
  String get llmErrorFormatUnsupportedSchema;

  /// No description provided for @llmErrorFormatUnsupportedJsonMode.
  ///
  /// In en, this message translates to:
  /// **'The service does not support JSON Mode. Turn off structured output or switch models'**
  String get llmErrorFormatUnsupportedJsonMode;

  /// No description provided for @llmErrorFormatUnsupportedNone.
  ///
  /// In en, this message translates to:
  /// **'The service rejected the request. Check the model configuration'**
  String get llmErrorFormatUnsupportedNone;

  /// No description provided for @llmFormatNone.
  ///
  /// In en, this message translates to:
  /// **'Structured output off'**
  String get llmFormatNone;

  /// No description provided for @llmFormatJsonMode.
  ///
  /// In en, this message translates to:
  /// **'JSON Mode'**
  String get llmFormatJsonMode;

  /// No description provided for @llmFormatJsonSchema.
  ///
  /// In en, this message translates to:
  /// **'JSON Schema'**
  String get llmFormatJsonSchema;

  /// No description provided for @lanApiTitle.
  ///
  /// In en, this message translates to:
  /// **'LAN Read-only API'**
  String get lanApiTitle;

  /// No description provided for @lanApiStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Service running'**
  String get lanApiStatusRunning;

  /// No description provided for @lanApiStatusStopped.
  ///
  /// In en, this message translates to:
  /// **'Service stopped'**
  String get lanApiStatusStopped;

  /// No description provided for @lanApiRunHint.
  ///
  /// In en, this message translates to:
  /// **'Runs only while this page is open. Access it from a computer or other device on the same LAN; the service stops automatically when you leave this page.'**
  String get lanApiRunHint;

  /// No description provided for @lanApiSecurity.
  ///
  /// In en, this message translates to:
  /// **'Meals and goals are personal health data. Requests must carry the token above; stopping the service or leaving this page invalidates the token immediately. HTTP is unencrypted, so the token travels in plain text over the LAN — use it only on trusted networks.'**
  String get lanApiSecurity;

  /// No description provided for @lanApiAddresses.
  ///
  /// In en, this message translates to:
  /// **'LAN addresses'**
  String get lanApiAddresses;

  /// No description provided for @lanApiCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address with token'**
  String get lanApiCopyAddress;

  /// No description provided for @lanApiToken.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get lanApiToken;

  /// No description provided for @lanApiCopyToken.
  ///
  /// In en, this message translates to:
  /// **'Copy token'**
  String get lanApiCopyToken;

  /// No description provided for @lanApiAvailableEndpoints.
  ///
  /// In en, this message translates to:
  /// **'Available endpoints'**
  String get lanApiAvailableEndpoints;

  /// No description provided for @lanApiEndpointMealsDesc.
  ///
  /// In en, this message translates to:
  /// **'Read meals and food-item details within a time range'**
  String get lanApiEndpointMealsDesc;

  /// No description provided for @lanApiEndpointGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Read daily nutrition goals'**
  String get lanApiEndpointGoalsDesc;

  /// No description provided for @lanApiEndpointHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Check service status'**
  String get lanApiEndpointHealthDesc;

  /// No description provided for @lanApiAuthHint.
  ///
  /// In en, this message translates to:
  /// **'Auth: URL parameter ?token=<token> or header Authorization: Bearer <. See the API docs.'**
  String get lanApiAuthHint;

  /// No description provided for @lanApiStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start the service: {error}'**
  String lanApiStartFailed(String error);

  /// No description provided for @lanApiCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get lanApiCopied;

  /// No description provided for @weeklyNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No meals were logged this week.'**
  String get weeklyNoRecords;

  /// No description provided for @weeklyRecordedDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days logged this week'**
  String weeklyRecordedDays(int days);

  /// No description provided for @weeklyDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily average about {kcal} kcal'**
  String weeklyDailyAvg(String kcal);

  /// No description provided for @weeklyCategoryRelativelyHigh.
  ///
  /// In en, this message translates to:
  /// **'{category} featured relatively heavily'**
  String weeklyCategoryRelativelyHigh(String category);

  /// No description provided for @weeklyKeepLogging.
  ///
  /// In en, this message translates to:
  /// **'Keep logging different meals to make next week\'s recap fit your diet better.'**
  String get weeklyKeepLogging;

  /// No description provided for @weeklyFocusGrains.
  ///
  /// In en, this message translates to:
  /// **'Next week, watch how you schedule staple grains and tubers.'**
  String get weeklyFocusGrains;

  /// No description provided for @weeklyFocusVegetables.
  ///
  /// In en, this message translates to:
  /// **'Next week, try adding a serving of vegetables to lunch or dinner.'**
  String get weeklyFocusVegetables;

  /// No description provided for @weeklyFocusMeat.
  ///
  /// In en, this message translates to:
  /// **'Next week, watch how you pair meat, eggs or seafood.'**
  String get weeklyFocusMeat;

  /// No description provided for @weeklyFocusDairy.
  ///
  /// In en, this message translates to:
  /// **'Next week, watch how you pair dairy, beans or nuts.'**
  String get weeklyFocusDairy;

  /// No description provided for @weeklyClauseSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get weeklyClauseSeparator;

  /// No description provided for @weeklySentenceEnd.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get weeklySentenceEnd;

  /// No description provided for @weeklyCategoryPlainGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains & tubers'**
  String get weeklyCategoryPlainGrains;

  /// No description provided for @weeklyCategoryPlainVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables & fruits'**
  String get weeklyCategoryPlainVegetables;

  /// No description provided for @weeklyCategoryPlainMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat, eggs & seafood'**
  String get weeklyCategoryPlainMeat;

  /// No description provided for @weeklyCategoryPlainDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy, beans & nuts'**
  String get weeklyCategoryPlainDairy;

  /// No description provided for @errCannotDecodeImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to decode the image'**
  String get errCannotDecodeImage;

  /// No description provided for @errSourceImageMissing.
  ///
  /// In en, this message translates to:
  /// **'Source image does not exist'**
  String get errSourceImageMissing;

  /// No description provided for @llmSchemaParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse the recognition result: {message}'**
  String llmSchemaParseFailed(String message);

  /// No description provided for @llmSchemaInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Unable to parse JSON'**
  String get llmSchemaInvalidJson;

  /// No description provided for @llmSchemaNoMeal.
  ///
  /// In en, this message translates to:
  /// **'No meal recognized'**
  String get llmSchemaNoMeal;

  /// No description provided for @llmSchemaZeroFoods.
  ///
  /// In en, this message translates to:
  /// **'0 foods recognized'**
  String get llmSchemaZeroFoods;

  /// No description provided for @llmSchemaTooManyFoods.
  ///
  /// In en, this message translates to:
  /// **'Too many foods ({count}); please confirm'**
  String llmSchemaTooManyFoods(int count);

  /// No description provided for @llmSchemaUnknownFood.
  ///
  /// In en, this message translates to:
  /// **'Unknown food'**
  String get llmSchemaUnknownFood;

  /// No description provided for @llmSchemaNegativeValue.
  ///
  /// In en, this message translates to:
  /// **'Food \"{name}\" has a negative value'**
  String llmSchemaNegativeValue(String name);

  /// No description provided for @llmSchemaInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number: {value}'**
  String llmSchemaInvalidNumber(String value);

  /// No description provided for @llmSchemaInvalidNumberType.
  ///
  /// In en, this message translates to:
  /// **'Invalid number type: {value}'**
  String llmSchemaInvalidNumberType(String value);

  /// No description provided for @llmSchemaMicronutrientNegative.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients contain a negative value'**
  String get llmSchemaMicronutrientNegative;

  /// No description provided for @llmResponseTruncated.
  ///
  /// In en, this message translates to:
  /// **'Model output hit the length limit; the recognition result is incomplete. Retry or shorten the output'**
  String get llmResponseTruncated;

  /// No description provided for @mineralIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get mineralIron;

  /// No description provided for @mineralZinc.
  ///
  /// In en, this message translates to:
  /// **'Zinc'**
  String get mineralZinc;

  /// No description provided for @mineralCopper.
  ///
  /// In en, this message translates to:
  /// **'Copper'**
  String get mineralCopper;

  /// No description provided for @mineralSelenium.
  ///
  /// In en, this message translates to:
  /// **'Selenium'**
  String get mineralSelenium;

  /// No description provided for @mineralIodine.
  ///
  /// In en, this message translates to:
  /// **'Iodine'**
  String get mineralIodine;

  /// No description provided for @mineralMolybdenum.
  ///
  /// In en, this message translates to:
  /// **'Molybdenum'**
  String get mineralMolybdenum;

  /// No description provided for @mineralChromium.
  ///
  /// In en, this message translates to:
  /// **'Chromium'**
  String get mineralChromium;

  /// No description provided for @mineralCobalt.
  ///
  /// In en, this message translates to:
  /// **'Cobalt'**
  String get mineralCobalt;

  /// No description provided for @mineralCalcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium'**
  String get mineralCalcium;

  /// No description provided for @mineralSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get mineralSodium;

  /// No description provided for @mineralMagnesium.
  ///
  /// In en, this message translates to:
  /// **'Magnesium'**
  String get mineralMagnesium;

  /// No description provided for @vitaminA.
  ///
  /// In en, this message translates to:
  /// **'Vitamin A'**
  String get vitaminA;

  /// No description provided for @vitaminB1.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B1'**
  String get vitaminB1;

  /// No description provided for @vitaminB2.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B2'**
  String get vitaminB2;

  /// No description provided for @vitaminB3.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B3 (Niacin)'**
  String get vitaminB3;

  /// No description provided for @vitaminB5.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B5'**
  String get vitaminB5;

  /// No description provided for @vitaminB6.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B6'**
  String get vitaminB6;

  /// No description provided for @vitaminB7.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B7 (Biotin)'**
  String get vitaminB7;

  /// No description provided for @vitaminB9.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B9 (Folate)'**
  String get vitaminB9;

  /// No description provided for @vitaminB12.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B12'**
  String get vitaminB12;

  /// No description provided for @vitaminC.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C'**
  String get vitaminC;

  /// No description provided for @vitaminD.
  ///
  /// In en, this message translates to:
  /// **'Vitamin D'**
  String get vitaminD;

  /// No description provided for @vitaminE.
  ///
  /// In en, this message translates to:
  /// **'Vitamin E'**
  String get vitaminE;

  /// No description provided for @vitaminK.
  ///
  /// In en, this message translates to:
  /// **'Vitamin K'**
  String get vitaminK;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
