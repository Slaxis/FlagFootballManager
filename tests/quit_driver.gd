# Lives under the tree root, NOT in the boot scene — the scene the Flow swaps
# in frees whatever was there, which is the whole point of the check.
extends Node

func run() -> void:
	for i: int in range(30):
		await get_tree().process_frame
	var screen: Node = get_tree().current_scene
	print(">> TELA: ", screen.name if screen != null else "<nula>")
	var quit_button: Button = _find(screen, UiText.t("start.quit"))
	if quit_button == null:
		print(">> FALHOU: nao achei o botao Sair")
		get_tree().quit(1)
		return
	print(">> APERTANDO: ", quit_button.text)
	quit_button.pressed.emit()
	for i: int in range(40):
		await get_tree().process_frame
	print(">> FALHOU: o jogo continua vivo depois de apertar Sair")
	get_tree().quit(1)

func _find(node: Node, label: String) -> Button:
	if node == null:
		return null
	if node is Button and (node as Button).text == label:
		return node
	for child: Node in node.get_children():
		var found: Button = _find(child, label)
		if found != null:
			return found
	return null
