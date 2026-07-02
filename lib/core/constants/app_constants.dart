class AppConstants {
  // Board sizes
  static const int smallBoard = 30;
  static const int mediumBoard = 50;
  static const int largeBoard = 100;

  // Player limits
  static const int minPlayers = 2;
  static const int maxPlayers = 7;

  // Dice
  static const int minDiceValue = 1;
  static const int maxDiceValue = 6;

  // Economy
  static const Map<int, double> startingMoneyByPlayers = {
    2: 2000000,
    3: 1800000,
    4: 1600000,
    5: 1400000,
    6: 1200000,
    7: 1000000,
  };

  static const Map<int, double> salaryByBoardSize = {
    25: 100000,
    50: 200000,
    100: 400000,
  };

  static const double defaultSalary = 100000;

  static const double maxLoanMultiplier = 0.5;

  static const Map<String, double> appreciationRate = {
    'residential': 0.03,
    'farm': 0.02,
    'commercial': 0.04,
    'industrial': 0.025,
    'corner': 0.035,
    'lakeView': 0.05,
    'premium': 0.06,
    'highwayFacing': 0.045,
    'garden': 0.03,
    'luxury': 0.08,
  };

  static const double baseRentPercent = 0.10;

  static const double smallLoan = 200000;
  static const double mediumLoan = 500000;
  static const double largeLoan = 1000000;
  static const double loanInterestRate = 0.10;

  static const Map<int, double> farmIncome = {
    1: 50000,
    2: 100000,
    3: 200000,
  };

  static const Map<int, double> upgradeMultiplier = {
    1: 1.0,
    2: 1.5,
    3: 2.0,
  };

  static const List<int> endRoundOptions = [3, 5, 10];

  static const int roomCodeLength = 6;

  static const Duration tokenMoveDuration =
      Duration(milliseconds: 300);

  static const Duration diceRollDuration =
      Duration(milliseconds: 800);

  static const Duration wheelSpinDuration =
      Duration(seconds: 3);
}