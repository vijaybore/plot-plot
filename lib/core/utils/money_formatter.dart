class MoneyFormatter {
  static String format(double amount) {
    if (amount >= 10000000) {
      // 1 Crore+
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      // 1 Lakh+
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String formatFull(double amount) {
    final str = amount.toStringAsFixed(0);
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0) {
        if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
          result.write(',');
        }
      }
      result.write(str[i]);
      count++;
    }
    return '₹${result.toString().split('').reversed.join()}';
  }
}