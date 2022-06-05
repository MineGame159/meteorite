using System;
using System.Threading;

using GLFW;

namespace Meteorite {
	class Program {
		public static double FRAME_START;

		public static void Main() {
			Meteorite me = new .();

			double lastTime = Glfw.GetTime();
			bool a = false;

			while (!me.window.ShouldClose) {
				FRAME_START = Glfw.GetTime();
				float delta = (.) (FRAME_START - lastTime);
				lastTime = FRAME_START;

				Input.[Friend]Update();
				me.window.PollEvents();

				me.Render(delta);

				if (a) {
					GC.Collect(false);
					GC.Report();
				}

				if (me.window.minimized) Thread.Sleep(1);
			}

			delete Meteorite.INSTANCE;
		}
	}
}