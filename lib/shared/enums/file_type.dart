enum FileType {
  profilePhoto,
  identityCard;

  /// Convert enum to API string (ex: PROFILE_PHOTO, ID)
  String get value {
    switch (this) {
      case FileType.profilePhoto:
        return 'PROFILE_PHOTO';
      case FileType.identityCard:
        return 'ID';
    }
  }
}
