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
escala o canvas por quanto a janela precisar — 1,333x num monitor 1440p — e cada
glifo, barra e retângulo é rasterizado numa fração de pixel. Não tem fonte que
salve isso.

O custo é real: com viewport base 1920x1080, um monitor **1080p dá 1x**
(perfeito) e **2160p dá 2x** (perfeito). Um **1440p dá 1x com borda**, porque 2x
não cabe. A escolha nessa resolução é entre borda e borrão, e não existe terceira
opção sem mudar o viewport base — e um base menor (1280x720, que daria 2x em
1440p) não segura um formulário de 1850px.
