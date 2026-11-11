# OmaDocks build ledger

## Estado atual — 2026-11-05

O resumo operacional está no `AGENTS.md` da raiz. Trabalhamos no checkout
`~/Projects/OmaDocks`, branch `main`; as mudanças desta sessão estão locais,
sem commit/push. O repo `~/Projects/dockfix` foi clonado de
`viniabdalla/dockfix-linux` para consulta; ele contém estudos, não a doca Linux.

O DockFix 5.3.0 foi examinado sem execução. Rastreamos o arraste das pilhas
até SwiftUI `onDrag(_:)` e um NSItemProvider criado da URL. O OmaDocks já
tinha arraste nativo; agora FileDrag captura a prévia do item, com limite de
320 × 128, hotspot no ponto pressionado e descarte de callbacks antigos.
Mantidas as regras de Copy/Move e a compatibilidade com terminais.

Após pesquisar imagens do macOS e obter aprovação do usuário, adicionamos
**Open in File Manager** com seta circular: sempre na ponta do Fan,
substituindo Show all, e como última célula rolável/selecionável do Grid.
O clique abre currentPath e recolhe a pilha, inclusive numa subpasta.
Removida a ação do menu de botão direito. List mantém sua ação existente.

Última suíte: 10 JavaScript + 15 Python + 16 resultados Qt Quick, todos
passando; diff sem problemas de whitespace. Aparência conferida offscreen.
Nenhum novo teste de transferência nativa entre apps após a prévia; não
iniciamos nem reiniciamos a doca. O usuário vai usar e ainda não relatou o
resultado. Preserve a instrução de não abrir o app e não automatize seu input.

## Histórico anterior — estados e pendências abaixo são datados

The user requested direct execution: brainstorming questions were opted out.
Work is in the requested dedicated checkout `~/Projects/OmaDocks`, branch
`feat/folder-stacks`; no second checkout is needed for an initially empty repo.

Tasks 1–2 complete: inherited dock copied with MIT attribution; independent
state migration, directory reader, pure folder/geometry model, 9 JS tests and
6 Python directory/state tests pass.

Task 3 implemented: Fan/Grid/List with overflow, scrolling, hover cascades,
animations, icon opening, native drag sources and drop targets, GIO Move/Copy,
folder pinning/reordering/unpinning, integrated Omarchy settings and outside
dismissal. Live Quickshell loads successfully; native drag and recursive
navigation validation still in progress. Current suite: 9 JS, 11 Python,
9 Qt Quick assertions including suite lifecycle.

Ruling: use the user's dedicated empty checkout in place — user explicitly
requested Projects/OmaDocks — no existing branch/work is affected.
Ruling: use the active customized Dockseid source as the base — preserves the
actual running dock — older archives may contain additional dormant changes.
Ruling: retain wallpaper blur as the portable fallback — inherited dock uses
it and no compositor settings need to change — windows behind the panel are
not visible through that fallback.

An early live test hit a Qt icon-loader pure-virtual abort on the background
pixmap thread. Core showed QQuickPixmapReader -> QIcon::pixmap. System icon
provider loads now run synchronously; local bitmap assets remain asynchronous.
Subsequent reloads have not crashed. Original desktop shell was unaffected.

User refinements: no plus button; no generic Linux settings dialog; compact
Omarchy settings in the bar; clicking outside retracts the dock. Drag folders
to pin; files move to/from folders, Ctrl copies, terminal gets a path only.

2026-11-03 installed milestone: dedicated plugin is now loaded in the normal
Omarchy shell. `omarchy-shell io.github.viniabdalla.omadocks status` returns
loaded=true with user's folders and 6 apps. Original dock disabled; original
checkout/state retained. Existing bar indicator uses compatibility IPC route.
Current passing suites: 9 JS, 14 Python, 12 QML (including lifecycle).

User latest refinement: remove the top view toolbar; Fan/Grid/List and Open
in file manager now live in an Omarchy-styled right-click menu on the pinned
folder icon and the open stack. Generic settings dialog and plus removed.

Independent reviewer findings addressed: side-edge Fan pointer targets, List
selection after shrinking, no-clobber pin action, cross-filesystem folder
move fallback retaining original until copy success, visible error toasts,
correct copied/moved wording. Regression tests observed RED then GREEN.

