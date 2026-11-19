import 'package:flutter/material.dart';

/// Modal pesquisável para escolher rapidamente entre dezenas de marcas ou modelos da BrasilAPI.
Future<T?> mostrarSeletorPesquisavel<T>({
  required BuildContext context,
  required String titulo,
  required String dicaBusca,
  required List<T> itens,
  required String Function(T item) obterTexto,
  T? selecionado,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _SeletorPesquisavelSheet<T>(
      titulo: titulo,
      dicaBusca: dicaBusca,
      itens: itens,
      obterTexto: obterTexto,
      selecionado: selecionado,
    ),
  );
}

class _SeletorPesquisavelSheet<T> extends StatefulWidget {
  const _SeletorPesquisavelSheet({
    required this.titulo,
    required this.dicaBusca,
    required this.itens,
    required this.obterTexto,
    this.selecionado,
  });

  final String titulo;
  final String dicaBusca;
  final List<T> itens;
  final String Function(T item) obterTexto;
  final T? selecionado;

  @override
  State<_SeletorPesquisavelSheet<T>> createState() =>
      _SeletorPesquisavelSheetState<T>();
}

class _SeletorPesquisavelSheetState<T>
    extends State<_SeletorPesquisavelSheet<T>> {
  final _buscaController = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final termo = _filtro.trim().toLowerCase();
    final filtrados = termo.isEmpty
        ? widget.itens
        : widget.itens
              .where((item) => widget.obterTexto(item).toLowerCase().contains(termo))
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tema.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: widget.dicaBusca,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filtro.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _filtro = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtrados.length} ${filtrados.length == 1 ? 'opção encontrada' : 'opções encontradas'}',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text('Nenhum resultado encontrado para a busca.'),
                  )
                : ListView.separated(
                    controller: scrollController,
                    itemCount: filtrados.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtrados[index];
                      final estaSelecionado = item == widget.selecionado;
                      return ListTile(
                        title: Text(
                          widget.obterTexto(item),
                          style: TextStyle(
                            fontWeight: estaSelecionado
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: estaSelecionado
                            ? Icon(
                                Icons.check_circle,
                                color: tema.colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
