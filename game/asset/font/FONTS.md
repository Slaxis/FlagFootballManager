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

### A janela é o canvas — um para um

`Look.fit_window()` põe `content_scale_size` igual à janela e
`content_scale_factor` em 1. **Não há escala nenhuma**: um pixel lógico é um
pixel de tela, que é o mais nítido que uma imagem consegue ser, porque não existe
etapa de reamostragem pra ser nítido *através* dela.

E `display/window/dpi/allow_hidpi=true`, sem o qual um monitor 4K não é um
monitor 4K: o Windows põe display de alta densidade em 150% por padrão, e um app
que não é DPI-aware recebe uma janela menor e depois é esticado borrado pra
preencher o painel.

#### Por que não escala inteira

Teve uma versão que escalava por número inteiro a partir de um canvas de
1280x720, então um monitor 1440p desenhava tudo em 2x. Aquilo é genuinamente
pixel-perfect — e é **outra estética**: grossa, próxima, SNES. Também ficava
apertada, porque 2x num 1440p deixa só 1280x720 de espaço de projeto e essa tela
é quase toda tabela.

**Pixel art de alta resolução** é a outra: glifo pequeno de aresta dura com
espaço em volta. Ela vem da **fonte** e do filtro **Nearest**, não de ampliar um
canvas pequeno.

⚠️ E `content_scale_size` e `content_scale_factor` **se multiplicam**. O `size` é
o canvas lógico que a engine já estica até a janela; o `factor` multiplica em
cima. Setar os dois pôs o jogo em 4x num monitor que devia dar 2x — viewport
lógico desabando pra 640x360 e formulários vazando pela borda. `tests/test_look.gd`
fixa os dois em "a janela, uma vez".

## O espaço de projeto é 2560x1440

`Look.DESIGN_MIN`, e é um **alvo**, não um divisor: a resolução pra qual as telas
são desenhadas e contra a qual `tests/fit_check.tscn` mede. Resolução menor é
problema pro dia em que alguém tiver uma.

Com todo esse espaço, as telas voltaram a caber de uma vez:

| tela | |
|---|---|
| criação | 2256x810 — três colunas, sem abas |
| draft | 1900x1028 |
| elenco | 1707x170 |

## O número está na tela

O canto inferior direito do menu inicial mostra
`2560x1440 · canvas 2560x1440 · 1.00x · corpo 18px`. Os dois pares iguais e
`1.00x` é o estado correto — qualquer outra coisa quer dizer que alguma escala
entrou no meio.
