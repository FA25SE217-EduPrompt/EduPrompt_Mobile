import 'package:flutter/material.dart';
import '../../service/prompt_service.dart';

class PromptDetailScreen extends StatefulWidget {
  final String promptId;
  const PromptDetailScreen({super.key, required this.promptId});

  @override
  State<PromptDetailScreen> createState() => _PromptDetailScreenState();
}

class _PromptDetailScreenState extends State<PromptDetailScreen> {
  final PromptService _promptService = PromptService();
  Map<String, dynamic>? _promptData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final result = await _promptService.getPromptById(widget.promptId);
    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _promptData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Prompt Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 40),
            _buildDetailSection('Instruction', _promptData?['instruction']),
            _buildDetailSection('Context', _promptData?['context']),
            _buildDetailSection('Input Example', _promptData?['inputExample']),
            _buildDetailSection('Output Format', _promptData?['outputFormat']),
            _buildDetailSection('Constraints', _promptData?['constraints']),
            const SizedBox(height: 20),
            _buildTags(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _promptData?['title'] ?? 'No Title',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _promptData?['description'] ?? 'No description provided.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String label, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF005CEE))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    final List tags = _promptData?['tags'] ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: tags.map<Widget>((tag) {
        return Chip(
          label: Text(tag['value'] ?? ''),
          backgroundColor: const Color(0xFF005CEE).withOpacity(0.1),
          side: BorderSide.none,
          labelStyle: const TextStyle(color: Color(0xFF005CEE), fontSize: 12),
        );
      }).toList(),
    );
  }
}