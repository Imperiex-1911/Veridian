import 'package:flutter/material.dart'; // <-- FIXED

// --- Data Models from other screens, now centralized ---

class AuditAnswers {
  final String fridgeAge;
  final String insulation;
  final String windowType;
  final String hvacAge;
  final bool hasSolar;
  final bool hasDryer;
  final bool hasDishwasher;

  AuditAnswers({
    required this.fridgeAge,
    required this.insulation,
    required this.windowType,
    required this.hvacAge,
    required this.hasSolar,
    required this.hasDryer,
    required this.hasDishwasher,
  });

  factory AuditAnswers.fromMap(Map<String, dynamic> map) {
    return AuditAnswers(
      fridgeAge: map['fridge_age'] ?? 'new',
      insulation: map['insulation'] ?? 'good',
      windowType: map['window_type'] ?? 'double',
      hvacAge: map['hvac_age'] ?? 'new',
      hasSolar: map['has_solar'] ?? false,
      hasDryer: map['has_dryer'] ?? false,
      hasDishwasher: map['has_dishwasher'] ?? false,
    );
  }

  // --- ADD THIS METHOD ---
  Map<String, dynamic> toMap() {
    return {
      'fridge_age': fridgeAge,
      'insulation': insulation,
      'window_type': windowType,
      'hvac_age': hvacAge,
      'has_solar': hasSolar,
      'has_dryer': hasDryer,
      'has_dishwasher': hasDishwasher,
    };
  }
}
class Emissions {
  final double appliances;
  final double heatingCooling;
  final double waterHeater;
  final double windows;
  final double solar;
  final double total;

  Emissions({
    required this.appliances,
    required this.heatingCooling,
    required this.waterHeater,
    required this.windows,
    required this.solar,
    required this.total,
  });

  factory Emissions.fromJson(Map<String, dynamic> json) {
    return Emissions(
      appliances: (json['appliances'] ?? 0).toDouble(),
      heatingCooling: (json['heating_cooling'] ?? 0).toDouble(),
      waterHeater: (json['water_heater'] ?? 0).toDouble(),
      windows: (json['windows'] ?? 0).toDouble(),
      solar: (json['solar'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class Rebate {
  final String id;
  final String name;
  final String description;
  final double amount;

  Rebate({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
  });

  factory Rebate.fromJson(Map<String, dynamic> json) {
    return Rebate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
    );
  }
}

class Contractor {
  final String id;
  final String name;
  final List<String> services;
  final String location;
  final String contact;
  final double rating;

  Contractor({
    required this.id,
    required this.name,
    required this.services,
    required this.location,
    required this.contact,
    required this.rating,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'],
      name: json['name'],
      services: List<String>.from(json['services']),
      location: json['location'],
      contact: json['contact'],
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}

// --- New Models for the Dashboard System ---

class Recommendation {
  final String title;
  final String reason;
  final IconData icon;
  final Rebate? relevantRebate;
  final Contractor? relevantContractor;

  Recommendation({
    required this.title,
    required this.reason,
    required this.icon,
    this.relevantRebate,
    this.relevantContractor,
  });
}

class DashboardData {
  final AuditAnswers auditAnswers;
  final Emissions emissions;
  final List<Rebate> rebates;
  final List<Contractor> contractors;

  DashboardData({
    required this.auditAnswers,
    required this.emissions,
    required this.rebates,
    required this.contractors,
  });
}
