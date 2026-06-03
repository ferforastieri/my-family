import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
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
  final lists = <FamilyList>[];
  final items = <String, List<FamilyListItem>>{};
  String? selectedListId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    widget.repository.socket.on('lists.created', _handleListEvent);
    widget.repository.socket.on('lists.updated', _handleListEvent);
    widget.repository.socket.on('lists.deleted', _handleListDeleted);
    widget.repository.socket.on('lists.items.created', _handleItemEvent);
    widget.repository.socket.on('lists.items.updated', _handleItemEvent);
    widget.repository.socket.on('lists.items.deleted', _handleItemDeleted);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    widget.repository.socket.off('lists.created', _handleListEvent);
    widget.repository.socket.off('lists.updated', _handleListEvent);
    widget.repository.socket.off('lists.deleted', _handleListDeleted);
    widget.repository.socket.off('lists.items.created', _handleItemEvent);
    widget.repository.socket.off('lists.items.updated', _handleItemEvent);
    widget.repository.socket.off('lists.items.deleted', _handleItemDeleted);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final rows = await widget.repository.listFamilyLists();
      lists
        ..clear()
        ..addAll(rows);
      selectedListId ??= lists.isNotEmpty ? lists.first.id : null;
      if (selectedListId != null) await _loadItems(selectedListId!);
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadItems(String listId) async {
    final rows = await widget.repository.listFamilyListItems(listId);
    items[listId] = rows;
  }

  Future<void> _select(FamilyList list) async {
    selectedListId = list.id;
    setState(() => loading = true);
    try {
      await _loadItems(list.id);
    } catch (error) {
      widget.toast.error(error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _handleListEvent(dynamic data) {
    if (data is! Map) return;
    final row = FamilyList.fromJson(Map<String, dynamic>.from(data));
    final index = lists.indexWhere((item) => item.id == row.id);
    setState(() {
      if (index >= 0) {
        lists[index] = row;
      } else {
        lists.insert(0, row);
        selectedListId ??= row.id;
      }
    });
  }

  void _handleListDeleted(dynamic data) {
    final id = data is Map ? data['id'].toString() : data.toString();
    setState(() {
      lists.removeWhere((item) => item.id == id);
      items.remove(id);
      if (selectedListId == id) selectedListId = lists.isNotEmpty ? lists.first.id : null;
    });
  }

  void _handleItemEvent(dynamic data) {
    if (data is! Map) return;
    final row = FamilyListItem.fromJson(Map<String, dynamic>.from(data));
    final listItems = items.putIfAbsent(row.listId, () => []);
    final index = listItems.indexWhere((item) => item.id == row.id);
    setState(() {
      if (index >= 0) {
        listItems[index] = row;
      } else {
        listItems.insert(0, row);
      }
    });
  }

  void _handleItemDeleted(dynamic data) {
    if (data is! Map) return;
    final id = data['id'].toString();
    final listId = data['listId']?.toString();
    setState(() {
      if (listId != null && items[listId] != null) {
        items[listId]!.removeWhere((item) => item.id == id);
      } else {
        for (final listItems in items.values) {
          listItems.removeWhere((item) => item.id == id);
        }
      }
    });
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
          selectedListId = row.id;
          widget.toast.success('Lista criada.');
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
          await widget.repository.createFamilyListItem(listId, text.text.trim());
          widget.toast.success('Item adicionado.');
        },
      ),
    );
  }

  bool _ensureLogged() {
    if (widget.auth.user != null) return true;
    widget.toast.info('Entre para alterar listas.');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;
    final selected = _selectedList;
    final selectedItems = selectedListId == null ? <FamilyListItem>[] : items[selectedListId] ?? const [];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgStart, palette.bgEnd],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
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
                child: loading && lists.isEmpty
                    ? const PageSkeleton(cards: 4)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 760;
                          final listPanel = _ListsPanel(
                            lists: lists,
                            selectedListId: selectedListId,
                            onSelect: _select,
                            onCreate: _createList,
                          );
                          final itemPanel = _ItemsPanel(
                            list: selected,
                            items: selectedItems,
                            onAdd: _addItem,
                            onToggle: (item) async {
                              if (!_ensureLogged()) return;
                              await widget.repository.updateFamilyListItem(
                                  item.id, {'checked': !item.checked});
                            },
                            onDelete: (item) async {
                              if (!_ensureLogged()) return;
                              await widget.repository.deleteFamilyListItem(item.id);
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
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  FamilyList? get _selectedList {
    for (final list in lists) {
      if (list.id == selectedListId) return list;
    }
    return null;
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
              title: Text(list.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: list.description?.isNotEmpty == true ? Text(list.description!) : null,
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
          AppButton(onPressed: list == null ? null : onAdd, label: 'Adicionar item', icon: Icons.add_task_outlined),
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
                    decoration: item.checked ? TextDecoration.lineThrough : null,
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
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text(description, style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
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
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
          const Text('Novo item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
