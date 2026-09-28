import 'goal_dao.dart';
import '../domain/daily_goal.dart';

class GoalRepository {
  final GoalDao _dao;
  GoalRepository(this._dao);

  Future<DailyGoal?> getGoalForDate(DateTime date) => _dao.getGoalForDate(date);
  Future<List<DailyGoal>> getAllGoals() => _dao.getAllGoals();
  Future<int> saveGoal(DailyGoal goal) => _dao.saveGoal(goal);
}
