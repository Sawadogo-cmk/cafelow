import 'package:flutter/material.dart';
import '../services/receipt_service.dart';

class ReceiptScreen extends StatefulWidget {
  final int orderId;
  final List<Map<String, dynamic>> items;
  final int total;
  final String customerName;
  final String phone;
  final DateTime date;

  const ReceiptScreen({
    super.key,
    required this.orderId,
    required this.items,
    required this.total,
    required this.customerName,
    required this.phone,
    required this.date,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isLoading = false;

  Future<void> _downloadReceipt() async {
    setState(() => _isLoading = true);
    try {
      await ReceiptService.generateAndDownloadReceipt(
        orderId: widget.orderId,
        items: widget.items,
        total: widget.total,
        customerName: widget.customerName,
        phone: widget.phone, // 👈 Le téléphone est bien transmis
        date: widget.date,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reçu téléchargé avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre Reçu'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 30,
                          color: Colors.brown,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Votre reçu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Client : ${widget.customerName}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Tél : ${widget.phone}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date : ${_formatDate(widget.date)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Articles commandés :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.items.map((item) {
                      final name = item['name'] ?? 'Sans nom';
                      final quantity = item['quantity'] ?? 1;
                      final price = item['price'] ?? 0;
                      final itemTotal = price * quantity;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('$quantity x'),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name)),
                            Text(
                              '$price FCFA',
                              style: const TextStyle(color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '= $itemTotal FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL :',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.total} FCFA',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✓ Commande validée avec succès !',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _downloadReceipt,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isLoading
                      ? 'Génération en cours...'
                      : 'Télécharger le reçu (PDF)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Retour au menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
