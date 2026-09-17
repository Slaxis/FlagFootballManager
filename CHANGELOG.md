# Changelog

## [Unreleased]

### Fixed - B.6m: a cor do clube nao aparecia (2026-09-17)
- **O accent era "a mais clara das duas" cores do clube**, que e a pergunta
  errada: clube de vinho e branco tem tinta branca, entao o accent saia BRANCO e
  o vinho que e a identidade inteira do lugar nao aparecia alem do escudo. Tres
  clubes seguidos renderizavam como a mesma tela cinza-esbranquicada. Agora
  `TeamColors.accent()` escolhe a que carrega o MATIZ (saturacao), e levanta so o
  valor — vinho escuro vira vinho claro, nao um nada palido. Estacio virou
  vermelho, America vermelho, Dark Owls roxo
- **A rampa do tint corria de 0 a 100 e os dados vivem entre 14 e 30.** Todo
  numero ficava 14 a 30% do caminho entre cinza e a cor do clube — cinza. Agora
  Geral normaliza contra a faixa do proprio elenco e a afinidade contra o teto da
  coluna, entao a rampa cobre os numeros que existem
- **`%d/%d — abaixo do minimo` alargava o painel inteiro.** Quatro palavras de
  explicacao numa coluna de 300px, dizendo o que a cor ao lado ja diz. Ficaram os
  numeros, em ambar, com a regra no tooltip

### Changed - B.6l: a tabela do elenco vira uma tabela (2026-09-17)
- **Um GridContainer so, cabecalho incluido.** Cabecalho e linhas eram
  HBoxContainers separados que concordavam sobre larguras por serem escritos das
  mesmas constantes — e sobre mais nada. Num grid a coluna e dimensionada pela
  celula mais larga DAQUELA coluna, cabecalho e linhas juntos, porque sao o mesmo
  container
- Custa a linha-como-botao: grid tem celula, nao linha. Selecao e **zebra** sao
  pintadas por celula (zebra nao e enfeite numa tabela de 27 colunas: e o que
  segura o olho na linha em que ele comecou), e **a celula do nome e a que se
  clica**, que e o idioma de tabela em todo lugar
- **A celula mostra a afinidade**, nao o codigo da propria coluna. O
  preenchimento e RELATIVO (contra o resto do elenco naquela posicao) e o numero
  e ABSOLUTO, entao respondem perguntas diferentes em vez de repetir. Tingido pelo
  proprio valor: coluna de afinidade baixa some e o olho cai em quem serve
- **A linha de nomes de grupo saiu.** Tres palavras cobrindo dezoito colunas nao
  se expressam num grid sem span, e ela nao pagava a linha: os codigos sao
  inequivocos, um fio marca cada fronteira, e o painel da esquerda ja diz
  Administracao / Comissao / Escalacao sobre as atribuicoes de verdade. Cada
  cabecalho carrega a posicao no tooltip
- O painel para de se explicar na tela: `admin_hint` (69 caracteres, permanentes,
  numa coluna de 300px) virou tooltip, e `%d inscritos de %d no elenco` virou
  `%d/%d inscritos` — estado fica, explicacao vai pro hover

### Fixed
- **O desalinhamento entre cabecalho e marcacoes.** O cabecalho separava as
  celulas por `COL_GAP` (6) e as linhas por `8`: dois pixels por coluna, 48px de
  deriva na vigesima quarta. Ja tinha sido "consertado" uma vez clipando um
  titulo que crescia alem do minimo — a largura nunca foi o problema, o arranjo
  era
- E o primeiro grid caiu na MESMA armadilha um nivel acima: as fronteiras eram
  contadas a mao (tres) e emitidas por um laco que produzia duas, porque ataque e
  defesa sao um bloco so. O grid recebia 27 colunas e cada linha preenchia 26, e
  tudo escorregava uma celula — 5706px de largura. Virou uma LISTA SO
  (`_column_plan`) que cabecalho e linhas percorrem

### Fixed - B.6k: presidente, corpo e o nome do clube (2026-09-17)
- **O player estava sendo sentado como HEAD COACH.** Era `head_coach` em dois dos
  tres cenarios, e isso silenciosamente o punha como membro da propria comissao
  tecnica — um entre quatro ou cinco disputando cadeira, num clube que ele
  deveria mandar. Agora e **PRESIDENTE** em qualquer cenario
- **A presidencia e a unica cadeira travada** na tabela do elenco: nao se
  resigna e nao se da pra um recebedor. Todo outro cargo e trabalho que se
  distribui, e a tabela e exatamente pra isso
- **Mudar o nome do clube nao mudava o clube.** Escrevia o dicionario e parava
  ali, entao o escudo colorido ao lado ficava com o nome sorteado — e pior, o
  `id` mantinha o SLUG do nome sorteado, que e o endereco pelo qual toda tela
  depois procura o clube. Dava pra batizar o time de qualquer coisa e continuar
  registrado com o que o dado disse primeiro

### Changed
- **O corpo sobe pra IDENTIDADE.** Altura e peso sao o mesmo tipo de fato que o
  nome, e estavam embaixo dos atributos so porque e la que mora o passo que eles
  deslocam. Duas caixas cabem onde tres campos de nome ja estavam
- **Talentos ganham a largura inteira** debaixo dos atributos e das habilidades —
  talento e uma frase e frase precisa de linha. Chip de 252 para **292px**, que
  e o que "Quebra de cintura  2 pp" pede (276px, medido)
- **O clube vai por ultimo** na coluna: so existe pro Fundador, e bloco que
  aparece e some no MEIO empurra tudo abaixo dele a cada troca de cenario
- **As vinte fontes cravadas da tela do elenco** (de 10 a 24, todas fora da grade
  e todas minusculas) foram pra escada do `Look`
- `tests/test_screen_create_manager.gd` passa a medir cada chip de talento contra
  a largura do proprio texto: `clip_text` corta em silencio, e chip que corta a
  coisa que ele existe pra dizer falhou

### Changed - B.6j: paleta neutra e glifos ASCII (2026-09-17)
- **A moldura vira azul-marinho muito escuro e branco** ate a tela do time. O
  verde do Elifoot e uma bela referencia e tambem uma tela inteira de cor
  saturada carregando informacao nenhuma — fundo que voce olha por uma hora e
  fundo que voce para de ver e passa a cansar
- A cor fica reservada pra onde significa: **verde/vermelho** (talento ou
  defeito), **ambar** (atencao), **os chakras** (um tom por atributo, herdado
  pelas habilidades) e **as cores do clube**, que a partir da tela do time
  modulam tudo. Contra uma aproximacao neutra a chegada no clube le como chegada
