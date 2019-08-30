class AppState {
  bool isLoading;

  AppState({
    this.isLoading = false,
  });

  factory AppState.loading() => new AppState(isLoading: true);

  @override
  String toString() {
    return 'AppState{isLoading: $isLoading}}';
  }
}
