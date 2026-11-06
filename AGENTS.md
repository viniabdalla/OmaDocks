# OmaDocks — contexto para agentes

## Projeto e localização

- Checkout: `/home/viniabdalla/Projects/OmaDocks`, branch `main`.
- Origem: `https://github.com/viniabdalla/OmaDocks`.
- Plugin de doca para Omarchy/Hyprland, em Qt Quick/Quickshell, derivado do Dockseid. Preserve as atribuições MIT.
- A instalação existente usa um link deste checkout em `~/.config/omarchy/plugins/io.github.viniabdalla.omadocks`. Alterações podem ser observadas pelo shell.
- O projeto de referência `/home/viniabdalla/Projects/dockfix` contém estudos do DockFix para macOS; a implementação Linux está aqui.

## Estado atual — sessão de 2026-11-05

O usuário aprovou as alterações abaixo e disse que vai usá-las. Ainda não há confirmação de uso real posterior a elas. As alterações desta sessão estão locais, sem commit/push. Preserve também as mudanças de prévia de arraste que já estavam no checkout ao iniciar o trabalho do botão.

### Arraste de arquivos para fora da pilha

- O DockFix 5.3.0 foi analisado estaticamente, sem execução. `StackDragSource` usa SwiftUI `onDrag(_:)` com um `NSItemProvider` inicializado pela URL do arquivo. Os detalhes e os limites da evidência estão em `../dockfix/docs/reference-findings.md`.
- OmaDocks já oferecia URIs reais e caminhos em texto via arraste nativo Wayland, com liberação da região de entrada, ocultação da pilha e recuperação dos handlers ao terminar/cancelar.
- `FileDrag.qml` agora captura a imagem do item antes do arraste, incluindo o nome, em Fan/Grid/List. Limite de 320 × 128 pixels; hotspot relativo ao ponto pressionado; mantém o resultado da captura até o término e ignora callbacks de gestos encerrados. Se a captura não puder começar, usa o ícone existente.
- Mantenha Copy e Move disponíveis: padrão Move, Ctrl no início oferece só Copy. O destino negocia a operação final. Terminais recebem o caminho e preservam o arquivo. Nunca apague a origem no callback de término do arraste.

### Open in File Manager como no macOS

- O usuário pediu referência visual na internet, recebeu a proposta e aprovou antes da implementação.
- `StackFan.qml`: o último item é sempre **Open in File Manager**, com seta curva dentro de um círculo, mesmo em pastas pequenas/vazias. Substitui **Show all**, que antes abria Grid. `StackModel.fanLayout()` reserva esse espaço dentro da capacidade do leque.
- `StackGrid.qml`: a mesma ação é a última célula da grade e acompanha a rolagem; End e Enter permitem ativá-la pelo teclado. Ela não representa um arquivo nem inicia arraste.
- `OpenFolderIcon.qml`: símbolo compartilhado, desenhado em QML, inspirado nas referências do macOS.
- `FolderStack.openCurrentFolder()` abre `currentPath` pelo controlador existente e fecha/recolhe a pilha. Deve funcionar também após entrar numa subpasta.
- A ação saiu de `FolderMenu.qml`; o handler correspondente foi removido de `DockSurface.qml`. As demais opções do menu permanecem. List conserva sua ação de abrir a pasta.
- Especificação e plano: `docs/superpowers/specs/2026-11-05-open-folder-action.md` e `docs/superpowers/plans/2026-11-05-open-folder-action.md`.

## Validação e cuidados

- Comando: `bash scripts/test.sh`. Última execução nesta sessão: 10 testes JavaScript, 15 Python e 16 resultados Qt Quick, todos passando; `git diff --check` sem erros.
- Os novos testes cobrem Fan vazio/pequeno/com overflow, ação final no Grid por clique/teclado, subpasta atual e fechamento no overlay oculto, captura assíncrona, cancelamento e gestos repetidos.
- A aparência do novo botão foi conferida em uma imagem de teste offscreen. Esse renderizador de software não exibe a camada de sombra/ícone preexistente dos arquivos no Fan; a nova seta aparece nas duas visualizações.
- Não houve novo teste de transferência nativa entre aplicativos após a alteração da prévia. A validação nativa de 2026-11-03 em `docs/qa/` é histórica e não deve ser apresentada como validação integral do código novo.
- O usuário pediu para não iniciar o app. Não abra uma segunda doca, execute o instalador, reinicie o shell ou injete teclado/mouse no desktop sem nova instrução. Os testes offscreen e de overlay não mapeado são o caminho usado nesta sessão.
- Não interprete registros antigos do ledger sobre **Show all** ou o comando no botão direito como o comportamento atual.

## Onde trabalhar

- Visualizações: `StackFan.qml`, `StackGrid.qml`, `StackList.qml`.
- Ciclo da janela e navegação: `FolderStack.qml`; menu: `FolderMenu.qml`; integração: `DockSurface.qml`.
- Arraste/recepção: `FileDrag.qml`, `FileDrop.qml`; modelo e geometria: `StackModel.js`.
- Histórico detalhado: `docs/superpowers/ledger.md`; uso: `README.md`.
- Evite mudanças no sistema/configurações e preserve alterações locais de outras tarefas. Não publique nem atribua validações que não foram executadas.

## Esclarecimento do usuário — testes em dois PCs

O usuário confirmou que os projetos a contextualizar são **OmaDocks e Dockfix**; “WOMA Shelf” foi um erro de ditado/escrita, não uma referência ao ShelfClip. Está usando um em cada PC para testar. Não foi informado qual projeto está em qual computador. Não presuma que os dois testes ocorrem nesta máquina, nem que o estado/configuração/resultado de um PC descreve o outro. O checkout local Dockfix continua contendo documentação de referência; essa informação de uso não comprova uma implementação executável neste repo ou o estado do outro PC. Ainda não foi relatado o resultado dos testes do usuário.

## Atualização — 2026-11-06

O usuário confirmou nesta máquina que o OmaDocks está funcionando bem e pediu
commit/push do estado local. As superfícies `omadocks` e `omadocks-trigger`
foram verificadas nos dois monitores; o relatório `enabled: false` do catálogo
não refletia essa execução. Não use só esse campo para afirmar que está parado.
As alterações descritas acima foram preparadas para publicação juntas.
`bash scripts/test.sh` passou novamente no Omarchy 4.5: 10 JavaScript,
15 Python e 16 resultados Qt Quick. Não houve novo teste manual de transferência
entre aplicativos nesta verificação.
