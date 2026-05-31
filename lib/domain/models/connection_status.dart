class ConnectionStatus {
  const ConnectionStatus._({this.username});

  const ConnectionStatus.disconnected() : username = null;
  ConnectionStatus.connected(String username) : this._(username: username);

  final String? username;
  bool get isConnected => username != null;
}
