import 'package:flutter/material.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_fixed_header_scroll_view.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_action_card.dart';
import '../../../core/widgets/love_background.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/family_repository.dart';
import '../../../data/models.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({
    super.key,
    required this.repository,
    required this.auth,
    required this.toast,
  });

  final FamilyRepository repository;
  final AuthController auth;
  final ToastController toast;

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  String? selectedListId;

  @override
  void initState() {
    super.initState();
    widget.repository.socket.on('lists.created', _handleListChanged);
    widget.repository.socket.on('lists.updated', _handleListChanged);
    widget.repository.socket.on('lists.deleted', _handleListDeleted);
    widget.repository.socket.on('lists.items.created', _handleItemChanged);
    widget.repository.socket.on('lists.items.updated', _handleItemChanged);
    widget.repository.socket.on('lists.items.deleted', _handleItemDeleted);
  }

  @override
  void dispose() {
    widget.repository.socket.off('lists.created', _handleListChanged);
    widget.repository.socket.off('lists.updated', _handleListChanged);
    widget.repository.socket.off('lists.deleted', _handleListDeleted);
    widget.repository.socket.off('lists.items.created', _handleItemChanged);
    widget.repository.socket.off('lists.items.updated', _handleItemChanged);
    widget.repository.socket.off('lists.items.deleted', _handleItemDeleted);
    super.dispose();
  }

  void _handleListChanged(dynamic _) => _invalidateLists();

  void _handleListDeleted(dynamic data) {
    final id = data is Map ? data['id']?.toString() : data?.toString();
    if (id != null && selectedListId == id) {
      setState(() => selectedListId = null);
    }
    _invalidateLists();
  }

  void _handleItemChanged(dynamic data) {
    if (data is! Map) return;
    final listId = data['listId']?.toString();
    if (listId != null) _invalidateItems(listId);
  }

  void _handleItemDeleted(dynamic data) {
    if (data is! Map) return;
    final listId = data['listId']?.toString();
    if (listId != null) _invalidateItems(listId);
  }

  void _invalidateLists() {
    if (mounted) invalidateQueries(context, QueryKeys.familyLists);
  }

  void _invalidateItems(String listId) {
    if (mounted) invalidateQueries(context, QueryKeys.familyListItems(listId));
  }

  Future<void> _createList() async {
    if (!_ensureLogged()) return;
    final title = TextEditingController();
    final description = TextEditingController();
    await showAppSheet<void>(
      context: context,
      builder: (_) => _ListFormSheet(
        title: 'Nova lista',
        titleController: title,
        descriptionController: description,
        onSave: () async {
          final row = await widget.repository.createFamilyList({
            'title': title.text.trim(),
            'description': description.text.trim(),
          });
          setState(() => selectedListId = row.id);
          _invalidateLists();
          widget.toast.backendSuccess(widget.repository.takeMessage());
        },
      ),
    );
  }

  Future<void> _addItem() async {
    if (!_ensureLogged()) return;
    final listId = selectedListId;
    if (listId == null) return;
    final text = TextEditingController();
    await showAppSheet<void>(
      context: context,
      builder: (_) => _ItemFormSheet(
        controller: text,
        onSave: () async {
          await widget.repository
              .createFamilyListItem(listId, text.text.trim());
          _invalidateItems(listId);
          widget.toast.backendSuccess(widget.repository.takeMessage());
        },
      ),
    );
  }

  Future<void> _deleteList(FamilyList list) async {
    if (!_ensureLogged()) return;
    final confirmed = await showAppSheet<bool>(
      context: context,
      builder: (_) => _DeleteListSheet(list: list),
    );
    if (confirmed != true) return;

    await widget.repository.deleteFamilyList(list.id);
    if (!mounted) return;
    if (selectedListId == list.id) {
      setState(() => selectedListId = null);
    }
    _invalidateLists();
    invalidateQueries(context, QueryKeys.familyListItems(list.id));
    widget.toast.backendSuccess(widget.repository.takeMessage());
  }

  bool _ensureLogged() {
    if (widget.auth.user != null) return true;
    widget.toast.info(context.tr('Entre para editar as listas da família.'));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LoveBackground(
      child: AppFixedHeaderScrollView(
        header: const AppPageHeader(
          title: 'Listas',
          subtitle: 'Compras, tarefas e qualquer combinado da família.',
          icon: Icons.checklist_outlined,
        ),
        children: [
          AppQuery<List<FamilyList>>(
            queryKey: QueryKeys.familyLists,
            queryFn: widget.repository.listFamilyLists,
            loading: const _ListsPageSkeleton(),
            builder: (context, lists, _) {
              final effectiveSelectedId =
                  selectedListId ?? (lists.isNotEmpty ? lists.first.id : null);
              if (selectedListId == null && effectiveSelectedId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && selectedListId == null) {
                    setState(() => selectedListId = effectiveSelectedId);
                  }
                });
              }
              final selected = _findList(lists, effectiveSelectedId);
              return _ListsLayout(
                lists: lists,
                selectedListId: effectiveSelectedId,
                selected: selected,
                repository: widget.repository,
                ensureLogged: _ensureLogged,
                onSelect: (list) => setState(() => selectedListId = list.id),
                onCreate: _createList,
                onAdd: _addItem,
                onDeleteList: _deleteList,
                invalidateItems: _invalidateItems,
              );
            },
          ),
        ],
      ),
    );
  }

  FamilyList? _findList(List<FamilyList> lists, String? id) {
    if (id == null) return null;
    for (final list in lists) {
      if (list.id == id) return list;
    }
    return null;
  }
}

