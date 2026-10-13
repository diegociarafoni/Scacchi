import '../l10n/app_localizations.dart';
import 'avatar.dart';

/// Nome tradotto dell'avatar; i nomi dei personaggi sono nomi propri.
String avatarName(AppLocalizations l, Avatar a) => switch (a) {
  Avatar.pawn => l.avatarNamePawn,
  Avatar.knight => l.avatarNameKnight,
  Avatar.bishop => l.avatarNameBishop,
  Avatar.rook => l.avatarNameRook,
  Avatar.queen => l.avatarNameQueen,
  Avatar.king => l.avatarNameKing,
  Avatar.chick => l.avatarNameChick,
  Avatar.fox => l.avatarNameFox,
  Avatar.flower => l.avatarNameFlower,
  Avatar.owl => l.avatarNameOwl,
  Avatar.astroCat => l.avatarNameAstroCat,
  Avatar.rabbit => l.avatarNameRabbit,
  Avatar.dragon => l.avatarNameDragon,
  Avatar.eagle => l.avatarNameEagle,
  Avatar.wolf => l.avatarNameWolf,
  Avatar.star => l.avatarNameStar,
};

String avatarFrameName(AppLocalizations l, AvatarFrame f) => switch (f) {
  AvatarFrame.none => l.avatarFrameNone,
  AvatarFrame.bronze => l.avatarFrameBronze,
  AvatarFrame.silver => l.avatarFrameSilver,
  AvatarFrame.gold => l.avatarFrameGold,
  AvatarFrame.flame => l.avatarFrameFlame,
  AvatarFrame.laurel => l.avatarFrameLaurel,
};
