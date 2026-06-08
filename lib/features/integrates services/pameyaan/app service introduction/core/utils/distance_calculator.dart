import 'dart:math' show cos, sqrt, asin;

class DistanceCalculator {
  // 1. A dictionary holding the GPS coordinates for ALL your Bongao locations
  static final Map<String, Map<String, double>> bongaoLocations = {
    // --- Terminals, Ports & Landmarks ---
    'Bongao Port': {'lat': 5.0275, 'lng': 119.7711},
    'Sanga-Sanga Airport': {'lat': 5.0444, 'lng': 119.7408},
    'Tawi-Tawi Provincial Capitol': {'lat': 5.0315, 'lng': 119.7745},
    'Bongao Municipal Hall': {'lat': 5.0280, 'lng': 119.7730},

    // --- Major Schools & Universities ---
    'MSU-TCTO Campus': {'lat': 5.0414, 'lng': 119.7825},
    'Mahardika Institute of Technology': {'lat': 5.0289, 'lng': 119.7752},
    'Tawi-Tawi Regional Agricultural College': {'lat': 5.0350, 'lng': 119.7700},
    'Abubakar Computer Learning Center': {'lat': 5.0295, 'lng': 119.7725},
    'Bongao Central Elementary School': {'lat': 5.0305, 'lng': 119.7760},
    'Datu Halun Pilot School': {'lat': 5.0282, 'lng': 119.7740},

    // --- All 35 Barangays of Bongao ---
    'Brgy. Bongao Poblacion': {'lat': 5.0292, 'lng': 119.7736},
    'Brgy. Ipil': {'lat': 5.0420, 'lng': 119.7650},
    'Brgy. Kamagong': {'lat': 5.0380, 'lng': 119.7710},
    'Brgy. Karungdong': {'lat': 5.0150, 'lng': 119.7850},
    'Brgy. Lagasan': {'lat': 5.0480, 'lng': 119.7550},
    'Brgy. Lakit Lakit': {'lat': 5.0500, 'lng': 119.7600},
    'Brgy. Lamion': {'lat': 5.0340, 'lng': 119.7810},
    'Brgy. Lapid Lapid': {'lat': 5.0550, 'lng': 119.7900},
    'Brgy. Lato Lato': {'lat': 5.0600, 'lng': 119.7950},
    'Brgy. Luuk Pandan': {'lat': 5.0450, 'lng': 119.7750},
    'Brgy. Luuk Tulay': {'lat': 5.0430, 'lng': 119.7720},
    'Brgy. Malassa': {'lat': 5.0400, 'lng': 119.7600},
    'Brgy. Mandulan': {'lat': 5.0650, 'lng': 119.8000},
    'Brgy. Masantong': {'lat': 5.0360, 'lng': 119.7850},
    'Brgy. Montay Montay': {'lat': 5.0520, 'lng': 119.7820},
    'Brgy. Nalil': {'lat': 5.0385, 'lng': 119.7500},
    'Brgy. Pababag': {'lat': 5.0250, 'lng': 119.7900},
    'Brgy. Pag-asa': {'lat': 5.0320, 'lng': 119.7750},
    'Brgy. Pagasinan': {'lat': 5.0310, 'lng': 119.7800},
    'Brgy. Pagatpat': {'lat': 5.0490, 'lng': 119.7680},
    'Brgy. Pahut': {'lat': 5.0460, 'lng': 119.7500},
    'Brgy. Pakias': {'lat': 5.0475, 'lng': 119.7450},
    'Brgy. Paniongan': {'lat': 5.0505, 'lng': 119.7350},
    'Brgy. Pasiagan': {'lat': 5.0330, 'lng': 119.7650},
    'Brgy. Sanga-Sanga': {'lat': 5.0450, 'lng': 119.7450},
    'Brgy. Silubog': {'lat': 5.0580, 'lng': 119.7780},
    'Brgy. Simandagit': {'lat': 5.0381, 'lng': 119.7801},
    'Brgy. Sumangat': {'lat': 5.0550, 'lng': 119.7400},
    'Brgy. Tarawakan': {'lat': 5.0800, 'lng': 119.8100},
    'Brgy. Tongsinah': {'lat': 5.0300, 'lng': 119.7820},
    'Brgy. Tubig Basag': {'lat': 5.0350, 'lng': 119.7740},
    'Brgy. Tubig Tanah': {'lat': 5.0325, 'lng': 119.7710},
    'Brgy. Tubig-Boh': {'lat': 5.0335, 'lng': 119.7780},
    'Brgy. Tubig-Mampallam': {'lat': 5.0318, 'lng': 119.7765},
    'Brgy. Ungus-ungus': {'lat': 5.0260, 'lng': 119.7700},
  };

  // 2. The standard Haversine formula to calculate distance in Kilometers
  static double getDistanceInKm(String origin, String destination) {
    final start = bongaoLocations[origin];
    final end = bongaoLocations[destination];

    // If a location is missing from the list, return 0
    if (start == null || end == null) return 0.0; 

    double lat1 = start['lat']!;
    double lon1 = start['lng']!;
    double lat2 = end['lat']!;
    double lon2 = end['lng']!;

    var p = 0.017453292519943295; // Math.PI / 180 (Convert to radians)
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
        (1 - cos((lon2 - lon1) * p)) / 2;

    double straightLineDistance = 12742 * asin(sqrt(a)); // 2 * R (Earth Radius = 6371 km)
    
    // Multiply by 1.3 to account for road curves, since roads aren't perfectly straight!
    return straightLineDistance * 1.3; 
  }
}