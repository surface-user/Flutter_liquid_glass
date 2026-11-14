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
    '容器与反馈',
    '组织一块内容，可按需开启整卡操作。',
    Icons.crop_landscape,
  ),
  BasicCatalogEntry(
    'showGlassDialog',
    '弹窗',
    '容器与反馈',
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
    '页面结构',
    '页面或分区的一个入口；选中状态由设计设置。',
    Icons.segment,
  ),
  BasicCatalogEntry(
    'GlassTab',
    '标签项',
    '页面结构',
    '一个可选中、可关闭的标签；不自动管理页面。',
    Icons.tab,
  ),
  BasicCatalogEntry(
    'GlassToolbar',
    '工具栏',
    '页面结构',
    '将多个操作放在一起，空间不足时换行。',
    Icons.view_week_outlined,
  ),
  BasicCatalogEntry(
    'GlassAppBar',
    '顶栏',
    '页面结构',
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
  const BasicPalette({super.key, required this.onAdd});
  final ValueChanged<String> onAdd;
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
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 4),
          child: Text('添加内容', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text('按用途选择，点击添加或拖入画布。', style: TextStyle(fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            key: const ValueKey('basic-catalog-search'),
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: '搜索内容或用途…',
              prefixIcon: Icon(Icons.search, size: 18),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('没有找到匹配内容'),
                ),
              for (final category
                  in visible.map((entry) => entry.category).toSet()) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                  child: Text(category, style: const TextStyle(fontSize: 11)),
                ),
                for (final entry in visible.where(
                  (entry) => entry.category == category,
                ))
                  Draggable<String>(
                    data: entry.type,
                    feedback: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(entry.title),
                      ),
                    ),
                    child: ListTile(
                      key: ValueKey('basic-add-${entry.type}'),
                      dense: true,
                      leading: Icon(entry.icon, size: 18),
                      title: Text(
                        entry.title,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.add, size: 16),
                      onTap: () => widget.onAdd(entry.type),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
