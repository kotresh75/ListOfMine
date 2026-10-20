class MovieSearchResult {
  final String title;
  final String year;
  final String directorOrArtist;
  final String genre;
  final String overview;
  final String posterUrl;
  final double rating;
  final String source; // 'tmdb' or 'itunes'

  const MovieSearchResult({
    required this.title,
    this.year = '',
    this.directorOrArtist = '',
    this.genre = '',
    this.overview = '',
    this.posterUrl = '',
    this.rating = 0.0,
    this.source = 'remote',
  });

  /// Factory for parsing iTunes search results
  factory MovieSearchResult.fromITunes(Map<String, dynamic> map) {
    final title = (map['trackName'] ?? map['collectionName'] ?? '').toString();
    final artist = (map['artistName'] ?? '').toString();
    final releaseDate = (map['releaseDate'] ?? '').toString();
    String year = '';
    if (releaseDate.length >= 4) {
      year = releaseDate.substring(0, 4);
    }
    final genre = (map['primaryGenreName'] ?? '').toString();
    final overview = (map['longDescription'] ?? map['shortDescription'] ?? '').toString();
    
    // Convert 100x100 artwork to higher resolution (600x600)
    String rawArtwork = (map['artworkUrl100'] ?? map['artworkUrl60'] ?? '').toString();
    String posterUrl = rawArtwork.replaceAll('100x100bb', '600x600bb');

    return MovieSearchResult(
      title: title,
      year: year,
      directorOrArtist: artist,
      genre: genre,
      overview: overview,
      posterUrl: posterUrl,
      source: 'itunes',
    );
  }

  /// Factory for parsing TMDB search results
  factory MovieSearchResult.fromTMDB(Map<String, dynamic> map) {
    final title = (map['title'] ?? map['name'] ?? '').toString();
    final releaseDate = (map['release_date'] ?? '').toString();
    String year = '';
    if (releaseDate.length >= 4) {
      year = releaseDate.substring(0, 4);
    }
    final overview = (map['overview'] ?? '').toString();
    final posterPath = (map['poster_path'] ?? '').toString();
    final posterUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';
    final voteAverage = (map['vote_average'] as num?)?.toDouble() ?? 0.0;
    // Normalize 10-point scale to 5-star scale
    final rating = (voteAverage / 2.0).clamp(0.0, 5.0);

    return MovieSearchResult(
      title: title,
      year: year,
      overview: overview,
      posterUrl: posterUrl,
      rating: double.parse(rating.toStringAsFixed(1)),
      source: 'tmdb',
    );
  }
}
