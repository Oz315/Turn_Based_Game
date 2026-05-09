extends Node
## Autoload global script to hold signals that reach across scenes
##
## If you want to trigger something in the UI on player turns, in _ready()
## connect player_turn to some local _on_player_turn(player) function:
##
## SignalBus.player_turn.connect(_on_player_turn)

signal any_moved
signal inc_turn()
signal player_turn(player: Player)
signal any_died(unit)
signal reset_turns
signal retry
