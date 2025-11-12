class UserModel {
  final String id;
  final String gmail;
  final int coins;
  final bool isPremium;
  final DateTime? premiumExpiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.gmail,
    this.coins = 0,
    this.isPremium = false,
    this.premiumExpiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return false;
    return DateTime.now().isBefore(premiumExpiryDate!);
  }

  bool get isPremiumExpired {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return false;
    return DateTime.now().isAfter(premiumExpiryDate!);
  }

  int get daysUntilExpiry {
    if (premiumExpiryDate == null) return 0;
    return premiumExpiryDate!.difference(DateTime.now()).inDays;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      gmail: json['gmail'] ?? '',
      coins: json['coins'] ?? 0,
      isPremium: json['isPremium'] ?? false,
      premiumExpiryDate: json['premiumExpiryDate'] != null
          ? DateTime.parse(json['premiumExpiryDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gmail': gmail,
      'coins': coins,
      'isPremium': isPremium,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? gmail,
    int? coins,
    bool? isPremium,
    DateTime? premiumExpiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      gmail: gmail ?? this.gmail,
      coins: coins ?? this.coins,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
