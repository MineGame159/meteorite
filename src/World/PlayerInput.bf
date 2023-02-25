using System;

using Cacti;

namespace Meteorite;

abstract class PlayerInput {
	public bool forward, backward;
	public bool right, left;

	public bool sprint, sneak;
	public bool jump;

	public Vec2d movement;
	public double vertical;

	public virtual void Tick() {
		movement = .(
			forward == backward ? 0 : (forward ? -1 : 1),
			left == right ? 0 : (left ? 1 : -1)
		);

		vertical = jump == sneak ? 0 : (jump ? 1 : -1);
	}
}

class PlayerKeyboardInput : PlayerInput {
	public override void Tick() {
		forward = !Input.capturingCharacters && Input.IsKeyDown(.W);
		backward = !Input.capturingCharacters && Input.IsKeyDown(.S);
		right = !Input.capturingCharacters && Input.IsKeyDown(.D);
		left = !Input.capturingCharacters && Input.IsKeyDown(.A);

		sprint = !Input.capturingCharacters && Input.IsKeyDown(.LeftControl) || Input.IsKeyDown(.RightControl);
		sneak = !Input.capturingCharacters && Input.IsKeyDown(.LeftShift) || Input.IsKeyDown(.RightShift);
		jump = !Input.capturingCharacters && Input.IsKeyDown(.Space);

		base.Tick();
	}
}