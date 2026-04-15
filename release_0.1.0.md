# FFM 0.1.0 — "Ato 0: Tryout"

Release playtest para amigos. Loop completo: abrir → criar → preparar 4 semanas → tryout → game over OU entrar num time da 4a divisão fictícia.

## Definition of Done

- [ ] Abre o jogo, menu principal com música
- [ ] Módulo → cutscene → home com ambient
- [ ] Celular lista os 4 times da 4a divisão, player escolhe, inscreve no tryout
- [ ] 4 semanas balanceando quest da mãe + stats + deck
- [ ] Tryout balanceado: game over esperado nas 1-2 primeiras tentativas
- [ ] Save/load funcional (single slot), Continue no menu quando save existe
- [ ] Game Over salva entrada no Hall of Fame
- [ ] Win screen se passar no tryout ("entrou no time X")
- [ ] Options: volumes + idioma + sair

---

## Hierarquia de Times (injetada no módulo brasil_2026)

Player começa na 4a divisão fictícia. Outras divisões existem pra progressão futura.

| Tier | Desc | Status MVP |
|---|---|---|
| Olimpico | Seleções IFAF (Brasil M/F) | Data only (referência) |
| 1a divisão | Times relevância nacional (Flag Kings, Cronos, etc.) | Data only |
| Estadual | Times relevância estadual | Data only |
| Menores | Times pequenos das cidades | Data only |
| **4a divisão (fictícia)** | **Liga mirim de adolescentes** | **Active — 4 times jogáveis** |

### 4 Times da 4a divisão (fictícios)

| Time | Cidade | Dificuldade | Foco |
|---|---|---|---|
| Atletinhas do Bairro | São Paulo | Fácil | Skills básicas |
| Raposas da Várzea | Rio de Janeiro | Médio-fácil | Velocidade |
| Lobinhos do Cerrado | Brasília | Médio | Defesa |
| Piratas da Praia | Santos | Difícil | QB/Complex |

---

## Card acquisition paths (Fase D.2)

Formas do player ganhar/reforçar cards:

1. **Assistir tutorial no YouTube** (atividade Watch Flag → chance de aprender common/uncommon aleatório)
2. **Treino com coach** (após entrar num time, treino da semana dá card da posição)
3. **Hangout com amigo** (relationship forte → amigo te ensina de graça)
4. **Shop no celular** (pagar R$ pra amigo/instrutor ensinar card específico)
5. **Reinforcement** (usar card em drill aumenta chance de sair no próximo)

---

## Fase A — Infraestrutura (BLOCKING)

### A.1 Save/Load (single slot)
- `user://save.json` com: session, technique_deck, technique_collection, vitals, money, week grid, quest progress, hall_of_fame, options
- `SaveManager` autoload: `save()`, `load()`, `has_save()`, `delete_save()`
- Auto-save após cada semana resolvida
- Manual save via options menu

### A.2 Continue button
- Main menu: Continue enabled se `SaveManager.has_save()`
- Click → carrega save → transiciona pra player_home direto

### A.3 Game Over screen
- Triggers: falhou 4 tryouts OU chegou fim da semana 4 sem aprovação
- Exibe: nome, idade, semanas, times tentados, stats finais
- Salva entrada no `hall_of_fame`: array de careers passadas
- Botão "Novo Jogo" (apaga save, volta pro menu)

### A.4 Hall of Fame (main menu / home)
- Widget no main menu exibindo careers passadas (nome, melhor resultado, tempo jogado)
- Persiste em save mesmo após game over

### A.5 Win screen (Ato 0 conclusion)
- Triggers: passou no tryout de um time da 4a div
- Cutscene curta: "Bem-vindo ao [Time]. Seu primeiro passo..."
- Botão "Continuar" (stub "Ato 1 em breve", volta pro menu com save preservado)

### A.6 Options menu
- Master volume, Music volume, SFX volume (sliders)
- Idioma PT/EN
- Save & Quit to Menu
- Quit to Desktop

---

## Fase B — Audio system

### B.1 AudioDef
- `game/defs/audio.json`: `music` dict e `sfx` dict mapeando id → caminho de arquivo
- Suporta i18n de nome, duration hint, loop flag

### B.2 AudioManager (autoload)
- `play_music(id)`, `stop_music()`, `play_sfx(id)`
- Respeita volumes das options
- Cross-fade entre músicas