- A paleta mora em `Look` e as quatro telas de antes do clube leem de la. Zero
  literais de cor sobraram nelas
- **Emoji vira ASCII**: `[*]` pro dado, `[-]` pro cadeado, e prefixos de uma
  letra no log do draft (`#` `?` `>` `<` `.` `=` `~` `!`)
- **Talentos ganham codigo de tres letras** (CRQ, FOG, CER...) como o resto da
  ficha, e o chip solta o glifo: a cor ja diz qualidade ou defeito e o nome esta
  do lado. O codigo existe pra coluna do elenco, onde nao cabe nome
- **Seletor de cor do clube**: dois quadradinhos que abrem picker, no lugar de
  uma paleta que se percorria com um botao. `TeamColors.of()` continua
  corrigindo o contraste se o par sair ilegivel
- **O nome do clube ganha a linha inteira** — e digitado pelo player e estava
  sendo cortado no campo e na previa do escudo
- `tests/test_glyphs.gd`: todo caractere de todo JSON de conteudo tem que existir
  na fonte do jogo, com o instrumento provado antes (`has_char` precisa RECUSAR
  um emoji)

### Fixed
- **O dado do clube nao sorteava nada.** A semente vinha do career seed, que e um
  hash dos tres campos de nome — entao toda pressionada devolvia o clube
  identico e o botao parecia morto. O clube fundado e uma ESCOLHA e nao estado do
  mundo, entao ganhou contador proprio
- Quatro simbolos do log do draft (⌂ ⚐ ⚑ ⚠) nao existiam em nenhuma das duas
  fontes e estavam sendo desenhados por fallback. Num log monoespacado, glifo de
  outra largura quebra a coluna que faz o log ser legivel
- `const TEXT` colidia em `Look`: ja era um tamanho de fonte. A cor virou `INK`

### Changed - B.6i: codigos de tres letras e tooltips (2026-09-17)
- **Todo atributo e habilidade tem um codigo de tres letras**, e e ele que
  aparece: INT, PER, CAR, VON, VIT, DES, AGI, FOR e os quinze das habilidades.
  "Chamada de jogada" tem dezessete caracteres ao lado de uma barra de dez casas,
  e vinte e tres linhas assim leem como classificado em vez de ficha
- Por idioma, porque a mnemonica e o ponto (VIT/Vitalidade, STA/Stamina), e
  unicos dentro de cada um — `StatDef.code()` e `StatDef.explain()`, com teste
- **Todo texto explicativo saiu da tela e virou tooltip.** Seis secoes carregavam
  duas linhas de prosa cada; a explicacao nao foi deletada, mudou pra onde
  explicacao pertence — a um hover de distancia, permanentemente disponivel em
  vez de permanentemente no caminho
- **Todo tooltip foi reescrito curto**, e o criterio inverte: o que estava na
  tela tinha que justificar o espaco explicando a si mesmo; o que esta no hover
  so precisa responder a pergunta com que voce passou o mouse ali. `plays_hint`
  de 193 para 105 caracteres, `perks_hint` de 166 para 66, `body_hint` de 144
  para 81
- **Sete tooltips novos** onde nao havia nenhum: os botoes de + e - (com o custo
  do proximo passo), o contador de career points, a paleta de cores, o escudo, e
  as secoes de identidade, atributos e habilidades
- O botao de sortear clube carrega o motivo de estar travado, que e onde se olha
  quando um botao nao aperta
- A ficha do atleta na tela do elenco recebeu o mesmo tratamento
- Criacao: **2256x810 -> 1740x790**

### Changed - B.6h: pixel art de alta resolucao (2026-09-17)
- **A janela E o canvas.** `content_scale_size` = janela, `content_scale_factor`
  = 1, escala nenhuma. Um pixel logico e um pixel de tela, que e o mais nitido
  que uma imagem consegue ser — nao existe reamostragem pra ser nitido atraves
- Escalar por inteiro a partir de 1280x720 era genuinamente pixel-perfect e era
  **outra estetica**: grossa, proxima, SNES. E apertada: 2x num 1440p deixa so
  1280x720 de espaco, e essa tela e quase toda tabela
- `Look.DESIGN_MIN` vira **2560x1440**, e passa a ser ALVO e nao divisor
- **Criacao volta a uma pagina de tres colunas** (2256x810). As abas existiam so
  porque nada cabia em 1280x720 — e um formulario que voce compara contra ele
  mesmo nao devia obrigar a clicar entre as metades que voce esta comparando
- **Elenco** recupera as larguras: os 18 codigos de posicao voltam a 36px com o
  rotulo no corpo normal, em vez de 22px no degrau de 9
- **Draft** recupera o log: 1850x760

### Fixed
- Tres avisos do compilador: `band` sombreando a funcao `band()` em `stat.gd`,
  o parametro `origin` sombreando o membro homonimo em `sheet_builder.gd` (numa
  funcao STATIC, onde o membro nem e alcancavel), e uma divisao inteira em
  `look.gd` que saiu junto com a aritmetica de escala

### Fixed - B.6g: o zoom de 4x (2026-09-17)
- **`content_scale_size` e `content_scale_factor` se MULTIPLICAM**, e eu setei os
  dois. O `size` e o canvas logico e a engine JA o estica ate a janela — 1280x720
  numa janela 2560x1440 ja e 2x — entao o `factor` em 2 deixou tudo em **4x**: o
  viewport logico desabando pra 640x360 e formularios feitos pra 1250 vazando
  pela borda. Le como zoom porque e zoom
- Agora so o `size` e setado; o `factor` fica em 1 e a escala sai da aritmetica
  (`canvas = janela / escala`), entao o esticao da engine e o mesmo inteiro nos
  dois eixos por construcao
- O readout do menu inicial lia a escala do `content_scale_factor` — teria
  mostrado "2x" enquanto a imagem estava em 4x. Agora sai de `janela / canvas`
- `tests/test_look.gd`: a aritmetica virou funcao pura (`scale_for`,
  `canvas_for`) e ganhou suite. Fixa que 1080p da 1x, 1440p da 2x e 4K da 3x, que
  `canvas x escala == janela` nos dois eixos, que `content_scale_factor` sai em 1,
  e que a escada de corpos cai na grade das fontes (multiplo de 9 na Pixel Code,
  de 5 na VT323)

### Changed - B.6f: canvas de projeto 1280x720 (2026-09-16)
- **O canvas de projeto vira 1280x720** (`Look.DESIGN_MIN`), escolhido pra que
  todo monitor comum peque um degrau inteiro em vez de ficar preso em 1x: 1080p
  1x, **1440p 2x**, 4K 3x. O tamanho aparente passa a acompanhar o monitor
