    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';
    import 'package:firebase_auth/firebase_auth.dart';
    import 'package:untitled/widget/auth.dart';
    import 'package:untitled/pages/cambia_password.dart';
    import 'package:untitled/widget/notifiche.dart';

    class Profilo extends StatelessWidget {
      Profilo({super.key});

      final User? user = Auth().currentUser;

      Future<void> signOut() async {
        await Auth().signOut();
      }

      @override
      Widget build(BuildContext context) {
        final email = user?.email ?? 'Nessuna email';
        final displayName = user?.displayName ?? 'Utente';
        final initials = displayName.isNotEmpty
            ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
            : '?';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 60),

                Text(
                  'Profilo',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A4A5C),
                  ),
                ),

                const SizedBox(height: 28),

                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A9CC6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7A9CC6).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A4A5C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF8A9BB5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Account',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A4A5C),
                  ),
                ),
                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                ),
                const SizedBox(height: 10),
                _InfoCard(
                  icon: Icons.verified_user_outlined,
                  label: 'Email verificata',
                  value: (user?.emailVerified ?? false) ? 'Sì' : 'No',
                ),
                const SizedBox(height: 10),
                _InfoCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Registrato il',
                  value: user?.metadata.creationTime != null
                      ? _formatDate(user!.metadata.creationTime!)
                      : '—',
                ),

                const SizedBox(height: 32),

                Text(
                  'Impostazioni',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A4A5C),
                  ),
                ),
                const SizedBox(height: 12),

                _ActionTile(
                  icon: Icons.lock_outline,
                  label: 'Cambia password',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CambioPassword( )),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifiche',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Notifiche()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Informazioni sull\'app',
                  onTap: () {
                    showDialog(
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
                            children: [

                              // Icona app
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EEF7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF7A9CC6),
                                  size: 30,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'TwentyOne',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A4A5C),
                                ),
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                'Versione 1.0.0',
                                style: TextStyle(
                                  color: Color(0xFF8A9BB5),
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 16),

                              const Divider(color: Color(0xFFE8EEF7)),

                              const SizedBox(height: 16),

                              const Text(
                                'Ogni grande cambiamento inizia con 21 giorni di costanza. Traccia i tuoi progressi e trasforma le tue intenzioni in abitudini reali.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF8A9BB5),
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                '© 2026 Massimo Minni',
                                style: TextStyle(
                                  color: Color(0xFFB0BEC5),
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 24),

                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EEF7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Chiudi',
                                      style: TextStyle(
                                        color: Color(0xFF3A4A5C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () async {
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
                                'Esci dall\'account',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A4A5C),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sei sicuro di voler uscire?',
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
                                            'Esci',
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
                    if (conferma == true) await signOut();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Esci dall\'account',
                        style: TextStyle(
                          color: Color(0xFFE57373),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }

      String _formatDate(DateTime date) {
        return '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';
      }
    }

    class _InfoCard extends StatelessWidget {
      final IconData icon;
      final String label;
      final String value;

      const _InfoCard({
        required this.icon,
        required this.label,
        required this.value,
      });

      @override
      Widget build(BuildContext context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF7A9CC6)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8A9BB5),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF3A4A5C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
    }

    class _ActionTile extends StatelessWidget {
      final IconData icon;
      final String label;
      final VoidCallback onTap;

      const _ActionTile({
        required this.icon,
        required this.label,
        required this.onTap,
      });

      @override
      Widget build(BuildContext context) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF7A9CC6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF3A4A5C),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8A9BB5)),
              ],
            ),
          ),
        );
      }
    }