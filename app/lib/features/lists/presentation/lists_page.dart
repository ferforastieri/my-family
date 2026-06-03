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
          widget.toast.success(widget.repository.takeMessage());
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
          widget.toast.success(widget.repository.takeMessage());
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
      builder: (context, selectedItems, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final listPanel = _ListsPanel(
              lists: lists,
              selectedListId: selectedListId,
              onSelect: onSelect,
              onCreate: onCreate,
            );
            final itemPanel = _ItemsPanel(
              list: selected,
              items: selectedItems,
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
            );
            if (!wide) {
              return Column(
                children: [
                  listPanel,
                  const SizedBox(height: 14),
                  itemPanel,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 330, child: listPanel),
                const SizedBox(width: 16),
                Expanded(child: itemPanel),
              ],
            );
          },
        );
      },
    );
  }
}

class _ListsPanel extends StatelessWidget {
  const _ListsPanel({
    required this.lists,
    required this.selectedListId,
    required this.onSelect,
    required this.onCreate,
  });

  final List<FamilyList> lists;
  final String? selectedListId;
  final ValueChanged<FamilyList> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      maxWidth: 980,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelTitle(
            title: 'Minhas listas',
            description: 'Compras, tarefas e combinados.',
            icon: Icons.list_alt_outlined,
          ),
          const SizedBox(height: 16),
          AppButton(onPressed: onCreate, label: 'Nova lista', icon: Icons.add),
          const SizedBox(height: 12),
          for (final list in lists)
            ListTile(
              selected: list.id == selectedListId,
              leading: const Icon(Icons.checklist_outlined),
              title: Text(list.title,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: list.description?.isNotEmpty == true
                  ? Text(list.description!)
                  : null,
              onTap: () => onSelect(list),
            ),
        ],
      ),
    );
  }
}

class _ItemsPanel extends StatelessWidget {
  const _ItemsPanel({
    required this.list,
    required this.items,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final FamilyList? list;
  final List<FamilyListItem> items;
  final VoidCallback onAdd;
  final ValueChanged<FamilyListItem> onToggle;
  final ValueChanged<FamilyListItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return LovePanel(
      maxWidth: 980,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            title: list?.title ?? 'Itens',
            description: list == null
                ? 'Selecione ou crie uma lista.'
                : '${items.where((item) => !item.checked).length} pendentes.',
            icon: Icons.task_alt_outlined,
          ),
          const SizedBox(height: 16),
          AppButton(
            onPressed: list == null ? null : onAdd,
            label: 'Adicionar item',
            icon: Icons.add_task_outlined,
          ),
          const SizedBox(height: 12),
          if (list == null)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nenhuma lista selecionada.'),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nenhum item por enquanto.'),
            )
          else
            for (final item in items)
              CheckboxListTile(
                value: item.checked,
                onChanged: (_) => onToggle(item),
                title: Text(
                  item.text,
                  style: TextStyle(
                    decoration:
                        item.checked ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                secondary: IconButton(
                  onPressed: () => onDelete(item),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Excluir',
                ),
              ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: palette.primary.withValues(alpha: .14),
          foregroundColor: palette.primary,
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              Text(description,
                  style: TextStyle(
                      color: palette.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
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
