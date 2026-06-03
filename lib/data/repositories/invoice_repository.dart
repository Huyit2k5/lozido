import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getInvoicesStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getInvoiceDetailsStream(String houseId, String invoiceId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('invoices')
        .doc(invoiceId)
        .snapshots();
  }

  Future<DocumentSnapshot> getInvoiceDetails(String houseId, String invoiceId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('invoices')
        .doc(invoiceId)
        .get();
  }

  Future<void> updateInvoice(String houseId, String invoiceId, Map<String, dynamic> data) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('invoices')
        .doc(invoiceId)
        .update(data);
  }

  Future<DocumentReference> addInvoice(String houseId, Map<String, dynamic> invoiceData) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('invoices')
        .add(invoiceData);
  }

  Future<QuerySnapshot> getInvoicesByMonth(String houseId, String billingMonth) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('invoices')
        .where('billingMonth', isEqualTo: billingMonth)
        .get();
  }

  Future<void> submitPayment(String houseId, String invoiceId, Map<String, dynamic> invoiceUpdateData, Map<String, dynamic> transactionData) async {
    final batch = _firestore.batch();
    
    final transactionRef = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('transactions')
        .doc();

    final invoiceRef = _firestore
        .collection('houses')
        .doc(houseId)
        .collection('invoices')
        .doc(invoiceId);

    batch.update(invoiceRef, invoiceUpdateData);
    batch.set(transactionRef, transactionData);

    await batch.commit();
  }
}
