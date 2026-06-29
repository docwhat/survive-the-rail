package render

import (
	"image/color"

	"github.com/hajimehoshi/ebiten/v2"
)

type GameRenderer struct{}

func NewGameRenderer() *GameRenderer {
	return &GameRenderer{}
}

func (r *GameRenderer) Draw(screen *ebiten.Image) {
	screen.Fill(color.RGBA{76, 76, 76, 255})
}
