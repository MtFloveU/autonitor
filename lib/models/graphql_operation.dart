class GraphQLOperation {
  final String queryId;
  final String operationName;

  GraphQLOperation({required this.queryId, required this.operationName});

  @override
  String toString() => '$operationName: $queryId';
}

enum QueryIdSource { apiDocument, custom }