Live QA evidence: native outbound Move into Nautilus succeeded (source gone,
destination content intact). Three hover-only cascade levels and outside
dismissal passed. Ctrl-copy offer has Qt pointer-modifier regression coverage;
several live Ctrl attempts were invalidated by target being in closed
scratchpad / changing window geometry. Do NOT claim end-to-end Ctrl or terminal
verification yet. User needs their computer: stop all host mouse/keyboard tests.
Any further native checks must be isolated offscreen. All uinput devices were
closed and no wtype process remains.

Development runtime moved to /run/user/1000/omadocks-dev-1000, linking only runtime
assets. Earlier .runtime project-root symlink created recursive watching and
reloads during QA changes. It was removed, and QA artifacts moved to
/tmp/omadocks-qa-artifacts-1793733483. The normal shell was restarted once and
is responsive with no Hyprland config errors. Dev instance stopped.

Pending: finish isolated native protocol checks (Ctrl and terminal), verify
right-click full integration without host automation, finalize docs/installer
handling, push repository to main and full completion audit.

Isolated Weston follow-up: Ctrl-copy into Nautilus was verified with the
original retained. Both-action native offers can be selected as Copy by the
destination even though OmaDocks proposes Move. A Move-only offer moved in
Nautilus but was rejected by foot, so that experiment was reverted to retain
terminal compatibility. Native outbound default-Move across receivers remains
an unresolved limitation; do not claim the entire original goal complete.
The toolbar removal and right-click folder menu are installed and pushed on
main in d5aaa2d. No host pointer or keyboard automation was used in this follow-up.

Follow-up after the user's real drag failure: reproduced with the complete
FolderStack layer under an isolated Labwc compositor. Dropping over the former
panel area hit its own FileDrop instead of the terminal. Removed the remaining
panel input region during native drags, hide all stack contents, signal dock
retraction at drag start, and unmap before restoring the normal input mask on
completion/cancellation. Repeating that full overlay drag inserted the quoted
path into Foot, with the source retained.

The user explicitly accepted native destinations choosing Copy to preserve
terminal compatibility and confirmed that inserting the path is the desired
terminal behavior. No terminal switch is needed.

The user then reported Escape trapping their keyboard and rebooted. Keyboard
focus is now None during outgoing drags, closing animation and after close;
Exclusive is limited to an opened, expanded, visible stack. The hidden-overlay
regression exercises actual FolderStack regions, content opacity, dock release,
cancel cleanup and closing focus; failures were observed before these fixes.
No visible host test window or host pointer/keyboard injection is used.
Fresh suite: 9 JS, 15 Python (including the actual hidden Quickshell overlay),
12 QML including lifecycle. Installed IPC responds and Hyprland config is clean.

Escape validation limitation: Labwc suppresses keyboard input during native
DnD, so its Escape result cannot stand in for Hyprland. The installed Hyprland
v0.56.2 source explicitly calls abortDndIfPresent on Escape in KeybindManager;
its DataDevice abort sends cancellation to the source. Real isolated Hyprland
Escape verification remains pending; do not claim it was tested on the user's
desktop. Temporary QA services/artifacts were removed by the reboot.

Final native follow-up supersedes the pending Escape limitation above. Ran the
actual complete Dock under a private Hyprland 0.56.2 with a 1280x720 headless
monitor and Foot, using only that compositor's virtual input socket. NVIDIA
headless allocation and parent protocol compatibility needed test-only
rendering adapters; production input code/QML remained unchanged.

Found and fixed a second native lifecycle bug: DragHandler.active remained
true after a native release consumed outside the source. Reopening the same
view could not start another offer. Recreating the gesture component on native
completion/cancellation resets both handlers. Unit regression failed first;
all three actual views then passed repeated drops and Escape-before-release,
with stack/dock dismissed, original retained and subsequent terminal typing.

Native receiving tests also exposed use of a nonexistent DropEvent.modifiers
property. Copy-only Ctrl offers were being moved. FileDrop and pinned-folder
receivers now share StackModel.dropCopies, preserving Copy-only offers while
keeping Move as default when supported. A Qt default Copy proposal by itself
must not change that default. Real cross-client tests verify retained source
on Ctrl-copy and removed source on default Move; complete file contents match.

Additional native checks passed: actual pinned-icon right-click and persisted
List selection; three hover-only cascades and Escape during leaf drag; Ctrl
terminal drop; folder pinning, reorder and drag-away unpin retaining its source.
Sanitized results and requirement audit are in docs/qa/. Final automated suite
is 10 JS + 15 Python + 13 Qt Quick results including lifecycle hooks.

