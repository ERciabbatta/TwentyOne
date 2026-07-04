import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twentyone/widget/auth.dart';
import 'package:twentyone/pages/cambia_password.dart';
import 'package:twentyone/pages/notifiche.dart';
import 'package:twentyone/pages/obiettivo.dart';
import 'package:twentyone/pages/statistiche.dart';
import 'package:twentyone/widget/app_colors.dart';
import 'package:twentyone/main.dart';
import 'package:twentyone/widget/badges_data.dart';

/// Schermata del profilo utente.
/// Mostra le informazioni dell'account, l'obiettivo personale,
/// le impostazioni (tema, notifiche, password) e le azioni (logout, eliminazione account).
class Profilo extends StatefulWidget {
  const Profilo({super.key});

  @override
  State<Profilo> createState() => _ProfiloState();
}

class _ProfiloState extends State<Profilo> {
  // Utente Firebase attualmente autenticato
  final User? user = Auth().currentUser;
  List<String> _badges = [];

  // Testo dell'obiettivo personale dell'utente
  String _obiettivo = '';

  @override
  void initState() {
    super.initState();
    _caricaObiettivo();
    _caricaBadge();
  }

  /// Recupera l'obiettivo dell'utente da Firestore per mostrarlo nella schermata profilo.
  Future<void> _caricaObiettivo() async {
    final uid = user?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .get();
    final ob = doc.data()?['obiettivo'] as String? ?? '';
    if (mounted) setState(() => _obiettivo = ob);
  }

  /// Carica i badge sbloccati dell'utente da Firestore.
  Future<void> _caricaBadge() async {
    final uid = user?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .get();
    final badges = List<String>.from(doc.data()?['badges'] ?? []);
    if (mounted) setState(() => _badges = badges);
  }

  /// Effettua il logout dell'utente corrente tramite Firebase Auth.
  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email       = user?.email ?? 'Nessuna email';
    final displayName = user?.displayName ?? 'Utente';
    final initials    = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
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
                color: colors.textPrimary,
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
                      color: colors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.3),
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
                          color: colors.textOnAccent,
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
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            if (_obiettivo.isNotEmpty) ...[
              Text(
                'Il mio obiettivo',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, color: colors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _obiettivo,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            Text(
              'Account',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _InfoCard(icon: Icons.email_outlined, label: 'Email', value: email),
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
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _ActionTile(
              icon: Icons.flag_rounded,
              label: 'Il mio obiettivo',
              onTap: () async {
                final nuovo = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnboardingObiettivo(modifica: true),
                  ),
                );
                if (nuovo != null) setState(() => _obiettivo = nuovo);
              },
            ),
            const SizedBox(height: 10),

            _ActionTile(
              icon: Icons.bar_chart_rounded,
              label: 'Statistiche',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Statistiche()),
                );
              },
            ),
            const SizedBox(height: 10),

            _ActionTile(
              icon: Icons.lock_outline,
              label: 'Cambia password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CambioPassword()),
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

            _ThemeToggleTile(colors: colors),
            const SizedBox(height: 10),

            // Badge Section
            const SizedBox(height: 32),
            Text(
              'Badge',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final badge = allBadges[index];
                final unlocked = _badges.contains(badge.id);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tapping a badge opens a dialog showing its name and description
                    GestureDetector(
                      onTap: () => _mostraDialogBadge(badge.name, badge.description),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: unlocked ? colors.accent.withValues(alpha: 0.2) : colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          badge.icon,
                          size: 28,
                          color: unlocked ? colors.accent : colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.name,
                      style: TextStyle(color: unlocked ? colors.accent : colors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

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
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.auto_awesome_rounded,
                                color: colors.accent, size: 30),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'TwentyOne',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Versione 1.4.3',
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: colors.surface),
                          const SizedBox(height: 16),
                          Text(
                            'Ogni grande cambiamento inizia con 21 giorni di costanza. Traccia i tuoi progressi e trasforma le tue intenzioni in abitudini reali.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                                height: 1.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2026 Massimo Minni',
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: double.infinity,
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  'Chiudi',
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600),
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
                            'Esci dall\'account',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sei sicuro di voler uscire?',
                            style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                                height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Annulla',
                                        style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: colors.errorBackground,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Esci',
                                        style: TextStyle(
                                            color: colors.error,
                                            fontWeight: FontWeight.w600),
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
                  color: colors.errorBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Esci dall\'account',
                    style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
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

  /// Formatta una data [DateTime] nel formato leggibile "GG/MM/AAAA".
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Mostra un dialog con nome e descrizione del badge selezionato.
  void _mostraDialogBadge(String badgeNome, String badgeDescrizione) {
    showDialog(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '🏆 Nuovo Badge!',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.stars_rounded, color: colors.accent, size: 60),
              ),
              const SizedBox(height: 16),
              Text(
                badgeNome,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badgeDescrizione,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Fantastico!',
                style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Card informativa in sola lettura per mostrare un dato del profilo (es. email, data di registrazione).
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Tile per alternare tra tema chiaro e tema scuro.
/// Ascolta le modifiche di [themeProvider] tramite [ListenableBuilder]
/// per aggiornare lo stato dello switch in tempo reale.
class _ThemeToggleTile extends StatelessWidget {
  final AppColors colors;

  const _ThemeToggleTile({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                themeProvider.isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                size: 18,
                color: colors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tema scuro',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggle(),
                activeThumbColor: colors.accent,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tile tappabile per azioni di navigazione delle impostazioni (es. Notifiche, Cambia password).
/// Mostra un'icona, un'etichetta testuale e una freccia di navigazione.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}