- **Criação em tres abas**: FICHA (cenario, nome, seed, clube, modalidade +
  atributos e corpo), HABILIDADES (15 em duas faixas), TALENTOS (27 numa grade
  que da pra ler). Antes eram tres colunas de 1850x1040
- **Elenco**: os dezoito codigos de posicao (3 admin + 5 comissao + 10 escalacao)
  rodam em `Look.MICRO` — 9px, o outro degrau nitido da fonte. Sao duas ou tres
  letras num botao, nao prosa, e a 2x/3x eles saem em 18 ou 27 pixels reais
- **Draft** mais curto: log de 470 para 330, margens do painel de 24 para 14
- Disciplina de espaco que valeu por si: **dica de uma linha** com o resto no
  tooltip (eram seis paragrafos de 4-5 linhas), e **rotulo de campo virando
  placeholder** — um label acima de cada campo era 22px, cinco campos, 110px de
  uma coluna de 520
- `fit_check` agora mede contra 1280x720

### Fixed
- **Icone de talento repetido.** Dois dos treze talentos novos reusaram glifos que
  ja estavam no catalogo (`ferrolho`/`braco_de_ouro` e `capitao`/`voz_de_comando`).
  O icone e a coluna Talento inteira do elenco — uma caixa de 26px com um glifo —
  entao repetido faz a coluna mentir, e o teste de tela que devolve um talento
  comecou a devolver o de outro. Invariante virou teste
- O rodape do formulario tinha 1379px de largura (uma dica de 700px ao lado de
  tres botoes), sozinho mais largo que o canvas

### Fixed - B.6e: o quadrado no meio da tela (2026-09-16)
- **`Look.fit_window()` calcula a escala no runtime**, porque a configuracao do
  projeto nao consegue expressar a regra: `scale_mode="integer"` arredonda a
  escala pra baixo e poe tarja na sobra, e `aspect="expand"` NAO devolve essa
  sobra. Num 2560x1440 com base 1920x1080 isso desenhava um canvas de 1920x1080 a
  1x no meio da tela com 320px de borda em volta — o quadrado
- A regra e `canvas = janela / escala`, com a escala sendo o maior inteiro que
  ainda deixa `DESIGN_MIN` (1920x1080) de espaco. Entao a sobra vira canvas
  usavel: 2560x1440 -> 1x com canvas 2560x1440, e 3840x2160 -> 2x com canvas
  1920x1080. Preenche e fica em pixel inteiro em qualquer resolucao
- O readout do menu inicial passa a mostrar o canvas REAL em vez do declarado, que
  e a unica versao que serve pra diagnosticar
- `FONTS.md` ganhou a conta de por que letra maior e sempre "menos coisa por
  tela", com os numeros do caso 1440p: 1x da 2560x1440 de espaco e 18px de corpo,
  2x da 36px de corpo e so 1280x720 de espaco — e o formulario pede 1850x1040

### Fixed - B.6d: 4K nao era 4K (2026-09-16)
- **`allow_hidpi=true`.** Sem isso um monitor 4K nao e um monitor 4K: o Windows
  poe display de 4K em 150% por padrao, e um app que nao e DPI-aware recebe uma
  janela de 2560x1440 e e esticado borrado pra preencher o painel. Junto com
  escala inteira da um desastre visivel — `floor(2560/1920)` e **1**, entao o jogo
  desenhava um canvas de 1920x1080 no meio de uma janela de 2560x1440: quadrado
  pequeno, cercado de borda, e ainda esticado pelo compositor
- **`aspect="expand"` no lugar de `keep`.** A escala inteira ja garante pixel
  inteiro; o `keep` ainda punha tarja no que a escala nao usou. Em 3840x2160 a 2x
  os dois sao identicos, entao expand nao custa nada ali e tira a borda no resto
- **O numero esta na tela**: canto inferior direito do menu inicial mostra
  `3840x2160 · canvas 1920x1080 · 2x · corpo 36px`. Um **1x** ali diz na hora que
  a janela nao e multiplo do canvas
- Escada de display subiu um degrau (45/35/30/25), que e onde havia folga: VT323
  nao e grid-bound alem da linha de base em multiplo de 5, e titulo e uma linha so
- `FONTS.md` ganhou a aritmetica do tamanho aparente, que e a conta que decide o
  resto: `aparente = corpo logico x escala`, `escala = floor(tela / viewport)`

### Fixed - B.6c: pixel perfect de verdade (2026-09-16)
- **`scale_mode="integer"`.** Metade do "nao esta pixel perfect" nao era fonte: o
  modo padrao escala o canvas por quanto a janela precisar (1,333x num 1440p) e
  rasteriza cada glifo, barra e retangulo numa fracao de pixel. Custo assumido e
  documentado: 1080p -> 1x, 2160p -> 2x, **1440p -> 1x com borda**
- **A escada de corpos foi MEDIDA nos arquivos, nao escolhida.** O mdc das caixas
  de todos os glifos e o tamanho de um pixel de design: Pixel Code tem 112
  unidades por pixel num em de 1008, entao os corpos nitidos sao 9/18/27/36. A
  escada anterior usava 12, 14 e 16 - todos fora, e o 16 punha um pixel de design
  em 1,78 pixels de tela. **O corpo agora tem um tamanho so** (18), porque nao
  existe degrau nitido entre 9 e 18; hierarquia sai da cor
- VT323 nao e fonte de pixel (mdc 4 num em de 1000), e outline imitando CRT. O
  que ela tem e metrica que so fecha em multiplo de 5 - display virou 20/25/30/40
- **O painel parou de mudar de tamanho entre cenarios.** Pinado nos dois eixos, e
  toda largura da linha de cores capada: o nome do clube e digitado pelo player e
  um nome longo movia o painel dois pixels
- **Talentos em duas colunas**: qualidades a esquerda (3 colunas), defeitos a
  direita. O sinal e a divisao - sao decisoes diferentes, uma gasta o saldo e a
  outra o financia, e misturadas em ordem de catalogo obrigava a ler o preco de
  cada chip
- Corpo em 18 fez a tela ir a 1329px, e o culpado eram os textos de ajuda: seis
  paragrafos de quatro ou cinco linhas. **Hint agora tem no maximo duas linhas** e
  carrega o resto no tooltip - e a descricao inteira do cenario, que estava
  desenhada em dez linhas, saiu (ja era o tooltip do chip)
- `fit_check` tambem verifica que o painel **nao muda de tamanho** entre os tres
  cenarios

