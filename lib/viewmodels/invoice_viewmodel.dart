import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/invoice_repository.dart';

class InvoiceViewModel extends ChangeNotifier {
  final InvoiceRepository _invoiceRepository;

  InvoiceViewModel({InvoiceRepository? invoiceRepository})
      : _invoiceRepository = invoiceRepository ?? InvoiceRepository();

  Stream<QuerySnapshot> getInvoicesStream(String houseId) {
    return _invoiceRepository.getInvoicesStream(houseId);
  }

  Stream<DocumentSnapshot> getInvoiceDetailsStream(String houseId, String invoiceId) {
    return _invoiceRepository.getInvoiceDetailsStream(houseId, invoiceId);
  }

  Future<DocumentSnapshot> getInvoiceDetails(String houseId, String invoiceId) {
    return _invoiceRepository.getInvoiceDetails(houseId, invoiceId);
  }

  Future<void> updateInvoice(String houseId, String invoiceId, Map<String, dynamic> data) {
    return _invoiceRepository.updateInvoice(houseId, invoiceId, data);
  }

  Future<DocumentReference> addInvoice(String houseId, Map<String, dynamic> invoiceData) {
    return _invoiceRepository.addInvoice(houseId, invoiceData);
  }

  Future<QuerySnapshot> getInvoicesByMonth(String houseId, String billingMonth) {
    return _invoiceRepository.getInvoicesByMonth(houseId, billingMonth);
  }

  Future<void> submitPayment(String houseId, String invoiceId, Map<String, dynamic> invoiceUpdateData, Map<String, dynamic> transactionData) {
    return _invoiceRepository.submitPayment(houseId, invoiceId, invoiceUpdateData, transactionData);
  }
}