class _ListsLayout extends StatelessWidget {
  const _ListsLayout({
    required this.lists,
    required this.selectedListId,
    required this.selected,
    required this.repository,
    required this.ensureLogged,
    required this.onSelect,
    required this.onCreate,
    required this.onAdd,
    required this.onDeleteList,
    required this.invalidateItems,
  });

  final List<FamilyList> lists;
  final String? selectedListId;
  final FamilyList? selected;
  final FamilyRepository repository;
  final bool Function() ensureLogged;
  final ValueChanged<FamilyList> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onAdd;
  final ValueChanged<FamilyList> onDeleteList;
  final void Function(String listId) invalidateItems;

  @override
  Widget build(BuildContext context) {
    return AppQuery<List<FamilyListItem>>(
      key: ValueKey(selectedListId ?? 'empty'),
      queryKey: selectedListId == null
          ? const ['lists', 'items', 'empty']
          : QueryKeys.familyListItems(selectedListId!),
      queryFn: () => selectedListId == null
          ? Future.value(<FamilyListItem>[])
          : repository.listFamilyListItems(selectedListId!),
      loading: const _ListsPanelSkeleton(),
      builder: (context, selectedItems, _) => _SimpleListsPanel(
        lists: lists,
        selectedListId: selectedListId,
        selected: selected,
        items: selectedItems,
        onSelect: onSelect,
        onCreate: onCreate,
        onAdd: onAdd,
        onDeleteList: onDeleteList,
        onToggle: (item) async {
          if (!ensureLogged()) return;
          await repository
              .updateFamilyListItem(item.id, {'checked': !item.checked});
          invalidateItems(item.listId);
        },
        onDelete: (item) async {
          if (!ensureLogged()) return;
          await repository.deleteFamilyListItem(item.id);
          invalidateItems(item.listId);
        },
      ),
    );
  }
}

class _ListsPageSkeleton extends StatelessWidget {
  const _ListsPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const LovePanel(
      maxWidth: 980,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 220, height: 24),
          SizedBox(height: 16),
          SkeletonBox(height: 48, borderRadius: 14),
          SizedBox(height: 16),
          SkeletonBox(height: 160, borderRadius: 14),
        ],
      ),
    );
  }
}

class _ListsPanelSkeleton extends StatelessWidget {
  const _ListsPanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return const LovePanel(
      maxWidth: 980,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 180, height: 22),
          SizedBox(height: 14),
          SkeletonBox(height: 46, borderRadius: 14),
          SizedBox(height: 14),
          SkeletonBox(height: 120, borderRadius: 14),
        ],
      ),
    );
  }
}

class _SimpleListsPanel extends StatelessWidget {
  const _SimpleListsPanel({
    required this.lists,
    required this.selectedListId,
    required this.selected,
    required this.items,
    required this.onSelect,
    required this.onCreate,
    required this.onAdd,
    required this.onDeleteList,
    required this.onToggle,
    required this.onDelete,
  });