### Added — B.6b: pixel art, layout e talentos (2026-09-16)
- **Duas fontes de terminal**, e as duas de proposito: o Elifoot era um jogo de
  DOS, e um simulador 100% painel nao tem sprite pra carregar o clima — a fonte
  carrega. **VT323** (matriz do DEC VT320) no display, **Pixel Code** (pixel
  monoespacada) no corpo. Monoespacada nao e gosto: metade do jogo e coluna de
  numero, e monoespacada alinha de graca
- **Render em Nearest** no projeto inteiro, e antialiasing / hinting / subpixel
  desligados no import — fonte pixel com antialiasing vira mingau
- `Look` — as duas faces e a escada de tamanhos num lugar so. ⚠️ Nao `Skin`:
  Godot ja tem essa classe (o recurso de esqueleto) e o `class_name` e erro de
  parse na hora
- **Formulario de criacao em tres colunas com rodape fixo**: quem voce e |
  atributos + corpo | habilidades em duas sub-colunas + talentos. Atributo e
  corpo lado a lado porque o corpo DESLOCA o atributo, e ler um com o outro fora
  da tela era o pior do scroll
- **Escalacao a esquerda, tabela a direita.** Voce le da esquerda pra direita, e
  a pergunta com que chega e "quem e meu time e o que falta" — a resposta e o
  painel
- **Talentos: 10 para 27.** Nenhuma das 15 habilidades fica sem talento (antes
  eram 11 descobertas). 20 qualidades, 7 defeitos
- `tests/fit_check.tscn` — o quarto harness: toda tela cabe em 1920x1080, e nao
  cabe usando um terco

### Fixed
- **O formulario de criacao pedia 1743px numa tela de 1080**, numa coluna de 940
  com dois tercos do monitor vazios do lado. Agora 1850x1050, sem scroll
- **A fonte nova e ~40% mais larga**, entao toda largura fixa calibrada contra a
  sans passou a estourar. Medido e corrigido um por um: dado com legenda de 185px
  (virou icone com tooltip), clube em duas linhas, chips de modalidade que
  embrulham, e o resumo do corpo — uma frase de 432px numa coluna de 400
- **Colunas da tabela do elenco** crescidas pra caber a monoespacada
- `HFlowContainer` reporta largura minima que depende da largura que recebeu:
  com 27 talentos voltou 81px acima do orcamento e empurrou o painel pra fora da
  tela. Grade, cujo minimo e a soma das colunas

### Changed — B.5e: peneiras no lugar do pool mundial (2026-09-16)
- **`Tryout`** — de onde jogador de flag realmente vem. Duas portas: o jogador de
  FA que tambem joga flag e aparece sozinho (o turnout indie), e quem o clube foi
  la e CHAMOU. A peneira gera **2d5* + alcance** candidatos **no nivel do proprio
  clube** — Bangu Castores peneira um pool Q1, Flag Kings peneira outro
- **A rodada**: peneiras → indies → draft da praca, sempre **do melhor clube pro
  pior**. Os melhores enchem primeiro e quem sobra fica com os piores, que e como
  funciona e e por que a tabela de tier nao precisa que ninguem a declare
- `LeagueGenerator.pick(clube, pool)` aponta pro lado CONTRARIO do antigo
  `draft(actor, times)`, de proposito: clube que faz compras sempre tem o que
  fazer, enquanto pessoa oferecida de clube em clube pode ser recusada por todos
  e voltar na rodada seguinte pra ser recusada de novo
- A peneira orienta o **CORPO**, nunca a posicao — decisao 47 intacta: uma peneira
  de center pode revelar um safety, ele so apareceu porque viu o cartaz
- **Comissao tecnica entra no elenco**, com orcamento separado e uma pessoa por
  cadeira. Quem e contratado como tecnico ja senta na cadeira (atleta nao:
  escolher os titulares e trabalho do player) e nao usa camisa

### Fixed
- **O "ninguem quis" de dezenas de linhas seguidas.** O gerador tinha PDF de
  posicao fixa e a condicao de parada dependia de posicoes especificas: liga sem
  center ficava rolando recebedor e recusando, esperando o dado. Agora a oferta e
  criada pelo clube para o buraco dele
- **Deadlock entre o teto de elenco e a jogabilidade.** Clube batia no
  `target_size` ainda com buraco na formacao: `is_built` exigia jogabilidade,
  entao ele seguia peneirando, e `wants` recusava todo mundo porque o elenco
  estava cheio. A rodada nao assinava ninguem, a guarda de estagnacao disparava,
  e a liga embarcava com cinco times que nao conseguiam escalar cinco. Buraco na
  formacao agora vence o teto
- **Peneira anunciando as onze posicoes nao orienta nada** — os candidatos se
  espalhavam um por posicao e o buraco real recebia um corpo em onze. Quatro
- **A orientacao vazava pro QB.** O clube pedia recebedor, o corpo era escolhido
  pra recebedor, e o matcher dizia "quarterback" — as duas posicoes querem coisas
  parecidas e QB e o vetor mais facil de pontuar. Todo clube encostava no teto de
  QB ainda faltando recebedor. Peneira agora te testa na posicao que anunciou

### Added — B.5d: a tela do draft (2026-09-16)
- **Tela do draft** entre a criacao e o elenco: barra de progresso, legenda de
  fase e o **log do draft** — quem foi pra onde e POR QUE. Com botao [OK], que
  espera voce em vez de a tela passar sozinha
- `LeagueDraft` — o mesmo draft, retomavel. `LeagueGenerator.fill()` virou um
  `while not is_done(): step()` por cima dele, entao o teste e a tela rodam
  exatamente o mesmo codigo
- A tela trabalha por **orcamento de tempo** (25ms/quadro) e nao por contagem de
  passos: um passo e uma carreira vivida, e elas nao tem o mesmo tamanho — um
  veterano de quinze anos custa o triplo de um moleque, entao contar passos
  engasgaria justo onde o trabalho e mais pesado
- `tests/test_screen_draft.gd` e `test_the_draft_writes_down_what_it_did`: a
  barra nunca anda pra tras, o log nunca sai com formatacao crua (que e a cara
  de uma chave de traducao faltando), e os dois caminhos montam o mesmo mundo

### Fixed
- **A tela do time congelava ~9s montando o mundo** sem repintar nada. Agora a
  montagem tem tela propria; o caminho sincrono continua existindo como recurso
  pra teste e save restaurado, e e por isso que ele nao e mais o normal
- **A barra de afinidade da tabela era verde cravado** e brigava com a cor do
  clube — elenco de time amarelo com barra verde em cima de fundo amarelo. Agora
  `StatBar.tint()` recebe a cor, e a tela passa a do clube. Junto foram os
  outros verdes soltos da tela: fundo dos botoes de posicao, bordas, o chip de
  escalacao, a linha da tabela e a tinta que vai EM CIMA do accent

