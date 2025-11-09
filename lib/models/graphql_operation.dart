class GraphQLOperation {
  final String queryId;
  final String operationName;
  final String path;

  GraphQLOperation({
    required this.queryId,
    required this.operationName,
    required this.path,
  });

  @override
  String toString() => '$operationName: $path';
}

enum PathSource {
  apiDocument,
  custom,
}