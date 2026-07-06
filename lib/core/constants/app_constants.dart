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
  // Fixed plot prices range ₹8L (farm) → ₹40L (luxury), avg ≈ ₹17L on a
  // 25-plot board. Starting cash is set so each player can buy 2-3 plots
  // right away and then grow via GO salary, rent, and farm income across
  // the game — nobody is meant to buy the whole board on turn one.
  static const Map<int, double> startingMoneyByPlayers = {
    2: 4000000,
    3: 3600000,
    4: 3200000,
    5: 2800000,
    6: 2400000,
    7: 2000000,
  };

  // ── Realistic 25-plot economy ─────────────────────────────────────
  // Every player starts on a perfectly level playing field regardless of
  // player count: ₹120L cash-in-hand, ₹80L already parked in the bank
  // (earning safety from tax/rent shocks), plus one starter farm so the
  // farm-income loop is live from turn one.
  static const double startingCash = 12000000;   // ₹120L
  static const double startingBank = 8000000;    // ₹80L
  static const int startingFarmsPerPlayer = 1;

  // Market inflation: every full round, ALL unsold plots get a little more
  // expensive as the township's total wealth grows — cheap 6-12L starter
  // plots slowly climb toward the high-tier prices, instead of staying
  // static forever while players get richer.
  static const double marketInflationRate = 0.015; // +1.5% / round

  // Sell to Bank: an instant, no-negotiation payout so an owner can always
  // free up cash without waiting for another player to want the plot.
  // Priced below full current value (a mortgage-style haircut) so it's
  // never more attractive than actually selling to another player.
  static const double sellToBankRate = 0.75; // 75% of current value

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

  // City Tax — a small recurring cost for using roads & public services.
  // Kept deliberately low (2%) so it's a minor drag on cash, not a
  // game-ending penalty. Charged whenever a player lands on a "CITY TAX"
  // infrastructure tile.
  static const double cityTaxRate = 0.02;

  // Central Bank reserve — the pool of money the in-game Bank starts with.
  // Shown to players as "Bank Balance Remaining" so they can see how much
  // liquidity the bank has left to lend out via loans.
  static const double bankTotalReserve = 500000000; // ₹50 Cr

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

  // Total rounds the whole game lasts (every player gets this many turns).
  // The game ends here regardless of whether every plot got sold —
  // winner is whoever has the highest net worth at that point.
  static const List<int> endRoundOptions = [10, 15, 25];

  static const int roomCodeLength = 6;

  static const Duration tokenMoveDuration =
      Duration(milliseconds: 300);

  static const Duration diceRollDuration =
      Duration(milliseconds: 800);

  static const Duration wheelSpinDuration =
      Duration(seconds: 3);
}