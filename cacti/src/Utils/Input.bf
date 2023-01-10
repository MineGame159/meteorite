using System;
using System.Collections;

using GLFW;

namespace Cacti {
	typealias Key = GlfwInput.Key;
	typealias InputAction = GlfwInput.Action;

	static class Input {
		public typealias KeyCallback = delegate bool(Key key, InputAction action);
		public typealias CharCallback = delegate bool(char32 char);
		public typealias ScrollCallback = delegate bool(float scroll);
		public typealias MousePosCallback = delegate void();

		public static Vec2f mouse, mouseLast, mouseDelta;

		public static PriorityList<KeyCallback> keyEvent = new .() ~ DeleteContainerAndItems!(_);
		public static PriorityList<CharCallback> charEvent = new .() ~ DeleteContainerAndItems!(_);
		public static PriorityList<ScrollCallback> scrollEvent = new .() ~ DeleteContainerAndItems!(_);
		public static List<MousePosCallback> mousePosEvent = new .() ~ DeleteContainerAndItems!(_);

		public static bool capturingCharacters;

		private static bool[512] keys, keysLast;

		private static void Update() {
			mouseDelta = mouse - mouseLast;
			mouseLast = mouse;
			
			Internal.MemCpy(&keysLast, &keys, keys.Count);
		}

		public static bool IsKeyDown(Key key) => keys[(.) key];
		public static bool IsKeyPressed(Key key) => keys[(.) key] && !keysLast[(.) key];
		public static bool IsKeyReleased(Key key) => !keys[(.) key] && keysLast[(.) key];
	}
}