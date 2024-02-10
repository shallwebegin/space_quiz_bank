enum Complexity {
  kolay,
  orta,
  zor,
}

class Ders {
  const Ders({
    required this.id,
    required this.categories,
    required this.title,
    required this.imageUrl,
    required this.sorular,
    required this.cevaplar,
    required this.duration,
    required this.complexity,
    this.zor,
    this.orta,
    this.kolay,
  });

  final String id;
  final List<String> categories;
  final String title;
  final String imageUrl;
  final List<String> sorular;
  final List<String> cevaplar;
  final int duration;
  final Complexity complexity;

  final bool? zor;
  final bool? orta;
  final bool? kolay;
}
