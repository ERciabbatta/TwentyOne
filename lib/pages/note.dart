import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twentyone/widget/crea_nota.dart';
import 'package:twentyone/widget/app_colors.dart';

/// Schermata del diario delle note.
/// Mostra le note settimanali dell'utente con possibilità di filtrarle per giorno
/// e di aggiungerne di nuove tramite il widget [CreaNota].
class Note extends StatefulWidget {
  const Note({super.key});

  @override
  State<Note> createState() => _NoteState();
}

class _NoteState extends State<Note> {
  // Abbreviazioni dei giorni della settimana per il selettore orizzontale
  final List<String> _giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  
  // Indice del giorno della settimana attualmente selezionato (0 = lunedì)
  late int _giornoSelezionato;

  @override
  void initState() {
    super.initState();
    // Pre-seleziona il giorno corrente all'apertura della schermata
    _giornoSelezionato = DateTime.now().weekday - 1;
  }

  /// Stream che emette in tempo reale le note dell'utente da Firestore,
  /// ordinate per orario di inizio crescente.
  Stream<QuerySnapshot> _noteStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('utenti')
        .doc(user.uid)
        .collection('note')
        .orderBy('inizio', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 60),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Note',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CreaNota(
                        giornoPreselezionato: _giornoSelezionato,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.add_circle_rounded,
                    size: 40,
                    color: colors.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_giorni.length, (index) {
                final selezionato = index == _giornoSelezionato;
                return GestureDetector(
                  onTap: () => setState(() => _giornoSelezionato = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selezionato
                          ? colors.accent
                          : colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _giorni[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selezionato
                                ? colors.textOnAccent
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            StreamBuilder<QuerySnapshot>(
              stream: _noteStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _nessunaNota();
                }

                final note = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final giorni = List<int>.from(data['giorni'] ?? []);
                  return giorni.contains(_giornoSelezionato);
                }).toList();

                if (note.isEmpty) return _nessunaNota();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: note.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final nota = note[index].data() as Map<String, dynamic>;
                    final docId = note[index].id;
                    return _buildNotaCard(nota, docId);
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _nessunaNota() {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text(
          'Nessuna nota per questo giorno',
          style: TextStyle(color: colors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildNotaCard(Map<String, dynamic> nota, String docId) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onLongPress: () async {
        final conferma = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elimina nota',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sei sicuro di voler eliminare questa nota?',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Annulla',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.errorBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Elimina',
                                style: TextStyle(
                                  color: colors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        if (conferma == true) {
          final user = FirebaseAuth.instance.currentUser;
          final docRef = FirebaseFirestore.instance
              .collection('utenti')
              .doc(user!.uid)
              .collection('note')
              .doc(docId);

          final giorni = List<int>.from((nota['giorni'] ?? []) as List);
          giorni.remove(_giornoSelezionato);

          if (giorni.isEmpty) {
            await docRef.delete();
          } else {
            await docRef.update({'giorni': giorni});
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              nota['inizio'] ?? '',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                nota['testo'] ?? '',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              nota['fine'] ?? '',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

