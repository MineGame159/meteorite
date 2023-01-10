using System;
using Cacti;

namespace Meteorite {
	class Program {
		private static bool RENDERDOC = true;

		public static void Main(String[] args) {
			if (Array.BinarySearch(args, "--renderdoc") != -1 || RENDERDOC) {
				Log.Info("Loading RenderDoc");
				Internal.LoadSharedLibrary("renderdoc");
			}

			RenderDoc.Init();

			scope Meteorite().Run();
		}
	}
}