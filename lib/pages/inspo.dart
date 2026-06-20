import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/quotes_data.dart';

const Color _bgColor = Color(0xFFF7F9FC);
const Color _cardBlue = Color(0xFFD6E4F5);
const Color _accentBlue = Color(0xFF7A9CC6);
const Color _textDark = Color(0xFF1E2A3A);
const Color _textMuted = Color(0xFF8A96A8);
const Color _white = Colors.white;

const List<String> _categories = ['Tutte', 'Disciplina', 'Abitudini', 'Mindset', 'Cambiamento', 'Coraggio', 'Gratitudine'];

class Inspo extends StatefulWidget {
  const Inspo({super.key});

  @override
  State<Inspo> createState() => _InspoState();
}

class _InspoState extends State<Inspo> {
  String _selectedCategory = 'Tutte';
  final Set<int> _favorites = {};
  bool _favoritiCaricati = false;

  @override
  void initState() {
    super.initState();
    _caricaPreferiti();
  }

  Future<void> _caricaPreferiti() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .get();
    final preferiti = List<int>.from(doc.data()?['preferiti'] ?? []);
    if (mounted) {
      setState(() {
        _favorites.addAll(preferiti);
        _favoritiCaricati = true;
      });
    }
  }

  Future<void> _salvaPreferiti() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .set({'preferiti': _favorites.toList()}, SetOptions(merge: true));
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
      }
    });
    _salvaPreferiti();
  }

  Quote get _quoteOfTheDay => getQuoteOfDay();

  List<Quote> get _filteredQuotes {
    final quoteOfTheDay = _quoteOfTheDay;
    return allQuotes.where((q) {
      if (q.text == quoteOfTheDay.text) return false;
      if (_selectedCategory == 'Tutte') return true;
      return q.category == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ispirazione',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Una citazione per ogni giorno del percorso',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: _textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FeaturedCard(
                      quote: _quoteOfTheDay,
                      isFavorite: _favorites.contains(allQuotes.indexOf(_quoteOfTheDay)),
                      onFavoriteTap: () => _toggleFavorite(allQuotes.indexOf(_quoteOfTheDay)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SFOGLIA PER TEMA',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategoryPills(
                      categories: _categories,
                      selected: _selectedCategory,
                      onSelect: (c) => setState(() => _selectedCategory = c),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final quote = _filteredQuotes[index];
                    final globalIndex = allQuotes.indexOf(quote);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuoteCard(
                        quote: quote,
                        isFavorite: _favorites.contains(globalIndex),
                        onFavoriteTap: () => _toggleFavorite(globalIndex),
                      ),
                    );
                  },
                  childCount: _filteredQuotes.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Quote quote;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _FeaturedCard({
    required this.quote,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC9D8F0), Color(0xFFDBE6F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -16,
            left: 16,
            child: Text(
              '\u201C',
              style: GoogleFonts.playfairDisplay(
                fontSize: 120,
                color: Colors.white.withValues(alpha: 0.35),
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✦  CITAZIONE DEL GIORNO',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: const Color(0xFF6A80A0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  quote.text,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    height: 1.6,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '— ${quote.author}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF6A80A0),
                        letterSpacing: 0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: isFavorite ? const Color(0xFFE57373) : _accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPills extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryPills({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((c) {
          final isSelected = c == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _accentBlue : _white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  c,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: isSelected ? _white : const Color(0xFF5A6A80),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _QuoteCard({
    required this.quote,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u201C',
              style: GoogleFonts.playfairDisplay(
                fontSize: 40,
                color: _cardBlue,
                height: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quote.text,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                height: 1.65,
                color: const Color(0xFF2C3E55),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '— ${quote.author}',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: _textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 14,
                      color: isFavorite ? const Color(0xFFE57373) : _textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

