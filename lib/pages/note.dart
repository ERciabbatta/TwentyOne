import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/widget/crea_nota.dart';

class Note extends StatefulWidget {
  const Note({super.key});

  @override
  State<Note> createState() => _NoteState();
}

class _NoteState extends State<Note> {

  Stream<QuerySnapshot> _noteStream() {
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('utenti')
        .doc(user!.uid)
        .collection('note')
        .orderBy('inizio', descending: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    color: const Color(0xFF3A4A5C),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CreaNota(),
                    );
                  },
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    size: 40,
                    color: Color(0xFF7A9CC6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: _noteStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'Nessuna nota',
                        style: const TextStyle(
                          color: Color(0xFF8A9BB5),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }

                final note = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: note.length,
                  itemBuilder: (context, index) {
                    final nota = note[index].data() as Map<String, dynamic>;
                    final docId = note[index].id;

                    return GestureDetector(
                      onLongPress: () async {
                        final conferma = await showDialog<bool>(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
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
                                      color: const Color(0xFF3A4A5C),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Sei sicuro di voler eliminare questa nota?',
                                    style: TextStyle(
                                      color: Color(0xFF8A9BB5),
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
                                              color: const Color(0xFFE8EEF7),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Annulla',
                                                style: TextStyle(
                                                  color: Color(0xFF3A4A5C),
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
                                              color: const Color(0xFFFFE8E8),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Elimina',
                                                style: TextStyle(
                                                  color: Color(0xFFE57373),
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
                          await FirebaseFirestore.instance
                              .collection('utenti')
                              .doc(user!.uid)
                              .collection('note')
                              .doc(docId)
                              .delete();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEF7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Color(0xFF8A9BB5)),
                            const SizedBox(width: 6),
                            Text(
                              nota['inizio'] ?? '',
                              style: const TextStyle(
                                color: Color(0xFF8A9BB5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nota['testo'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF3A4A5C),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              nota['fine'] ?? '',
                              style: const TextStyle(
                                color: Color(0xFF8A9BB5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 10);
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
}