/// Local Philippines venue lookup. Names and hole cards follow
/// `docs/context/PH_Golf_Venues.md`. Courses without a published hole card
/// are searchable and do not override par.
class PhGolfCourse {
  const PhGolfCourse({
    required this.name,
    required this.region,
    required this.holes,
    required this.totalPar,
    this.holePars,
  });

  final String name;
  final String region;
  final int holes;
  final int totalPar;

  /// Official par for each hole, or null when no card is published.
  /// Mount Malarayat stores its published nine once.
  final List<int>? holePars;

  bool get hasCard => holePars != null;
}

class PhGolfCatalog {
  PhGolfCatalog._();

  static const courses = <PhGolfCourse>[
    PhGolfCourse(
      name: 'Alabang Country Club',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 5, 4, 4, 3, 5, 3, 4, 4, 4, 3, 5, 4, 3, 4, 4, 5],
    ),
    PhGolfCourse(
      name: 'Camp Aguinaldo Golf Club',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 68,
      holePars: [4, 3, 5, 5, 4, 4, 4, 3, 4, 5, 3, 3, 3, 4, 3, 3, 3, 5],
    ),
    PhGolfCourse(
      name: 'Club Intramuros Golf Course',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 66,
      holePars: [3, 4, 3, 4, 4, 3, 5, 4, 4, 3, 4, 3, 4, 4, 4, 3, 4, 3],
    ),
    PhGolfCourse(
      name: 'Manila Golf and Country Club',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 71,
      holePars: [4, 4, 3, 5, 4, 3, 5, 4, 4, 4, 3, 4, 4, 3, 5, 3, 4, 5],
    ),
    PhGolfCourse(
      name: 'Philippine Army Golf Club (Kagitingan)',
      region: 'Metro Manila',
      holes: 9,
      totalPar: 33,
      holePars: [4, 3, 4, 3, 4, 4, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'Philippine Navy Golf Club',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 70,
      holePars: [5, 4, 3, 4, 3, 4, 4, 3, 5, 3, 4, 3, 5, 5, 5, 3, 3, 4],
    ),
    PhGolfCourse(
      name: 'Southlinks Golf Club',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Veterans Golf Club',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 70,
      holePars: [4, 3, 3, 4, 5, 4, 4, 3, 4, 4, 4, 4, 3, 3, 5, 4, 5, 4],
    ),
    PhGolfCourse(
      name: 'Villamor Golf Club',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 5, 4, 3, 4, 4, 4, 3, 5],
    ),
    PhGolfCourse(
      name: 'Wack Wack Golf & Country Club — East',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 4, 4, 5, 4, 4, 3, 4, 4, 4, 4, 5, 4, 4, 3, 4, 4],
    ),
    PhGolfCourse(
      name: 'Wack Wack Golf & Country Club — West',
      region: 'Metro Manila',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 5, 4, 4, 5, 3, 4, 5, 3, 4, 5, 3, 4, 4, 4, 4],
    ),
    PhGolfCourse(
      name: 'Valley Golf & Country Club — South',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 4, 3, 5, 4, 5, 3, 4, 4, 5, 3, 4, 4, 4, 4, 5, 3],
    ),
    PhGolfCourse(
      name: 'Valley Golf & Country Club — North',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 4, 5, 3, 5, 3, 5, 5, 3, 3, 5, 4, 3, 5, 4, 4],
    ),
    PhGolfCourse(
      name: 'Forest Hills Golf & Country Club — Nicklaus',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 71,
      holePars: [4, 4, 4, 3, 4, 5, 3, 4, 4, 5, 4, 4, 3, 4, 3, 5, 4, 4],
    ),
    PhGolfCourse(
      name: 'Forest Hills Golf & Country Club — Palmer',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 4, 3, 4, 4, 4, 3, 5, 4, 4, 3, 4, 5, 3, 5, 4, 4],
    ),
    PhGolfCourse(
      name: 'Eastridge Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 3, 4, 4, 5, 4, 3, 4, 4, 4, 3, 5, 4, 4, 3, 4, 5],
    ),
    PhGolfCourse(
      name: 'Manila Southwoods — Masters Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 5, 3, 4, 4, 5, 4, 4, 4, 4, 3, 4, 5, 4, 3, 5],
    ),
    PhGolfCourse(
      name: 'Manila Southwoods — Legends Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 4, 4, 5, 3, 5, 4, 4, 4, 3, 4, 5, 4, 3, 5, 4],
    ),
    PhGolfCourse(
      name: 'The Orchard — Palmer Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 4, 4, 3, 5, 3, 4, 4, 4, 4, 3, 4, 5, 4, 3, 4, 5],
    ),
    PhGolfCourse(
      name: 'The Orchard — Player Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 5, 3, 4, 4, 4, 5, 4, 3, 5, 4, 3, 4, 4, 4, 5],
    ),
    PhGolfCourse(
      name: 'The Riviera Golf Club — Langer Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 71,
      holePars: [4, 4, 4, 3, 5, 4, 4, 3, 4, 5, 4, 3, 4, 4, 4, 5, 3, 4],
    ),
    PhGolfCourse(
      name: 'The Riviera Golf Club — Couples Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 4, 4, 4, 3, 5, 3, 4, 4, 5, 4, 4, 3, 4, 5, 3, 4],
    ),
    PhGolfCourse(
      name: 'Sherwood Hills Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 4, 5, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 5, 3, 4, 4],
    ),
    PhGolfCourse(
      name: 'Eagle Ridge G&CC — Nick Faldo Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 3, 5, 4, 3, 4, 4, 4, 4, 3, 5, 4, 5, 4, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'Eagle Ridge G&CC — Greg Norman Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 5, 3, 5, 4, 4, 3, 4, 4, 5, 4, 4, 3, 5, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'Eagle Ridge G&CC — Pete Dye Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Eagle Ridge G&CC — Isao Aoki Course',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'South Forbes Golf City',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 66,
    ),
    PhGolfCourse(
      name: 'Tagaytay Highlands International Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 5, 3, 4, 4, 4, 5, 3, 4],
    ),
    PhGolfCourse(
      name: 'Tagaytay Midlands Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 3, 4, 3, 5, 4, 4, 4, 4, 4, 3, 4, 4, 4, 5, 3, 5],
    ),
    PhGolfCourse(
      name: 'Royale Tagaytay Country Club',
      region: 'Calabarzon',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Splendido Taal Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [5, 5, 3, 4, 4, 4, 4, 3, 4, 4, 5, 4, 4, 4, 3, 4, 3, 5],
    ),
    PhGolfCourse(
      name: 'Canyon Woods Resort Club',
      region: 'Calabarzon',
      holes: 9,
      totalPar: 34,
    ),
    PhGolfCourse(
      name: 'The Country Club (TCC)',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 3, 4, 4, 3, 4, 5, 4, 5, 3, 4, 4, 5, 4, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'Sta. Elena Golf & Country Estate',
      region: 'Calabarzon',
      holes: 27,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Canlubang Golf & Country Club — North',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 4, 3, 4, 3, 4, 4, 5, 4, 3, 4, 4, 5, 3, 4, 5, 4],
    ),
    PhGolfCourse(
      name: 'Canlubang Golf & Country Club — South',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 4, 3, 4, 4, 4, 3, 5, 4, 5, 4, 3, 4, 4, 4, 3, 5],
    ),
    PhGolfCourse(
      name: 'Ayala Greenfield Golf & Leisure Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 3, 4, 4, 3, 4, 4, 5, 5, 3, 4, 5, 3, 4, 3, 5, 4],
    ),
    PhGolfCourse(
      name: 'Hallow Ridge Filipinas Golf (KC Filipinas)',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 4, 3, 5, 4, 4, 5, 4, 4, 3, 5, 4, 3, 4, 4, 5],
    ),
    PhGolfCourse(
      name: 'Caliraya Springs Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Mount Malarayat Golf & Country Club',
      region: 'Calabarzon',
      holes: 9,
      totalPar: 36,
      holePars: [4, 4, 4, 3, 5, 4, 5, 3, 4],
    ),
    PhGolfCourse(
      name: 'Summit Point Golf & Residential Estates',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 5, 4, 5, 3, 4, 3, 5, 4, 4, 4, 3, 5, 4, 5, 3, 4],
    ),
    PhGolfCourse(
      name: 'Fernando Air Base Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Calatagan Golf Club',
      region: 'Calabarzon',
      holes: 18,
      totalPar: 72,
      holePars: [5, 3, 4, 5, 4, 4, 4, 3, 4, 4, 3, 4, 5, 4, 4, 3, 4, 5],
    ),
    PhGolfCourse(
      name: 'Club Punta Fuego',
      region: 'Calabarzon',
      holes: 9,
      totalPar: 32,
    ),
    PhGolfCourse(
      name: 'Mimosa Plus Golf Course — Mountainview',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
      holePars: [5, 3, 4, 4, 5, 3, 4, 3, 4, 5, 4, 4, 5, 3, 4, 3, 4, 5],
    ),
    PhGolfCourse(
      name: 'Mimosa Plus Golf Course — Acacia Lakeview',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Clark Sun Valley Golf & Country Club — Clark',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 4, 5, 4, 5, 4, 3, 4, 5, 4, 4, 4, 3, 5, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'Clark Sun Valley Golf & Country Club — Sun Valley',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'FA Korea Country Club',
      region: 'Central and Northern Luzon',
      holes: 27,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Pradera Verde Golf & Country Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 4, 4, 5, 4, 3, 4, 5, 4, 3, 5, 4, 4, 4, 4, 3, 5],
    ),
    PhGolfCourse(
      name: 'Beverly Place Golf Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 71,
    ),
    PhGolfCourse(
      name: 'Air Force City Golf Club',
      region: 'Central and Northern Luzon',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Royal Garden Golf & Country Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 5, 4, 3, 4, 3, 5, 4, 5, 3, 4, 5, 4, 4, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'Luisita Golf & Country Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 4, 5, 3, 4, 4, 5, 3, 4],
    ),
    PhGolfCourse(
      name: 'Royal Northwoods Golf & Residential Estates',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
      holePars: [5, 4, 3, 4, 5, 4, 3, 4, 4, 4, 4, 3, 5, 4, 5, 3, 4, 4],
    ),
    PhGolfCourse(
      name: 'Lakewood Golf & Country Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Anvaya Cove Golf & Sports Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 4, 4, 4, 3, 4, 3, 5, 5, 4, 4, 3, 4, 5, 3, 4, 4],
    ),
    PhGolfCourse(
      name: 'Camaya Coast (Tandatangan Golf Course)',
      region: 'Central and Northern Luzon',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Subic International Golf Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Camp John Hay Golf Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 69,
      holePars: [5, 4, 4, 3, 4, 3, 4, 4, 4, 4, 3, 4, 3, 4, 3, 5, 5, 3],
    ),
    PhGolfCourse(
      name: 'Baguio Country Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 61,
      holePars: [3, 4, 4, 4, 4, 4, 3, 4, 3, 3, 4, 3, 3, 3, 3, 3, 3, 3],
    ),
    PhGolfCourse(
      name: 'Pinewoods Golf & Country Club',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'The Cliffs Golf & Beach Club',
      region: 'Central and Northern Luzon',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Paoay Golf Course (Fort Ilocandia)',
      region: 'Central and Northern Luzon',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Isabela Golf Club',
      region: 'Central and Northern Luzon',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Haciendas de Naga Golf Course',
      region: 'Central and Northern Luzon',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Cebu Country Club',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 3, 4, 3, 4, 5, 4, 4, 4, 5, 4, 3, 4, 3, 5, 4, 4],
    ),
    PhGolfCourse(
      name: 'Alta Vista Golf & Country Club',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 4, 4, 4, 3, 5, 3, 5, 5, 4, 4, 3, 4, 3, 5, 4, 5],
    ),
    PhGolfCourse(
      name: 'Mactan Island Golf Club',
      region: 'Visayas',
      holes: 18,
      totalPar: 69,
      holePars: [4, 3, 4, 5, 3, 4, 5, 4, 3, 4, 4, 3, 3, 3, 5, 4, 4, 4],
    ),
    PhGolfCourse(
      name: 'Club Filipino Inc. de Cebu',
      region: 'Visayas',
      holes: 18,
      totalPar: 71,
      holePars: [4, 4, 4, 3, 4, 5, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'Liloan Golf & Leisure Estate',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Queens Island Golf and Resort',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Mercedes Plantation Golf & Country Club',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Cebu International Golf and Resort',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Fairways and Bluewater Resort',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 4, 4, 5, 4, 3, 4, 5, 5, 3, 4, 4, 5, 4, 3, 4, 4],
    ),
    PhGolfCourse(
      name: 'Iloilo Golf & Country Club (Santa Barbara)',
      region: 'Visayas',
      holes: 18,
      totalPar: 70,
      holePars: [4, 4, 4, 5, 3, 4, 4, 4, 4, 3, 4, 4, 3, 5, 4, 3, 4, 4],
    ),
    PhGolfCourse(
      name: 'Negros Occidental (Marapara) G&CC',
      region: 'Visayas',
      holes: 18,
      totalPar: 70,
      holePars: [4, 5, 3, 4, 4, 4, 4, 3, 4, 4, 4, 4, 3, 4, 4, 3, 4, 5],
    ),
    PhGolfCourse(
      name: 'Bacolod Golf & Country Club (Binitinan)',
      region: 'Visayas',
      holes: 18,
      totalPar: 70,
      holePars: [4, 4, 3, 4, 5, 4, 4, 3, 4, 3, 4, 4, 4, 4, 5, 4, 4, 3],
    ),
    PhGolfCourse(
      name: 'Victorias Golf & Country Club',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Negros International Golf & Country Club',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'San Juanico Golf and Country Club',
      region: 'Visayas',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Apo Golf & Country Club',
      region: 'Mindanao',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 5, 3, 4, 5, 3, 4, 4, 4, 3, 4, 5, 4, 4, 4, 3, 5],
    ),
    PhGolfCourse(
      name: 'Rancho Palos Verdes Golf & Country Club',
      region: 'Mindanao',
      holes: 18,
      totalPar: 72,
      holePars: [5, 3, 4, 4, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 5, 4, 3, 4],
    ),
    PhGolfCourse(
      name: 'South Pacific Golf & Leisure Estates',
      region: 'Mindanao',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 3, 4, 3, 4, 5, 4, 4, 4, 4, 5, 3, 4, 3, 4, 4, 5],
    ),
    PhGolfCourse(
      name: 'Lanang Country Club',
      region: 'Mindanao',
      holes: 18,
      totalPar: 72,
      holePars: [4, 5, 4, 4, 3, 5, 4, 3, 4, 4, 3, 5, 4, 4, 4, 5, 3, 4],
    ),
    PhGolfCourse(
      name: 'Del Monte Golf Club',
      region: 'Mindanao',
      holes: 18,
      totalPar: 72,
      holePars: [4, 4, 3, 4, 4, 5, 3, 4, 5, 4, 4, 3, 4, 5, 4, 3, 4, 5],
    ),
    PhGolfCourse(
      name: 'Pueblo de Oro Golf & Country Club',
      region: 'Mindanao',
      holes: 18,
      totalPar: 72,
      holePars: [4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 4, 3, 4, 5, 4, 5, 4],
    ),
    PhGolfCourse(
      name: 'Camp Evangelista Golf Club',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'West Highlands Golf Club',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Dole Kalsangi Golf Club',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Sarangani Golf & Country Club',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Brittannika Golf Club',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Dakak Golf Club',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Zamboanga Golf Course & Beach Park',
      region: 'Mindanao',
      holes: 18,
      totalPar: 72,
    ),
    PhGolfCourse(
      name: 'Edwin Andrews Air Base Golf Course',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Golf & Country Club of Iligan',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
    PhGolfCourse(
      name: 'Illana Bay Golf & Country Club',
      region: 'Mindanao',
      holes: 9,
      totalPar: 36,
    ),
  ];

  static const ranges = <String>[
    'CityGolf Driving Range',
    'Villamor Golf Driving Range',
    'Philippine Navy Driving Range',
    'Philippine Army (Kagitingan) Range',
    'Veterans Golf Club Driving Range',
    'Camp Aguinaldo Driving Range',
    'Southpoint Driving Range',
    'Royal Palm / Las Piñas Driving Range',
    'NUVALI Driving Range',
    'Teakwood Golf Driving Range',
    'Canlubang Lifestyle Center Range',
    'Hallow Ridge Driving Range',
    'BW Golf Driving Range',
    'Air Force City Golf Driving Range',
    'Camp Lapu-Lapu Golf Driving Range',
    'Davao Eaglemaster Golf Driving Range',
    "Winners' Golf Range",
    'Champion Golf Range',
  ];

  static const simulators = <String>[
    'GolfX Sports Hub — BGC',
    'Elite Tee Box',
    'Friends Screen Indoor Golf — Makati',
    'Joy Golf Science',
    'The Alpha Suites Indoor Golf',
    'Quantum Golf',
    'ParTee Golf — Pioneer',
    'Prime Golf',
    'Eastwing Golf',
    'Golf Life PH',
    'Swng Golf and Lounge',
    'ParTee Golf — Scout Gandia',
    'DN Golf',
    'Hole In Hub Golf and Lounge',
    'Foreplay Golf Lounge',
    'Golf Hack — Brittany Square',
    'The Tee Room',
    'Alpha Sports Alabang (Friends Screen)',
    'K-Golf — Alabang',
    'K-Golf — City of Dreams',
    'Blue Bird Golf',
    'G-Flex Screen Golf Lounge',
    'VIP Golf',
    'Golf Avenue',
    'ParTee Golf — Batangas',
    'The Golf Den',
    'Break100 Golf Simulator Lounge',
    'iSwing Golf Lounge — SM JMall',
    'iSwing Golf Lounge — Banawa',
    'Tiger Indoor Golf',
  ];

  static List<String> get courseNames =>
      [for (final course in courses) course.name];

  static List<String> get rangeAndSimNames => [...ranges, ...simulators];

  static PhGolfCourse? matchCourse(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final course in courses) {
      if (course.name.toLowerCase() == key) return course;
    }
    return null;
  }

  /// Card par for [holeNumber], or null when the name is unknown or the hole
  /// is past a published card.
  static int? parForHole(String name, int holeNumber) {
    final pars = matchCourse(name)?.holePars;
    if (pars == null || holeNumber < 1 || holeNumber > pars.length) return null;
    return pars[holeNumber - 1];
  }

  /// Holes on a published card, or 18 when the course is custom or has no card.
  static int holeCount(String name) =>
      matchCourse(name)?.holePars?.length ?? 18;

  /// `18 holes · par 72` for a published card. Custom and card-less names return null.
  static String? courseCaption(String name) {
    final course = matchCourse(name);
    final pars = course?.holePars;
    if (course == null || pars == null) return null;
    return '${course.holes} holes · par ${course.totalPar}';
  }
}
