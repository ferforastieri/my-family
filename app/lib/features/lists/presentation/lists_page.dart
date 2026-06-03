import 'package:flutter/material.dart';

import '../../../core/api/query_keys.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/query/app_query.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/toast/toast_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/love_action_card.dart';
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

  bool _ensureLogged() {
    if (widget.auth.user != null) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgStart, palette.bgEnd],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async => _invalidateLists(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: const AppPageHeader(
                  title: 'Listas',
                  subtitle: 'Compras, tarefas e qualquer combinado da família.',
                  icon: Icons.checklist_outlined,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: AppQuery<List<FamilyList>>(
                  queryKey: QueryKeys.familyLists,
                  queryFn: widget.repository.listFamilyLists,
                  loading: const PageSkeleton(cards: 4),
                  builder: (context, lists, _) {
                    final effectiveSelectedId = selectedListId ??
                        (lists.isNotEmpty ? lists.first.id : null);
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
                      onSelect: (list) =>
                          setState(() => selectedListId = list.id),
                      onCreate: _createList,
                      onAdd: _addItem,
                      invalidateItems: _invalidateItems,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
  final void Function(String listId) invalidateItems;

  @override
  Widget build(BuildContext context) {
    return AppQuery<List<FamilyListItem>>(
      queryKey: selectedListId == null
          ? const ['lists', 'items', 'empty']
          : QueryKeys.familyListItems(selectedListId!),
      queryFn: () => selectedListId == null
          ? Future.value(<FamilyListItem>[])
          : repository.listFamilyListItems(selectedListId!),
      loading: const PageSkeleton(cards: 2),
      builder: (context, selectedItems, _) => _SimpleListsPanel(
        lists: lists,
        selectedListId: selectedListId,
        selected: selected,
        items: selectedItems,
        onSelect: onSelect,
        onCreate: onCreate,
        onAdd: onAdd,
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

class _SimpleListsPanel extends StatelessWidget {
  const _SimpleListsPanel({
    required this.lists,
    required this.selectedListId,
    required this.selected,
    required this.items,
    required this.onSelect,
    required this.onCreate,
    required this.onAdd,
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
  final ValueChanged<FamilyListItem> onToggle;
  final ValueChanged<FamilyListItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final pending = items.where((item) => !item.checked).length;
    return LovePanel(
      maxWidth: 980,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Listas da família',
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                tooltip: 'Nova lista',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lists.isEmpty)
            const _EmptyState(
              icon: Icons.playlist_add_outlined,
              title: 'Nenhuma lista ainda',
              text: 'Crie uma lista para compras, tarefas ou combinados.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final list in lists) ...[
                    ChoiceChip(
                      selected: list.id == selectedListId,
                      label: Text(list.title),
                      avatar: const Icon(Icons.checklist_outlined, size: 18),
                      onSelected: (_) => onSelect(list),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          DecoratedBox(
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
                              selected?.title ?? 'Itens',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              selected == null
                                  ? 'Selecione ou crie uma lista.'
                                  : selected?.description?.isNotEmpty == true
                                      ? selected!.description!
                                      : '$pending pendentes.',
                              style: TextStyle(
                                color: palette.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        onPressed: selected == null ? null : onAdd,
                        icon: const Icon(Icons.add_task_outlined),
                        tooltip: 'Adicionar item',
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
        ],
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
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted),
          ),
        ],
      ),
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
            tooltip: 'Excluir',
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
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Nome da lista'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Descrição'),
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
          const Text('Novo item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Item'),
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
