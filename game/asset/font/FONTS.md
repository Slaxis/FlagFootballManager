# Fontes

Duas, e as duas são de terminal de propósito: **o Elifoot era um jogo de DOS.**
Um simulador que é 100% painel não tem sprite pra carregar o clima — a fonte é
o clima. E monoespaçada no corpo resolve alinhamento de coluna de graça, que é
metade do trabalho numa tela que é quase toda tabela.

| arquivo | fonte | papel | onde |
|---|---|---|---|
| `vt323.ttf` | **VT323** | display | títulos, o número grande da idade, placas de clube |
| `pixel_code.ttf` | **Pixel Code** | corpo | tabelas, rótulos, o log do draft, tudo o mais |

As duas cobrem a acentuação portuguesa inteira (á à ã â é ê í ó ô õ ú ç e as
maiúsculas) — checado glifo por glifo na `cmap`, porque fonte pixel bonita sem
cedilha é fonte que não serve.

## Procedência e licença

**VT323** — desenhada por Peter Hull a partir da matriz de caracteres do
terminal DEC VT320. A própria fonte declara a licença na tabela `name`:

> This Font Software is licensed under the SIL Open Font License, Version 1.1.

**Pixel Code** — veio de `ScrapWarriors/game/resources/fonts/terminal.ttf`, o
outro jogo da casa. ⚠️ **O arquivo não declara licença na tabela `name`.** A
Pixel Code é distribuída sob OFL-1.1 pelo autor (Qwerasd), mas isso não está
verificado a partir do arquivo — antes de qualquer release comercial, confirme
a origem e vendore o texto da licença aqui do lado.

## O que NÃO entrou, e por quê

- **ChronoType** (`chronotype.ttf`, `dialog.ttf`) — é a fonte que aparece em
  quase todo projeto da casa, mas declara
  *Creative Commons Attribution Non-commercial Share Alike*. **Non-commercial**
  mata ela pra um jogo que pode ser vendido. Vale rever no resto dos projetos.
- **Avalancheno** — é bitmap de verdade e tem cara, mas tem 91 glifos e
  nenhum acento. Não escreve português.

## Nitidez, e os números não são gosto

Fonte pixel renderizada com antialiasing vira mingau, então antialiasing,
hinting e subpixel positioning estão desligados no `.import`, e o filtro de
textura do projeto está em **Nearest**.

Mas isso é metade. A outra metade são **duas** coisas que foram medidas lendo
os arquivos, não escolhidas:

### O tamanho tem que cair na grade da fonte

O maior divisor comum das caixas de todos os glifos **é** o tamanho de um pixel
de design. Num corpo em que isso não cai num pixel inteiro de tela, a haste
alterna entre 1 e 2 pixels de largura — é exatamente esse o borrão.

| fonte | grade medida | corpos nítidos |
|---|---|---|
| **Pixel Code** | 112 unidades por pixel num em de 1008 → 9 px de design por em | **9 · 18 · 27 · 36** |
| **VT323** | mdc 4 num em de 1000 → não é grid-aligned | nenhum; ver abaixo |

A primeira escada usava 12, 14 e 16. Todos fora da grade, e o 16 no pior caso:
punha um pixel de design em **1,78** pixels de tela.

Por isso **o corpo tem um tamanho só**: não existe degrau nítido entre 9 (que
não se lê a 1x) e 18, e inventar um é reinventar o borrão. Hierarquia sai da
**cor**, que já era como essas telas faziam a maior parte dela.

A **VT323 não é fonte de pixel** — é outline lisa imitando um CRT. Nenhum corpo
deixa as hastes perfeitamente uniformes; com antialiasing desligado ela sai de
aresta dura de qualquer jeito, e em tamanho de display a irregularidade é o que
um CRT era mesmo. O que ela tem é uma restrição de métrica: ascent 800 e descent
-200 num em de 1000, então **só múltiplo de 5** põe a linha de base em pixel
inteiro. Fora disso a linha desloca meio pixel e tudo nela amolece.

Se algum dia quiser pixel-perfect estrito também no display, o troco é usar
Pixel Code em 27 ou 36 — perde o contraste entre as duas, ganha a grade.

### A escala da janela tem que ser inteira

`display/window/stretch/scale_mode="integer"`. O modo padrão (`fractional`)
escala o canvas por quanto a janela precisar — 1,333x num 1440p — e cada glifo,
barra e retângulo é rasterizado numa fração de pixel. Não tem fonte que salve
isso.

E `display/window/dpi/allow_hidpi=true`, que é tão importante quanto: **sem ele
um monitor 4K não é um monitor 4K.** O Windows põe display de 4K em 150% por
padrão, e um app que não é DPI-aware recebe uma janela de 2560x1440 e depois é
esticado borrado pra preencher o painel. Junto com escala inteira isso dá um
desastre visível: `floor(2560/1920)` é **1**, então o jogo desenha um canvas de
1920x1080 no meio de uma janela de 2560x1440 — um quadrado pequeno, cercado de
borda, e ainda esticado pelo compositor.

`aspect="expand"` e não `keep`: a escala inteira já garante pixel inteiro, e o
`keep` ainda põe tarja no que a escala não usou. O `expand` entrega essa sobra
como canvas lógico extra. Numa resolução que é múltiplo exato — 3840x2160 em 2x —
os dois são idênticos, então o expand não custa nada ali e tira a borda em todo o
resto.

## A aritmética do tamanho aparente

Essa é a conta que decide tudo, e não tem como fugir dela:

```
tamanho aparente = corpo lógico × escala inteira
escala inteira   = floor(resolução da tela / canvas de projeto)
canvas           = resolução da tela / escala      (a sobra vira canvas)
```

A escala é calculada em `Look.fit_window()` e **não** no project.godot, porque a
configuração não consegue expressar a regra: `scale_mode="integer"` arredonda a
escala pra baixo e põe tarja na sobra, e `aspect="expand"` não devolve essa
sobra. Num monitor 2560x1440 isso desenhava o canvas no meio da tela com borda
em volta — um quadrado pequeno.

### O canvas de projeto é 1280x720

`Look.DESIGN_MIN`. Escolhido pra que **todo monitor comum peque um degrau
inteiro** em vez de ficar preso em 1x:

| monitor | escala | canvas | corpo 18 |
|---|---|---|---|
| 1920x1080 | 1x | 1920x720+ | 18 px reais |
| **2560x1440** | **2x** | **1280x720** | **36 px reais** |
| 3840x2160 | 3x | 1280x720 | 54 px reais |

O preço é o espaço: **1280x720 é o que toda tela tem que caber dentro**, e o
formulário de criação queria 1850x1040. Pago em **abas** — FICHA, HABILIDADES,
TALENTOS — e em disciplina: dica de uma linha com o resto no tooltip, rótulo de
campo virando placeholder, e os códigos de posição da tabela do elenco rodando em
`Look.MICRO` (9px, o outro degrau nítido) porque são dezoito colunas de duas ou
três letras num botão, não prosa.

`tests/fit_check.tscn` verifica os dois lados: cabe em 1280x720, e não cabe
usando menos de 60% da largura.

## O número está na tela

O canto inferior direito do menu inicial mostra
`2560x1440 · canvas 1280x720 · 2x · corpo 36px`. O primeiro par é a janela, o
segundo é o canvas; se os dois forem iguais, a escala é 1x e alguma coisa está
errada num monitor grande.
