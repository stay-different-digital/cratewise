class DiscogsIdentity {
  const DiscogsIdentity({
    required this.username,
    required this.resourceUrl,
  });

  final String username;
  final String resourceUrl;

  factory DiscogsIdentity.fromJson(Map<String, dynamic> json) {
    return DiscogsIdentity(
      username: json['username'] as String,
      resourceUrl: json['resource_url'] as String,
    );
  }
}
