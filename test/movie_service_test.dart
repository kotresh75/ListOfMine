import 'package:flutter_test/flutter_test.dart';
import 'package:listofmine/models/movie_search_result.dart';
import 'package:listofmine/services/movie_service.dart';

void main() {
  group('MovieSearchResult & MovieService Tests', () {
    test('MovieSearchResult.fromITunes parsing', () {
      final sample = {
        'trackName': 'Inception',
        'artistName': 'Christopher Nolan',
        'releaseDate': '2010-07-16T07:00:00Z',
        'primaryGenreName': 'Action & Adventure',
        'longDescription': 'Dom Cobb is a skilled thief who steals valuable secrets from deep within the subconscious.',
        'artworkUrl100': 'https://example.com/100x100bb.jpg',
      };

      final result = MovieSearchResult.fromITunes(sample);
      expect(result.title, 'Inception');
      expect(result.directorOrArtist, 'Christopher Nolan');
      expect(result.year, '2010');
      expect(result.genre, 'Action & Adventure');
      expect(result.posterUrl, 'https://example.com/600x600bb.jpg');
      expect(result.source, 'itunes');
    });

    test('MovieSearchResult.fromTMDB parsing', () {
      final sample = {
        'title': 'The Dark Knight',
        'release_date': '2008-07-18',
        'overview': 'Batman raises the stakes in his war on crime.',
        'poster_path': '/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
        'vote_average': 8.5,
      };

      final result = MovieSearchResult.fromTMDB(sample);
      expect(result.title, 'The Dark Knight');
      expect(result.year, '2008');
      expect(result.posterUrl, 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg');
      expect(result.rating, 4.3); // 8.5 / 2 = 4.25 -> 4.3
      expect(result.source, 'tmdb');
    });

    test('MovieService empty search returns curated suggestions', () async {
      final results = await MovieService.searchMovies('');
      expect(results.isNotEmpty, true);
      expect(results.first.title, 'Interstellar');
    });
  });
}
