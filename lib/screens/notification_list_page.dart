import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/notification_log.dart';
import '../models/read_stats.dart';
import '../theme/app_colors.dart';
import 'notification_detail_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<NotificationLog> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  
  String _filter = 'all'; // all, unread
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreLogs();
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _logs = [];
      _offset = 0;
      _hasMore = true;
    });

    try {
      final newLogs = await NotificationService.getLogs(limit: _limit, offset: 0);
      if (mounted) {
        setState(() {
          _logs = newLogs;
          _isLoading = false;
          _offset = newLogs.length;
          if (newLogs.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newLogs = await NotificationService.getLogs(limit: _limit, offset: _offset);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (newLogs.isEmpty) {
            _hasMore = false;
          } else {
            _logs.addAll(newLogs);
            _offset += newLogs.length;
            if (newLogs.length < _limit) {
              _hasMore = false;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadInitialData();
  }

  Future<void> _showStats(BuildContext context, NotificationLog log) async {
    final stats = await NotificationService.getReadStats(log.id);
    if (stats == null) return;
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stats.judul, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _statRow('Target Penerima', '${stats.recipientsCount ?? 0}'),
            _statRow('Sudah Membaca', '${stats.readCount}'),
            _statRow('Persentase', '${stats.persentaseBaca ?? 0}%'),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (stats.persentaseBaca ?? 0) / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.currentUser?.role.toLowerCase() == 'admin';
    final hasUnread = _logs.any((l) => !l.isRead);
    
    // Local Filter & Search (Keep for now, but pagination works best with server-side filter)
    var displayedLogs = _logs;
    if (_searchQuery.isNotEmpty) {
      displayedLogs = displayedLogs.where((l) => 
        l.judul.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        l.isiPesan.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    if (_filter == 'unread') {
      displayedLogs = displayedLogs.where((l) => !l.isRead).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kotak Masuk'),
        actions: [
          if (!isAdmin && hasUnread)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Tandai Semua Dibaca',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Tandai Semua Dibaca?'),
                    content: const Text('Semua notifikasi yang belum dibaca akan ditandai sebagai sudah dibaca.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya, Tandai')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await NotificationService.markAllAsRead();
                  setState(() {
                    for (var log in _logs) {
                      log.isRead = true;
                    }
                  });
                }
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Cari pengumuman...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _filterButton('Semua', 'all'),
                  const SizedBox(width: 8),
                  _filterButton('Belum Dibaca', 'unread'),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading && _logs.isEmpty
            ? _buildShimmerLoading()
            : displayedLogs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: displayedLogs.length + (_hasMore ? 1 : 0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      if (index == displayedLogs.length) {
                        return _buildShimmerItem();
                      }

                      final log = displayedLogs[index];
                      return _buildLogCard(log, isAdmin);
                    },
                  ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) => _buildShimmerItem(),
    );
  }

  Widget _buildShimmerItem() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const ListTile(
          leading: SizedBox(width: 48, height: 48),
          title: SizedBox(width: 100, height: 16),
          subtitle: SizedBox(width: double.infinity, height: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Tidak ada notifikasi ditemukan', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(NotificationLog log, bool isAdmin) {
    final titleStyle = TextStyle(
      fontWeight: log.isRead ? FontWeight.normal : FontWeight.bold,
      color: log.isRead ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8) : Theme.of(context).colorScheme.onSurface,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: log.isRead ? Theme.of(context).dividerColor : AppColors.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Stack(
          children: [
            _buildLeadingIcon(log),
            if (!log.isRead && !isAdmin)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
          ],
        ),
        title: Text.rich(
          _highlightSpan(log.judul, _searchQuery, titleStyle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              _highlightSpan(log.isiPesan, _searchQuery, const TextStyle(fontSize: 13)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${log.tipe.split('_').last.toUpperCase()} • ${log.createdAt?.toString().substring(0, 16) ?? ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: isAdmin ? const Icon(Icons.bar_chart_rounded, color: AppColors.primary) : const Icon(Icons.chevron_right, size: 18),
        onTap: () async {
          if (isAdmin) {
            _showStats(context, log);
          } else {
            if (!log.isRead) {
              await NotificationService.markAsRead(log.id.toString());
              setState(() {
                log.isRead = true; // Local update for QoL
              }); 
            }
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationDetailPage(log: log)),
            ).then((_) => setState(() {}));
          }
        },
      ),
    );
  }

  TextSpan _highlightSpan(String text, String query, TextStyle style) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return TextSpan(text: text, style: style);
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    final List<InlineSpan> spans = [];
    int start = 0;
    int indexOfQuery = lowerText.indexOf(lowerQuery, start);

    while (indexOfQuery != -1) {
      if (indexOfQuery > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfQuery), style: style));
      }

      spans.add(TextSpan(
        text: text.substring(indexOfQuery, indexOfQuery + query.length),
        style: style.copyWith(
          backgroundColor: AppColors.primary.withOpacity(0.3),
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ));

      start = indexOfQuery + query.length;
      indexOfQuery = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return TextSpan(children: spans);
  }

  Widget _buildLeadingIcon(NotificationLog log) {
    if (log.gambarUrl != null && log.gambarUrl!.isNotEmpty) {
      return Hero(
        tag: 'notif_img_${log.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: log.gambarUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade100,
              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            errorWidget: (context, url, error) => _defaultIcon(),
          ),
        ),
      );
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 24),
    );
  }

  Widget _filterButton(String label, String value) {
    bool isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (s) => setState(() {
        _filter = value;
      }),
      selectedColor: AppColors.primary.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.secondaryDark : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
