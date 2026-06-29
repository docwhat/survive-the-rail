package render

import (
	"image/color"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/text"
	"golang.org/x/image/font/basicfont"
)

type MenuRenderer struct {
	StartButton struct {
		X, Y, W, H int
	}
	QuitButton struct {
		X, Y, W, H int
	}
}

func NewMenuRenderer() *MenuRenderer {
	return &MenuRenderer{
		StartButton: struct{ X, Y, W, H int }{
			X: 540,
			Y: 300,
			W: 200,
			H: 50,
		},
		QuitButton: struct{ X, Y, W, H int }{
			X: 540,
			Y: 370,
			W: 200,
			H: 50,
		},
	}
}

func (r *MenuRenderer) Draw(screen *ebiten.Image) {
	// Background
	screen.Fill(color.RGBA{30, 30, 30, 255})

	// Draw Start Button
	r.drawButton(screen, r.StartButton, color.RGBA{100, 200, 100, 255}, "START")

	// Draw Quit Button
	r.drawButton(screen, r.QuitButton, color.RGBA{200, 100, 100, 255}, "QUIT")
}

func (r *MenuRenderer) drawButton(screen *ebiten.Image, rect struct{ X, Y, W, H int }, clr color.RGBA, label string) {
	// Draw Button Body
	for y := rect.Y; y < rect.Y+rect.H; y++ {
		for x := rect.X; x < rect.X+rect.W; x++ {
			screen.Set(x, y, clr)
		}
	}

	// Draw Border
	borderColor := color.RGBA{255, 255, 255, 255}
	for x := rect.X; x < rect.X+rect.W; x++ {
		screen.Set(x, rect.Y, borderColor)
		screen.Set(x, rect.Y+rect.H-1, borderColor)
	}
	for y := rect.Y; y < rect.Y+rect.H; y++ {
		screen.Set(rect.X, y, borderColor)
		screen.Set(rect.X+rect.W-1, y, borderColor)
	}

	// Draw Text Label (using basicfont as it's built-in and requires no external files)
	text.Draw(screen, label, basicfont.Face7x13, rect.X+rect.W/2-len(label)*3, rect.Y+rect.H/2+5, color.White)
}
