import 'package:flutter/material.dart';
import 'registry.dart';

class BasicCatalogEntry {
  const BasicCatalogEntry(
    this.type,
    this.title,
    this.category,
    this.description,
    this.icon,
  );
  final String type, title, category, description;
  final IconData icon;
}

const basicCatalog = <BasicCatalogEntry>[
  BasicCatalogEntry('Text', '文字', '内容', '显示标题、标签或说明文字。', Icons.title),
  BasicCatalogEntry(
    'Icon',
    '图标',
    '内容',
    '显示装饰图形；需要点击时请使用图标按钮。',
    Icons.auto_awesome_outlined,
  ),
  BasicCatalogEntry(
    'GlassCard',
    '卡片',
    '容器',
    '组织一块内容，可按需开启整卡操作。',
    Icons.crop_landscape,
  ),
  BasicCatalogEntry(
    'showGlassDialog',
    '弹窗',
    '容器',
    '编辑说明或确认内容，再试用真实弹窗。',
    Icons.open_in_new,
  ),
  BasicCatalogEntry(
    'GlassButton',
    '按钮',
    '操作',
    '用文字引导用户完成一个操作。',
    Icons.touch_app_outlined,
  ),
  BasicCatalogEntry(
    'GlassIconButton',
    '图标按钮',
    '操作',
    '用图标触发操作，并提供提示文字。',
    Icons.ads_click,
  ),
  BasicCatalogEntry('GlassMenu', '菜单', '操作', '一个入口展开多项操作。', Icons.menu_open),
  BasicCatalogEntry(
    'GlassTextField',
    '文本输入',
    '输入',
    '输入和提交单行文字；搜索用途不自动连接查询服务。',
    Icons.text_fields,
  ),
  BasicCatalogEntry(
    'GlassNavigationItem',
    '导航项',
    '导航',
    '页面或分区的一个入口；选中状态由设计设置。',
    Icons.segment,
  ),
  BasicCatalogEntry(
    'GlassTab',
    '标签项',
    '导航',
    '一个可选中、可关闭的标签；不自动管理页面。',
    Icons.tab,
  ),
  BasicCatalogEntry(
    'GlassToolbar',
    '工具栏',
    '导航',
    '将多个操作放在一起，空间不足时换行。',
    Icons.view_week_outlined,
  ),
  BasicCatalogEntry(
    'GlassAppBar',
    '顶栏',
    '导航',
    '页面顶部的标题与操作区域。',
    Icons.web_asset,
  ),
  BasicCatalogEntry(
    'Row',
    '横排',
    '布局',
    '将内容横向排列；复杂结构可在高级模式编辑。',
    Icons.view_column_outlined,
  ),
  BasicCatalogEntry(
    'Column',
    '竖排',
    '布局',
    '将内容纵向排列；内容较长时可滚动。',
    Icons.view_agenda_outlined,
  ),
];

BasicCatalogEntry? basicEntryFor(String type) {
  if (type == 'GlassDialog') type = 'showGlassDialog';
  for (final entry in basicCatalog) {
    if (entry.type == type) return entry;
  }
  return null;
}

Json createBasicModule(String type, int id, {Offset? at}) {
  if (type == 'GlassDialog') type = 'showGlassDialog';
  if (!basicCatalog.any((entry) => entry.type == type)) {
    throw const FormatException('此内容请在高级模式添加');
  }
  final result = module(type, id, x: at?.dx ?? 40, y: at?.dy ?? 40);
  if (type == 'GlassCard') result['props']['onTap'] = 'none';
  if (type == 'showGlassDialog') result['props']['motion'] = null;
  return result;
}

class BasicPalette extends StatefulWidget {
  const BasicPalette({super.key, required this.onAdd, this.onCollapse});
  final ValueChanged<String> onAdd;
  final VoidCallback? onCollapse;
  @override
  State<BasicPalette> createState() => _BasicPaletteState();
}

class _BasicPaletteState extends State<BasicPalette> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final visible = basicCatalog
        .where(
          (entry) => '${entry.title} ${entry.category} ${entry.description}'
              .contains(query.trim()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '组件',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.onCollapse != null)
                IconButton(
                  onPressed: widget.onCollapse,
                  tooltip: '收起组件面板',
                  icon: const Icon(Icons.chevron_left, size: 20),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: TextField(
            key: const ValueKey('basic-catalog-search'),
            onChanged: (value) => setState(() => query = value),
            decoration: InputDecoration(
              hintText: '搜索组件',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            key: const PageStorageKey('component-catalog'),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('没有找到匹配内容'),
                ),
              for (final group in const {
                '操作': Icons.touch_app_outlined,
                '导航': Icons.explore_outlined,
                '容器': Icons.crop_landscape,
                '输入': Icons.input,
                '内容': Icons.text_fields,
                '布局': Icons.dashboard_outlined,
              }.entries)
                if (visible.any((entry) => entry.category == group.key))
                  ExpansionTile(
                    key: ValueKey('catalog-${group.key}-${query.isNotEmpty}'),
                    initiallyExpanded:
                        query.isNotEmpty || ['操作', '导航'].contains(group.key),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                    childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    leading: Icon(group.value, size: 20),
                    title: Text(
                      group.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      LayoutBuilder(
                        builder: (context, size) {
                          final scale = MediaQuery.textScalerOf(
                            context,
                          ).scale(1);
                          final columns = size.maxWidth < 220 || scale > 1.3
                              ? 1
                              : 2;
                          final width =
                              (size.maxWidth - (columns - 1) * 10) / columns;
                          return SizedBox(
                            width: size.maxWidth,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final entry in visible.where(
                                  (entry) => entry.category == group.key,
                                ))
                                  SizedBox(
                                    width: width,
                                    height: 96 * scale.clamp(1, 1.7),
                                    child: Draggable<String>(
                                      data: entry.type,
                                      feedback: Material(
                                        elevation: 6,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(entry.title),
                                        ),
                                      ),
                                      child: Tooltip(
                                        message:
                                            '${entry.description} 点击添加，或拖入画布。',
                                        child: Material(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: .4),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          child: InkWell(
                                            key: ValueKey(
                                              'basic-add-${entry.type}',
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            onTap: () =>
                                                widget.onAdd(entry.type),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    entry.icon,
                                                    size: 26,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    entry.title,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
