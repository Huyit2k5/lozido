import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/pdf_contract_service.dart';

class ContractPdfPreviewPage extends StatefulWidget {
  final Map<String, dynamic> contractData;
  final String roomName;

  const ContractPdfPreviewPage({
    super.key,
    required this.contractData,
    required this.roomName,
  });

  @override
  State<ContractPdfPreviewPage> createState() => _ContractPdfPreviewPageState();
}

class _ContractPdfPreviewPageState extends State<ContractPdfPreviewPage> {
  String _ownerName = '..............................';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchOwnerName();
  }

  Future<void> _fetchOwnerName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['name'] != null) {
            _ownerName = data['name'];
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải tên chủ nhà: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingName) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Xem văn bản hợp đồng'),
          backgroundColor: const Color(0xFF00A651),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00A651))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem văn bản hợp đồng'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => PdfContractService.generateContractPdf(
          contractData: widget.contractData,
          roomName: widget.roomName,
          ownerName: _ownerName,
        ),
        pdfFileName: 'hop_dong_${widget.roomName.replaceAll(' ', '_')}.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: false, // Turn off default share button
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.download_rounded),
            onPressed: (context, build, pageFormat) async {
              final bytes = await build(pageFormat);
              await Printing.sharePdf(
                bytes: bytes, 
                filename: 'hop_dong_${widget.roomName.replaceAll(' ', '_')}.pdf'
              );
            },
          )
        ],
        // Optional custom styling matching brand
        pdfPreviewPageDecoration: const BoxDecoration(
           color: Colors.white,
           boxShadow: [
             BoxShadow(
               color: Colors.black12,
               blurRadius: 4,
               spreadRadius: 2,
             )
           ],
        ),
      ),
    );
  }
}
