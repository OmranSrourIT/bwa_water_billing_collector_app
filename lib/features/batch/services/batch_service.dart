import '../models/batch_model.dart';

abstract class BatchService {
  Future<BatchModel> getBatch();
}
