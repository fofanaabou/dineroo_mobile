import 'package:dineroo_mobile/shared/common/widgets/app_back_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_cart_icon.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

class AppCollapsingScaffold extends StatefulWidget {
  final String title;
  final String imageUrl;
  final List<Widget> slivers;
  final Widget? bottomNavigationBar;
  final bool showCartAction;
  final double expandedHeaderHeight;
  final Widget? headerOverlay;
  final double headerOverlayHeight;
  final double headerOverlayOverlap;
  final Future<void> Function()? onRefresh;
  final ValueChanged<double>? onScroll;
  final ScrollController? scrollController;

  const AppCollapsingScaffold({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.slivers,
    this.bottomNavigationBar,
    this.showCartAction = true,
    this.expandedHeaderHeight = 160,
    this.headerOverlay,
    this.headerOverlayHeight = 72,
    this.headerOverlayOverlap = 72,
    this.onRefresh,
    this.onScroll,
    this.scrollController,
  });

  @override
  State<AppCollapsingScaffold> createState() => _AppCollapsingScaffoldState();
}

class _AppCollapsingScaffoldState extends State<AppCollapsingScaffold> {
  static const Duration _titleAnimDuration = Duration(milliseconds: 220);
  static const double _overlayContentGap = 8;

  late final ScrollController _scrollController;
  late final bool _ownsScrollController;
  final GlobalKey _headerOverlayKey = GlobalKey();
  bool _showCollapsedTitle = false;
  double? _measuredHeaderOverlayHeight;

  double get _titleTriggerOffset =>
      widget.expandedHeaderHeight - kToolbarHeight - 24;

  double get _effectiveExpandedHeight =>
      widget.expandedHeaderHeight +
      (widget.headerOverlay != null
          ? (_effectiveHeaderOverlayHeight - widget.headerOverlayOverlap) +
                _overlayContentGap
          : 0);

  double get _effectiveHeaderOverlayHeight =>
      _measuredHeaderOverlayHeight ?? widget.headerOverlayHeight;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      widget.onScroll?.call(_scrollController.offset);
    }

    final shouldShow =
        _scrollController.hasClients &&
        _scrollController.offset > _titleTriggerOffset;

    if (shouldShow != _showCollapsedTitle && mounted) {
      setState(() {
        _showCollapsedTitle = shouldShow;
      });
    }
  }

  void _scheduleHeaderOverlayMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _headerOverlayKey.currentContext?.size?.height;
      if (height == null) return;

      final previous = _measuredHeaderOverlayHeight;
      if (previous != null && (previous - height).abs() < 0.5) return;

      setState(() {
        _measuredHeaderOverlayHeight = height;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.headerOverlay != null) {
      _scheduleHeaderOverlayMeasurement();
    }

    final scrollView = CustomScrollView(
      controller: _scrollController,
      clipBehavior: Clip.none,
      physics: widget.onRefresh != null
          ? const AlwaysScrollableScrollPhysics()
          : null,
      slivers: [
        SliverAppBar(
          pinned: true,
          clipBehavior: Clip.none,
          expandedHeight: _effectiveExpandedHeight,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: AnimatedOpacity(
            opacity: _showCollapsedTitle ? 1 : 0,
            duration: _titleAnimDuration,
            curve: Curves.easeOutCubic,
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          leadingWidth: 72,
          leading: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: AppBackButton(backgroundColor: Colors.white),
          ),
          actions: [
            if (widget.showCartAction)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const AppCartIcon(),
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: AppNetworkImage(
                    imageUrl: widget.imageUrl,
                    height: _effectiveExpandedHeight,
                    width: double.infinity,
                    borderRadius: 0,
                  ),
                ),

                if (widget.headerOverlay != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    top:
                        widget.expandedHeaderHeight -
                        widget.headerOverlayOverlap,
                    child: KeyedSubtree(
                      key: _headerOverlayKey,
                      child: widget.headerOverlay!,
                    ),
                  ),
              ],
            ),
          ),
        ),
        ...widget.slivers,
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.onRefresh != null
          ? RefreshIndicator(onRefresh: widget.onRefresh!, child: scrollView)
          : scrollView,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
