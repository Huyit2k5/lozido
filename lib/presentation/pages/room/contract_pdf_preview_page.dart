import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../services/pdf_contract_service.dart';

class ContractPdfPreviewPage extends StatelessWidget {
  final Map<String, dynamic> contractData;
  final String roomName;

  const ContractPdfPreviewPage({
    super.key,
    required this.contractData,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem văn bản hợp đồng'),
        backgroundColor: const Color(0xFF00A651),
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (format) => PdfContractService.generateContractPdf(
          contractData: contractData,
          roomName: roomName,
        ),
        pdfFileName: 'hop_dong_${roomName.replaceAll(' ', '_')}.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        // Optional custom styling matching brand
        pdfPreviewPageDecoration: BoxDecoration(
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
