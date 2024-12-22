import 'package:shadcn_flutter/shadcn_flutter.dart' hide Image;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:collection/collection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:spotube/collections/spotube_icons.dart';
import 'package:spotube/components/playbutton_view/playbutton_view.dart';
import 'package:spotube/modules/album/album_card.dart';
import 'package:spotube/components/inter_scrollbar/inter_scrollbar.dart';
import 'package:spotube/components/fallbacks/anonymous_fallback.dart';
import 'package:spotube/extensions/context.dart';
import 'package:spotube/provider/authentication/authentication.dart';
import 'package:spotube/provider/spotify/spotify.dart';

class UserAlbums extends HookConsumerWidget {
  const UserAlbums({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final auth = ref.watch(authenticationProvider);
    final albumsQuery = ref.watch(favoriteAlbumsProvider);
    final albumsQueryNotifier = ref.watch(favoriteAlbumsProvider.notifier);

    final controller = useScrollController();

    final searchText = useState('');

    final albums = useMemoized(() {
      if (searchText.value.isEmpty) {
        return albumsQuery.asData?.value.items ?? [];
      }
      return albumsQuery.asData?.value.items
              .map((e) => (
                    weightedRatio(e.name!, searchText.value),
                    e,
                  ))
              .sorted((a, b) => b.$1.compareTo(a.$1))
              .where((e) => e.$1 > 50)
              .map((e) => e.$2)
              .toList() ??
          [];
    }, [albumsQuery.asData?.value, searchText.value]);

    if (auth.asData?.value == null) {
      return const AnonymousFallback();
    }

    return SafeArea(
      child: Scaffold(
        child: RefreshTrigger(
          onRefresh: () async {
            ref.invalidate(favoriteAlbumsProvider);
          },
          child: InterScrollbar(
            controller: controller,
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SliverAppBar(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  floating: true,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        onChanged: (value) => searchText.value = value,
                        leading: const Icon(SpotubeIcons.filter),
                        placeholder: Text(context.l10n.filter_artist),
                      ),
                    ),
                  ),
                ),
                const SliverGap(10),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: PlaybuttonView(
                    controller: controller,
                    itemCount: albums.length,
                    hasMore: albumsQuery.asData?.value.hasMore == true,
                    isLoading: albumsQuery.isLoading,
                    onRequestMore: albumsQueryNotifier.fetchMore,
                    gridItemBuilder: (context, index) => AlbumCard(
                      albums[index],
                    ),
                    listItemBuilder: (context, index) =>
                        AlbumCard.tile(albums[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