### Added — B.5c: a Praca e o draft (2026-09-16)
- **`LeagueGenerator`** — o mundo inteiro num laco so: `spawn` poe gente na
  Praca, `draft(actor, teams)` decide quem leva, e isso roda ate todo clube
  estar cheio. Substitui o elenco montado dentro do clube que precisava dele
- **`Praca` (Record)** — quem nao tem clube, e a unica origem de gente no jogo.
  Fica com residuo depois do fill: liga que para de spawnar no instante em que
  todo clube ficou legal tem mercado vazio no dia um. KPIs: tamanho, idade
  mediana, geral mediano, nivel mediano
- **`ActorGenerator.spawn(semente_mundo, semente_actor, nivel)`** — desacoplado
  de clube. A posicao vem do CORPO, entre as posicoes de quadra
- **Ninguem nasce preparador fisico.** O matcher escolhia entre as 14 posicoes,
  5 delas de comissao — dai o elenco com mais prancheta do que jogador. Cadeira
  de comissao e transicao de fim de carreira: `PositionDef.match_on_sides`
- **`Rosters` deixa de gerar e passa a receber.** Sobrou o que sempre bastou:
  uma lista por clube que outro preenche
- **Estratificacao emergente.** Ninguem atribui qualidade a clube — o draft casa
  nivel com nivel e a tabela de tier cai sozinha. Federados saem acima da varzea
  sem que nada diga isso
- **Origens viram trajetoria, nao cargo.** `track: player | staff` no lugar da
  posicao fixa. Isso mata os tres sintomas de uma vez: o ex-jogador deixa de ser
  sempre QB, o fundador deixa de ter so skill de gestao, e o estudado (que tinha
  `years_max: 0`) passa a variar
- **O Fundador batiza o proprio clube** — nome, bairro, cidade e cores, com os
  campos abertos ja preenchidos pela semente. E nao e draftado
- `city` e `neighborhood` viram campos separados: o bairro e o que identifica um
  clube nesse nivel, mas o fundador precisa poder escolher os dois
- `tests/test_league_generator.gd` — 10 testes sobre o campeonato INTEIRO, que e
  onde o bug morava: cada teste antigo olhava um clube so

### Fixed
- **O draft comparava duas reguas diferentes.** Reputacao vai de 14 a 90; Geral,
  nesse tier, vai de 14 a 30 — entao todo jogador parecia de varzea pra
  subtracao, os clubes fracos ganhavam todo termo de fit e os fortes assinavam
  so o que sobrou. Flag Kings saia com elenco PIOR que o Madureira. Agora os dois
  lados usam a escada do mundo, que e a regua que ja compartilham
- **O laco parava na legalidade em vez da lotacao**, deixando todo mundo no piso
  de 7 inscritos — clube tier 1 saindo menor que clube tier 4, e a Praca vazia
- **Ninguem carrega um quarto quarterback.** Sem teto de excedente o melhor clube
  da liga juntava 6 rushers numa posicao de 1 vaga, porque ganhava no fit e nada
  dizia nao. Dois alem da formacao e o limite
- **O manager podia sair com 15 anos e a ficha vazia** — orcamento de 3 career
  points, tela desenhada e todo botao morto. Voce nao esta criando uma crianca:
  estreia adulta, mais os anos de quem ja anda pelo esporte
- `test_the_opening_leaves_nobody_hollow` existia no arquivo e **nunca estava na
  lista** — nunca rodou


### Added — B.5: a tela do clube (2026-09-15)
- **Tela do clube** com abas Elenco e Adversarios. Clicar em alguem abre a
  ficha completa — 8 atributos, habilidades treinadas, corpo, perk. E isso que
  paga a divida de A.2/A.3: ~700 linhas de modelo que nunca viraram pixel
- `ActorDef`: atletas curados como Thing de modulo, **esparsos**. Seis linhas
  de JSON viram uma pessoa completa; o que o curador nao escreve, o gerador
  preenche a partir da reputacao do clube. Semeado pelo id do atleta, entao o
  mesmo atleta sai igual em toda carreira
- Fonte posterior **mescla** por id em vez de substituir — um mod que so quer
  mudar uma stat escreve so ela
- `Rosters` (Record): quem joga onde AGORA. Estado, nao formula — elenco
  derivado da semente quebraria na primeira contratacao. Montado por clube na
  primeira leitura
- Validacao do elenco curado, rodando na suite: clube inexistente, id
  duplicado, habilidade escrita errado, numero fora de faixa, perk inventado
- `content/ELENCOS.md` — guia de curadoria
- Colunas do elenco: **Nome | Perk | Forca | Idade**, com a Forca tingida num
  gradiente cinza(0) -> verde(100), a mesma leitura das barrinhas
- **Clicar num adversario abre o elenco dele** — a aba listava clube e parava
  ali. Com botao de volta pro seu