  final List<FamilyList> lists;
  final String? selectedListId;
  final FamilyList? selected;
  final List<FamilyListItem> items;
  final ValueChanged<FamilyList> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onAdd;
  final ValueChanged<FamilyList> onDeleteList;
  final ValueChanged<FamilyListItem> onToggle;
  final ValueChanged<FamilyListItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final pending = items.where((item) => !item.checked).length;
    return LovePanel(
      maxWidth: 980,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.primary.withValues(alpha: .92),
                    palette.primaryDark.withValues(alpha: .92),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .24)),
                    ),
                    child: const Icon(Icons.checklist_outlined,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Listas da família'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lists.isEmpty
                              ? context.tr('Crie a primeira lista.')
                              : context.tr('{count} listas organizadas',
                                  args: {'count': lists.length}),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .84),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    tooltip: context.tr('Nova lista'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: lists.isEmpty
                  ? const _EmptyState(
                      icon: Icons.playlist_add_outlined,
                      title: 'Nenhuma lista ainda',
                      text:
                          'Crie uma lista para compras, tarefas ou combinados.',
                    )
                  : _ListPickerButton(
                      lists: lists,
                      selected: selected,
                      selectedListId: selectedListId,
                      onSelect: onSelect,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.card.withValues(alpha: .72),
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected?.title ?? context.tr('Itens'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selected == null
                                      ? context
                                          .tr('Selecione ou crie uma lista.')
                                      : selected?.description?.isNotEmpty ==
                                              true
                                          ? selected!.description!
                                          : context.tr('{count} pendentes.',
                                              args: {'count': pending}),
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: selected == null
                                ? null
                                : () => onDeleteList(selected!),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: context.tr('Excluir lista'),
                          ),
                          const SizedBox(width: 4),
                          IconButton.filled(
                            onPressed: selected == null ? null : onAdd,
                            icon: const Icon(Icons.add_task_outlined),
                            tooltip: context.tr('Adicionar item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (selected == null)
                        const _EmptyState(
                          icon: Icons.touch_app_outlined,
                          title: 'Escolha uma lista',
                          text: 'Toque em uma lista acima para ver os itens.',
                        )
                      else if (items.isEmpty)
                        const _EmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'Lista vazia',
                          text: 'Adicione o primeiro item quando quiser.',
                        )
                      else
                        for (final item in items)
                          _ListItemRow(
                            item: item,
                            onToggle: () => onToggle(item),
                            onDelete: () => onDelete(item),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: palette.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            context.tr(title),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(text),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _ListPickerButton extends StatelessWidget {
  const _ListPickerButton({
    required this.lists,
    required this.selected,
    required this.selectedListId,
    required this.onSelect,
  });

  final List<FamilyList> lists;
  final FamilyList? selected;
  final String? selectedListId;
  final ValueChanged<FamilyList> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return OutlinedButton(
      onPressed: () => _openListSheet(context),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist_outlined, color: palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Escolher lista'),
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected?.title ?? context.tr('Selecione uma lista'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: palette.primary),
        ],
      ),
    );
  }

  Future<void> _openListSheet(BuildContext context) async {
    final id = await showAppSheet<String>(
      context: context,
      builder: (_) => _ListOptionsSheet(
        lists: lists,
        selectedListId: selectedListId,
      ),
    );
    if (id == null) return;
    for (final list in lists) {
      if (list.id == id) {
        onSelect(list);
        return;
      }
    }
  }
}

class _ListOptionsSheet extends StatelessWidget {
  const _ListOptionsSheet({
    required this.lists,
    required this.selectedListId,
  });

  final List<FamilyList> lists;
  final String? selectedListId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetHeader(
          title: 'Escolher lista',
          subtitle: 'Selecione qual lista deseja visualizar.',
          icon: Icons.checklist_outlined,
        ),
        const SizedBox(height: 12),
        for (final list in lists)
          _ListOptionTile(
            list: list,
            selected: list.id == selectedListId,
            onTap: () => Navigator.pop(context, list.id),
          ),
      ],
    );
  }
}

class _ListOptionTile extends StatelessWidget {
  const _ListOptionTile({
    required this.list,
    required this.selected,
    required this.onTap,
  });

  final FamilyList list;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final description = list.description?.trim();
    return ListTile(
      onTap: onTap,
      leading: Icon(Icons.checklist_outlined,
          color: selected ? palette.primary : palette.muted),
      title:
          Text(list.title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: description == null || description.isEmpty
          ? null
          : Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing:
          selected ? Icon(Icons.check_circle, color: palette.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _ListItemRow extends StatelessWidget {
  const _ListItemRow({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final FamilyListItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Checkbox(value: item.checked, onChanged: (_) => onToggle()),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                decoration: item.checked ? TextDecoration.lineThrough : null,
                color: item.checked ? palette.muted : palette.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: context.tr('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _DeleteListSheet extends StatelessWidget {
  const _DeleteListSheet({required this.list});

  final FamilyList list;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHeader(
            title: 'Excluir lista',
            subtitle: 'Esta ação remove a lista e todos os itens dela.',
            icon: Icons.delete_outline,
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.card.withValues(alpha: .72),
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                list.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('Cancelar')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.tr('Excluir')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListFormSheet extends StatelessWidget {
  const _ListFormSheet({
    required this.title,
    required this.titleController,
    required this.descriptionController,
    required this.onSave,
  });

  final String title;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr(title),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: context.tr('Nome da lista')),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: context.tr('Descrição')),
            onSubmitted: (_) async {
              await onSave();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: () async {
              await onSave();
              if (context.mounted) Navigator.pop(context);
            },
            label: 'Salvar',
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }
}

class _ItemFormSheet extends StatelessWidget {
  const _ItemFormSheet({required this.controller, required this.onSave});

  final TextEditingController controller;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr('Novo item'),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: context.tr('Item')),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) async {
              await onSave();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: () async {
              await onSave();
              if (context.mounted) Navigator.pop(context);
            },
            label: 'Adicionar',
            icon: Icons.add,
          ),
        ],
      ),
    );
  }
}
