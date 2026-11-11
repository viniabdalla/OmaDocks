# Toolbar — 2026-11-11

Escopo aprovado: widget independente e movível, nome Toolbar, três atalhos
iniciais (Terminal padrão, Herdr e navegador padrão), seleção separada,
configuração integrada, menu contextual e remoção por arraste nos dois grupos.

## Verificação

- `bash scripts/test.sh`: 19 testes JavaScript, 20 Python e 25 resultados Qt Quick.
- Modelo real: migração, lista vazia, normalização, persistência independente,
  aliases dos aplicativos padrão, argumentos dos lançadores e remoção idempotente.
- Componentes reais em Quickshell oculto: aba Toolbar, sinais separados,
  ações Adicionar à Toolbar/Remover da Toolbar, importação do companion por
  symlink, layout horizontal/vertical, alteração de seleção pelo file watcher,
  lista vazia sem espaço ocupado, foco de teclado emprestado/restaurado.
- QtTest offscreen com eventos reais: clique, soltura fora, soltura dentro,
  retorno ao balão, Escape, cancelamento por perda do pointer grab, tooltips
  em texto seguro e prioridade sobre a MouseArea do mover de widgets.
- Instalador: registro independente e adjacente, preferência pelo grupo real
  sobre indicador legado, preservação de posição posterior e idempotência.
- Revisão independente encontrou a falta de margem para mover o grupo Trópico;
  correção coberta por teste RED→GREEN.
- `preview.png`: renderização offscreen inspecionada, com os ícones reais de
  Ghostty, terminal (Herdr sem desktop entry próprio) e Chrome, em duas orientações.

## Ativação concluída

Após autorização explícita do usuário ("s"), a Toolbar foi registrada ao lado
do widget OmaDocks em `centerEnd`, recalculando o layout pela configuração
atual. Executado `omarchy restart shell`; o novo controlador respondeu:

```json
{"apps":["omadocks-default-terminal","omadocks-herdr","omadocks-default-browser"],"defaults":{"terminal":"com.mitchellh.ghostty","browser":"google-chrome","herdr":"herdr"}}
```

A comparação com o backup confirmou preservação de `version`, `pinned`,
`barPinned`, `order`, `folders` e `settings`; somente `toolbarPinned` foi
acrescentado. O status dos favoritos continua Oracle, Artemis, CRM e Scraper.
A captura real `live-bar.png` foi inspecionada: Toolbar compacta com os três
ícones ao lado do grupo existente. `live-groups.png` mostra essa região.
O log do shell não registrou erros dos novos componentes.

Backup desta ativação:
`~/.local/state/omadocks/toolbar-backups/20261111-132320-513519/`.

## Limites da verificação

Não houve injeção de teclado/mouse no desktop, abertura de outra doca ou
execução do instalador. A revisão dos gestos, tooltips e foco usa QtTest e
componentes ocultos; arrastes e lançamentos reais não foram exercitados
manualmente nesta sessão. O reinício do shell foi autorizado para ativação.

## Correção visual após feedback

Removidos o fundo e o contorno: a Toolbar agora mostra somente ícones sobre a barra. Teste `test_toolbar.py` passou e novas capturas reais foram conferidas após aplicar. A seleção atual do usuário (Terminal e navegador, sem Herdr) foi preservada. `preview.png` mostra a prévia atual sem fundo ou contorno; `live-groups.png` e `live-bar.png` mostram o visual atual.

## Encaixe dos ícones e fundo do Oracle

Após feedback visual no omarchy2, os ícones agora respeitam margem mínima de 4 px por lado dentro do slot; o destaque de hover fica a 2 px das bordas. Em uma barra de 26 px, a arte ocupa no máximo 18 px. O atalho Oracle (logo Trópico) recebe um fundo escuro arredondado próprio; os demais atalhos e o grupo Toolbar não ganham fundo adicional. Teste de regressão reproduziu o excesso de tamanho anterior e passou após a correção. Suite: 19 JavaScript, 20 Python e 26 resultados Qt Quick. Revisão independente sem achados.

## Remoção por arraste desabilitada por solicitação do usuário

O usuário relatou remoções acidentais e pediu para desabilitar o recurso sem investigar/corrigir o gesto. O componente não emite mais remoção ao soltar fora, e os handlers de remoção por arraste foram desconectados dos dois widgets. O arraste também não toma mais foco de teclado. Os testes de gesto passaram a exigir zero remoções ao soltar fora; menu contextual e configurações continuam sendo ações explícitas de seleção. Terminal e Herdr foram restaurados na Toolbar local. Esta seção substitui os resultados históricos que validavam remoção por arraste.

## Reorganização interna da Toolbar

Por esclarecimento do usuário, o arraste interno na Toolbar permite reorganizar sem adicionar ou remover aplicativos. A soltura dentro determina o slot alvo; a soltura fora não emite reorganização nem remoção. O controlador persiste a ordem e rejeita IDs ausentes. Testes cobrem movimento para esquerda/direita, IDs inválidos, persistência e preservação das outras listas, gestos dentro/fora e mapeamento dos slots nas duas orientações.
