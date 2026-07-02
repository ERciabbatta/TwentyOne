import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/widget/quotes_data.dart';
import 'package:twentyone/widget/app_colors.dart';

// Categorie disponibili per filtrare le citazioni nella schermata Ispirazione
const List<String> _categories = ['Tutte', 'Disciplina', 'Abitudini', 'Mindset', 'Cambiamento', 'Coraggio', 'Gratitudine'];

/// Schermata di ispirazione che presenta la citazione del giorno e una raccolta filtrabile
/// di frasi motivazionali tratte da [allQuotes], con possibilità di aggiungere preferiti.
class Inspo extends StatefulWidget {
  const Inspo({super.key});

  @override
  State<Inspo> createState() => _InspoState();
}

class _InspoState extends State<Inspo> {
  // Categoria attualmente selezionata per filtrare le citazioni
  String _selectedCategory = 'Tutte';
  
  // Indici delle citazioni salvate tra i preferiti dall'utente
  final Set<int> _favorites = {};
  
  // true una volta terminato il caricamento dei preferiti da Firestore
  bool _favoritiCaricati = false;

  @override
  void initState() {
    super.initState();
    _caricaPreferiti();
  }

  /// Carica da Firestore la lista degli indici delle citazioni preferite dell'utente.
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

  /// Persiste su Firestore l'insieme corrente degli indici dei preferiti.
  Future<void> _salvaPreferiti() async {
    final uid = Auth().currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .set({'preferiti': _favorites.toList()}, SetOptions(merge: true));
  }

  /// Aggiunge o rimuove una citazione dai preferiti e salva la modifica su Firestore.
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

  /// Restituisce la citazione del giorno, calcolata in modo deterministico dalla data odierna.
  Quote get _quoteOfTheDay => getQuoteOfDay();

  /// Restituisce le citazioni filtrate per categoria (esclusa la citazione del giorno)
  /// in base alla selezione corrente di [_selectedCategory].
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
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
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
                        color: colors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Una citazione per ogni giorno del percorso',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: colors.textSecondary,
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
                        color: colors.textSecondary,
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
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withValues(alpha: 0.35),
            colors.accentGradientEnd.withValues(alpha: 0.35),
          ],
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
                color: colors.textOnAccent.withValues(alpha: 0.35),
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
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  quote.text,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    height: 1.6,
                    color: colors.textPrimary,
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
                        color: colors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.card,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: isFavorite ? colors.error : colors.accent,
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
    final colors = AppColors.of(context);
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
                  color: isSelected ? colors.accent : colors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  c,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: isSelected ? colors.textOnAccent : colors.textSecondary,
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
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
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
                color: colors.surfaceSelected,
                height: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quote.text,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                height: 1.65,
                color: colors.textPrimary,
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
                    color: colors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 14,
                      color: isFavorite ? colors.error : colors.textSecondary,
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

