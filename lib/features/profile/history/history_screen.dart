import 'package:flutter/material.dart';
import 'kawman_transaction.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedService = 'All';
  bool _isLoading = true;

  // These will be populated from your real API
  List<ServiceLinkStatus> _linkStatuses = [];
  List<KawmanTransaction> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Call your real APIs here to fetch history and link statuses.
      // Example:
      // final zentroMartOrders = await zentroMartApi.getOrders();
      // final hanapGawaBookings = await hanapGawaApi.getBookings();
      // ... convert to KawmanTransaction and add to a list.
      // 
      // For now, it stays empty until the real APIs are connected.
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network request
      
      setState(() {
        _linkStatuses = [
          // Temporarily assume everything is linked, update this from real data
          ServiceLinkStatus(serviceName: 'ZentroMart', isLinked: true),
          ServiceLinkStatus(serviceName: 'HanapGawa', isLinked: true),
          ServiceLinkStatus(serviceName: 'TDLF-Educ', isLinked: true),
          ServiceLinkStatus(serviceName: 'PAMEYAAN', isLinked: true),
        ];
        _allTransactions = [];
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'ZentroMart':
        return Icons.shopping_cart_outlined;
      case 'HanapGawa':
        return Icons.work_outline;
      case 'TDLF-Educ':
        return Icons.school_outlined;
      case 'PAMEYAAN':
        return Icons.storefront_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildFilterChips() {
    final services = ['All', 'ZentroMart', 'HanapGawa', 'TDLF-Educ', 'PAMEYAAN'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: services.map((service) {
          final isSelected = _selectedService == service;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(service),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedService = service;
                });
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLinkPrompt(String serviceName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Account Not Linked',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to link your account to $serviceName to view its transaction history.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Implement linking logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigate to $serviceName linking screen')),
                );
              },
              icon: const Icon(Icons.link_rounded),
              label: Text('Link to $serviceName'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _selectedService == 'All'
        ? _allTransactions
        : _allTransactions.where((t) => t.serviceName == _selectedService).toList();

    // Check link status if a specific service is selected
    bool requiresLinking = false;
    if (_selectedService != 'All') {
      final status = _linkStatuses.firstWhere(
        (s) => s.serviceName == _selectedService,
        orElse: () => ServiceLinkStatus(serviceName: _selectedService, isLinked: true),
      );
      if (!status.isLinked) {
        requiresLinking = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : requiresLinking
                    ? _buildLinkPrompt(_selectedService)
                    : filteredTransactions.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions found.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = filteredTransactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  _getServiceIcon(tx.serviceName),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                tx.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${tx.serviceName} • ${tx.subtitle}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(tx.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tx.status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getStatusColor(tx.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(tx.date),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: tx.amount != null
                                  ? Text(
                                      '₱${tx.amount!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                // TODO: Navigate to detail
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
