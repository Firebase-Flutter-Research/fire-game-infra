class Player {
  final int id;
  String name;

  Player({required this.id, this.name = "Guest"});

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };

  static Player fromJson(Map<String, dynamic> json) =>
      Player(id: json["id"], name: json["name"]);

  @override
  bool operator ==(Object other) =>
      other.runtimeType == Player && id == (other as Player).id;

  @override
  int get hashCode => id.hashCode;
}
