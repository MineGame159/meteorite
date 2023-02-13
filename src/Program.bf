using System;

using Cacti;
using Cacti.Graphics;

namespace Meteorite;

class Program {
	private static bool RENDERDOC =
#if DEBUG
		true;
#else
		false;
#endif

	public static void Main(String[] args) {
		if (Array.BinarySearch(args, "--renderdoc") != -1 || RENDERDOC) {
			Log.Info("Loading RenderDoc");
			RenderDoc.Init();
		}

		scope Meteorite().Run();
	}
}