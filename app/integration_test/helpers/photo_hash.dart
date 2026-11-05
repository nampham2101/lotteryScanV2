// Used on both sides of the tests of ticket #18: on the phone for the picture
// ML Kit is given, and on the Mac for the kept photo. The Mac can't import
// Flutter, so this must not either.

/// A number for a file's contents (FNV-1a), to tell whether two are the same.
int photoHash(List<int> bytes) {
  var hash = 2166136261;
  for (final byte in bytes) {
    hash = ((hash ^ byte) * 16777619) & 0xffffffff;
  }
  return hash;
}
