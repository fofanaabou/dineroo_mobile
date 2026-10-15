class PaginationParams {
  final int page;
  final int size;
  final String sort;
  final String? search;

  const PaginationParams({
    this.page = 1,
    this.size = 10,
    this.sort = '',
    this.search,
  });

  Map<String, String> toQueryParams() {
    return {
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
      if (search != null && search!.isNotEmpty) 'search': search!,
    };
  }

  PaginationParams copyWith({
    int? page,
    int? size,
    String? sort,
    String? search,
  }) {
    return PaginationParams(
      page: page ?? this.page,
      size: size ?? this.size,
      sort: sort ?? this.sort,
      search: search ?? this.search,
    );
  }
}
