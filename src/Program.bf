using System;
using System.Threading;

using GLFW;

namespace Meteorite {
	class Program {
		public static double FRAME_START;

		private static bool RENDERDOC = false;

		public static void Main(String[] args) {
			if (Array.BinarySearch(args, "--renderdoc") != -1 || RENDERDOC) {
				Log.Info("Loading RenderDoc");
				Internal.LoadSharedLibrary("renderdoc");
			}

			Meteorite me = new .();

			double lastTime = Glfw.GetTime();

			while (!me.window.ShouldClose) {
				FRAME_START = Glfw.GetTime();
				float delta = (.) (FRAME_START - lastTime);
				lastTime = FRAME_START;

				Input.[Friend]Update();
				me.window.PollEvents();

				me.Render(delta);

				if (me.window.minimized) Thread.Sleep(1);
			}

			delete Meteorite.INSTANCE;
		}
	}
}