import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_exception.dart';
import '../../api/photos_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/ui_kit.dart';
import 'photo_badge.dart';

/// An image the coach chose: its bytes and file name.
typedef PickedPhoto = ({List<int> bytes, String name});

Future<PickedPhoto?> pickPhotoFromDevice() async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 90);
  if (file == null) return null;
  return (bytes: await file.readAsBytes(), name: file.name);
}

/// Lets a coach set their team logo and their own profile photo.
class CoachPhotosCard extends StatefulWidget {
  const CoachPhotosCard({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.coachName,
    this.pick = pickPhotoFromDevice,
  });

  final int? teamId;
  final String teamName;
  final String coachName;

  /// How an image is chosen. Tests replace this.
  final Future<PickedPhoto?> Function() pick;

  @override
  State<CoachPhotosCard> createState() => _CoachPhotosCardState();
}

class _CoachPhotosCardState extends State<CoachPhotosCard> {
  late final PhotosApi _api = PhotosApi(SessionScope.read(context).api);

  String? _logo;
  String? _avatar;
  bool _logoBusy = false;
  bool _avatarBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final teamId = widget.teamId;
    try {
      final avatar = await _api.myAvatar();
      final logo = teamId == null ? null : await _api.teamLogo(teamId);
      if (!mounted) return;
      setState(() {
        _avatar = avatar;
        _logo = logo;
      });
    } on ApiException {
      // The photos just stay as initials; uploading still works.
    }
  }

  String _message(ApiException e) => switch (e.code) {
        'FILE_TOO_LARGE' => 'That image is over 5 MB. Choose a smaller one.',
        'INVALID_IMAGE' => 'Please choose a JPEG, PNG or WebP image.',
        'STORAGE_UNAVAILABLE' => 'Photo uploads are not switched on yet. Please try again later.',
        _ => e.message,
      };

  void _busy(bool logo, bool value) {
    if (logo) {
      _logoBusy = value;
    } else {
      _avatarBusy = value;
    }
  }

  Future<void> _change({required bool logo}) async {
    final picked = await widget.pick();
    if (picked == null || !mounted) return;
    setState(() {
      _error = null;
      _busy(logo, true);
    });
    try {
      final url = logo
          ? await _api.uploadTeamLogo(widget.teamId!, picked.bytes, picked.name)
          : await _api.uploadAvatar(picked.bytes, picked.name);
      if (mounted) {
        setState(() {
          if (logo) {
            _logo = url;
          } else {
            _avatar = url;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy(logo, false));
    }
  }

  Future<void> _remove({required bool logo}) async {
    setState(() {
      _error = null;
      _busy(logo, true);
    });
    try {
      if (logo) {
        await _api.removeTeamLogo(widget.teamId!);
      } else {
        await _api.removeAvatar();
      }
      if (mounted) {
        setState(() {
          if (logo) {
            _logo = null;
          } else {
            _avatar = null;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy(logo, false));
    }
  }

  Widget _slot({
    required String title,
    required String hint,
    required Widget badge,
    required bool hasImage,
    required bool busy,
    required bool logo,
  }) {
    return SizedBox(
      width: 330,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          badge,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SiteButton(
                      label: busy ? 'UPLOADING…' : (hasImage ? 'CHANGE' : 'UPLOAD'),
                      icon: Icons.upload,
                      small: true,
                      onPressed: busy ? null : () => _change(logo: logo),
                    ),
                    if (hasImage && !busy) TextButton(onPressed: () => _remove(logo: logo), child: const Text('Remove')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Logo and photo',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 32,
              runSpacing: 20,
              children: [
                if (widget.teamId != null)
                  _slot(
                    title: 'Team logo',
                    hint: 'Shown next to your team name. PNG, JPEG or WebP, up to 5 MB.',
                    badge: PhotoBadge(url: _logo, fallback: widget.teamName, size: 72, square: true),
                    hasImage: _logo != null,
                    busy: _logoBusy,
                    logo: true,
                  ),
                _slot(
                  title: 'Your photo',
                  hint: 'Your coach profile picture.',
                  badge: PhotoBadge(url: _avatar, fallback: widget.coachName, size: 72),
                  hasImage: _avatar != null,
                  busy: _avatarBusy,
                  logo: false,
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
              ),
          ],
        ),
      ),
    );
  }
}