## 2026-11-11 — Toolbar

- Escopo aprovado nesta conversa: widget independente e movível, apenas três ícones iniciais (Terminal padrão, Herdr e navegador padrão), lista toolbarPinned, aba Toolbar, ações contextuais em português e remoção por arraste para fora nos dois grupos.
- Execução no checkout solicitado pelo usuário, sem commits/push. Plano e especificação em docs/superpowers/{plans,specs}/2026-11-11-toolbar.md.
- Estado: defaults semeados em arquivos antigos, lista vazia preservada, três listas independentes; lançadores seguem os padrões do sistema. Herdr é CLI e abre dentro do Terminal padrão.
- Input: conteúdo dos dois widgets fica acima do mover nativo, com margem livre para mover o grupo inteiro. Foco de teclado emprestado só durante arraste, restaurando a configuração anterior. Escape, perda de grab e soltura dentro não removem.
- Revisão independente encontrou perda do alvo de movimento do grupo existente. Corrigido com margem livre; regressão reproduzida e teste passou após a correção.
- Integração identificou prioridade incorreta do indicador legado sobre o widget principal ao escolher a posição inicial. Corrigida e coberta por teste: preferir sempre o widget OmaDocks quando presente.
- Ativação parcial retirada: rescanPlugins reconheceu o companion mas o controlador carregado permaneceu com os métodos antigos (toolbarStatus ausente). Não reiniciado o shell por restrição explícita do AGENTS.md; configuração anterior restaurada. O novo plugin permanece disponível via symlink para toolbar/.
- Backup e configuração proposta para ativação: ~/.local/state/omadocks/toolbar-backups/20261111-123333-486117/{shell.json,state.json,pending-shell.json}. A ativação após autorização deve recalcular configure_toolbar sobre a configuração atual para preservar alterações posteriores.

- Histórico operacional registrado e verificado com status parcial; task_id a99e7462-ea02-4de0-a070-7dbbd1f49954. Implementação e testes concluídos; falta somente ativação após autorização de reinício.

- Ativação concluída após autorização explícita do usuário ("s"): configure_toolbar sobre config atual → Toolbar em centerEnd junto do OmaDocks → omarchy restart shell. toolbarStatus confirmou os três atalhos e padrões Ghostty/Chrome; estado anterior preservado em todos os demais campos. Captura real inspecionada em docs/qa/toolbar/live-bar.png. Backup: ~/.local/state/omadocks/toolbar-backups/20261111-132320-513519/. Sem teste manual de arraste/lançamento. Histórico atualizado com o mesmo task_id.

- Correção do histórico: a tentativa de atualizar o mesmo UUID de parcial para concluído foi rejeitada pelo serviço (invalid_record_or_task_id_conflict), inclusive mantendo os campos originais. A consulta confirmou que o registro segue parcial. Não foi criado outro UUID nem histórico paralelo. Ativação da Toolbar concluída; falha limitada à atualização do registro operacional.

- Correção visual solicitada pelo usuário: removidos BorderSurface/fundo/contorno da Toolbar; somente ícones. Teste test_toolbar.py passou, shell reiniciado com autorização vigente e captura real conferida. Seleção atual preservada (Terminal e navegador; Herdr já removido da lista pelo usuário). Histórico registrado e verificado: d99b5f70-afe6-4177-9476-c764725ff998.

- Ajuste visual aprovado: reduzir os ícones para caberem na barra e colocar fundo no logo da Trópico/Oracle. BarShortcut limita arte ao menor lado menos 8 px e hover ao menor lado menos 4 px; fundo opcional habilitado somente para o id Oracle. Regressão de margens horizontal/vertical reproduzida e corrigida; 65 testes passaram e revisão independente sem achados.

- Por solicitação explícita após remoções acidentais, desabilitada remoção por arraste nos favoritos e Toolbar, sem investigar o bug de grab. Desconectados handlers de remoção e foco emprestado nos widgets. Terminal e Herdr restaurados na Toolbar local; backup before-disable-drag-removal-20261111-152719.json. Esclarecimento posterior: arraste DENTRO da Toolbar reorganiza e persiste; soltar fora não remove nem reorganiza. 67 testes passaram; revisão independente sem achados; reinício local aplicado e teste IPC de reorganizar/restaurar confirmou preservação integral do estado. Alterações locais ainda sem commit/push. Registro operacional verificado: 3c7906f9-0790-4341-a3e2-af708ecf4560.