### B.3 SFX wiring
- Card picked (drill minigame)
- Pass/Fail (situation result)
- Week advance (resolve all slots)
- Collapse (vital zero)
- Menu click, menu open/close
- Fridge open, phone open

### B.4 Music loops
- main_menu.ogg
- home_ambient.ogg
- drill_tense.ogg
- tryout_intense.ogg
- victory.ogg
- game_over.ogg

---

## Fase C — Conteúdo Ato 0

### C.1 Team data (4 divisões + olimpico)
- `game/modules/brasil_2026/content/things/teams/`:
  - Olimpico: br_flag_m, br_flag_f (IFAF selections)
  - 1a div: já tem 8 times existentes
  - Estadual: 4-6 por estado principal
  - Menores: 3-4 por cidade-alvo
  - **4a div (fictícios)**: 4 times teen com roster genérico

### C.2 Phone "Buscar Times"
- Opens from phone → list com tabs por divisão
- 4a div habilitada, outras mostram "Nível muito alto, treine mais"
- Card por time: nome, cidade, dificuldade, foco, botão "Inscrever Tryout"
- Inscrição adiciona tryout ao próximo slot disponível

### C.3 Tryout balance (calibrar dificuldade)
- Atletinhas: 4 situations, difficulty 5-6
- Raposas: 4 situations, difficulty 6-7
- Lobinhos: 5 situations, difficulty 7-8
- Piratas: 5 situations, difficulty 8-9
- pass_threshold = 60% (precisa 3/5 ou 2/4)
- Playtest target: jogador iniciante passa no Atletinhas na 3a tentativa

### C.4 Drill seed randomization
- Seed = `hash(team_id + tryout_attempt_number + player_id)`
- Shuffle situations/cards reproduzível
- Replay do mesmo tryout sem grinding memória muscular

### C.5 Game Over triggers
- Contador `tryout_failed_count` em session
- Ao fim da semana 4 sem team → game over
- 4 tryouts falhados → game over imediato

---

## Fase D — Loop enrichment

### D.1 Quest providers
- **Mãe**: quests casa/estudo, mesada semanal (R$20-50 baseado em quests completas)
- **Best Friend** (NPC): social quests, card reward no fim do mês
- **Tech Shop** (NPC virtual no celular): pagar pra aprender card específico
- Cada provider tem weekly quest pool + relationship level

### D.2 Card acquisition
- Activity `watch_flag_tutorial` (nova): YouTube tutorial → 20% chance random card uncommon
- Activity `hangout_friend` (existente): 15% chance card + reinforce existing
- Activity `team_practice` (bloqueada sem time): +1 card da posição se foi
- Shop no celular: pagar R$50-200 por card específico uncommon
- Reinforcement visual: memory mostra x2, x3, x4 conforme usa

### D.3 Weekly reward screen
- Fim de semana: summary + rewards obtidos (já existe, expandir)
- Incluir: stats ganhos, cards aprendidos, cards reforçados, money delta
- Relationship changes com providers

---

## Fase E — Pixel art + polish

### E.1 Asset loader
- `res://game/modules/brasil_2026/art/` com subpastas: `people/`, `events/`, `items/`, `tiles/`
- `AssetDef` com mapping id → path
- Fallback pra ColorRect se png não existe (já funciona)

### E.2 Sprite integration
- Drill minigame: sprites em `art/people/player_*.png`, `art/people/coach_*.png`, etc.
- Event illustrations nas cutscenes
- Team logos

### E.3 Polish pass
- Transições suaves entre telas
- Feedback visual em cliques
- Consistência de cores/fontes

---

## Ordem de execução

```
A.1 Save/Load          ← START HERE
A.2 Continue button
A.3 Game Over screen
A.4 Hall of Fame
A.5 Win screen
A.6 Options menu
B.1 AudioDef
B.2 AudioManager
B.3 SFX wiring
B.4 Music loops
C.1 Team data 4 divs
C.2 Phone team browser
C.3 Tryout balance
C.4 Drill seed
C.5 Game Over triggers
D.1 Quest providers
D.2 Card acquisition
D.3 Weekly rewards
E.1 Asset loader
E.2 Sprite integration
E.3 Polish
```
