using System;
using GLFW;

namespace Meteorite {
	static class Input {
		public static Vec2 mouse, mouseLast, mouseDelta;

		private static bool[512] keys, keysLast;

		private static void Update() {
			mouseDelta = mouse - mouseLast;
			mouseLast = mouse;

			Internal.MemCpy(&keysLast, &keys, keys.Count);
		}

		public static bool IsKeyDown(GlfwInput.Key key) => keys[(.) key];
		public static bool IsKeyPressed(GlfwInput.Key key) => keys[(.) key] && !keysLast[(.) key];
		public static bool IsKeyReleased(GlfwInput.Key key) => !keys[(.) key] && keysLast[(.) key];
	}
}