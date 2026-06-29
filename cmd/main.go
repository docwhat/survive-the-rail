package main

import (
	"flag"
	"image/color"
	"log"
	"time"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/docwhat/survive-the-rail/ai-go/pkg/game"
	"github.com/docwhat/survive-the-rail/ai-go/pkg/render"
)

const (
	screenWidth  = 1280
	screenHeight = 720
)

type GameInstance struct {
	manager     *game.Manager
	menuRender  *render.MenuRenderer
	gameRender  *render.GameRenderer
	startTime   time.Time
	quitAfterMs int
}

func (g *GameInstance) Update() error {
	if g.quitAfterMs > 0 && time.Since(g.startTime).Milliseconds() >= int64(g.quitAfterMs) {
		return ebiten.Termination
	}

	mx, my := ebiten.CursorPosition()
	mouseDown := ebiten.IsMouseButtonPressed(ebiten.MouseButtonLeft)
	
	action, err := g.manager.Update(mx, my, mouseDown)
	if err != nil {
		return err
	}

	if action == game.ActionQuit {
		return ebiten.Termination
	}

	return nil
}

func (g *GameInstance) Draw(screen *ebiten.Image) {
	// Use the color to prevent unused import error
	_ = color.RGBA{0, 0, 0, 0}
	switch g.manager.State.CurrentState {
	case game.StateMenu:
		g.menuRender.Draw(screen)
	case game.StatePlaying:
		g.gameRender.Draw(screen)
	}
}

func (g *GameInstance) Layout(outsideWidth, outsideHeight int) (int, int) {
	return screenWidth, screenHeight
}

func main() {
	quitAfterMs := flag.Int("quit-after-ms", 0, "Auto-quit after this many milliseconds (0 = never)")
	flag.Parse()

	instance := &GameInstance{
		manager:     game.NewManager(),
		menuRender:  render.NewMenuRenderer(),
		gameRender:  render.NewGameRenderer(),
		startTime:   time.Now(),
		quitAfterMs: *quitAfterMs,
	}

	ebiten.SetWindowSize(screenWidth, screenHeight)
	ebiten.SetWindowTitle("Survive the Rail")
	if err := ebiten.RunGame(instance); err != nil {
		log.Fatal(err)
	}
}
