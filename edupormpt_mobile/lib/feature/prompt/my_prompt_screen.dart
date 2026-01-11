import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../service/prompt_service.dart'; // Ensure this service is created

class MyPromptsScreen extends StatefulWidget {
  const MyPromptsScreen({super.key});

  @override
  State<MyPromptsScreen> createState() => _MyPromptsScreenState();
}

class _MyPromptsScreenState extends State<MyPromptsScreen> {
  final PromptService _promptService = PromptService();
  final ScrollController _scrollController = ScrollController(); // Track scroll position

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Prompts',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF005CEE)),
            onPressed: () async {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          prompt['title'] ?? 'Untitled Prompt',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              prompt['description'] ?? 'No description provided.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF005CEE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                prompt['visibility']?.toString().toUpperCase() ?? 'PRIVATE',
                style: const TextStyle(color: Color(0xFF005CEE), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // TODO: Navigate to Prompt Details
        },
      ),
    );
  }
}