import 'package:edupormpt_mobile/feature/prompt/prompt_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../service/prompt_service.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyPromptsScreen extends StatefulWidget {
  const MyPromptsScreen({super.key});

  @override
  State<MyPromptsScreen> createState() => _MyPromptsScreenState();
}
enum PromptView { myPrompts, publicPrompts }

class _MyPromptsScreenState extends State<MyPromptsScreen> {
  final PromptService _promptService = PromptService();
  final ScrollController _scrollController = ScrollController();
  PromptView _currentView = PromptView.myPrompts;

  List<dynamic> _prompts = [];
  bool _isLoading = true;
  bool _isLoadMore = false;
  bool _hasNextPage = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        if (!_isLoadMore && _hasNextPage && _errorMessage == null) {
          _fetchMyPrompts(loadMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showQrDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Share Prompt", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Link copied to clipboard!",
              style: TextStyle(color: Colors.green, fontSize: 14),
            ),
            const SizedBox(height: 20),
            // QR Code Generation
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF005CEE),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              url,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAuthAndLoad() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    _fetchMyPrompts();
  }

  Future<void> _fetchMyPrompts({bool loadMore = false}) async {
    if (!loadMore && _promptService.isFullyLoaded && _promptService.cachedPrompts.isNotEmpty) {
      setState(() {
        _prompts = _promptService.cachedPrompts;
        _isLoading = false;
        _hasNextPage = false;
      });
      return;
    }

    if (loadMore) {
      setState(() => _isLoadMore = true);
    } else {
      setState(() {
        _isLoading = _promptService.cachedPrompts.isEmpty;
        _errorMessage = null;
        _currentPage = 0;
      });
    }

    final result = await _promptService.getMyPrompts(page: _currentPage, size: 10);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _prompts = _promptService.cachedPrompts;
        _isLoading = false;
        _isLoadMore = false;
        _currentPage++;

        if (result['fromCache'] == true || _promptService.isFullyLoaded) {
          _hasNextPage = false;
        }
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
        _isLoadMore = false;
      });
      if (result['message'].toString().contains('Unauthorized')) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future<void> _handleShare(String promptId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _promptService.sharePrompt(promptId);

    if (!mounted) return;
    Navigator.pop(context);

    if (result['success']) {
      final String shareUrl = result['shareUrl'];

      await Clipboard.setData(ClipboardData(text: shareUrl));

      _showQrDialog(shareUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link copied: $shareUrl'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchPrompts({bool loadMore = false}) async {
    final isPublic = _currentView == PromptView.publicPrompts;
    final cache = isPublic ? _promptService.cachedPublicPrompts : _promptService.cachedPrompts;
    final fullyLoaded = isPublic ? _promptService.isPublicFullyLoaded : _promptService.isFullyLoaded;

    if (!loadMore && fullyLoaded && cache.isNotEmpty) {
      setState(() {
        _prompts = cache;
        _isLoading = false;
        _hasNextPage = false;
      });
      return;
    }

    if (loadMore) {
      setState(() => _isLoadMore = true);
    } else {
      setState(() {
        _isLoading = cache.isEmpty;
        _errorMessage = null;
        _currentPage = 0;
        _hasNextPage = true;
      });
    }

    final result = isPublic
        ? await _promptService.getPublicPrompts(page: _currentPage, size: 10)
        : await _promptService.getMyPrompts(page: _currentPage, size: 10);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _prompts = isPublic ? _promptService.cachedPublicPrompts : _promptService.cachedPrompts;
        _isLoading = false;
        _isLoadMore = false;
        _currentPage++;
        if (result['fromCache'] == true || (isPublic ? _promptService.isPublicFullyLoaded : _promptService.isFullyLoaded)) {
          _hasNextPage = false;
        }
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
        _isLoadMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<PromptView>(
            value: _currentView,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            onChanged: (PromptView? newValue) {
              if (newValue != null && newValue != _currentView) {
                setState(() {
                  _currentView = newValue;
                  _prompts = [];
                });
                _fetchPrompts();
              }
            },
            items: const [
              DropdownMenuItem(value: PromptView.myPrompts, child: Text("My Prompts")),
              DropdownMenuItem(value: PromptView.publicPrompts, child: Text("Public Prompts")),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF005CEE)),
            onPressed: () async {
              _promptService.clearCache();
              await AuthService.clearToken();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF005CEE),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF005CEE)));
    }

    if (_errorMessage != null && _prompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _fetchMyPrompts(), child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_prompts.isEmpty) {
      return const Center(child: Text("You haven't created any prompts yet."));
    }

    return RefreshIndicator(
      onRefresh: () => _fetchMyPrompts(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _prompts.length + (_hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _prompts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final prompt = _prompts[index];
          return _buildPromptCard(prompt);
        },
      ),
    );
  }

  Widget _buildPromptCard(dynamic prompt) {
    final String promptId = prompt['id']?.toString() ?? '';
    final String author = prompt['fullName'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PromptDetailScreen(promptId: promptId),
            ),
          );
        },
        title: Text(
          prompt['title'] ?? 'Untitled Prompt',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15, // Smaller title
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentView == PromptView.publicPrompts)
              Text(
                "By $author",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
              prompt['description'] ?? 'No description.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12, // Smaller description
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF005CEE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                prompt['visibility']?.toString().toUpperCase() ?? 'PRIVATE',
                style: const TextStyle(
                    color: Color(0xFF005CEE),
                    fontSize: 9, // Smaller tag
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Color(0xFF005CEE), size: 12),
              onPressed: () => _handleShare(promptId),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 8),
          ],
        ),
      ),
    );
  }
}