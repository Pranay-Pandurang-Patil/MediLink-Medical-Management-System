enum ExpiryStatus {
  expired,
  critical,
  warning,
  upcoming,
  safe,
}

class ExpiryUtils {
  static ExpiryStatus getStatus(DateTime expiryDate) {
    final today = DateTime.now();

    final currentDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    final difference =
        expiry.difference(currentDate).inDays;

    if (difference < 0) {
      return ExpiryStatus.expired;
    }

    if (difference <= 30) {
      return ExpiryStatus.critical;
    }

    if (difference <= 60) {
      return ExpiryStatus.warning;
    }

    if (difference <= 90) {
      return ExpiryStatus.upcoming;
    }

    return ExpiryStatus.safe;
  }

  static int daysRemaining(DateTime expiryDate) {
    final today = DateTime.now();

    final currentDate = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    return expiry.difference(currentDate).inDays;
  }

  static String getLabel(DateTime expiryDate) {
    final status = getStatus(expiryDate);
    final days = daysRemaining(expiryDate);

    switch (status) {
      case ExpiryStatus.expired:
        return 'Expired';

      case ExpiryStatus.critical:
        return days == 0
            ? 'Expires today'
            : 'Expires in $days days';

      case ExpiryStatus.warning:
        return 'Expires in $days days';

      case ExpiryStatus.upcoming:
        return 'Expires in $days days';

      case ExpiryStatus.safe:
        return 'Expires in $days days';
    }
  }
}