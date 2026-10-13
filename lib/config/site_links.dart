import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Every destination that lives outside this site.
///
/// Each one is null until the real address is known. Nothing on the site
/// invents a link: a control pointing at a null entry either hides itself or
/// says plainly that it is not ready, rather than opening a dead end or - worse
/// for a social handle - sending someone to an account that is not ours.
///
/// Fill these in and the controls appear by themselves.
abstract final class SiteLinks {
  // TODO: add the real profiles once the accounts exist.
  static const String? facebook = null;
  static const String? instagram = null;
  static const String? x = null;
  static const String? youtube = null;

  // TODO: add the store listings once the apps are published.
  static const String? appStore = null;
  static const String? playStore = null;

  // TODO: add the launch film once it is cut.
  static const String? storyVideo = null;

  /// The head office, as it should be searched for on a map.
  // TODO: confirm the address before launch; it also appears on the contact
  // page and in the footer.
  static const officeAddress = 'The Campus, 57 Sloane Street, Bryanston, Johannesburg, 2191';

  static Uri get officeOnMap =>
      Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': officeAddress});

  /// True when [url] is set, i.e. the control behind it should be live.
  static bool has(String? url) => url != null && url.isNotEmpty;
}

/// Opens [url] in a new tab, telling the visitor if it could not be opened
/// rather than failing silently.
Future<void> openExternal(BuildContext context, Uri url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened && messenger != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}
