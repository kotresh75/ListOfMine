import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie_search_result.dart';

class MovieService {
  static const String _tmdbApiKeyPref = 'listofmine_tmdb_api_key';

  /// Default popular suggestions shown before user enters a search query
  static final List<MovieSearchResult> curatedPopularSuggestions = [
    const MovieSearchResult(
      title: 'Interstellar',
      year: '2014',
      directorOrArtist: 'Christopher Nolan',
      genre: 'Sci-Fi & Adventure',
      overview: 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
      posterUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Video5/v4/94/0b/4e/940b4e58-6628-dfb4-2565-5521c11dcdd4/pr_source.lsr/600x600bb.jpg',
      rating: 4.8,
    ),
    const MovieSearchResult(
      title: 'Dune: Part Two',
      year: '2024',
      directorOrArtist: 'Denis Villeneuve',
      genre: 'Sci-Fi & Action',
      overview: 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
      posterUrl: '',
      rating: 4.7,
    ),
    const MovieSearchResult(
      title: 'Oppenheimer',
      year: '2023',
      directorOrArtist: 'Christopher Nolan',
      genre: 'Biography & Drama',
      overview: 'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb.',
      posterUrl: '',
      rating: 4.6,
    ),
    const MovieSearchResult(
      title: 'Spirited Away',
      year: '2001',
      directorOrArtist: 'Hayao Miyazaki',
      genre: 'Animation & Fantasy',
      overview: 'During her family\'s move to the suburbs, a sullen 10-year-old girl wanders into a world ruled by gods, witches, and spirits.',
      posterUrl: '',
      rating: 4.9,
    ),
  ];

  static Future<String?> getTmdbApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_tmdbApiKeyPref);
    if (key != null && key.trim().isNotEmpty) {
      return key.trim();
    }
    return null;
  }

  static Future<void> saveTmdbApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tmdbApiKeyPref, apiKey.trim());
  }

  /// Search movies using TMDB (if key available) or fallback to Open iTunes Movie Catalog
  static Future<List<MovieSearchResult>> searchMovies(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return curatedPopularSuggestions;
    }

    final tmdbKey = await getTmdbApiKey();

    if (tmdbKey != null) {
      try {
        final tmdbResults = await _searchTMDB(trimmed, tmdbKey);
        if (tmdbResults.isNotEmpty) {
          return tmdbResults;
        }
      } catch (e) {
        debugPrint('TMDB search error: $e. Falling back to open catalog...');
      }
    }

    // Fallback: Open Movie Catalog (Zero API Key required)
    return await _searchOpenCatalog(trimmed);
  }

  static Future<List<MovieSearchResult>> _searchTMDB(
    String query,
    String apiKey,
  ) async {
    final url = Uri.parse(
      'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(query)}&include_adult=false&language=en-US&page=1',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final rawResults = decoded['results'] as List<dynamic>? ?? [];
      return rawResults
          .map((item) => MovieSearchResult.fromTMDB(item as Map<String, dynamic>))
          .where((m) => m.title.isNotEmpty)
          .take(15)
          .toList();
    }
    return [];
  }

  static Future<List<MovieSearchResult>> _searchOpenCatalog(String query) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&country=US&limit=25',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final rawResults = decoded['results'] as List<dynamic>? ?? [];

        final List<MovieSearchResult> results = [];
        for (final item in rawResults) {
          if (item is Map<String, dynamic>) {
            final kind = item['kind']?.toString() ?? '';
            final trackName = item['trackName']?.toString() ?? '';
            // Match feature movies or items with movie metadata
            if ((kind == 'feature-movie' || kind.isEmpty) && trackName.isNotEmpty) {
              results.add(MovieSearchResult.fromITunes(item));
            }
          }
        }
        return results.take(15).toList();
      }
    } catch (e) {
      debugPrint('Error searching open movie catalog: $e');
    }
    return [];
  }
}
