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
escala inteira   = floor(resolução da tela / viewport base)
```

Num monitor 3840x2160:

| viewport base | escala | corpo 18 | corpo 27 | espaço lógico |
|---|---|---|---|---|
| **1920x1080** | **2x** | **36 px reais** | 54 px reais | 1920x1080 |
| 1280x720 | 3x | 54 px reais | 81 px reais | 1280x720 |

Com `aspect="expand"` só a escala importa: qualquer base entre 1281 e 1920 dá 2x
e entrega 1920 lógicos; entre 961 e 1280 dá 3x e entrega 1280.

O formulário de criação precisa de **1850x1040 lógicos** com o corpo em 18. Então
`1920x1080 @ 2x` é o ponto de projeto, e **36 pixels reais de corpo é o que a
densidade dessa tela compra**.

Querer letra maior é a mesma decisão vista duas vezes: **menos coisa por tela.**
Corpo 27 ou base 1280 só fecham se o formulário passar a caber em ~1280x720 — o
que significa abas, ou tirar habilidades e talentos do mesmo painel. É decisão de
design, não de constante.

## O número está na tela

O canto inferior direito do menu inicial mostra
`3840x2160 · canvas 1920x1080 · 2x · corpo 36px`. Se disser **1x**, a janela não
é múltiplo do canvas e nada mais na imagem vai parecer certo — foi assim que o
"quadrado no meio" apareceu.
