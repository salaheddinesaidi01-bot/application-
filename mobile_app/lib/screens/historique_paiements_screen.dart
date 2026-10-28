import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cloture_mensuelle.dart';
import '../models/paiement_historique.dart';
import '../services/api_service.dart';

class HistoriquePaiementsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const HistoriquePaiementsScreen({super.key, this.onBack});

  @override
  State<HistoriquePaiementsScreen> createState() =>
      _HistoriquePaiementsScreenState();
}

class _HistoriquePaiementsScreenState extends State<HistoriquePaiementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 : Flux des paiements
  List<PaiementHistorique> _paiements = [];
  double _totalMontant = 0;
  int _totalCount = 0;
  bool _isLoadingPaiements = true;
  String? _errorPaiements;
  final _searchController = TextEditingController();

  // Tab 2 : Archives clôtures
  List<ClotureMensuelle> _clotures = [];
  bool _isLoadingClotures = true;
  String? _errorClotures;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerPaiements();
    _chargerClotures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerPaiements() async {
    setState(() {
      _isLoadingPaiements = true;
      _errorPaiements = null;
    });
    try {
      final res = await ApiService.getHistoriquePaiements(limit: 100);
      if (mounted) {
        setState(() {
          _paiements = res.paiements;
          _totalMontant = res.totalMontant.toDouble();
          _totalCount = res.totalCount;
          _isLoadingPaiements = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorPaiements = 'Erreur chargement paiements : $e';
          _isLoadingPaiements = false;
        });
      }
    }
  }

  Future<void> _chargerClotures() async {
    setState(() {
      _isLoadingClotures = true;
      _errorClotures = null;
    });
    try {
      final list = await ApiService.getCloturesMensuelles();
      if (mounted) {
        setState(() {
          _clotures = list;
          _isLoadingClotures = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorClotures = 'Erreur clôtures : $e';
          _isLoadingClotures = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Historique des Paiements',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF006A61),
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: const Color(0xFF006A61),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt_long_rounded, size: 20),
              text: 'Flux des Règlements',
            ),
            Tab(
              icon: Icon(Icons.archive_outlined, size: 20),
              text: 'Archives Clôtures',
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _chargerPaiements();
              _chargerClotures();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFluxTab(isDark),
          _buildCloturesTab(isDark),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1 : FLUX DES RÈGLEMENTS
  // -------------------------------------------------------------
  Widget _buildFluxTab(bool isDark) {
    if (_isLoadingPaiements) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)));
    }

    final query = _searchController.text.trim().toLowerCase();
    final paiementsFiltres = _paiements.where((p) {
      if (query.isEmpty) return true;
      return p.nomEleve.toLowerCase().contains(query) ||
          (p.niveau ?? '').toLowerCase().contains(query) ||
          (p.nomGroupe ?? '').toLowerCase().contains(query) ||
          p.matiere.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // Carte Récapitulative Total Encaissé
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF061449), Color(0xFF1E2A5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF061449).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF86F2E4),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL ENCAISSÉ ENREGISTRÉ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat('#,###').format(_totalMontant)} DZD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_totalCount règlement(s)',
                  style: const TextStyle(
                    color: Color(0xFF86F2E4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Recherche
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher par élève, groupe ou matière...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: isDark ? const Color(0xFF131D42) : Colors.white,
            ),
          ),
        ),

        if (_errorPaiements != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_errorPaiements!, style: const TextStyle(color: Colors.red)),
          ),

        // Liste
        Expanded(
          child: paiementsFiltres.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun règlement trouvé',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Les séances encaissées apparaîtront ici chronologiquement.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: paiementsFiltres.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = paiementsFiltres[index];
                    return _buildPaiementTile(p, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaiementTile(PaiementHistorique p, bool isDark) {
    final dateStr = p.datePaiement != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(p.datePaiement!)
        : (p.dateSeance != null ? DateFormat('dd/MM/yyyy').format(p.dateSeance!) : 'Date inconnue');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.nomEleveEtNiveau,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '+ ${p.montant.toInt()} DZD',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (p.nomGroupe != null && p.nomGroupe!.trim().isNotEmpty)
                            ? const Color(0xFF006A61).withValues(alpha: 0.12)
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (p.nomGroupe != null && p.nomGroupe!.trim().isNotEmpty)
                            ? '👥 ${p.nomGroupe}'
                            : (p.typeSeance == 'Privée' ? '👤 Séance privée' : '👤 Séance individuelle'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: (p.nomGroupe != null && p.nomGroupe!.trim().isNotEmpty)
                              ? const Color(0xFF006A61)
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.dureeMinutes} min',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.modePaiement ?? 'Espèces',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
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

  // -------------------------------------------------------------
  // TAB 2 : ARCHIVES CLÔTURES MENSUELLES
  // -------------------------------------------------------------
  Widget _buildCloturesTab(bool isDark) {
    if (_isLoadingClotures) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)));
    }

    if (_errorClotures != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_errorClotures!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _chargerClotures,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_clotures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.archive_outlined, size: 52, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text(
                'Aucune clôture mensuelle archivée',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'À la fin de chaque mois, vous pouvez archiver votre registre financier depuis l\'onglet Finance pour figer le bilan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _clotures.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final c = _clotures[idx];
        return _buildClotureCard(c, isDark);
      },
    );
  }

  Widget _buildClotureCard(ClotureMensuelle c, bool isDark) {
    const moisNoms = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    final nomMois = (c.mois >= 1 && c.mois <= 12) ? moisNoms[c.mois] : 'Mois ${c.mois}';
    final dateClotureStr = DateFormat('dd/MM/yyyy à HH:mm').format(c.dateCloture);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D42) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A61).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF006A61),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nomMois ${c.annee}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Clôturé le $dateClotureStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${c.tauxEncaissement.toInt()}% encaissé',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Séances réalisées', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    '${c.totalSeances}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('CA Réalisé', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    '${c.totalCaRealise.toInt()} DZD',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('CA Encaissé', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    '${c.totalCaEncaisse.toInt()} DZD',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF006A61),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