- `StatBar` corta rotulo longo em vez de empurrar o painel ("Chamada de
  jogada" abria a ficha inteira)
- A ficha mostra **todas** as 15 habilidades, treinadas ou nao, agrupadas e
  com rolagem. Esconder as zeradas fazia a ficha de um gerado (tudo acima de
  zero) e a de um manager feito na mao (uma ou duas) crescerem linhas
  DIFERENTES, e duas fichas incomparaveis nao servem pra nada
- d5star v0.5.0: o scanner de Things aceita qualquer layout de pasta

### Added — B.4c: nome, apelido e perks (2026-09-13)
- Nome, sobrenome e apelido em TRES campos separados na criacao do gestor
- Gerador de apelidos coerente com o actor, quatro fontes:
  morfologia do nome (Pedro -> Pedrinho, Lucas -> Luquinho, Thiago ->
  Thiaguinho), do sobrenome (Vasconcelos -> Vasco), do que ele e notavel por
  (9 de agilidade -> Foguete, 2 de percepcao -> Tapado) e o saco aberto
- 313 apelidos novos em `name_gen.json`, indexados por stat e direcao
- `StatDef.notable_traits()`: atributo conta pros dois lados, habilidade so
  pra cima — um amador tem 12 habilidades zeradas por nunca ter treinado
- `PerkDef` + `game/defs/perk.json`: os 10 perks aprovados, com preco em
  career point. Defeito DEVOLVE pontos (Vidraca +30, Sumido +30, Maos de
  pedra +25), no maximo 1 por actor, e nao pegar nenhum e uma resposta
- A semente agora e `hash(nome + sobrenome + apelido)` — escreva os tres num
  papel e voce volta ao mesmo mundo (inverte a decisao 21)
- Um so 🎲: sorteia nome, sobrenome, apelido, a vida inteira em career points
  e talvez um perk. `SheetBuilder.roll_random()` gasta tudo com apetites
  lognormais, entao sai especialista e nao uma linha reta na media
- `ActorGenerator` usa o mesmo catalogo — um jogador garimpado le igual a um
  criado. Prepara os elencos aleatorios de B.5
- 31 testes novos (`test_names`, `test_perk`, `test_screen_create_manager`)

### Changed
- A tela de criacao **sorteia um moleque de 12 anos** em vez de abrir em 5 em
  tudo: corpo, os 8 atributos entre 2 e 7 (piso de bebe, teto de crianca
  excepcional) e as vezes um perk, que sai dos mesmos 12 anos e da um tom ao
  personagem. **Nao encosta nas habilidades** — como um teste e atributo +
  habilidade, decidir isso pelo jogador esvaziaria a unica pergunta da tela.
  Sobram ~130 career points, os 6 anos que fazem dele um adulto
- O 🎲 sorteia outro moleque, identico a abertura. Um verbo so: os dados
  escolhem quem voce nasceu, nunca quem voce virou. `roll_random()`, que
  gastava os 414 e entregava um adulto pronto, saiu — ficou sem chamador

### Changed
- **Modalidade virou multipla escolha**: masc, fem, masc+misto, fem+misto ou
  nenhuma. Misto sozinho nao vale — o time misto tem cota de mulheres, entao
  precisa saber que vaga voce ocupa. `ActorGenerator` passou a gravar isso
  tambem: um elenco misto sai com `[masc, misto]` / `[fem, misto]`

### Fixed
- Botao **Sair** nao fazia nada, e o primeiro conserto tambem nao funcionou:
  `Game` conectava `flow_finished`, mas `Game` E a cena de boot e o primeiro
  `change_scene_to_packed` libera ela — o sinal chegava num objeto morto antes
  do jogador ver a tela inicial. Agora o boot DECLARA `Flow.quit_on_finish` e
  quem executa e o Flow, que e o no feito pra sobreviver a troca de cena.
  d5star v0.4.2, e `tests/quit_check.tscn` aperta o botao de verdade
- Voce era sorteado pra um clube **inexistente na lista**: `club_select` chama
  `League.ensure_filled()` sem semente e o default era uma constante, entao a
  tela seguinte reconstruia a varzea de outro mundo e o clube que tinha acabado
  de te chamar sumia. O default agora pergunta pro Blackboard qual carreira
  esta rodando — tela que nao liga pra semente nao tem como errar
- `League.ensure_filled()` era idempotente pelo NUMERO de clubes, entao trocar
  a semente nao trocava a varzea. Agora refaz quando a semente muda, e
  `TeamDef.remove_generated()` poupa os clubes autorais
- O runner esperava um frame antes de rodar: dentro de `_ready` a arvore ainda
  esta montando filhos e `add_child()` e recusado, o que trancava fora
  qualquer suite que precise montar uma tela

### Changed — B.4b: a ficha ganha dados, habilidades e idade (2026-09-09)
- D5 na d5star v0.4.0: o dado explodente que da nome a lib
- 8o atributo: Vontade (resiliencia mental)
- camada `derived` removida; 15 HABILIDADES no lugar, cada uma regida por um
  atributo. Roll = atributo + habilidade + 2d5*
- altura e peso trocam atributos (soma zero), nao custam pontos
- criacao paga em anos: crianca de 12 -> adulto de 18
- modificador de lider = passo - 5

### Added — B.1 a B.4: o loop de abertura (2026-09-08)
- Start Screen, Ajustes (PT/EN), Selecao de Modulo, Criar Gestor
- Todo texto de UI em i18n (`game/defs/ui.json` + `UiText.t()`)
- TeamGenerator: 6 clubes de varzea carioca completam o campeonato em 16
- CategoryDef: masc/fem/misto x 5x5/4x4, com min_women
- Actor perdeu `gender` e ganhou `plays`/`manages`
- `Career extends Record`, produzido no Blackboard e validado pelo Flow

### Added — A.3 Actor (2026-09-06)
- `Actor extends Thing` em `game/model/` — jogador, tecnico, scout e o
  manager sao a MESMA entidade; funcao e escalacao, nao tipo
- `ActorGenerator` deterministico: mesma seed, mesmo actor. Sub-seeds salgadas
  por indice, entao crescer o elenco nao embaralha quem ja estava nele
- Sem sistema de arquetipos: como cada derivada le um trio diferente de
  atributos, variancia simples ja produz especialistas (16 pontos medios de
  espalhamento entre a melhor e a pior derivada de cada actor)
- Nomes vindos do name_gen salvo do life sim, com pools por genero

### Added — A.2 modelo de atributos (2026-09-06)
- 7 atributos base: strength, stamina, agility, dexterity, perception,
  intelligence, charisma
- 9 stats derivadas, cada uma a media (piso) de exatamente 3 atributos base:
  speed, passing, catching, protection, pressure, coverage, reading,
  leadership, trash_talk
- "Geral" (overall): media dos 7 atributos base, arredondada pra baixo
- Suite de testes do FFM em `tests/run.tscn`, rodando por cena
- Removidos skill.gd/skill.json — as derivadas substituem os 12 skills

### Changed — virada para club manager (2026-09-05)
- O jogo abandonou a simulacao da vida do atleta e voltou a ser um club
  manager: "o Elifoot 2000 do flag football". Plano completo em `roadmap.md`.
- Engine trocada para a d5star como submodule (`addons/d5star`).
- Docs do life sim removidos deste branch (TODO.md, release_0.1.0.md,
  game/docs/mechanics.md) — preservados na tag `pre-d5star-migration` e na
  branch `legacy/life-sim`.

### Added (Phase C.1/C.2 — Ato 0 team picking)
- Existing 8 teams tagged `division: "1a_div"` (not accessible in Ato 0)
- 4 fictional 4a_div teen teams with distinct archetypes (`pelada_quadra`, `colegio_bulldogs`, `clube_recanto`, `undergrounds`) — each with `drill_focus`, `difficulty`, `tryout_threshold`, fixed `tryout_week`/`tryout_day`/`tryout_slot`, and bilingual descriptions
- **Phone** scene (`game/modules/brasil_2026/ui/phone/phone.{gd,tscn}`): grid of apps → Network (social feed) → team account → Ficha with "Inscrever no tryout" button
- Enrollment flow: clicking Inscrever persists `The.session.enrolled_tryouts[team_id] = {week, day, slot}`
- `_apply_enrolled_tryouts()` in player_home overrides the matching day/slot with "★ Tryout: \<team\>", disables the OptionButton, and tags it with a `tryout_team_id` meta
- Slot resolution detects the tryout meta and routes to `_run_tryout_for_team(team_id)` instead of the normal activity flow; passes `drill_focus`, `difficulty`, `tryout_threshold` into tryout config (consumed by C.3 balance)
- Tryout music swaps to `tryout_intense` during the attempt and back to `home_ambient` after
- Passing a team-specific tryout sets `session.team_id = team_id` (no longer `pending_selection`) so win screen shows the actual team joined

### Added (Phase B — audio)
- `AudioDef` (`game/defs/audio.gd` + `audio.json`) — mapping of music/sfx ids to file paths, buses, and loop flags
- `Audio` autoload (`engine/globals/audio_manager.gd`) — `play_music(id)` with cross-fade between tracks, `play_sfx(id)` with pooled `AudioStreamPlayer`s, `stop_music()`; silently no-ops when the mapped file is missing so the game runs without audio assets
- Music cues wired: `main_menu` → main menu, `home_ambient` → player home, `victory` → Ato 0 win, `game_over` → game over
- SFX cues wired: `menu_click` on all menu buttons, `card_pick` on card select in drill, `pass`/`fail` on drill situation result, `week_advance` on week finalize, `collapse` on vital-triggered binge, `fridge_open`/`menu_open`/`menu_close` on room windows
- `audio/README.md` documents the expected filenames so the user can drop `.ogg` files in and Godot auto-imports them

### Added (release 0.1.0 prep)
- SaveManager autoload (single-slot save + Hall of Fame + settings) at `engine/globals/save_manager.gd`
- Main menu Continue button + new-game overwrite confirmation
- Auto-save at end of each week in `player_home`
- Game Over screen + Hall of Fame entry on 4 failed tryouts
- Win screen (Ato 0) saved to Hall of Fame with act0_complete result
- Hall of Fame screen listing past careers from main menu
- Options menu: Master / Music / SFX volume sliders, language toggle (PT/EN), reset defaults, persisted to `user://settings.json`
- 3-bus audio layout (Master / Music / SFX) in `default_bus_layout.tres`
- Save & Quit button in player_home tool row (blocked while a week is resolving)
- Unified action bar in player_home: `[SPACE] PAUSE | [Q] ATIVIDADE | [W] DIA | [E] SEMANA | X | [ESC] MENU` — replaces per-day `>`/`>>` columns for a cleaner grid
- ESC hotkey opens Save & Quit; pause button toggles PAUSE/RESUME label inline

### Fixed
- Continue after clearing Ato 0 now returns to the win screen instead of dropping back into the weekly grid (Act 1 unavailable); session flag `ato0_complete` drives the routing
- Save & Quit mid-week now persists per-day resolution progress (`day_resolved`, `day_slot_index`, `slot_colors`); previously resolved slots would reset to unplayed on reload, double-applying their vital/money effects when replayed
- Starting a new career now wipes `The.session` before module select; prior-run grid selections, `ato0_complete`, and tryout counters no longer bleed into the fresh playthrough (both main-menu NEW GAME and game-over NEW GAME paths)
- Replaced cryptic `X` clear-plan button with labeled `LIMPAR PLANO` / `CLEAR PLAN`

### Added (4.x cycle)
- Technique card system (`technique.gd`/`technique.json`): rarities, tiers, personalities (intenso/tecnico/estrategico), coins, vital_cost, situation_tags
- Drill system (`drill.gd`/`drill.json`): 8 drills (3 physical + 5 position: qb/wr/center/db/rusher)
- Drill minigame in NEO Scavenger format: player | other sprites, narrative prompt, card hand (commons always available via tag match + memory cards from deck), d5* dice, yomi rock-paper-scissors between personalities
- Tryout manager: position select → 3 physical drills → 1 position drill → results
- Common cards auto-appear in hand when their tags match the situation's tags; memory cards (uncommon/rare) drawn from deck
- Added `respirar_fundo` (recovery common) and `tentativa_honesta` (universal fallback)
- Origin system, cutscene, fridge meals with delivery cascade, hunger auto-resolution, tryout failure counter

### Changed (4.x cycle)
- Tryout uses drill_minigame for all drills (removed old card_minigame path for position drill)
- Position drills converted to NEO Scavenger format with situations + tags + check_stats
- Replaced green field + animated dot viewport with player/other sprite panels


### Added
- Module select screen: choose campaign module before character creation
- Module manifest now supports i18n fields (name, description) and version
- Player age set to 15 (was 16)
- Gender toggle (M/F) on character creation header
- Language toggle (PT/EN) button on home screen top bar
- All UI strings converted to i18n dicts: activities, stats, skills, vitals, day names, room items, all menu buttons, cutscene pages bilingual PT/EN
- Cutscene pages now loaded from injectable Thing JSON (`group: "cutscene"`) with i18n text + image field
- Weekly planner: 7x4 grid (Mon-Sun x Morning/Afternoon/Night/Late Night) replaces daily slots
- Late Night time slot added to activities, "Stay Up Late" activity added
- NEXT WEEK button resolves all 28 slots, CLEAR resets grid
- Per-day play buttons: [>] resolves one day, changes to [ok] when done
- Days must be resolved in order (Mon->Tue->Wed...)
- Color-coded outcomes: blue (running), green (good), yellow (neutral), red (bad)
- Log text colored to match outcomes via BBCode
- Progressive resolution with 500ms delay per slot, vitals update live
- TV renamed to Computer
- Slot synergy/penalty matrix: activities have slot_modifiers, effects scaled by modifier
- Vital collapse: when vital hits 0, planned activity replaced by binge (APAGAO, COMILANCA, CARENCIA, MARATONA DE CELULAR)
- Per-day play buttons: > (single slot), >> (full day), >> WEEK (all remaining)
- Color-coded calendar and log: green=synergy, yellow=normal, red=collapse
- Progressive resolution with 500ms delay, vitals update live
- Column header dropdowns: set all 7 days in a slot at once
- Week summary popup: vitals before/after, money delta, activities by color
- Cutscene: BACK/NEXT/SKIP buttons
- Weekly quests sidebar: injectable per week via Things, live tracking, summary results
- 9 attribute training activities with 3 events each (pos/neu/neg), stat bonuses
- HP vital, Room (quarto) vital
- Activity categories: BRUTALITY/FINESSE/COGNITION/SCHOOL/FAMILY/FRIENDS with grouped dropdowns
- All activities available in all 4 time slots (soft margins via modifiers, no hard locks)
- Late night global energy penalty (-15 for non-sleep activities)
- Fridge meal system: cooking stocks meals, hunger=0 eats from fridge before collapse
- Floating draggable fridge window with live meal count
- Week schedule carryover (copies previous week's choices)
- Beach Football and Video Games activities
- Quest type: activity_category_count (tracks any activity from a category)

- Technique card system: collectible cards with personality types (Intenso/Tecnico/Estrategico), yomi layer, d5* dice, vital costs
- Drill minigame: situation sequences with technique card hand, multi-card play, synergy, viewport animation
- New Defs: TechniqueDef (technique.gd/json), DrillDef (drill.gd/json) — 9 basic + 6 advanced + 4 casa + 6 meta + 6 origin cards
- Personality selection in character creation with starter deck (1 base + 1 origin bonus)
- Tryout physical drills now use drill_minigame with technique cards (40-yard, three-cone, shuttle)
- Hand panel permanent on home screen, hotkeys changed: Q/W/E for slot/day/week, 1-5 for cards, S for skip
- Mechanics reference document: game/docs/mechanics.md
- Home screen redesign: sidebar (casa/vitals/quests/diary/effects) + main panel (grid + embedded viewport)
- Minigames now embedded in SubViewport instead of Window popups (play_minigame, tryout)
- Room placeholder shown in viewport when no minigame is active
- Log replaced with Diary (narrative text in sidebar, scrollable)
- Origin system: 3 origins (quebrada/condomínio/mansão) with distinct starting money, fridge, vitals, stat modifiers
- School system: 3 schools (público/bairro/elite) with stat modifiers, turno selection (1=manhã, 2=tarde, 3=noite)
- Body system: height (150-200cm) and weight (45-110kg) sliders with threshold-based stat bonuses
- All origin/school/body modifiers stack and display live during character creation
- New Def: OriginDef (origin.gd + origin.json) with compute_modifiers, turnos_for_school
- Session stores origin, school, turno, height, weight for downstream use
- Hunger system: auto-meals at breakfast (morning) and dinner (night) when hunger < 80
- Meal source cascade: fridge (free, +35) → delivery (R$15, +30) → lanche (up to R$30, scaled)
- Emergency cascade at hunger=0: same sources, fridge gives +25 (smaller emergency portion)
- Collapse only triggers when broke and no fridge — cooking is now strategic
- Route card drawings now use fixed scale (100-unit reference), preserving relative route sizes
- Hotkey labels on play buttons: [1]> slot, [2]>> day, [3]>> week
- Fridge and mirror windows now unfocusable — keyboard shortcuts toggle them properly
- Team practice uses play_minigame (5 rounds, diff 2, 12s timer) with events (Foco Tático buff, Coach's Scolding debuff)
- Minigame activities now continue to effects/events after minigame (no early return)
- Play card minigame: route drawings on cards (Line2D) instead of text names
- Generalized card minigame (card_minigame.gd): supports path, label, and play_ref card types
- Tryout system overhaul: position selection (QB/WR/Center/DB/Rusher) → 3 physical drills (40-yard dash, three-cone, pro agility) → 1 position-specific drill → results
- New "TEAM" activity category with tryout moved from brutality
- Physical drill minigames: sprint reaction (GO/HOLD), cone path matching, shuttle direction calls
- Position drill minigames: QB defensive reads, WR/Center route recognition, DB coverage calls, Rusher rush reads
- Tryout pass/fail: 60% combined threshold (9/14 points)
- WIN screen on tryout pass with position display
- GAME OVER screen when week 4 ends without team (returns to main menu)
- Tryout results breakdown in weekly summary popup
- Activity requires: no_team check (hides tryout after joining team)
- Fixed activity dropdown index mapping: _grid_activities now uses grouped order matching dropdown display

### Changed
- Removed gym/academia, train_solo, socialize, stay_up_late activities
- Renamed activities for 15yo context: Hill Sprints, Calisthenics, Parkour, etc.
- Cooking now stocks fridge (+3 meals) instead of direct hunger restore
- Timed effect system: events produce buffs/debuffs lasting N slots (Runner's High, Zen, Contusão, etc.)
- Effect cards in bottom bar with styled panels (green/red border)
- Mirror/character sheet window (M key): stats with effect modifiers, skills, active effects
- Keyboard shortcuts: SPACE pause, 1/2/3 slot/day/week, F fridge, M mirror
- Realistic default week schedule for 15yo student
- Removed Sleep In (merged into Sleep with morning 0.8x soft margin)
- Activity lock/unlock system: requires field (min_age, has_item, has_team, week_range). Locked activities hidden from dropdowns, appear when unlocked.
- Locked activities added: Part-time Job (age 16+), Gym (membership), Team Practice (has team)

### Changed
- Home screen layout: grid takes ~75% width (left), room + vitals + log on right
- "Plan your day" → "Plan your week", "Next day" ��� "Next week"
- Day advances by 7 per week instead of 1

### Changed
- Main menu START → module select → character creation (was: START → creation)
- Character creation BACK → module select (was: BACK → main menu)
- activity.json, stat.json, skill.json now use `{"pt": ..., "en": ...}` format
- Home screen fully i18n-aware: labels, dropdowns, log messages update on language switch

## [0.0.1] — 2026-04-07

### Added
- Engine ported from SugarLoaf: Thing system, modules, Defs, command bus, i18n, logging
- Main menu: Continue / Start / Options / Quit
- Character creation: Player/Coach toggle, RPG stat sheet (Brutality/Finesse/Cognition), star/dummy mark system, read-only skills panel
- Stat Def (`game/defs/stat.gd`): injectable attribute groups via JSON
- Skill Def (`game/defs/skill.gd`): injectable skills (Offense/Defense/General) via JSON
- Creation Def (`game/defs/creation.gd`): injectable balancing rules via JSON
- Activity Def (`game/defs/activity.gd`): 12 daily activities with time slots and vital effects
- Cutscene: 7-page narrative intro
- Home screen: top bar (money/calendar), weekly planner (3 slots), room objects, vitals panel, effects bar
- Day progression: resolve activities, apply effects, vital collapse warnings
- 8 Brazilian flag football teams as Things with full rosters: Flag Kings (RJ), Cronos (SP), Spartans (SP), Predadores (MS), Coritiba Crocodiles (PR), Fortaleza Tritões (CE), Floripa Ghosts (SC), Cavalaria 2 de Julho (BA)
- Base player Thing with 9 attributes + 12 skills
- `project.godot` configured with autoloads and Forward Plus rendering
- `roadmap.md` with full development roadmap (Cycles B-I)
- `CLAUDE.md` with project conventions and architecture docs
