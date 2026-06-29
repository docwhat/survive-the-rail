package game

import (
	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"
)

type ScreenState int

const (
	StateMenu ScreenState = iota
	StatePlaying
)

type GameState struct {
	CurrentState ScreenState
}

type QuitAction int

const (
	ActionNone QuitAction = iota
	ActionQuit
)

type Manager struct {
	State *GameState
}

func NewManager() *Manager {
	return &Manager{
		State: &GameState{
			CurrentState: StateMenu,
		},
	}
}

func (m *Manager) Update(mouseX, mouseY int, mouseDown bool) (QuitAction, error) {
	switch m.State.CurrentState {
	case StateMenu:
		// Check for "Start" button
		if (mouseX >= 540 && mouseX <= 740 && mouseY >= 300 && mouseY <= 350) && mouseDown {
			m.State.CurrentState = StatePlaying
		}
		// Check for "Quit" button
		if (mouseX >= 540 && mouseX <= 740 && mouseY >= 370 && mouseY <= 420) && mouseDown {
			return ActionQuit, nil
		}
		// Check for Enter key
		if inpututil.IsKeyJustPressed(ebiten.KeyEnter) {
			m.State.CurrentState = StatePlaying
		}
	case StatePlaying:
		// Check for ESC (Return to Menu)
		if inpututil.IsKeyJustPressed(ebiten.KeyEscape) {
			m.State.CurrentState = StateMenu
		}
	}
	return ActionNone, nil
}
