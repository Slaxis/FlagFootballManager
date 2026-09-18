# Curando elencos

Um atleta é um arquivo JSON em qualquer lugar debaixo de
`content/things/actor/`. **A organização das pastas é sua.** A engine varre
tudo e mescla por `id`, então estas três são igualmente válidas:

```
things/actor/flag_kings.json              o elenco inteiro num array
things/actor/flag_kings/qb.json           um arquivo por atleta
things/actor/tijuca/qualquer_nome.json    organizado por bairro
```

## O mínimo

```json
{
  "id": "kings_07",
  "team": "flag_kings",
  "plays": ["masc"],
  "first_name": "Fulano",
  "last_name": "de Tal"
}
```

Isso já é uma pessoa completa no jogo. **Tudo que você não escrever é gerado**
a partir da reputação do clube — atributos, habilidades, altura, peso, idade,
apelido. Você não precisa preencher 23 números por atleta.

O preenchimento é semeado pelo `id`, não pela semente da carreira: **o mesmo
atleta sai igual em toda partida que qualquer jogador começar.** Só os
jogadores gerados pra completar o elenco mudam com a semente.

## Vários num arquivo

```json
[
  {"id": "kings_01", "team": "flag_kings", "plays": ["masc"], "first_name": "..."},
  {"id": "kings_02", "team": "flag_kings", "plays": ["masc"], "first_name": "..."}
]
```

Num array, **todo mundo precisa de `id`** — um nome de arquivo não identifica
dez pessoas.

## Aprofundando quando você sabe

```json
{
  "id": "kings_07",
  "team": "flag_kings",
  "plays": ["masc", "misto"],
  "manages": ["fem"],
  "first_name": "Fulano", "last_name": "de Tal", "nickname": "Fulaninho",
  "age": 34,
  "quality": 78,
  "stats":  { "charisma": 80, "will": 75 },
  "skills": { "throwing": 70, "play_calling": 60 },
  "perks":  ["capitao"],
  "height": 1.84, "weight": 88
}
```

| campo | o que faz |
|---|---|
| `quality` | 0–100. Puxa **tudo** que você não fixou. Sem isso, usa a reputação do clube |
| `stats` / `skills` | 0–100, só os que você quiser. O resto continua gerado |
| `plays` | `["masc"]`, `["fem"]`, `["masc","misto"]`, `["fem","misto"]` ou `[]` |
| `manages` | modalidades que a pessoa **treina**. Um técnico tem `plays: []` |
| `perks` | no máximo 1. Ids em `game/defs/perk.json` |

⚠️ **`misto` nunca fica sozinho.** O time misto tem cota de mulheres, então o
elenco precisa saber se a pessoa ocupa vaga de homem ou de mulher.

## Override

Um arquivo que chega depois **mescla** por `id` — não substitui. Um mod do
jogador que só quer mudar uma coisa escreve só ela:

```json
{"id": "kings_07", "stats": {"strength": 100}}
```

O resto do atleta continua como estava. Conteúdo em `user://modules` chega
depois do conteúdo do jogo, então o mod do jogador sempre ganha.

## Antes de commitar

```bash
godot --headless --path . res://tests/run.tscn
```

`test_rosters::test_the_shipped_module_validates` roda a validação em cima do
seu elenco e reprova nomeando o atleta: clube que não existe, id duplicado,
habilidade escrita errado, número fora de 0–100, perk inventado, modalidade
inválida. **Um `team` com typo não dá erro em lugar nenhum — o atleta
simplesmente nunca aparece.** É pra isso que o teste existe.
