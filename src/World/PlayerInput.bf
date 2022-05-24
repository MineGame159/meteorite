using System;

namespace Meteorite {
	interface PlayerInput {
		bool IsForward();
		bool IsBackward();
		bool IsRight();
		bool IsLeft();

		bool IsSprint();
		bool IsSneak();
		bool IsJump();

		double GetForward() {
			if (IsForward() == IsBackward()) return 0;
			return IsForward() ? -1 : 1;
		}

		double GetLeft() {
			if (IsLeft() == IsRight()) return 0;
			return IsLeft() ? 1 : -1;
		}
	}

	class PlayerKeyboardInput : PlayerInput {
		public bool IsForward() {
			return Input.IsKeyDown(.W);
		}

		public bool IsBackward() {
			return Input.IsKeyDown(.S);
		}

		public bool IsRight() {
			return Input.IsKeyDown(.D);
		}

		public bool IsLeft() {
			return Input.IsKeyDown(.A);
		}

		public bool IsSprint() {
			return Input.IsKeyDown(.LeftControl) || Input.IsKeyDown(.RightControl);
		}

		public bool IsSneak() {
			return Input.IsKeyDown(.LeftShift) || Input.IsKeyDown(.RightShift);
		}

		public bool IsJump() {
			return Input.IsKeyDown(.Space);
		}
	}
}