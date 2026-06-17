enum RecordDateSort {
  oldestFirst('Oldest to Newest'),
  newestFirst('Newest to Oldest');

  const RecordDateSort(this.label);

  final String label;
}

List<T> sortRecordsByDate<T>({
  required Iterable<T> records,
  required DateTime Function(T record) dateOf,
  required RecordDateSort order,
}) {
  final sorted = records.toList();
  sorted.sort((a, b) {
    final comparison = dateOf(a).compareTo(dateOf(b));
    return order == RecordDateSort.oldestFirst ? comparison : -comparison;
  });
  return sorted;
}
