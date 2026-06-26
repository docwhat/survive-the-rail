package main

import (
	"flag"
	"image/color"
	"log"
	"time"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"
)

const (
	screenWidth  = 1280
	screenHeight = 720
)

type Game struct {
	startTime   time.Time
	quitAfterMs int
}

func (g *Game) Update() error {
	if g.quitAfterMs > 0 && time.Since(g.startTime).Milliseconds() >= int64(g.quitAfterMs) {
		return ebiten.Termination
	}
	if inpututil.IsKeyJustPressed(ebiten.KeyEscape) {
		return ebiten.Termination
	}
	return nil
}

func (g *Game) Draw(screen *ebiten.Image) {
	screen.Fill(color.RGBA{76, 76, 76, 255})
}

func (g *Game) Layout(outsideWidth, outsideHeight int) (int, int) {
	return screenWidth, screenHeight
}

func main() {
	quitAfterMs := flag.Int("quit-after-ms", 0, "Auto-quit after this many milliseconds (0 = never)")
	flag.Parse()

	game := &Game{
		startTime:   time.Now(),
		quitAfterMs: *quitAfterMs,
	}

	ebiten.SetWindowSize(screenWidth, screenHeight)
	ebiten.SetWindowTitle("Survive the Rail")
	if err := ebiten.RunGame(game); err != nil {
		log.Fatal(err)
	}
}
